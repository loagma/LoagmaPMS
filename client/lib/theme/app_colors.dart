import 'package:flutter/material.dart';

/// Central color palette for Loagma PMS.
/// Base brand color: 0xFFCEB56E
class AppColors {
  AppColors._();

  /// Primary brand color and its shades based on 0xFFCEB56E.
  static const Color primary = Color(0xFFCEB56E);
  static const Color primaryLight = Color(0xFFE6D396);
  static const Color primaryLighter = Color(0xFFF6E8C5);
  static const Color primaryDark = Color(0xFFB09152);
  static const Color primaryDarker = Color(0xFF8A6C36);

  /// Surfaces / backgrounds.
  /// Use [background] for full-screen backgrounds and [surface] for cards.
  static const Color background = Colors.white;
  static const Color surface = Colors.white;

  /// Text colors.
  static const Color textDark = Color(0xFF2C2416);
  static const Color textMuted = Color(0xFF6B5D4A);

  /// Border color for inputs and dividers.
  static const Color border = Color(0xFFE0E0E0);
}
