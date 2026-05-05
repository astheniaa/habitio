import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// GitHub-style contribution grid.
/// [data] maps dates to completed (true) / missed (false).
/// Days not in the map are shown as "not scheduled" (dimmed).
class ContributionGrid extends StatelessWidget {
  final Map<DateTime, bool> data;
  final DateTime periodStart;
  final DateTime periodEnd;

  const ContributionGrid({
    super.key,
    required this.data,
    required this.periodStart,
    required this.periodEnd,
  });

  static const _cellSize = 14.0;
  static const _cellGap = 3.0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final dayLabels = [
      loc.weekdayMon,
      loc.weekdayTue,
      loc.weekdayWed,
      loc.weekdayThu,
      loc.weekdayFri,
      loc.weekdaySat,
      loc.weekdaySun,
    ];

    // Align to Monday start
    final firstMonday =
        periodStart.subtract(Duration(days: (periodStart.weekday - 1) % 7));

    final weeks = <List<DateTime?>>[];
    var d = firstMonday;
    while (!d.isAfter(periodEnd)) {
      final week = <DateTime?>[];
      for (int i = 0; i < 7; i++) {
        final day = d.add(Duration(days: i));
        if (day.isBefore(periodStart) || day.isAfter(periodEnd)) {
          week.add(null);
        } else {
          week.add(day);
        }
      }
      weeks.add(week);
      d = d.add(const Duration(days: 7));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: List.generate(7, (i) {
              return SizedBox(
                width: 22,
                height: _cellSize + _cellGap,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontSize: 9,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              );
            }),
          ),
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(right: _cellGap),
              child: Column(
                children: week.map((day) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: _cellGap),
                    child: _Cell(
                      size: _cellSize,
                      color: _colorForDay(day, colors),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _colorForDay(DateTime? day, AppPalette colors) {
    if (day == null) return Colors.transparent;
    final normalized = DateTime(day.year, day.month, day.day);
    if (data.containsKey(normalized)) {
      return data[normalized]! ? colors.accent : colors.missed;
    }
    return colors.surface;
  }
}

class _Cell extends StatelessWidget {
  final double size;
  final Color color;

  const _Cell({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
