import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/habit.dart';
import '../../domain/models/entities/habit_completion.dart';
import '../../domain/models/habit_statistics.dart';
import '../../domain/usecases/compute_habit_statistics.dart';
import '../../domain/utils/time_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/category_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final useCase = ComputeHabitStatisticsUseCase();
    final gridData = useCase.completionMap(habit, completions, period);
    final today = TimeUtils.toDate(TimeUtils.now());
    final periodStart = _periodStart(period, today);
    final category =
        context.watch<CategoryViewModel>().byId(habit.categoryId);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(habit.title, style: AppText.title),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (category != null) ...[
                    Text(category.icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    category?.name ?? '',
                    style: AppText.caption,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Contribution grid
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.activityTitle.toUpperCase(),
                      style: AppText.sectionLabel,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ContributionGrid(
                      data: gridData,
                      periodStart: periodStart,
                      periodEnd: today,
                    ),
                    const SizedBox(height: 8),
                    _gridLegend(loc),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _statsGrid(loc),
              const SizedBox(height: AppSpacing.lg),
              _consolidationCard(loc),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _gridLegend(AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _legendItem(AppColors.accent, loc.legendCompleted),
        const SizedBox(width: 12),
        _legendItem(const Color(0xFF5C3A3A), loc.legendMissed),
        const SizedBox(width: 12),
        _legendItem(AppColors.surface, loc.legendNotScheduled),
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
        Text(label, style: AppText.footnote),
      ],
    );
  }

  Widget _statsGrid(AppLocalizations loc) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(
          loc.currentStreakLabel,
          '${stats.currentStreak} ${loc.daysShort}',
          Icons.local_fire_department,
          AppColors.streak,
        ),
        _statCard(
          loc.bestStreakLabel,
          '${stats.bestStreak} ${loc.daysShort}',
          Icons.emoji_events,
          AppColors.best,
        ),
        _statCard(
          loc.completionPercent,
          '${(stats.completionPercentage * 100).round()}%',
          Icons.percent,
          AppColors.accent,
        ),
        _statCard(
          loc.totalCompletions,
          '${stats.totalCompletions}',
          Icons.check_circle_outline,
          AppColors.accent,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.footnote),
        ],
      ),
    );
  }

  Widget _consolidationCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                stats.isConsolidated ? Icons.verified : Icons.track_changes,
                color: stats.isConsolidated
                    ? AppColors.accent
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                stats.isConsolidated
                    ? loc.consolidated
                    : loc.consolidationProgress,
                style: AppText.callout,
              ),
              if (stats.freezeActive) ...[
                const SizedBox(width: 8),
                const Icon(Icons.ac_unit_rounded,
                    color: AppColors.freeze, size: 16),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!stats.isConsolidated) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.consolidationProgress / 21.0,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  stats.freezeActive ? AppColors.freeze : AppColors.accent,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.consolidationProgress} / 21 ${loc.daysShort}',
              style: AppText.caption,
            ),
          ] else
            Text(
              '${loc.postConsolidationStreak}: ${stats.postConsolidationStreak} ${loc.daysShort}',
              style: AppText.body,
            ),
        ],
      ),
    );
  }

  DateTime _periodStart(StatsPeriod period, DateTime today) {
    switch (period) {
      case StatsPeriod.week:
        return TimeUtils.weekStart(today);
      case StatsPeriod.month:
        return DateTime(today.year, today.month, 1);
      case StatsPeriod.allTime:
        return habit.createdAt != null
            ? TimeUtils.toDate(habit.createdAt!)
            : today;
    }
  }
}
