import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user-selected locale for the app.
///
/// On first launch the device locale is used. The user can override via the
/// language toggle; the override is persisted with shared_preferences and
/// survives restarts.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale_override';
  static const _supported = ['ru', 'en'];

  Locale? _override;

  /// `null` means "follow device locale" — MaterialApp will resolve it via
  /// supportedLocales.
  Locale? get locale => _override;

  bool get isOverridden => _override != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && _supported.contains(code)) {
      _override = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale != null && !_supported.contains(locale.languageCode)) return;
    _override = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
