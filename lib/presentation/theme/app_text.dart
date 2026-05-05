import 'package:flutter/material.dart';

/// Typography scale modelled on Apple's SF text styles.
///
/// Styles are intentionally uncolored so widgets inherit the active
/// [ThemeData] text color in both day and night themes.
class AppText {
  AppText._();

  static const TextStyle _largeTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.4,
  );

  static const TextStyle _title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static const TextStyle _headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle _body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle _callout = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle _caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  static const TextStyle _footnote = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  static const TextStyle _sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.6,
  );

  static TextStyle get largeTitle => _largeTitle;
  static TextStyle get title => _title;
  static TextStyle get headline => _headline;
  static TextStyle get body => _body;
  static TextStyle get callout => _callout;
  static TextStyle get caption => _caption;
  static TextStyle get footnote => _footnote;
  static TextStyle get sectionLabel => _sectionLabel;
}
