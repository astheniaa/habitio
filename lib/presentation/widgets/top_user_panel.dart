import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/user.dart';
import '../localization/app_strings.dart';
import '../state/user_view_model.dart';
import 'avatar_picker_sheet.dart';

class TopUserPanel extends StatefulWidget {
  const TopUserPanel({super.key});

  @override
  State<TopUserPanel> createState() => _TopUserPanelState();
}

class _TopUserPanelState extends State<TopUserPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  Animation<double> _barAnim = const AlwaysStoppedAnimation(0);
  Animation<int> _xpNumAnim = const AlwaysStoppedAnimation(0);

  int _displayLevel = 1;
  int _displayDenom = 100;

  User? _prevUser;
  UserViewModel? _vm;
  bool _levelUpInProgress = false;
  OverlayEntry? _overlayEntry;
  Completer<void>? _overlayCompleter;

  static const _green = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<UserViewModel>();
    if (_vm != vm) {
      _vm?.removeListener(_onVmChanged);
      _vm = vm;
      _vm!.addListener(_onVmChanged);
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _ctrl.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    final vm = _vm;
    if (vm == null || vm.user == null) return;
    final user = vm.user!;

    if (_prevUser == null) {
      _initWithUser(user);
      return;
    }

    if (_levelUpInProgress) return;

    final hadLevelUp = vm.levelUpEvent != null;
    if (hadLevelUp) {
      final evt = vm.levelUpEvent!;
      vm.consumeLevelUpEvent();
      _prevUser = user;
      _runLevelUpSequence(user, evt.newLevel);
    } else if (user.currentXp != _prevUser!.currentXp) {
      _prevUser = user;
      _runNormalXpAnimation(user);
    } else {
      _prevUser = user;
    }
  }

  void _initWithUser(User user) {
    _prevUser = user;
    _displayLevel = user.level;
    _displayDenom = user.xpToNextLevel;
    final ratio =
        user.xpToNextLevel > 0 ? user.currentXp / user.xpToNextLevel : 0.0;
    _barAnim = AlwaysStoppedAnimation(ratio);
    _xpNumAnim = AlwaysStoppedAnimation(user.currentXp);
    setState(() {});
  }

  void _runNormalXpAnimation(User user) {
    final fromBar = _barAnim.value;
    final toBar =
        user.xpToNextLevel > 0 ? user.currentXp / user.xpToNextLevel : 0.0;
    final fromXp = _xpNumAnim.value;
    final toXp = user.currentXp;

    _ctrl.stop();
    _ctrl.duration = const Duration(milliseconds: 800);
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _barAnim = Tween<double>(begin: fromBar, end: toBar).animate(curved);
    _xpNumAnim = IntTween(begin: fromXp, end: toXp).animate(curved);
    _ctrl.forward(from: 0);
  }

  void _runLevelUpSequence(User user, int newLevel) async {
    _levelUpInProgress = true;
    try {
      final fromBar = _barAnim.value;
      final fromXp = _xpNumAnim.value;
      final fillDenom = _displayDenom;

      _ctrl.stop();
      _ctrl.duration = const Duration(milliseconds: 600);
      final curved1 = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
      _barAnim = Tween<double>(begin: fromBar, end: 1.0).animate(curved1);
      _xpNumAnim =
          IntTween(begin: fromXp, end: fillDenom).animate(curved1);
      await _ctrl.forward(from: 0).orCancel;
      if (!mounted) return;

      _overlayCompleter = Completer<void>();
      _showLevelUpOverlay(newLevel);

      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!(_overlayCompleter?.isCompleted ?? true)) {
          _overlayCompleter!.complete();
        }
      });

      await _overlayCompleter!.future;
      _dismissLevelUpOverlay();
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      setState(() {
        _displayLevel = newLevel;
        _displayDenom = user.xpToNextLevel;
      });

      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      final toBar =
          user.xpToNextLevel > 0 ? user.currentXp / user.xpToNextLevel : 0.0;
      _barAnim = const AlwaysStoppedAnimation(0.0);
      _xpNumAnim = const AlwaysStoppedAnimation(0);
      _ctrl.value = 0;
      setState(() {});

      _ctrl.stop();
      _ctrl.duration = const Duration(milliseconds: 800);
      final curved4 = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
      _barAnim = Tween<double>(begin: 0.0, end: toBar).animate(curved4);
      _xpNumAnim =
          IntTween(begin: 0, end: user.currentXp).animate(curved4);
      _ctrl.forward(from: 0);
    } on TickerCanceled {
      _dismissLevelUpOverlay();
    } finally {
      _levelUpInProgress = false;
    }
  }

  void _showLevelUpOverlay(int newLevel) {
    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!(_overlayCompleter?.isCompleted ?? true)) {
            _overlayCompleter!.complete();
          }
        },
        child: Material(
          color: Colors.black.withValues(alpha: 0.75),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.levelUpBadge,
                  style: TextStyle(
                    color: _green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${AppStrings.level} $newLevel',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.levelUpSub,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismissLevelUpOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    entry?.remove();
  }

  // ── Gesture handlers ──────────────────────────────────────────────────────

  void _onAvatarTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  void _onNameLongPress() {
    HapticFeedback.mediumImpact();
    final vm = context.read<UserViewModel>();
    final currentName = vm.user?.name ?? '';
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.editNameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: AppStrings.editNameHint,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              vm.updateName(name);
              Navigator.of(ctx).pop();
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  // ── Avatar widget ──────────────────────────────────────────────────────────

  Widget _buildAvatarContent(User? user) {
    final name = user?.name ?? '';
    final avatarPath = user?.avatarPath;
    final avatarRpgId = user?.avatarRpgId;

    if (avatarPath != null && avatarPath.isNotEmpty) {
      return Image.file(
        File(avatarPath),
        fit: BoxFit.cover,
        width: 48,
        height: 48,
        errorBuilder: (_, __, ___) => _buildInitialAvatar(name),
      );
    } else if (avatarRpgId != null && avatarRpgId.isNotEmpty) {
      return Container(
        color: const Color(0xFF1E1E1E),
        alignment: Alignment.center,
        child: Text(avatarRpgId, style: const TextStyle(fontSize: 24)),
      );
    } else {
      return _buildInitialAvatar(name);
    }
  }

  Widget _buildInitialAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: _green.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: _green,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();

    if (vm.isLoading && _prevUser == null) {
      return const SizedBox(
        height: 72,
        child: Center(child: LinearProgressIndicator()),
      );
    }

    final user = vm.user ?? _prevUser;
    final name = user?.name ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: _onAvatarTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _green, width: 2),
              ),
              child: ClipOval(child: _buildAvatarContent(user)),
            ),
          ),
          const SizedBox(width: 12),
          // ── Right column ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name + level badge
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onLongPress: _onNameLongPress,
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Container(
                        key: ValueKey(_displayLevel),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Lvl $_displayLevel',
                          style: const TextStyle(
                            color: _green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // XP bar
                LinearProgressIndicator(
                  value: _barAnim.value.clamp(0.0, 1.0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(_green),
                ),
                const SizedBox(height: 2),
                // XP text
                Text(
                  '${_xpNumAnim.value} / $_displayDenom ${AppStrings.xp}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
