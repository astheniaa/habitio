import 'package:flutter/foundation.dart';

import '../../domain/models/entities/habit.dart';
import '../../domain/models/entities/habit_completion.dart';
import '../../domain/models/weekly_stats.dart';
import '../../domain/repositories/habit_completion_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/usecases/compute_weekly_stats.dart';
import '../../domain/usecases/filter_habits_for_date.dart';
import '../../domain/utils/time_utils.dart';

class HabitViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final HabitCompletionRepository _completionRepository;
  final FilterHabitsForDateUseCase _filterHabits;
  final ComputeWeeklyStatsUseCase _computeWeeklyStats;

  List<Habit> _habits = [];
  List<HabitCompletion> _completions = [];
  bool _isLoading = false;

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

  List<Habit> get todayHabits =>
      _filterHabits(_habits, TimeUtils.nowUtc3());

  WeeklyStats get weeklyStats =>
      _computeWeeklyStats(_habits, _completions, TimeUtils.nowUtc3());

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
    final today = TimeUtils.nowUtc3();
    return _completions.any((c) =>
        c.habitId == habit.id &&
        c.completed &&
        TimeUtils.isSameUtc3Date(c.date, today));
  }

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
    }
    notifyListeners();
  }

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
}
