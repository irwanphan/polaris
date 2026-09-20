import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:polaris/app/theme/color_palette.dart';

/// Manages user's theme preferences: color palette + brightness mode.
///
/// Persists choices in SharedPreferences so they survive app restarts.
/// Exposes a stream that MaterialApp watches to rebuild with new themes.
class ThemeController {
  ThemeController(this._prefs) {
    _loadPreferences();
  }

  final SharedPreferences _prefs;
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  static const String _paletteKey = 'polaris.theme.palette.v1';
  static const String _brightnessKey = 'polaris.theme.brightness.v1';

  ColorPalette _palette = ColorPalette.midnight;
  ThemeMode _themeMode = ThemeMode.system;

  ColorPalette get palette => _palette;
  ThemeMode get themeMode => _themeMode;
  Stream<void> get changes => _changeController.stream;

  void _loadPreferences() {
    final String? paletteKey = _prefs.getString(_paletteKey);
    if (paletteKey != null) {
      _palette = ColorPalette.fromKey(paletteKey) ?? ColorPalette.midnight;
    }

    final String? modeKey = _prefs.getString(_brightnessKey);
    if (modeKey != null) {
      _themeMode = switch (modeKey) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    }
  }

  Future<void> setPalette(ColorPalette palette) async {
    _palette = palette;
    await _prefs.setString(_paletteKey, palette.key);
    _changeController.add(null);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final String key = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_brightnessKey, key);
    _changeController.add(null);
  }

  void dispose() {
    _changeController.close();
  }
}

/// Singleton [ThemeController] backed by the bootstrap-supplied
/// [SharedPreferences]. Disposed when the provider scope is torn down.
final Provider<ThemeController> themeControllerProvider =
    Provider<ThemeController>(
  (ref) {
    final controller = ThemeController(ref.watch(sharedPreferencesProvider));
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Stream provider that rebuilds whenever theme changes.
///
/// MaterialApp watches this to rebuild with new themes when the user
/// changes their palette or brightness preference.
final StreamProvider<ThemeController> themeStreamProvider =
    StreamProvider<ThemeController>(
  (ref) async* {
    final controller = ref.watch(themeControllerProvider);
    yield controller;
    await for (final _ in controller.changes) {
      yield controller;
    }
  },
);
