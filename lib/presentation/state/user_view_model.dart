import 'package:flutter/foundation.dart';

import '../../domain/models/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  User? _user;
  bool _isLoading = false;

  UserViewModel({required UserRepository userRepository})
      : _userRepository = userRepository;

  User? get user => _user;
  bool get isLoading => _isLoading;

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
}
