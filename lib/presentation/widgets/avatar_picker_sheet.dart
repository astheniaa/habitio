import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../state/locale_provider.dart';
import '../state/user_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key});

  static const _rpgAvatars = ['⚔️', '🛡️', '🧙', '🏹', '🗡️', '🔮', '🪄', '👑'];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final vm = context.read<UserViewModel>();
    final currentRpgId = vm.user?.avatarRpgId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
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
            Text(loc.avatarPickerTitle, style: AppText.title),
            const SizedBox(height: AppSpacing.lg),

            // ── Photo ───────────────────────────────────────────────────────
            Text(loc.fromGallery.toUpperCase(), style: AppText.sectionLabel),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(Icons.image_outlined, color: AppColors.accent),
              ),
              title: Text(loc.choosePhoto, style: AppText.body),
              onTap: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                );
                if (image != null) {
                  await vm.updateAvatar(
                    avatarPath: image.path,
                    avatarRpgId: null,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── RPG avatars ────────────────────────────────────────────────
            Text(loc.rpgAvatarsTitle.toUpperCase(),
                style: AppText.sectionLabel),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _rpgAvatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final emoji = _rpgAvatars[index];
                  final isSelected = currentRpgId == emoji;
                  return GestureDetector(
                    onTap: () async {
                      await vm.updateAvatar(
                        avatarPath: null,
                        avatarRpgId: emoji,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.divider,
                          width: isSelected ? 2 : 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Language toggle ────────────────────────────────────────────
            Text(loc.languageLabel.toUpperCase(),
                style: AppText.sectionLabel),
            const SizedBox(height: AppSpacing.sm),
            const _LanguageToggle(),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeVm = context.watch<LocaleProvider>();
    final code = localeVm.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;

    Widget tab(String langCode, String label) {
      final active = code == langCode;
      return Expanded(
        child: GestureDetector(
          onTap: () => context
              .read<LocaleProvider>()
              .setLocale(Locale(langCode)),
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          tab('ru', loc.languageRussian),
          tab('en', loc.languageEnglish),
        ],
      ),
    );
  }
}
