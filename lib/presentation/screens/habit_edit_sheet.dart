import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/category.dart';
import '../../domain/models/entities/habit.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/category_view_model.dart';
import '../state/habit_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'category_manager_screen.dart';

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
  late TextEditingController _targetController;
  late TextEditingController _unitController;

  int? _categoryId;
  late HabitScheduleType _scheduleType;
  late HabitType _habitType;
  late Set<int> _selectedWeekdays;
  bool _weekdayError = false;

  bool get _isEditing => widget.habit != null;
  int get _todayWeekday => DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _titleController = TextEditingController(text: h?.title ?? '');
    _targetController =
        TextEditingController(text: (h?.targetValue ?? 1).toString());
    _unitController = TextEditingController(text: h?.unit ?? '');
    _categoryId = h?.categoryId;
    _habitType = h?.habitType ?? HabitType.binary;
    _scheduleType = h?.scheduleType ??
        (widget.initialWeekday != null
            ? HabitScheduleType.selectedWeekdays
            : HabitScheduleType.everyday);
    _selectedWeekdays = h != null
        ? Set<int>.from(h.weekdays)
        : (widget.initialWeekday != null
            ? {widget.initialWeekday!}
            : <int>{});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final categories = context.watch<CategoryViewModel>().categories;

    // Default to first category on first build for new habits.
    if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _grabHandle(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _isEditing ? loc.editHabitTitle : loc.createHabitTitle,
                  style: AppText.title,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                _label(loc.habitTitleLabel),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(hint: loc.habitTitleHint),
                  style: AppText.body,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? loc.validationTitleRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Category picker
                _label(loc.categoryLabel),
                const SizedBox(height: AppSpacing.sm),
                _categoryPicker(categories, loc),
                const SizedBox(height: AppSpacing.lg),

                // Habit type segment
                _label(loc.habitTypeLabel),
                const SizedBox(height: AppSpacing.sm),
                _habitTypeSegment(loc),
                const SizedBox(height: AppSpacing.lg),

                // Counter-only fields
                if (_habitType == HabitType.counter) ...[
                  _counterFields(loc),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Schedule
                _label(loc.scheduleLabel),
                const SizedBox(height: AppSpacing.sm),
                _scheduleSegment(loc),
                if (_scheduleType == HabitScheduleType.selectedWeekdays) ...[
                  const SizedBox(height: AppSpacing.md),
                  _weekdayChips(loc),
                  if (_weekdayError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        loc.validationWeekdayRequired,
                        style: const TextStyle(
                          color: AppColors.destructive,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.xl),

                // Action row
                Row(
                  children: [
                    if (_isEditing)
                      TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.destructive),
                        child: Text(loc.delete),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(loc.save),
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

  // ── Building blocks ──────────────────────────────────────────────────────

  Widget _grabHandle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.hairline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: AppText.sectionLabel,
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
      );

  Widget _categoryPicker(List<Category> categories, AppLocalizations loc) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            // Manage button (last)
            return _CategoryManageChip(label: loc.manageCategoriesAction);
          }
          final cat = categories[index];
          final selected = cat.id == _categoryId;
          return GestureDetector(
            onTap: () => setState(() => _categoryId = cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minWidth: 64),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accentMuted
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: selected
                    ? Border.all(color: AppColors.accent, width: 1)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cat.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _habitTypeSegment(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _segmentTab(
            label: loc.habitTypeBinary,
            sublabel: loc.habitTypeBinaryHint,
            active: _habitType == HabitType.binary,
            onTap: () => setState(() => _habitType = HabitType.binary),
          ),
          _segmentTab(
            label: loc.habitTypeCounter,
            sublabel: loc.habitTypeCounterHint,
            active: _habitType == HabitType.counter,
            onTap: () => setState(() => _habitType = HabitType.counter),
          ),
        ],
      ),
    );
  }

  Widget _segmentTab({
    required String label,
    required String sublabel,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: active
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counterFields(AppLocalizations loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(loc.targetLabel),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration(),
                style: AppText.body,
                validator: (v) {
                  if (_habitType != HabitType.counter) return null;
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return loc.validationTargetRequired;
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(loc.unitLabel),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _unitController,
                decoration: _inputDecoration(hint: loc.unitHint),
                style: AppText.body,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scheduleSegment(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _scheduleTab(
            label: loc.everyDay,
            active: _scheduleType == HabitScheduleType.everyday,
            onTap: () => setState(() {
              _scheduleType = HabitScheduleType.everyday;
            }),
          ),
          _scheduleTab(
            label: loc.specificDays,
            active: _scheduleType == HabitScheduleType.selectedWeekdays,
            onTap: () => setState(() {
              _scheduleType = HabitScheduleType.selectedWeekdays;
            }),
          ),
        ],
      ),
    );
  }

  Widget _scheduleTab({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _weekdayChips(AppLocalizations loc) {
    final labels = [
      loc.weekdayMon,
      loc.weekdayTue,
      loc.weekdayWed,
      loc.weekdayThu,
      loc.weekdayFri,
      loc.weekdaySat,
      loc.weekdaySun,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isToday = day == _todayWeekday;
        final isSelected = _selectedWeekdays.contains(day);
        return GestureDetector(
          onTap: () => setState(() {
            _weekdayError = false;
            if (isSelected) {
              _selectedWeekdays.remove(day);
            } else {
              _selectedWeekdays.add(day);
              if (_selectedWeekdays.length == 7) {
                _scheduleType = HabitScheduleType.everyday;
                _selectedWeekdays.clear();
              }
            }
          }),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.accent : AppColors.surface,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.accent, width: 1)
                  : null,
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Save / delete ────────────────────────────────────────────────────────

  void _save() {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.validationCategoryRequired)));
      return;
    }

    if (_scheduleType == HabitScheduleType.selectedWeekdays &&
        _selectedWeekdays.isEmpty) {
      setState(() => _weekdayError = true);
      return;
    }

    final vm = context.read<HabitViewModel>();
    final weekdays = _scheduleType == HabitScheduleType.selectedWeekdays
        ? (_selectedWeekdays.toList()..sort())
        : <int>[];

    final target = int.tryParse(_targetController.text) ?? 1;
    final unit = _unitController.text.trim();

    if (_isEditing) {
      final updated = widget.habit!.copyWith(
        title: _titleController.text.trim(),
        categoryId: _categoryId,
        scheduleType: _scheduleType,
        weekdays: weekdays,
        habitType: _habitType,
        targetValue: _habitType == HabitType.counter ? target : 1,
        unit: _habitType == HabitType.counter ? unit : '',
      );
      vm.updateHabit(updated);
    } else {
      vm.addHabit(Habit(
        title: _titleController.text.trim(),
        categoryId: _categoryId!,
        scheduleType: _scheduleType,
        weekdays: weekdays,
        habitType: _habitType,
        targetValue: _habitType == HabitType.counter ? target : 1,
        unit: _habitType == HabitType.counter ? unit : '',
      ));
    }

    Navigator.of(context).pop();
  }

  void _delete() {
    context.read<HabitViewModel>().deleteHabit(widget.habit!);
    Navigator.of(context).pop();
  }
}

/// Last chip in the category list — opens the manager.
class _CategoryManageChip extends StatelessWidget {
  final String label;
  const _CategoryManageChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tune_rounded,
                size: 22, color: AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
