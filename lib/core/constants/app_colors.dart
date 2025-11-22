import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF667EEA);

  static const Color primaryGradientStart = Color(0xFF667EEA);
  static const Color primaryGradientEnd = Color(0xFF764BA2);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary Gradient
  static const Color secondaryGradientStart = Color(0xFFF093FB);
  static const Color secondaryGradientEnd = Color(0xFFF5576C);
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryGradientStart, secondaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Accent Colors
  static const Color gold = Color(0xFFFFD700);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);

  // Neutrals - Light Mode
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);

  // Neutrals - Dark Mode
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Additional Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2A2A2A);
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);
  static const Color overlay = Color(0x80000000);

  // Dynamic color getters based on theme
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : backgroundLight;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceLight;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondaryLight;
  }

  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dividerDark
        : divider;
  }

  static Color getShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? shadowDark
        : shadow;
  }
}
