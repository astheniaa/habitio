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
    final colors = AppColors.of(context);
    final useCase = ComputeHabitStatisticsUseCase();
    final gridData = useCase.completionMap(habit, completions, period);
    final today = TimeUtils.toDate(TimeUtils.now());
    final periodStart = _periodStart(period, today);
    final category = context.watch<CategoryViewModel>().byId(habit.categoryId);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
                    color: colors.hairline,
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
                    style: AppText.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Contribution grid
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.activityTitle.toUpperCase(),
                      style: AppText.sectionLabel.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ContributionGrid(
                      data: gridData,
                      periodStart: periodStart,
                      periodEnd: today,
                    ),
                    const SizedBox(height: 8),
                    _gridLegend(context, loc),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _statsGrid(context, loc),
              const SizedBox(height: AppSpacing.lg),
              _consolidationCard(context, loc),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _gridLegend(BuildContext context, AppLocalizations loc) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _legendItem(context, colors.accent, loc.legendCompleted),
        const SizedBox(width: 12),
        _legendItem(context, colors.missed, loc.legendMissed),
        const SizedBox(width: 12),
        _legendItem(context, colors.surface, loc.legendNotScheduled),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    final colors = AppColors.of(context);
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
        Text(
          label,
          style: AppText.footnote.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }

  Widget _statsGrid(BuildContext context, AppLocalizations loc) {
    final colors = AppColors.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(
          context,
          loc.currentStreakLabel,
          '${stats.currentStreak} ${loc.daysShort}',
          Icons.local_fire_department,
          colors.streak,
        ),
        _statCard(
          context,
          loc.bestStreakLabel,
          '${stats.bestStreak} ${loc.daysShort}',
          Icons.emoji_events,
          colors.best,
        ),
        _statCard(
          context,
          loc.completionPercent,
          '${(stats.completionPercentage * 100).round()}%',
          Icons.percent,
          colors.accent,
        ),
        _statCard(
          context,
          loc.totalCompletions,
          '${stats.totalCompletions}',
          Icons.check_circle_outline,
          colors.accent,
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    final colors = AppColors.of(context);
    return Container(
      width: 155,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
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
          Text(
            label,
            style: AppText.footnote.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _consolidationCard(BuildContext context, AppLocalizations loc) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                stats.isConsolidated ? Icons.verified : Icons.track_changes,
                color:
                    stats.isConsolidated ? colors.accent : colors.textSecondary,
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
                Icon(Icons.ac_unit_rounded, color: colors.freeze, size: 16),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!stats.isConsolidated) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.consolidationProgress / 21.0,
                backgroundColor: colors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  stats.freezeActive ? colors.freeze : colors.accent,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.consolidationProgress} / 21 ${loc.daysShort}',
              style: AppText.caption.copyWith(color: colors.textSecondary),
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
