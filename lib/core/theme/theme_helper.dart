import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';

/// Helper class for theme-aware widgets
class ThemeHelper {
  /// Get background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
  }

  /// Get surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
  }

  /// Get primary text color based on theme
  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
  }

  /// Get secondary text color based on theme
  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
  }

  /// Get divider color based on theme
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark.withValues(alpha: 0.2)
        : AppColors.divider;
  }

  /// Get card shadow based on theme
  static List<BoxShadow> getCardShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Check if dark mode is active
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get input decoration theme-aware
  static InputDecoration getInputDecoration(
    BuildContext context, {
    required String hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: getSurfaceColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: getDividerColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: getDividerColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGradientStart, width: 2),
      ),
    );
  }

  /// Get container decoration theme-aware
  static BoxDecoration getContainerDecoration(
    BuildContext context, {
    Color? color,
    double borderRadius = 12,
    bool withShadow = true,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? getSurfaceColor(context),
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null ? Border.all(color: borderColor) : null,
      boxShadow: withShadow ? getCardShadow(context) : null,
    );
  }
}
