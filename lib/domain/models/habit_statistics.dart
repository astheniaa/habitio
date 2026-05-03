enum StatsPeriod { week, month, allTime }

class HabitStatistics {
  final int habitId;
  final int currentStreak;
  final int bestStreak;
  final double completionPercentage;
  final int consolidationProgress; // 0–21
  final bool isConsolidated;
  final int postConsolidationStreak;
  final bool freezeActive;
  final int totalCompletions;
  final int totalScheduledDays;

  const HabitStatistics({
    required this.habitId,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionPercentage,
    required this.consolidationProgress,
    required this.isConsolidated,
    required this.postConsolidationStreak,
    required this.freezeActive,
    required this.totalCompletions,
    required this.totalScheduledDays,
  });

  static const empty = HabitStatistics(
    habitId: 0,
    currentStreak: 0,
    bestStreak: 0,
    completionPercentage: 0,
    consolidationProgress: 0,
    isConsolidated: false,
    postConsolidationStreak: 0,
    freezeActive: false,
    totalCompletions: 0,
    totalScheduledDays: 0,
  );
}

class OverallStatistics {
  final int totalCompletionsInPeriod;
  final int activityStreak; // consecutive calendar days with ≥1 completion
  final int bestHabitStreak;
  final String? bestHabitStreakName; // title of the habit with best streak

  const OverallStatistics({
    required this.totalCompletionsInPeriod,
    required this.activityStreak,
    required this.bestHabitStreak,
    this.bestHabitStreakName,
  });

  static const empty = OverallStatistics(
    totalCompletionsInPeriod: 0,
    activityStreak: 0,
    bestHabitStreak: 0,
  );
}
