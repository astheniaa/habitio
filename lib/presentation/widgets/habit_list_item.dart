import 'package:flutter/material.dart';

import '../../domain/models/entities/habit.dart';
import '../localization/app_strings.dart';

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
  static const _green = Color(0xFF4CAF50);

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
    _sizeFactor = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeOut));
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeOut));

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
    ++_generation; // invalidate any pending playDismiss
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
    final showCompleted = widget.isCompletedToday || _completionVisual;

    return SizeTransition(
      sizeFactor: _sizeFactor,
      child: FadeTransition(
        opacity: _fadeOut,
        child: AnimatedOpacity(
          opacity: (widget.isCompletedToday || _completionVisual) ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: InkWell(
            onTap: widget.onEdit,
            child: Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(_iconForSpec(widget.habit.specialization),
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.habit.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _labelForSpec(widget.habit.specialization),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Checkbox(
                          value: showCompleted,
                          onChanged: (_) => widget.onToggleCompleted(),
                          activeColor: _green,
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
