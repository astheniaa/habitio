import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/habit.dart';
import '../localization/app_strings.dart';
import '../state/habit_view_model.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/weekly_summary_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<HabitViewModel>(
      builder: (context, vm, _) {
        final stats = vm.weeklyStats;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 260,
                child: ProfileRadarChart(stats: stats),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  AppStrings.weeklyActivityTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              WeeklySummaryItem(
                label: AppStrings.sport,
                value: stats.valueFor(HabitSpecialization.sport),
              ),
              WeeklySummaryItem(
                label: AppStrings.creativity,
                value: stats.valueFor(HabitSpecialization.creativity),
              ),
              WeeklySummaryItem(
                label: AppStrings.finance,
                value: stats.valueFor(HabitSpecialization.finance),
              ),
              WeeklySummaryItem(
                label: AppStrings.social,
                value: stats.valueFor(HabitSpecialization.social),
              ),
              WeeklySummaryItem(
                label: AppStrings.processing,
                value: stats.valueFor(HabitSpecialization.processing),
              ),
            ],
          ),
        );
      },
    );
  }
}
