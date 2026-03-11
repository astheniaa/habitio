import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../state/habit_view_model.dart';
import '../widgets/habit_list_item.dart';
import 'habit_edit_sheet.dart';

class LifeScreen extends StatelessWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = vm.todayHabits;
        if (habits.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                AppStrings.emptyToday,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            return HabitListItem(
              habit: habit,
              isCompletedToday: vm.isHabitCompletedToday(habit),
              onToggleCompleted: () => vm.toggleHabitCompletionToday(habit),
              onEdit: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => HabitEditSheet(habit: habit),
              ),
            );
          },
        );
      },
    );
  }
}
