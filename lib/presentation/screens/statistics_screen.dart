import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/category.dart';
import '../../domain/models/entities/habit.dart';
import '../../domain/models/entities/habit_completion.dart';
import '../../domain/models/habit_statistics.dart';
import '../../domain/usecases/compute_habit_statistics.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/category_view_model.dart';
import '../state/habit_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/habit_detail_sheet.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  StatsPeriod _period = StatsPeriod.week;
  final _useCase = ComputeHabitStatisticsUseCase();
  bool _missBannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<HabitViewModel, CategoryViewModel>(
      builder: (context, habitVm, catVm, _) {
        final habits = habitVm.habits.where((h) => !h.isArchived).toList();
        final completions = habitVm.completions;
        final loc = AppLocalizations.of(context)!;

        final showMissBanner = !_missBannerDismissed &&
            _useCase.hadMissYesterday(habits, completions) &&
            !_useCase.hasCompletionToday(completions);

        final overall = _useCase.computeOverall(habits, completions, _period);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showMissBanner) _missBanner(loc),
              const SizedBox(height: AppSpacing.sm),
              _periodSwitcher(loc),
              const SizedBox(height: AppSpacing.lg),
              _summaryRow(overall, loc),
              const SizedBox(height: AppSpacing.xl),
              ..._categorySections(catVm.categories, habits, completions, loc),
            ],
          ),
        );
      },
    );
  }

  // ── Banner ──────────────────────────────────────────────────────────────

  Widget _missBanner(AppLocalizations loc) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => setState(() => _missBannerDismissed = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.ac_unit_rounded, color: colors.freeze, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(loc.freezeNotification, style: AppText.callout),
                ),
                Icon(Icons.close_rounded, color: colors.textTertiary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Period switcher ─────────────────────────────────────────────────────

  Widget _periodSwitcher(AppLocalizations loc) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: StatsPeriod.values.map((p) {
            final active = p == _period;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _period = p),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? colors.surfaceElevated : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      _periodLabel(p, loc),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color:
                            active ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _periodLabel(StatsPeriod p, AppLocalizations loc) {
    switch (p) {
      case StatsPeriod.week:
        return loc.periodWeek;
      case StatsPeriod.month:
        return loc.periodMonth;
      case StatsPeriod.allTime:
        return loc.periodAllTime;
    }
  }

  // ── Summary cards ───────────────────────────────────────────────────────

  Widget _summaryRow(OverallStatistics overall, AppLocalizations loc) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              value: '${overall.totalCompletionsInPeriod}',
              label: loc.completedInPeriod,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _summaryCard(
              value: '${overall.activityStreak}',
              label: loc.activityStreak,
              suffix: loc.daysShort,
              accent: overall.activityStreak > 0
                  ? colors.streak
                  : colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String value,
    required String label,
    String? suffix,
    Color? accent,
  }) {
    final colors = AppColors.of(context);
    final effectiveAccent = accent ?? colors.textPrimary;
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
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: effectiveAccent,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(suffix,
                    style:
                        AppText.caption.copyWith(color: colors.textSecondary)),
              ],
            ],
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

  // ── Sections grouped by category ────────────────────────────────────────

  List<Widget> _categorySections(
    List<Category> categories,
    List<Habit> habits,
    List<HabitCompletion> completions,
    AppLocalizations loc,
  ) {
    final sections = <Widget>[];
    for (final cat in categories) {
      final catHabits = habits.where((h) => h.categoryId == cat.id).toList();
      if (catHabits.isEmpty) continue;
      sections.add(_section(cat, catHabits, completions, loc));
    }
    return sections;
  }

  Widget _section(
    Category cat,
    List<Habit> habits,
    List<HabitCompletion> completions,
    AppLocalizations loc,
  ) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Text(cat.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  cat.name.toUpperCase(),
                  style: AppText.sectionLabel
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                for (int i = 0; i < habits.length; i++) ...[
                  _habitRow(habits[i], completions, loc),
                  if (i < habits.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.md),
                      child: Divider(height: 0.5),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _habitRow(
    Habit habit,
    List<HabitCompletion> completions,
    AppLocalizations loc,
  ) {
    final colors = AppColors.of(context);
    final stats = _useCase.call(habit, completions, _period);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(habit, stats, completions),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      habit.title,
                      style: AppText.callout,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (stats.freezeActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.ac_unit_rounded,
                          color: colors.freeze, size: 14),
                    ),
                  if (stats.currentStreak > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _streakChip(stats.currentStreak, loc),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _consolidationLine(stats, loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _streakChip(int days, AppLocalizations loc) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$days ${loc.daysShort}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.streak,
        ),
      ),
    );
  }

  Widget _consolidationLine(HabitStatistics stats, AppLocalizations loc) {
    final colors = AppColors.of(context);
    if (stats.isConsolidated) {
      return Row(
        children: [
          Icon(Icons.verified_rounded, color: colors.accent, size: 14),
          const SizedBox(width: 4),
          Text(
            '${loc.consolidated} · ${stats.postConsolidationStreak} ${loc.daysShort}',
            style: AppText.footnote.copyWith(color: colors.accent),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: stats.consolidationProgress / 21.0,
              backgroundColor: colors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                stats.freezeActive ? colors.freeze : colors.accent,
              ),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${stats.consolidationProgress}/21',
          style: AppText.footnote.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }

  void _openDetail(
    Habit habit,
    HabitStatistics stats,
    List<HabitCompletion> completions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitDetailSheet(
        habit: habit,
        stats: stats,
        completions: completions,
        period: _period,
      ),
    );
  }
}
