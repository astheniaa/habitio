import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/entities/habit.dart';
import '../../domain/models/entities/habit_completion.dart';
import '../../domain/models/habit_statistics.dart';
import '../../domain/repositories/habit_completion_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/usecases/compute_habit_statistics.dart';
import '../../domain/usecases/filter_habits_for_date.dart';
import '../../domain/utils/time_utils.dart';
import 'user_view_model.dart';

const int _xpPerCompletion = 30;
const int _xpConsolidationBonus = 150;

class HabitViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final HabitCompletionRepository _completionRepository;
  final FilterHabitsForDateUseCase _filterHabits;
  final ComputeHabitStatisticsUseCase _computeStats;

  UserViewModel? _userViewModel;
  // ignore: avoid_setters_without_getters
  set userViewModel(UserViewModel? vm) => _userViewModel = vm;

  List<Habit> _habits = [];
  List<HabitCompletion> _completions = [];
  bool _isLoading = false;

  /// Pending binary completions waiting for the undo timer (habitId → timer).
  final Map<int, Timer> _pendingCompletions = {};

  HabitViewModel({
    required HabitRepository habitRepository,
    required HabitCompletionRepository completionRepository,
  })  : _habitRepository = habitRepository,
        _completionRepository = completionRepository,
        _filterHabits = FilterHabitsForDateUseCase(),
        _computeStats = ComputeHabitStatisticsUseCase();

  List<Habit> get habits => _habits;
  List<HabitCompletion> get completions => _completions;
  bool get isLoading => _isLoading;

  /// Habits scheduled for today that are NOT yet completed in DB.
  /// Pending habits (not in DB) still pass the filter.
  List<Habit> get todayHabits {
    final now = TimeUtils.now();
    return _filterHabits(_habits, now)
        .where((h) => !isHabitCompletedToday(h))
        .toList();
  }

  List<Habit> habitsForDate(DateTime date) => _filterHabits(_habits, date);

  bool isHabitPending(int habitId) => _pendingCompletions.containsKey(habitId);

  // ── Loading ──────────────────────────────────────────────────────────────

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _habits = await _habitRepository.getAllHabits();
      _completions = await _completionRepository.getAllCompletions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Completion lookup ────────────────────────────────────────────────────

  bool isHabitCompletedToday(Habit habit) =>
      isHabitCompletedOnDate(habit, TimeUtils.now());

  bool isHabitCompletedOnDate(Habit habit, DateTime date) {
    return _completions.any((c) =>
        c.habitId == habit.id &&
        c.completed &&
        TimeUtils.isSameDate(c.date, date));
  }

  /// Returns the completion row for [habit] on [date], or null.
  HabitCompletion? _completionFor(Habit habit, DateTime date) {
    for (final c in _completions) {
      if (c.habitId == habit.id && TimeUtils.isSameDate(c.date, date)) {
        return c;
      }
    }
    return null;
  }

  /// Today's progress for a counter habit (0 if no row, else stored value).
  int todayProgressFor(Habit habit) {
    final row = _completionFor(habit, TimeUtils.now());
    return row?.progress ?? 0;
  }

  // ── Pending binary completion (LifeScreen undo flow) ─────────────────────

  /// Mark a binary habit as pending completion. No DB write yet.
  /// After [duration] the completion is auto-confirmed.
  void startPendingCompletion(Habit habit,
      {Duration duration = const Duration(seconds: 4)}) {
    final id = habit.id!;
    _pendingCompletions[id]?.cancel();
    _pendingCompletions[id] = Timer(duration, () {
      _confirmPendingCompletion(habit);
    });
    notifyListeners();
  }

  void cancelPendingCompletion(int habitId) {
    _pendingCompletions.remove(habitId)?.cancel();
    notifyListeners();
  }

  Future<void> _confirmPendingCompletion(Habit habit) async {
    final id = habit.id!;
    _pendingCompletions.remove(id);
    try {
      final today = TimeUtils.now();
      final completion = HabitCompletion(
        habitId: id,
        date: TimeUtils.toDate(today),
        completed: true,
        progress: habit.targetValue,
      );
      await _completionRepository.insertCompletion(completion);
      _completions = await _completionRepository.getAllCompletions();
      await _awardXpForCompletion(habit);
    } catch (e, st) {
      debugPrint('[HabitVM] confirmPending error: $e\n$st');
    }
    notifyListeners();
  }

  // ── Counter-habit progress ───────────────────────────────────────────────

  /// Increment today's progress on a counter habit by 1. When progress
  /// reaches the target the row is marked completed and XP is awarded.
  Future<void> incrementProgressToday(Habit habit) async {
    final today = TimeUtils.now();
    final todayDate = TimeUtils.toDate(today);
    final existing = _completionFor(habit, todayDate);

    if (existing == null) {
      // Brand-new row at progress = 1
      const wasComplete = false;
      const newProgress = 1;
      final isComplete = newProgress >= habit.targetValue;
      final row = HabitCompletion(
        habitId: habit.id!,
        date: todayDate,
        completed: isComplete,
        progress: newProgress,
      );
      await _completionRepository.insertCompletion(row);
      _completions = await _completionRepository.getAllCompletions();
      if (isComplete && !wasComplete) {
        await _awardXpForCompletion(habit);
      }
    } else {
      final newProgress = existing.progress + 1;
      final isComplete = newProgress >= habit.targetValue;
      final updated = existing.copyWith(
        progress: newProgress,
        completed: isComplete,
      );
      await _completionRepository.updateCompletion(updated);
      final idx = _completions.indexWhere((c) => c.id == existing.id);
      if (idx != -1) {
        final list = List<HabitCompletion>.from(_completions);
        list[idx] = updated;
        _completions = list;
      }
      if (isComplete && !existing.completed) {
        await _awardXpForCompletion(habit);
      }
    }
    notifyListeners();
  }

  /// Decrement today's progress by 1. If progress reaches 0 the row is
  /// deleted. If we drop below the target after being completed, the
  /// completion XP is revoked.
  Future<void> decrementProgressToday(Habit habit) async {
    final today = TimeUtils.now();
    final todayDate = TimeUtils.toDate(today);
    final existing = _completionFor(habit, todayDate);
    if (existing == null) return;

    final newProgress = existing.progress - 1;

    if (newProgress <= 0) {
      await _completionRepository.deleteCompletion(existing.id!);
      _completions =
          _completions.where((c) => c.id != existing.id).toList();
      if (existing.completed) {
        await _revokeXpForCompletion(habit);
      }
    } else {
      final isComplete = newProgress >= habit.targetValue;
      final updated = existing.copyWith(
        progress: newProgress,
        completed: isComplete,
      );
      await _completionRepository.updateCompletion(updated);
      final idx = _completions.indexWhere((c) => c.id == existing.id);
      if (idx != -1) {
        final list = List<HabitCompletion>.from(_completions);
        list[idx] = updated;
        _completions = list;
      }
      if (existing.completed && !isComplete) {
        await _revokeXpForCompletion(habit);
      }
    }
    notifyListeners();
  }

  // ── Direct toggle (Upcoming screen, undo on LifeScreen) ──────────────────

  Future<void> toggleHabitCompletionToday(Habit habit) async {
    await toggleHabitCompletionOnDate(habit, TimeUtils.now());
  }

  Future<void> toggleHabitCompletionOnDate(Habit habit, DateTime date) async {
    if (isHabitCompletedOnDate(habit, date)) {
      await _completionRepository.deleteCompletionByHabitAndDate(
          habit.id!, date);
      _completions.removeWhere((c) =>
          c.habitId == habit.id && TimeUtils.isSameDate(c.date, date));
      await _revokeXpForCompletion(habit);
    } else {
      final completion = HabitCompletion(
        habitId: habit.id!,
        date: TimeUtils.toDate(date),
        completed: true,
        progress: habit.targetValue,
      );
      await _completionRepository.insertCompletion(completion);
      _completions = await _completionRepository.getAllCompletions();
      await _awardXpForCompletion(habit);
    }
    notifyListeners();
  }

  // ── XP awarding (streak-aware) ───────────────────────────────────────────

  Future<void> _awardXpForCompletion(Habit habit) async {
    final vm = _userViewModel;
    if (vm == null) return;

    // Pre-completion streak — already excludes the just-inserted row
    // because compute_habit_statistics walks scheduled dates and counts
    // completedDates that contain each scheduled day. The row we just
    // added IS included in completedDates; subtract 1 so the multiplier
    // reflects the streak the user is _extending_, not the post-state.
    //
    // This keeps award/revoke symmetric (revoke runs after the row is
    // gone, so the stat there is already pre-completion).
    final stats =
        _computeStats.call(habit, _completions, StatsPeriod.allTime);
    final priorStreak = (stats.currentStreak - 1).clamp(0, 1 << 20);

    await vm.awardXpWithStreak(_xpPerCompletion, priorStreak);
    await _checkAndAwardConsolidationBonus(habit);
  }

  Future<void> _revokeXpForCompletion(Habit habit) async {
    final vm = _userViewModel;
    if (vm == null) return;
    final stats =
        _computeStats.call(habit, _completions, StatsPeriod.allTime);
    await vm.revokeXpWithStreak(_xpPerCompletion, stats.currentStreak);
  }

  /// One-time bonus when habit just reached 21/21 consolidation.
  Future<void> _checkAndAwardConsolidationBonus(Habit habit) async {
    if (habit.consolidationBonusAwarded) return;
    final justConsolidated =
        _computeStats.isJustConsolidated(habit, _completions);
    if (!justConsolidated) return;
    await _userViewModel!.awardXp(_xpConsolidationBonus);
    final updated = habit.copyWith(consolidationBonusAwarded: true);
    await _habitRepository.updateHabit(updated);
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      final list = List<Habit>.from(_habits);
      list[index] = updated;
      _habits = list;
    }
  }

  // ── Habit CRUD ───────────────────────────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    final inserted = await _habitRepository.insertHabit(habit);
    _habits = [..._habits, inserted];
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    await _habitRepository.updateHabit(habit);
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      final updated = List<Habit>.from(_habits);
      updated[index] = habit;
      _habits = updated;
      notifyListeners();
    }
  }

  Future<void> deleteHabit(Habit habit) async {
    await _habitRepository.deleteHabit(habit.id!);
    _habits = _habits.where((h) => h.id != habit.id).toList();
    _completions =
        _completions.where((c) => c.habitId != habit.id).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final t in _pendingCompletions.values) {
      t.cancel();
    }
    _pendingCompletions.clear();
    super.dispose();
  }
}
