import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/habit.dart';
import '../state/category_view_model.dart';
import '../state/habit_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

class HabitListItem extends StatefulWidget {
  final Habit habit;
  final bool isCompletedToday;
  final VoidCallback onToggleCompleted;
  final VoidCallback onEdit;

  /// If true, the item starts in collapsed (dismissed) state.
  final bool isPending;

  const HabitListItem({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onToggleCompleted,
    required this.onEdit,
    this.isPending = false,
  });

  @override
  State<HabitListItem> createState() => HabitListItemState();
}

class HabitListItemState extends State<HabitListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dismissCtrl;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _fadeOut;

  bool _completionVisual = false; // strikethrough + dimmed text
  int _generation = 0; // guards stale Future.delayed callbacks

  @override
  void initState() {
    super.initState();
    _dismissCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sizeFactor = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeOut));
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeOut));

    if (widget.isPending) {
      _dismissCtrl.value = 1.0;
      _completionVisual = true;
    }
  }

  /// Play completion visual → 600ms pause → size+fade dismiss.
  Future<void> playDismiss() async {
    if (_dismissCtrl.value == 1.0) return;
    final gen = ++_generation;
    setState(() => _completionVisual = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || gen != _generation) return;
    await _dismissCtrl.forward();
  }

  /// Reverse dismiss animation (for undo).
  Future<void> playAppear() async {
    ++_generation;
    await _dismissCtrl.reverse();
    if (!mounted) return;
    setState(() => _completionVisual = false);
  }

  @override
  void dispose() {
    _dismissCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.isCompletedToday || _completionVisual;
    final colors = AppColors.of(context);
    final category =
        context.watch<CategoryViewModel>().byId(widget.habit.categoryId);

    return SizeTransition(
      sizeFactor: _sizeFactor,
      child: FadeTransition(
        opacity: _fadeOut,
        child: AnimatedOpacity(
          opacity: isDone ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 4),
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: widget.onEdit,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10),
                  child: Row(
                    children: [
                      _CategoryIcon(emoji: category?.icon ?? '·'),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.habit.title,
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w500,
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                                decorationColor: colors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              category?.name ?? '',
                              style: AppText.footnote.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildAction(context, isDone),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Right-side action: counter UI for counter habits, circular tick for binary.
  Widget _buildAction(BuildContext context, bool isDone) {
    if (widget.habit.isCounter && !isDone) {
      return _CounterAction(habit: widget.habit);
    }
    return _CompletionIndicator(
      completed: isDone,
      onTap: widget.onToggleCompleted,
    );
  }
}

// ─── Pieces ────────────────────────────────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  final String emoji;
  const _CategoryIcon({required this.emoji});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceElevated,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }
}

/// Apple-style circular completion checkmark.
class _CompletionIndicator extends StatelessWidget {
  final bool completed;
  final VoidCallback onTap;

  const _CompletionIndicator({
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? colors.accent : Colors.transparent,
            border: Border.all(
              color: completed ? colors.accent : colors.textTertiary,
              width: 1.5,
            ),
          ),
          child: completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}

/// Counter UI: shows current progress as `n/target` plus a single +1 tap.
/// Long-press on the chip subtracts 1 (forgiving, no separate – button to
/// keep the row visually quiet).
class _CounterAction extends StatelessWidget {
  final Habit habit;
  const _CounterAction({required this.habit});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HabitViewModel>();
    final colors = AppColors.of(context);
    final progress = vm.todayProgressFor(habit);
    final target = habit.targetValue;

    return GestureDetector(
      onTap: () => vm.incrementProgressToday(habit),
      onLongPress: () => vm.decrementProgressToday(habit),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$progress / $target',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.add_rounded, color: colors.accent, size: 16),
          ],
        ),
      ),
    );
  }
}
