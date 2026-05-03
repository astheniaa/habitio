import 'package:flutter/material.dart';

import '../../domain/models/entities/habit.dart';
import '../../domain/models/habit_statistics.dart';
import '../../domain/usecases/compute_habit_statistics.dart';
import '../../domain/models/entities/habit_completion.dart';
import '../../domain/utils/time_utils.dart';
import '../localization/app_strings.dart';
import 'contribution_grid.dart';

class HabitDetailSheet extends StatelessWidget {
  final Habit habit;
  final HabitStatistics stats;
  final List<HabitCompletion> completions;
  final StatsPeriod period;

  const HabitDetailSheet({
    super.key,
    required this.habit,
    required this.stats,
    required this.completions,
    required this.period,
  });

  static const _green = Color(0xFF4CAF50);
  static const _cardColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    final useCase = ComputeHabitStatisticsUseCase();
    final gridData = useCase.completionMap(habit, completions, period);
    final now = TimeUtils.nowUtc3();
    final today = TimeUtils.toUtc3Date(now);
    final periodStart = _periodStart(period, today);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                habit.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _specLabel(habit.specialization),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 20),

              // Contribution grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Активность',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ContributionGrid(
                      data: gridData,
                      periodStart: periodStart,
                      periodEnd: today,
                    ),
                    const SizedBox(height: 8),
                    _gridLegend(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats cards
              _statsGrid(),
              const SizedBox(height: 16),

              // Consolidation status
              _consolidationCard(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _gridLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _legendItem(const Color(0xFF4CAF50), 'Выполнено'),
        const SizedBox(width: 12),
        _legendItem(const Color(0xFF5C3A3A), 'Пропуск'),
        const SizedBox(width: 12),
        _legendItem(const Color(0xFF1E1E1E), 'Не запл.'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
      ],
    );
  }

  Widget _statsGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(
          AppStrings.currentStreakLabel,
          '${stats.currentStreak} ${AppStrings.daysShort}',
          Icons.local_fire_department,
          const Color(0xFFFF9800),
        ),
        _statCard(
          AppStrings.bestStreakLabel,
          '${stats.bestStreak} ${AppStrings.daysShort}',
          Icons.emoji_events,
          const Color(0xFFFFD700),
        ),
        _statCard(
          AppStrings.completionPercent,
          '${(stats.completionPercentage * 100).round()}%',
          Icons.percent,
          _green,
        ),
        _statCard(
          AppStrings.totalCompletions,
          '${stats.totalCompletions}',
          Icons.check_circle_outline,
          _green,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consolidationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                stats.isConsolidated ? Icons.verified : Icons.track_changes,
                color: stats.isConsolidated ? _green : const Color(0xFFCCCCCC),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                stats.isConsolidated
                    ? AppStrings.consolidated
                    : AppStrings.consolidationProgress,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (stats.freezeActive) ...[
                const SizedBox(width: 8),
                const Icon(Icons.ac_unit, color: Color(0xFF64B5F6), size: 16),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (!stats.isConsolidated) ...[
            // Progress bar 0-21
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.consolidationProgress / 21.0,
                backgroundColor: const Color(0xFF2D2D2D),
                valueColor: AlwaysStoppedAnimation<Color>(
                  stats.freezeActive ? const Color(0xFF64B5F6) : _green,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.consolidationProgress} / 21 ${AppStrings.daysShort}',
              style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            ),
          ] else ...[
            Text(
              '${AppStrings.postConsolidationStreak}: ${stats.postConsolidationStreak} ${AppStrings.daysShort}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  DateTime _periodStart(StatsPeriod period, DateTime today) {
    switch (period) {
      case StatsPeriod.week:
        return TimeUtils.weekStartUtc3(today);
      case StatsPeriod.month:
        return DateTime.utc(today.year, today.month, 1);
      case StatsPeriod.allTime:
        return habit.createdAt != null
            ? TimeUtils.toUtc3Date(habit.createdAt!)
            : today;
    }
  }

  String _specLabel(HabitSpecialization spec) {
    switch (spec) {
      case HabitSpecialization.sport:
        return AppStrings.sport;
      case HabitSpecialization.creativity:
        return AppStrings.creativity;
      case HabitSpecialization.finance:
        return AppStrings.finance;
      case HabitSpecialization.social:
        return AppStrings.social;
      case HabitSpecialization.processing:
        return AppStrings.processing;
    }
  }
}
