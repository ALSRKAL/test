import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';

/// Extension methods for easy theme access
extension ThemeExtensions on BuildContext {
  /// Get current theme
  ThemeData get theme => Theme.of(this);
  
  /// Check if dark mode is active
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isDark => theme.brightness == Brightness.dark;
  
  /// Get text colors based on theme
  Color get textPrimary => isDarkMode 
      ? AppColors.textPrimaryDark 
      : AppColors.textPrimaryLight;
      
  Color get textSecondary => isDarkMode 
      ? AppColors.textSecondaryDark 
      : AppColors.textSecondaryLight;
      
  /// Get background colors based on theme
  Color get background => isDarkMode 
      ? AppColors.backgroundDark 
      : AppColors.backgroundLight;
      
  Color get surface => isDarkMode 
      ? AppColors.surfaceDark 
      : AppColors.surfaceLight;
      
  /// Get card color with proper shadow
  BoxShadow get cardShadow => BoxShadow(
    color: isDarkMode 
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.08),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );
  
  /// Get divider color
  Color get dividerColor => isDarkMode
      ? AppColors.textSecondaryDark.withValues(alpha: 0.2)
      : AppColors.divider;
}
