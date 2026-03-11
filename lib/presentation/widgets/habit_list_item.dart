import 'package:flutter/material.dart';

import '../../domain/models/entities/habit.dart';
import '../localization/app_strings.dart';

class HabitListItem extends StatelessWidget {
  final Habit habit;
  final bool isCompletedToday;
  final VoidCallback onToggleCompleted;
  final VoidCallback onEdit;

  const HabitListItem({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onToggleCompleted,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(_iconForSpec(habit.specialization),
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _labelForSpec(habit.specialization),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Checkbox(
                    value: isCompletedToday,
                    onChanged: (_) => onToggleCompleted(),
                  ),
                  Text(
                    AppStrings.completedToday,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForSpec(HabitSpecialization spec) {
    switch (spec) {
      case HabitSpecialization.sport:
        return Icons.fitness_center;
      case HabitSpecialization.creativity:
        return Icons.brush;
      case HabitSpecialization.finance:
        return Icons.account_balance_wallet;
      case HabitSpecialization.social:
        return Icons.group;
      case HabitSpecialization.processing:
        return Icons.settings;
    }
  }

  String _labelForSpec(HabitSpecialization spec) {
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
