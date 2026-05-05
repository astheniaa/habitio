import 'package:flutter/material.dart';

/// Full color palette for the app, attached to [ThemeData] as a
/// [ThemeExtension] so widgets can resolve colors via
/// `Theme.of(context).extension<AppPalette>()`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color accent;
  final Color accentMuted;

  final Color streak;
  final Color best;
  final Color freeze;
  final Color destructive;
  final Color missed;

  final Color divider;
  final Color hairline;

  /// Used for system UI overlays. True if this palette is dark-themed.
  final bool isDark;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentMuted,
    required this.streak,
    required this.best,
    required this.freeze,
    required this.destructive,
    required this.missed,
    required this.divider,
    required this.hairline,
    required this.isDark,
  });

  factory AppPalette.dark() => const AppPalette(
        background: Color(0xFF0A0A0B),
        surface: Color(0xFF1C1C1E),
        surfaceElevated: Color(0xFF2C2C2E),
        textPrimary: Color(0xFFFFFFFF),
        textSecondary: Color(0xFFA0A0A4),
        textTertiary: Color(0xFF6E6E73),
        accent: Color(0xFF4CAF50),
        accentMuted: Color(0x334CAF50),
        streak: Color(0xFFFF9F0A),
        best: Color(0xFFFFD60A),
        freeze: Color(0xFF64B5F6),
        destructive: Color(0xFFFF453A),
        missed: Color(0xFF5C3A3A),
        divider: Color(0x14FFFFFF),
        hairline: Color(0x29FFFFFF),
        isDark: true,
      );

  factory AppPalette.light() => const AppPalette(
        background: Color(0xFFF7F7F8),
        surface: Color(0xFFFFFFFF),
        surfaceElevated: Color(0xFFEEEEF0),
        textPrimary: Color(0xFF050507),
        textSecondary: Color(0xFF53545B),
        textTertiary: Color(0xFF8E8E93),
        accent: Color(0xFF34A853),
        accentMuted: Color(0x2234A853),
        streak: Color(0xFFFF8800),
        best: Color(0xFFE6A500),
        freeze: Color(0xFF1F86D8),
        destructive: Color(0xFFE53935),
        missed: Color(0xFFF7C5C5),
        divider: Color(0x14000000),
        hairline: Color(0x29000000),
        isDark: false,
      );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentMuted,
    Color? streak,
    Color? best,
    Color? freeze,
    Color? destructive,
    Color? missed,
    Color? divider,
    Color? hairline,
    bool? isDark,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      streak: streak ?? this.streak,
      best: best ?? this.best,
      freeze: freeze ?? this.freeze,
      destructive: destructive ?? this.destructive,
      missed: missed ?? this.missed,
      divider: divider ?? this.divider,
      hairline: hairline ?? this.hairline,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      best: Color.lerp(best, other.best, t)!,
      freeze: Color.lerp(freeze, other.freeze, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      missed: Color.lerp(missed, other.missed, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
