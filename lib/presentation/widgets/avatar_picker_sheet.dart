import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
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
    final colors = AppColors.of(context);
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
                  color: colors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(loc.avatarPickerTitle, style: AppText.title),
            const SizedBox(height: AppSpacing.lg),

            // ── Photo ───────────────────────────────────────────────────────
            Text(
              loc.fromGallery.toUpperCase(),
              style: AppText.sectionLabel
                  .copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colors.surface,
                child: Icon(Icons.image_outlined, color: colors.accent),
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
            Text(
              loc.rpgAvatarsTitle.toUpperCase(),
              style: AppText.sectionLabel
                  .copyWith(color: colors.textSecondary),
            ),
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
                        color: colors.surface,
                        border: Border.all(
                          color:
                              isSelected ? colors.accent : colors.divider,
                          width: isSelected ? 2 : 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
