import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale modelled on Apple's SF text styles.
/// Weights are restrained — semibold (600) for emphasis, bold (700) only for
/// display-level numbers.
class AppText {
  AppText._();

  static const TextStyle largeTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.25,
    color: AppColors.textSecondary,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textTertiary,
  );

  /// Small uppercase section labels (Apple groups headers in Settings).
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
  );
}
