import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/habit.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/habit_view_model.dart';
import '../theme/app_colors.dart';
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
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    return Consumer<HabitViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = vm.todayHabits;
        if (habits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                loc.emptyToday,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
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
              onToggleCompleted: () => _handleToggle(vm, habit, loc),
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

  void _handleToggle(HabitViewModel vm, Habit habit, AppLocalizations loc) {
    // Counter habits don't go through the pending-undo flow at all — their
    // increment/decrement actions are wired directly inside HabitListItem.
    // The only time _handleToggle fires for a counter habit is when the
    // user taps the green tick to UN-complete a fully-completed habit.
    if (vm.isHabitCompletedToday(habit)) {
      vm.toggleHabitCompletionToday(habit);
      return;
    }

    if (habit.isCounter) {
      // Should be unreachable (counter habits show counter UI when not
      // done) but keep a sane fallback.
      vm.toggleHabitCompletionToday(habit);
      return;
    }

    if (vm.isHabitPending(habit.id!)) return;

    vm.startPendingCompletion(habit);
    _itemKeys[habit.id!]?.currentState?.playDismiss();
    _showUndoSnackbar(vm, habit, loc);
  }

  void _undo(HabitViewModel vm, int habitId) {
    vm.cancelPendingCompletion(habitId);
    _itemKeys[habitId]?.currentState?.playAppear();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _showUndoSnackbar(HabitViewModel vm, Habit habit, AppLocalizations loc) {
    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, bottom: 24, right: 80),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.divider, width: 0.5),
        ),
        duration: const Duration(seconds: 4),
        content: GestureDetector(
          onTap: () => _undo(vm, habit.id!),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.undo_rounded,
                  color: colors.destructive,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.undo,
                      style: TextStyle(
                        color: colors.destructive,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.doneLabel,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
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
