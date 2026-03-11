import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';

import '../../domain/models/entities/habit.dart';
import '../../domain/models/weekly_stats.dart';
import '../localization/app_strings.dart';

class ProfileRadarChart extends StatelessWidget {
  final WeeklyStats stats;

  const ProfileRadarChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = [
      [
        HabitSpecialization.sport,
        HabitSpecialization.creativity,
        HabitSpecialization.finance,
        HabitSpecialization.social,
        HabitSpecialization.processing,
      ].map((s) => stats.valueFor(s)).toList(),
    ];

    return RadarChart.dark(
      ticks: const [0, 1, 2, 3, 4, 5, 6, 7],
      features: const [
        AppStrings.sport,
        AppStrings.creativity,
        AppStrings.finance,
        AppStrings.social,
        AppStrings.processing,
      ],
      data: data,
    );
  }
}
