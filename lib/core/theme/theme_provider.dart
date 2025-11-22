import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Mode State
class ThemeModeState {
  final ThemeMode themeMode;
  final bool isLoading;

  const ThemeModeState({
    required this.themeMode,
    this.isLoading = false,
  });

  ThemeModeState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
  }) {
    return ThemeModeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Theme Provider
class ThemeNotifier extends StateNotifier<ThemeModeState> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(const ThemeModeState(themeMode: ThemeMode.light)) {
    _loadThemeMode();
  }

  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        final themeMode = _stringToThemeMode(savedTheme);
        state = state.copyWith(themeMode: themeMode);
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    final newThemeMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    await setThemeMode(newThemeMode);
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      state = state.copyWith(isLoading: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeModeToString(themeMode));

      state = state.copyWith(
        themeMode: themeMode,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Check if current theme is dark
  bool get isDarkMode => state.themeMode == ThemeMode.dark;

  /// Convert ThemeMode to String
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert String to ThemeMode
  ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}

/// Theme Provider Instance
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeModeState>((ref) {
  return ThemeNotifier();
});
