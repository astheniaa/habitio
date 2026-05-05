import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/user.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/theme_provider.dart';
import '../state/user_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
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
      _xpNumAnim = IntTween(begin: fromXp, end: fillDenom).animate(curved1);
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
      _xpNumAnim = IntTween(begin: 0, end: user.currentXp).animate(curved4);
      _ctrl.forward(from: 0);
    } on TickerCanceled {
      _dismissLevelUpOverlay();
    } finally {
      _levelUpInProgress = false;
    }
  }

  void _showLevelUpOverlay(int newLevel) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!(_overlayCompleter?.isCompleted ?? true)) {
            _overlayCompleter!.complete();
          }
        },
        child: Material(
          color: Colors.black.withValues(alpha: 0.85),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.levelUpBadge,
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${loc.level} $newLevel',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  loc.levelUpSub,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 15,
                  ),
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
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  void _onNameLongPress() {
    HapticFeedback.mediumImpact();
    final vm = context.read<UserViewModel>();
    final loc = AppLocalizations.of(context)!;
    final currentName = vm.user?.name ?? '';
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.editNameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: loc.editNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              vm.updateName(name);
              Navigator.of(ctx).pop();
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  // ── Avatar widget ──────────────────────────────────────────────────────────

  Widget _buildAvatarContent(User? user) {
    final colors = AppColors.of(context);
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
        color: colors.surface,
        alignment: Alignment.center,
        child: Text(avatarRpgId, style: const TextStyle(fontSize: 24)),
      );
    } else {
      return _buildInitialAvatar(name);
    }
  }

  Widget _buildInitialAvatar(String name) {
    final colors = AppColors.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: colors.surface,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();
    final colors = AppColors.of(context);

    if (vm.isLoading && _prevUser == null) {
      return const SizedBox(
        height: 72,
        child: Center(child: LinearProgressIndicator()),
      );
    }

    final user = vm.user ?? _prevUser;
    final name = user?.name ?? '';
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: _onAvatarTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
              ),
              child: ClipOval(child: _buildAvatarContent(user)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // ── Right column ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name + level
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onLongPress: _onNameLongPress,
                        child: Text(
                          name,
                          style: AppText.headline,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        key: ValueKey(_displayLevel),
                        '· ${loc.level} $_displayLevel',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // XP bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _barAnim.value.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: colors.surface,
                    valueColor: AlwaysStoppedAnimation(colors.accent),
                  ),
                ),
                const SizedBox(height: 4),
                // XP text
                Text(
                  '${_xpNumAnim.value} / $_displayDenom ${loc.xp}',
                  style: AppText.footnote.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _ThemeToggle(),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = AppColors.of(context);
    final icon =
        theme.isNight ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
    final iconColor = theme.isNight ? colors.best : colors.freeze;

    return Tooltip(
      message: theme.isNight ? 'Switch to day theme' : 'Switch to night theme',
      child: Material(
        color: colors.surface,
        shape: CircleBorder(
          side: BorderSide(color: colors.divider, width: 0.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.read<ThemeProvider>().toggle(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                icon,
                key: ValueKey(theme.isNight),
                color: iconColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
