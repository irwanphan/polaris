import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the user's UI language preference.
///
/// State semantics:
///   - `null` → follow the OS locale (`MaterialApp.locale = null`).
///   - non-null → force `MaterialApp.locale` to this value.
///
/// We persist into the same [SharedPreferences] used by M1 to avoid
/// adding another storage seam. The key is namespaced so other
/// features never collide.
class LocaleController extends Notifier<Locale?> {
  static const String _prefsKey = 'polaris.locale.v1';
  static const Set<String> _supported = <String>{'en', 'id'};

  @override
  Locale? build() {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || !_supported.contains(raw)) return null;
    return Locale(raw);
  }

  /// Pass `null` to revert to the system locale.
  Future<void> setLocale(Locale? locale) async {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      if (!_supported.contains(locale.languageCode)) return;
      await prefs.setString(_prefsKey, locale.languageCode);
    }
    state = locale;
  }
}

final NotifierProvider<LocaleController, Locale?> localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
