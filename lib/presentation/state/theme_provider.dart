import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_palette.dart';

/// Holds the user-selected day/night theme.
///
/// Night is the default so the app keeps its current appearance until the
/// user opts into the day theme.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'app_theme_is_night';

  bool _isNight = true;

  bool get isNight => _isNight;
  bool get isDay => !_isNight;
  ThemeMode get themeMode => _isNight ? ThemeMode.dark : ThemeMode.light;
  AppPalette get palette => _isNight ? AppPalette.dark() : AppPalette.light();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isNight = prefs.getBool(_prefsKey) ?? true;
    notifyListeners();
  }

  Future<void> toggle() => setNight(!_isNight);

  Future<void> setNight(bool value) async {
    if (_isNight == value) return;
    _isNight = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isNight);
  }
}
