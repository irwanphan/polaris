import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/widgets/providers.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:polaris/app/theme/color_palette.dart';

/// User's theme preferences: color palette + brightness mode.
///
/// Immutable state that triggers rebuilds when changed, matching the
/// [LocaleController] pattern.
class ThemePreferences {
  const ThemePreferences({
    required this.palette,
    required this.themeMode,
  });

  final ColorPalette palette;
  final ThemeMode themeMode;

  ThemePreferences copyWith({
    ColorPalette? palette,
    ThemeMode? themeMode,
  }) {
    return ThemePreferences(
      palette: palette ?? this.palette,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Manages user's theme preferences with Notifier pattern.
///
/// Persists choices in SharedPreferences so they survive app restarts.
/// Rebuilds MaterialApp when palette or brightness changes.
class ThemeController extends Notifier<ThemePreferences> {
  static const String _paletteKey = 'polaris.theme.palette.v1';
  static const String _brightnessKey = 'polaris.theme.brightness.v1';

  @override
  ThemePreferences build() {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    
    final String? paletteKey = prefs.getString(_paletteKey);
    final ColorPalette palette = paletteKey != null
        ? ColorPalette.fromKey(paletteKey) ?? ColorPalette.midnight
        : ColorPalette.midnight;

    final String? modeKey = prefs.getString(_brightnessKey);
    final ThemeMode themeMode = switch (modeKey) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return ThemePreferences(palette: palette, themeMode: themeMode);
  }

  Future<void> setPalette(ColorPalette palette) async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_paletteKey, palette.key);
    state = state.copyWith(palette: palette);
    
    // Refresh home widget to match new palette
    try {
      await ref.read(homeWidgetUpdaterProvider).refresh();
    } catch (e) {
      // Widget refresh failures are logged internally, don't block theme change
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final String key = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_brightnessKey, key);
    state = state.copyWith(themeMode: mode);
  }
}

/// Notifier provider for theme preferences.
///
/// Watches this to rebuild MaterialApp when palette or brightness changes.
final NotifierProvider<ThemeController, ThemePreferences>
    themeControllerProvider =
    NotifierProvider<ThemeController, ThemePreferences>(ThemeController.new);
