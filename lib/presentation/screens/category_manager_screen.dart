import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/category.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/category_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

class CategoryManagerScreen extends StatelessWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.manageCategories),
      ),
      body: Consumer<CategoryViewModel>(
        builder: (context, vm, _) {
          final categories = vm.categories;
          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            buildDefaultDragHandles: true,
            itemCount: categories.length,
            onReorder: (oldIdx, newIdx) {
              final list = List<Category>.from(categories);
              if (newIdx > oldIdx) newIdx -= 1;
              final item = list.removeAt(oldIdx);
              list.insert(newIdx, item);
              vm.reorder(list);
            },
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryRow(
                key: ValueKey(cat.id),
                category: cat,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(loc.newCategory,
            style: const TextStyle(color: Colors.white)),
        onPressed: () => _openEditor(context, null),
      ),
    );
  }
}

void _openEditor(BuildContext context, Category? existing) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _CategoryEditorSheet(existing: existing),
  );
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  const _CategoryRow({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => _openEditor(context, category),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                  ),
                  child:
                      Text(category.icon, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(category.name, style: AppText.body),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textTertiary),
                  onPressed: () => _confirmDelete(context, category, loc),
                ),
                const Icon(Icons.drag_handle_rounded,
                    color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Category category,
    AppLocalizations loc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(loc.categoryDeleteConfirmTitle),
        content: Text(loc.categoryDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success =
        await context.read<CategoryViewModel>().delete(category.id!);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.categoryInUseError)),
      );
    }
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  final Category? existing;
  const _CategoryEditorSheet({this.existing});

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _icon;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _icon = TextEditingController(text: widget.existing?.icon ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isEdit ? loc.renameCategory : loc.newCategory,
                style: AppText.title,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _icon,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                      decoration: InputDecoration(
                        hintText: '🏃',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      style: AppText.body,
                      autofocus: !isEdit,
                      decoration: InputDecoration(
                        hintText: loc.categoryNameLabel,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    onPressed: _submit,
                    child: Text(loc.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final icon = _icon.text.trim();
    if (name.isEmpty) return;
    final vm = context.read<CategoryViewModel>();
    if (widget.existing != null) {
      await vm.rename(widget.existing!, name, icon);
    } else {
      await vm.add(name: name, icon: icon);
    }
    if (mounted) Navigator.of(context).pop();
  }
}
