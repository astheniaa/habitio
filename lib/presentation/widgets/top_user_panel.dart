import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/user.dart';
import '../localization/app_strings.dart';
import '../state/user_view_model.dart';

class TopUserPanel extends StatelessWidget {
  const TopUserPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading || vm.user == null) {
          return const LinearProgressIndicator();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _UserInfo(user: vm.user!),
        );
      },
    );
  }
}

class _UserInfo extends StatelessWidget {
  final User user;

  const _UserInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    final xpProgress =
        user.xpToNextLevel > 0 ? user.currentXp / user.xpToNextLevel : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text('${AppStrings.level} ${user.level}'),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: xpProgress.clamp(0.0, 1.0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppStrings.xp}: ${user.currentXp}/${user.xpToNextLevel}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
