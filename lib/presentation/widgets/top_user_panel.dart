import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/entities/user.dart';
import '../localization/app_strings.dart';
import '../state/user_view_model.dart';

class TopUserPanel extends StatefulWidget {
  const TopUserPanel({super.key});

  @override
  State<TopUserPanel> createState() => _TopUserPanelState();
}

class _TopUserPanelState extends State<TopUserPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Current animated values (updated each frame via addListener)
  Animation<double> _barAnim = const AlwaysStoppedAnimation(0);
  Animation<int> _xpNumAnim = const AlwaysStoppedAnimation(0);

  // What the level text and XP denominator display
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
      // ── Step 1: fill bar to 100 % (600 ms) ──────────────────────────────
      final fromBar = _barAnim.value;
      final fromXp = _xpNumAnim.value;
      final fillDenom = _displayDenom;

      _ctrl.stop();
      _ctrl.duration = const Duration(milliseconds: 600);
      final curved1 = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
      _barAnim =
          Tween<double>(begin: fromBar, end: 1.0).animate(curved1);
      _xpNumAnim =
          IntTween(begin: fromXp, end: fillDenom).animate(curved1);
      await _ctrl.forward(from: 0).orCancel;
      if (!mounted) return;

      // ── Step 2: show overlay, wait up to 2.5 s or user tap ───────────────
      _overlayCompleter = Completer<void>();
      _showLevelUpOverlay(newLevel);

      // auto-dismiss timer
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!(_overlayCompleter?.isCompleted ?? true)) {
          _overlayCompleter!.complete();
        }
      });

      await _overlayCompleter!.future;
      _dismissLevelUpOverlay();
      if (!mounted) return;

      // brief pause for overlay fade-out
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      // ── Step 3: update level text, reset bar instantly ────────────────────
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

      // ── Step 4: animate bar to new value (800 ms) ─────────────────────────
      _ctrl.stop();
      _ctrl.duration = const Duration(milliseconds: 800);
      final curved4 = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
      _barAnim =
          Tween<double>(begin: 0.0, end: toBar).animate(curved4);
      _xpNumAnim =
          IntTween(begin: 0, end: user.currentXp).animate(curved4);
      _ctrl.forward(from: 0);
    } on TickerCanceled {
      // widget disposed mid-animation – clean up overlay if needed
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
                    color: Color(0xFF4CAF50),
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();

    if (vm.isLoading && _prevUser == null) {
      return const LinearProgressIndicator();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vm.user?.name ?? _prevUser?.name ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              '${AppStrings.level} $_displayLevel',
              key: ValueKey(_displayLevel),
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _barAnim.value.clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            '${_xpNumAnim.value} / $_displayDenom ${AppStrings.xp}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
