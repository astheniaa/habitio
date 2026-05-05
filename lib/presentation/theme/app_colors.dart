import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Convenience accessor for the active [AppPalette].
///
/// All colour values are theme-aware: in light mode, you get the light
/// palette; in dark mode, the dark one. Always pass the current
/// [BuildContext]:
///
/// ```dart
/// final p = AppColors.of(context);
/// Container(color: p.surface);
/// ```
class AppColors {
  AppColors._();

  static AppPalette of(BuildContext context) {
    final ext = Theme.of(context).extension<AppPalette>();
    return ext ?? AppPalette.dark();
  }
}
