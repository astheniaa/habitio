import 'package:flutter/material.dart';

/// Centralised palette for the Habitio dark theme.
///
/// Inspired by Apple's iOS Human Interface Guidelines (dark mode):
/// restrained neutrals, a single brand-green accent, and a small set of
/// semantic accents used sparingly.
class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF2C2C2E);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A4);
  static const Color textTertiary = Color(0xFF6E6E73);

  // ── Brand ───────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF4CAF50);
  static const Color accentMuted = Color(0x334CAF50); // 20 % alpha

  // ── Semantic ────────────────────────────────────────────────────────────
  /// Streak / fire indicator. Used very sparingly.
  static const Color streak = Color(0xFFFF9F0A);

  /// Best / achievement indicator.
  static const Color best = Color(0xFFFFD60A);

  /// Freeze / paused indicator.
  static const Color freeze = Color(0xFF64B5F6);

  /// Destructive actions.
  static const Color destructive = Color(0xFFFF453A);

  // ── Lines ───────────────────────────────────────────────────────────────
  static const Color divider = Color(0x14FFFFFF); // ~ 8 % white
  static const Color hairline = Color(0x29FFFFFF); // ~ 16 % white
}
