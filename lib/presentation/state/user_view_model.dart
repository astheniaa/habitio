import 'package:flutter/foundation.dart';

import '../../domain/models/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class LevelUpEvent {
  final int newLevel;
  const LevelUpEvent(this.newLevel);
}

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  User? _user;
  bool _isLoading = false;
  LevelUpEvent? _levelUpEvent;

  UserViewModel({required UserRepository userRepository})
      : _userRepository = userRepository;

  User? get user => _user;
  bool get isLoading => _isLoading;
  LevelUpEvent? get levelUpEvent => _levelUpEvent;

  void consumeLevelUpEvent() => _levelUpEvent = null;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _userRepository.getOrCreateDefaultUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatar({String? avatarPath, String? avatarRpgId}) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      avatarPath: avatarPath,
      avatarRpgId: avatarRpgId,
      clearAvatarPath: avatarPath == null && avatarRpgId != null,
      clearAvatarRpgId: avatarRpgId == null && avatarPath != null,
    );
    await _userRepository.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    if (_user == null) return;
    final updated = _user!.copyWith(name: name);
    await _userRepository.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> awardXp(int xp) async {
    if (_user == null) return;
    var level = _user!.level;
    var currentXp = _user!.currentXp + xp;
    bool didLevelUp = false;

    while (currentXp >= level * 100) {
      currentXp -= level * 100;
      level++;
      didLevelUp = true;
    }

    final updated = _user!.copyWith(
      level: level,
      currentXp: currentXp,
      xpToNextLevel: level * 100,
    );
    await _userRepository.updateUser(updated);
    _user = updated;
    if (didLevelUp) {
      _levelUpEvent = LevelUpEvent(level);
    }
    notifyListeners();
  }

  /// Award XP scaled by a per-habit streak. The multiplier grows linearly
  /// with the streak length and is capped at 2× (reached at 100-day streak).
  ///
  ///   xp = (base × min(2, 1 + streak / 100)).round()
  Future<int> awardXpWithStreak(int base, int streak) async {
    final multiplier = (1 + streak / 100).clamp(1.0, 2.0);
    final amount = (base * multiplier).round();
    await awardXp(amount);
    return amount;
  }

  /// Safety net: revert XP to a known snapshot (e.g. if XP was awarded
  /// before undo could cancel it).
  Future<void> revokeXp({
    required int xpBefore,
    required int levelBefore,
  }) async {
    if (_user == null) return;
    // Only revert if XP actually changed relative to snapshot
    if (_user!.currentXp == xpBefore && _user!.level == levelBefore) return;
    final updated = _user!.copyWith(
      level: levelBefore,
      currentXp: xpBefore,
      xpToNextLevel: levelBefore * 100,
    );
    await _userRepository.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  /// Revoke streak-scaled XP using the same multiplier formula as
  /// [awardXpWithStreak]. Returns the amount actually revoked.
  Future<int> revokeXpWithStreak(int base, int streak) async {
    final multiplier = (1 + streak / 100).clamp(1.0, 2.0);
    final amount = (base * multiplier).round();
    await revokeXpAmount(amount);
    return amount;
  }

  /// Revoke a fixed amount of XP (e.g. when un-completing a habit).
  /// Handles level-down if needed. XP cannot go below 0 at level 1.
  Future<void> revokeXpAmount(int xp) async {
    if (_user == null) return;
    var level = _user!.level;
    var currentXp = _user!.currentXp - xp;

    while (currentXp < 0 && level > 1) {
      level--;
      currentXp += level * 100;
    }
    if (currentXp < 0) currentXp = 0;

    final updated = _user!.copyWith(
      level: level,
      currentXp: currentXp,
      xpToNextLevel: level * 100,
    );
    await _userRepository.updateUser(updated);
    _user = updated;
    notifyListeners();
  }
}
