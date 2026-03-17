import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/entities/habit.dart';
import '../../domain/models/entities/habit_completion.dart';
import '../../domain/models/weekly_stats.dart';
import '../../domain/repositories/habit_completion_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/usecases/compute_weekly_stats.dart';
import '../../domain/usecases/filter_habits_for_date.dart';
import '../../domain/utils/time_utils.dart';
import 'user_view_model.dart';

const int _xpPerCompletion = 30;

class HabitViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final HabitCompletionRepository _completionRepository;
  final FilterHabitsForDateUseCase _filterHabits;
  final ComputeWeeklyStatsUseCase _computeWeeklyStats;
  UserViewModel? _userViewModel;

  // ignore: avoid_setters_without_getters
  set userViewModel(UserViewModel? vm) => _userViewModel = vm;

  List<Habit> _habits = [];
  List<HabitCompletion> _completions = [];
  bool _isLoading = false;

  /// Pending completions waiting for undo timeout (habitId → timer).
  final Map<int, Timer> _pendingCompletions = {};

  HabitViewModel({
    required HabitRepository habitRepository,
    required HabitCompletionRepository completionRepository,
  })  : _habitRepository = habitRepository,
        _completionRepository = completionRepository,
        _filterHabits = FilterHabitsForDateUseCase(),
        _computeWeeklyStats = ComputeWeeklyStatsUseCase();

  List<Habit> get habits => _habits;
  List<HabitCompletion> get completions => _completions;
  bool get isLoading => _isLoading;

  /// Habits scheduled for today that are NOT yet completed in DB.
  /// Pending habits (not in DB) still pass the filter.
  List<Habit> get todayHabits {
    final now = TimeUtils.nowUtc3();
    return _filterHabits(_habits, now)
        .where((h) => !isHabitCompletedToday(h))
        .toList();
  }

  List<Habit> habitsForDate(DateTime date) => _filterHabits(_habits, date);

  WeeklyStats get weeklyStats =>
      _computeWeeklyStats(_habits, _completions, TimeUtils.nowUtc3());

  /// Whether a habit is in the pending-completion state (waiting for undo).
  bool isHabitPending(int habitId) => _pendingCompletions.containsKey(habitId);

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

  bool isHabitCompletedToday(Habit habit) {
    return isHabitCompletedOnDate(habit, TimeUtils.nowUtc3());
  }

  bool isHabitCompletedOnDate(Habit habit, DateTime date) {
    return _completions.any((c) =>
        c.habitId == habit.id &&
        c.completed &&
        TimeUtils.isSameUtc3Date(c.date, date));
  }

  // ── Pending completion flow (LifeScreen undo) ─────────────────────────────

  /// Mark habit as pending completion. No DB write yet.
  /// After [duration] the completion is auto-confirmed.
  void startPendingCompletion(Habit habit,
      {Duration duration = const Duration(seconds: 4)}) {
    final id = habit.id!;
    debugPrint('[HabitVM] startPendingCompletion id=$id');
    _pendingCompletions[id]?.cancel();
    _pendingCompletions[id] = Timer(duration, () {
      debugPrint('[HabitVM] Timer fired for id=$id, calling confirm');
      _confirmPendingCompletion(habit);
    });
    notifyListeners();
  }

  /// Cancel pending completion (user tapped undo).
  void cancelPendingCompletion(int habitId) {
    debugPrint('[HabitVM] cancelPendingCompletion id=$habitId');
    _pendingCompletions.remove(habitId)?.cancel();
    notifyListeners();
  }

  /// Finalize: write to DB + award XP.
  Future<void> _confirmPendingCompletion(Habit habit) async {
    final id = habit.id!;
    debugPrint('[HabitVM] _confirmPendingCompletion START id=$id');
    _pendingCompletions.remove(id);
    try {
      final today = TimeUtils.nowUtc3();
      final completion = HabitCompletion(
        habitId: id,
        date: TimeUtils.toUtc3Date(today),
        completed: true,
      );
      await _completionRepository.insertCompletion(completion);
      _completions = await _completionRepository.getAllCompletions();
      debugPrint('[HabitVM] DB done. _userViewModel=${_userViewModel != null ? "SET" : "NULL"}');
      if (_userViewModel != null) {
        await _userViewModel!.awardXp(_xpPerCompletion);
        debugPrint('[HabitVM] awardXp done, xp=${_userViewModel!.user?.currentXp}');
      }
    } catch (e, st) {
      debugPrint('[HabitVM] _confirmPendingCompletion ERROR: $e\n$st');
    }
    notifyListeners();
    debugPrint('[HabitVM] _confirmPendingCompletion END id=$id');
  }

  // ── Direct toggle (UpcomingScreen / uncomplete on LifeScreen) ─────────────

  Future<void> toggleHabitCompletionToday(Habit habit) async {
    final today = TimeUtils.nowUtc3();
    if (isHabitCompletedToday(habit)) {
      await _completionRepository.deleteCompletionByHabitAndDate(
          habit.id!, today);
      _completions.removeWhere((c) =>
          c.habitId == habit.id && TimeUtils.isSameUtc3Date(c.date, today));
    } else {
      final completion = HabitCompletion(
        habitId: habit.id!,
        date: TimeUtils.toUtc3Date(today),
        completed: true,
      );
      await _completionRepository.insertCompletion(completion);
      _completions = await _completionRepository.getAllCompletions();
      await _userViewModel?.awardXp(_xpPerCompletion);
    }
    notifyListeners();
  }

  Future<void> toggleHabitCompletionOnDate(Habit habit, DateTime date) async {
    if (isHabitCompletedOnDate(habit, date)) {
      await _completionRepository.deleteCompletionByHabitAndDate(
          habit.id!, date);
      _completions.removeWhere((c) =>
          c.habitId == habit.id && TimeUtils.isSameUtc3Date(c.date, date));
      await _userViewModel?.revokeXpAmount(_xpPerCompletion);
    } else {
      final completion = HabitCompletion(
        habitId: habit.id!,
        date: TimeUtils.toUtc3Date(date),
        completed: true,
      );
      await _completionRepository.insertCompletion(completion);
      _completions = await _completionRepository.getAllCompletions();
      await _userViewModel?.awardXp(_xpPerCompletion);
    }
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

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
    for (final timer in _pendingCompletions.values) {
      timer.cancel();
    }
    _pendingCompletions.clear();
    super.dispose();
  }
}
