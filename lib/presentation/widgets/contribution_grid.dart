import 'package:flutter/material.dart';

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
  static const _completedColor = Color(0xFF4CAF50);
  static const _missedColor = Color(0xFF5C3A3A);
  static const _notScheduledColor = Color(0xFF1E1E1E);
  static const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    // Align to Monday start
    final firstMonday = periodStart
        .subtract(Duration(days: (periodStart.weekday - 1) % 7));

    // Build list of weeks (columns)
    final weeks = <List<DateTime?>>[];
    var d = firstMonday;
    while (!d.isAfter(periodEnd)) {
      final week = <DateTime?>[];
      for (int i = 0; i < 7; i++) {
        final day = d.add(Duration(days: i));
        if (day.isBefore(periodStart) || day.isAfter(periodEnd)) {
          week.add(null); // outside range
        } else {
          week.add(day);
        }
      }
      weeks.add(week);
      d = d.add(const Duration(days: 7));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // most recent weeks on the right, scroll starts at end
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day labels column
          Column(
            children: List.generate(7, (i) {
              return SizedBox(
                width: 22,
                height: _cellSize + _cellGap,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dayLabels[i],
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              );
            }),
          ),
          // Grid columns
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(right: _cellGap),
              child: Column(
                children: week.map((day) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: _cellGap),
                    child: _Cell(
                      size: _cellSize,
                      color: _colorForDay(day),
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

  Color _colorForDay(DateTime? day) {
    if (day == null) return Colors.transparent;
    final normalized = DateTime.utc(day.year, day.month, day.day);
    if (data.containsKey(normalized)) {
      return data[normalized]! ? _completedColor : _missedColor;
    }
    return _notScheduledColor;
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
