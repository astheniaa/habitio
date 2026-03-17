import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../state/user_view_model.dart';

class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key});

  static const _rpgAvatars = ['⚔️', '🛡️', '🧙', '🏹', '🗡️', '🔮', '🪄', '👑'];

  static const _rpgColors = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF66BB6A),
    Color(0xFF8D6E63),
    Color(0xFF7E57C2),
    Color(0xFFEC407A),
    Color(0xFFFFCA28),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.read<UserViewModel>();
    final currentRpgId = vm.user?.avatarRpgId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.avatarPickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // ── Section 1: From gallery ──────────────────────────────────
            Text(
              AppStrings.fromGallery,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2A2A2A),
                child: Icon(Icons.image_outlined, color: Color(0xFF4CAF50)),
              ),
              title: const Text(AppStrings.choosePhoto),
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
            const SizedBox(height: 16),
            // ── Section 2: RPG avatars ───────────────────────────────────
            Text(
              AppStrings.rpgAvatarsTitle,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _rpgAvatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final emoji = _rpgAvatars[index];
                  final color = _rpgColors[index];
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
                        color: const Color(0xFF1E1E1E),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : color.withValues(alpha: 0.6),
                          width: isSelected ? 2.5 : 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
