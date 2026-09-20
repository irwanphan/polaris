import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:polaris/app/theme/color_palette.dart';

part 'theme_controller.g.dart';

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

@Riverpod(keepAlive: true)
ThemeController themeController(ThemeControllerRef ref) {
  final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
  final controller = ThemeController(prefs);
  ref.onDispose(controller.dispose);
  return controller;
}

/// Stream provider that rebuilds whenever theme changes.
@Riverpod(keepAlive: true)
Stream<ThemeController> themeStream(ThemeStreamRef ref) async* {
  final controller = ref.watch(themeControllerProvider);
  yield controller;
  await for (final _ in controller.changes) {
    yield controller;
  }
}

/// Expose SharedPreferences as a provider (overridden in bootstrap).
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in bootstrap',
  );
}
