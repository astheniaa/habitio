import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/habit.dart';
import '../../domain/models/entities/habit_completion.dart';
import '../../domain/models/habit_statistics.dart';
import '../../domain/usecases/compute_habit_statistics.dart';
import '../localization/app_strings.dart';
import '../state/habit_view_model.dart';
import '../state/user_view_model.dart';
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

  static const _green = Color(0xFF4CAF50);
  static const _cardColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<HabitViewModel, UserViewModel>(
      builder: (context, habitVm, userVm, _) {
        final habits = habitVm.habits.where((h) => !h.isArchived).toList();
        final completions = habitVm.completions;

        final showIce = _useCase.hadMissYesterday(habits, completions) &&
            !_useCase.hasCompletionToday(completions);

        final overall = _useCase.computeOverall(habits, completions, _period);

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _periodSwitcher(),
                  const SizedBox(height: 12),
                  _overallStatsCard(overall),
                  const SizedBox(height: 12),
                  _rpgBlock(userVm, overall),
                  const SizedBox(height: 16),
                  ..._specializationBlocks(habits, completions),
                ],
              ),
            ),
            if (showIce) _iceOverlay(),
          ],
        );
      },
    );
  }

  // ── Period switcher ─────────────────────────────────────────────────────

  Widget _periodSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: StatsPeriod.values.map((p) {
            final isActive = p == _period;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _period = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _green.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _periodLabel(p),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? _green : const Color(0xFF888888),
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

  String _periodLabel(StatsPeriod p) {
    switch (p) {
      case StatsPeriod.week:
        return AppStrings.periodWeek;
      case StatsPeriod.month:
        return AppStrings.periodMonth;
      case StatsPeriod.allTime:
        return AppStrings.periodAllTime;
    }
  }

  // ── Overall stats card ──────────────────────────────────────────────────

  Widget _overallStatsCard(OverallStatistics overall) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _miniStat(
              Icons.check_circle_outline,
              _green,
              '${overall.totalCompletionsInPeriod}',
              AppStrings.completedInPeriod,
            ),
            _miniStat(
              Icons.local_fire_department,
              const Color(0xFFFF9800),
              '${overall.activityStreak} ${AppStrings.daysShort}',
              AppStrings.activityStreak,
            ),
            _miniStat(
              Icons.emoji_events,
              const Color(0xFFFFD700),
              '${overall.bestHabitStreak} ${AppStrings.daysShort}',
              overall.bestHabitStreakName ?? AppStrings.bestStreakLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── RPG block ───────────────────────────────────────────────────────────

  Widget _rpgBlock(UserViewModel userVm, OverallStatistics overall) {
    final user = userVm.user;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Level badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  '${user.level}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // XP bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.level} ${user.level}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: user.xpToNextLevel > 0
                          ? user.currentXp / user.xpToNextLevel
                          : 0,
                      backgroundColor: const Color(0xFF2D2D2D),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_green),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.currentXp} / ${user.xpToNextLevel} XP',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Activity streak
            Column(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF9800),
                  size: 26,
                ),
                const SizedBox(height: 2),
                Text(
                  '${overall.activityStreak}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'дней',
                  style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Specialization blocks ───────────────────────────────────────────────

  List<Widget> _specializationBlocks(
    List<Habit> habits,
    List<HabitCompletion> completions,
  ) {
    return HabitSpecialization.values.map((spec) {
      final specHabits =
          habits.where((h) => h.specialization == spec).toList();
      return _specBlock(spec, specHabits, completions);
    }).toList();
  }

  Widget _specBlock(
    HabitSpecialization spec,
    List<Habit> habits,
    List<HabitCompletion> completions,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(_specIcon(spec), color: _green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _specLabel(spec),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${habits.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            if (habits.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  AppStrings.noHabitsInCategory,
                  style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                ),
              )
            else ...[
              ...habits.map((h) => _habitRow(h, completions)),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _habitRow(Habit habit, List<HabitCompletion> completions) {
    final stats = _useCase.call(habit, completions, _period);

    return InkWell(
      onTap: () => _openDetail(habit, stats, completions),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    habit.title,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (stats.freezeActive)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.ac_unit,
                      color: Color(0xFF64B5F6),
                      size: 16,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${stats.currentStreak}🔥',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(stats.completionPercentage * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _consolidationBar(stats),
          ],
        ),
      ),
    );
  }

  Widget _consolidationBar(HabitStatistics stats) {
    if (stats.isConsolidated) {
      return Row(
        children: [
          const Icon(Icons.verified, color: _green, size: 14),
          const SizedBox(width: 4),
          Text(
            '${AppStrings.consolidated} · ${stats.postConsolidationStreak} ${AppStrings.daysShort}',
            style: const TextStyle(fontSize: 11, color: _green),
          ),
          if (stats.freezeActive) ...[
            const SizedBox(width: 6),
            const Icon(Icons.ac_unit, color: Color(0xFF64B5F6), size: 13),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: stats.consolidationProgress / 21.0,
              backgroundColor: const Color(0xFF2D2D2D),
              valueColor: AlwaysStoppedAnimation<Color>(
                stats.freezeActive ? const Color(0xFF64B5F6) : _green,
              ),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${stats.consolidationProgress}/21',
          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
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

  // ── Ice overlay ─────────────────────────────────────────────────────────

  Widget _iceOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.12),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ac_unit,
                    size: 72,
                    color: Color(0xFF64B5F6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.iceOverlayTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.iceOverlaySubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  IconData _specIcon(HabitSpecialization spec) {
    switch (spec) {
      case HabitSpecialization.sport:
        return Icons.fitness_center;
      case HabitSpecialization.creativity:
        return Icons.brush;
      case HabitSpecialization.finance:
        return Icons.wallet;
      case HabitSpecialization.social:
        return Icons.group;
      case HabitSpecialization.processing:
        return Icons.settings;
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
