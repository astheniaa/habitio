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
}
