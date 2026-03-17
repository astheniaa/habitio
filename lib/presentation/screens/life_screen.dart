import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/habit.dart';
import '../localization/app_strings.dart';
import '../state/habit_view_model.dart';
import '../widgets/habit_list_item.dart';
import 'habit_edit_sheet.dart';

class LifeScreen extends StatefulWidget {
  const LifeScreen({super.key});

  @override
  State<LifeScreen> createState() => _LifeScreenState();
}

class _LifeScreenState extends State<LifeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// GlobalKeys to control dismiss/appear animations on each item.
  final Map<int, GlobalKey<HabitListItemState>> _itemKeys = {};

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            final key = _itemKeys.putIfAbsent(
                habit.id!, () => GlobalKey<HabitListItemState>());

            return HabitListItem(
              key: key,
              habit: habit,
              isCompletedToday: vm.isHabitCompletedToday(habit),
              isPending: vm.isHabitPending(habit.id!),
              onToggleCompleted: () => _handleToggle(vm, habit),
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

  void _handleToggle(HabitViewModel vm, Habit habit) {
    // Already completed in DB → uncomplete directly
    if (vm.isHabitCompletedToday(habit)) {
      vm.toggleHabitCompletionToday(habit);
      return;
    }

    // Already pending → ignore (item is collapsed, shouldn't happen)
    if (vm.isHabitPending(habit.id!)) return;

    // Start pending completion + dismiss animation + snackbar
    vm.startPendingCompletion(habit);
    _itemKeys[habit.id!]?.currentState?.playDismiss();
    _showUndoSnackbar(vm, habit);
  }

  void _undo(HabitViewModel vm, int habitId) {
    vm.cancelPendingCompletion(habitId);
    _itemKeys[habitId]?.currentState?.playAppear();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _showUndoSnackbar(HabitViewModel vm, Habit habit) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, bottom: 24, right: 80),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
        duration: const Duration(seconds: 4),
        content: GestureDetector(
          onTap: () => _undo(vm, habit.id!),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.undo_rounded,
                  color: Color(0xFFE57373),
                  size: 22,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Отменить',
                      style: TextStyle(
                        color: Color(0xFFE57373),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Выполнено',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
