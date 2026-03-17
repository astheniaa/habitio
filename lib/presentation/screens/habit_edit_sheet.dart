import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/habit.dart';
import '../localization/app_strings.dart';
import '../state/habit_view_model.dart';

class HabitEditSheet extends StatefulWidget {
  final Habit? habit;
  /// Pre-select this weekday (1=Mon … 7=Sun) when creating a new habit.
  final int? initialWeekday;

  const HabitEditSheet({super.key, this.habit, this.initialWeekday});

  @override
  State<HabitEditSheet> createState() => _HabitEditSheetState();
}

class _HabitEditSheetState extends State<HabitEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late HabitSpecialization _selectedSpec;
  late HabitScheduleType _scheduleType;
  late Set<int> _selectedWeekdays;
  bool _weekdayError = false;

  bool get _isEditing => widget.habit != null;

  int get _todayWeekday => DateTime.now().weekday; // 1=Пн … 7=Вс

  static const _weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _titleController = TextEditingController(text: habit?.title ?? '');
    _selectedSpec = habit?.specialization ?? HabitSpecialization.sport;
    _scheduleType = habit?.scheduleType ??
        (widget.initialWeekday != null
            ? HabitScheduleType.selectedWeekdays
            : HabitScheduleType.everyday);
    _selectedWeekdays = habit != null
        ? Set<int>.from(habit.weekdays)
        : (widget.initialWeekday != null
            ? {widget.initialWeekday!}
            : <int>{});
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditing
                      ? AppStrings.editHabitTitle
                      : AppStrings.createHabitTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.habitTitleLabel,
                    hintText: AppStrings.habitTitleHint,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.validationTitleRequired
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<HabitSpecialization>(
                  initialValue: _selectedSpec,
                  decoration: const InputDecoration(
                    labelText: AppStrings.specializationLabel,
                    border: OutlineInputBorder(),
                  ),
                  items: HabitSpecialization.values.map((spec) {
                    return DropdownMenuItem(
                      value: spec,
                      child: Text(_specLabel(spec)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSpec = v);
                  },
                ),
                const SizedBox(height: 16),
                Text(AppStrings.scheduleLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                RadioGroup<HabitScheduleType>(
                  groupValue: _scheduleType,
                  onChanged: (v) {
                    if (v != null) setState(() => _scheduleType = v);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<HabitScheduleType>(
                        title: Text(AppStrings.everyDay),
                        value: HabitScheduleType.everyday,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<HabitScheduleType>(
                        title: Text(AppStrings.specificDays),
                        value: HabitScheduleType.selectedWeekdays,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                if (_scheduleType == HabitScheduleType.selectedWeekdays) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final isToday = day == _todayWeekday;
                      final isSelected = _selectedWeekdays.contains(day);
                      return FilterChip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_weekdayLabels[i]),
                            if (isToday)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _weekdayError = false;
                            if (selected) {
                              _selectedWeekdays.add(day);
                              // Если выбраны все 7 дней — переключаем на «каждый день»
                              if (_selectedWeekdays.length == 7) {
                                _scheduleType = HabitScheduleType.everyday;
                                _selectedWeekdays.clear();
                              }
                            } else {
                              _selectedWeekdays.remove(day);
                            }
                          });
                        },
                      );
                    }),
                  ),
                  if (_weekdayError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        AppStrings.validationWeekdayRequired,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (_isEditing)
                      TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text(AppStrings.delete),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text(AppStrings.save),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_scheduleType == HabitScheduleType.selectedWeekdays &&
        _selectedWeekdays.isEmpty) {
      setState(() => _weekdayError = true);
      return;
    }

    final vm = context.read<HabitViewModel>();
    List<int> weekdays;
    if (_scheduleType == HabitScheduleType.selectedWeekdays) {
      weekdays = _selectedWeekdays.toList()..sort();
    } else {
      weekdays = <int>[];
    }

    if (_isEditing) {
      final updated = widget.habit!.copyWith(
        title: _titleController.text.trim(),
        specialization: _selectedSpec,
        scheduleType: _scheduleType,
        weekdays: weekdays,
      );
      vm.updateHabit(updated);
    } else {
      final newHabit = Habit(
        title: _titleController.text.trim(),
        specialization: _selectedSpec,
        scheduleType: _scheduleType,
        weekdays: weekdays,
      );
      vm.addHabit(newHabit);
    }

    Navigator.of(context).pop();
  }

  void _delete() {
    context.read<HabitViewModel>().deleteHabit(widget.habit!);
    Navigator.of(context).pop();
  }

  String _specLabel(HabitSpecialization spec) {
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
