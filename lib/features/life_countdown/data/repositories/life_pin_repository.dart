import 'dart:async';

import 'package:polaris/features/life_countdown/domain/value_objects/life_pin_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists [LifePinPreferences] and exposes a reactive stream.
///
/// SharedPreferences is the right substrate for a single-record user
/// preference like this: no schema migration drift, atomic writes,
/// already wired into M1's profile bootstrap.
///
/// The stream is fed by an internal broadcast controller — every
/// successful [save] emits the new value to listeners, so the widget
/// updater (and the AppBar pin icon) re-render without manual
/// invalidation.
class LifePinRepository {
  LifePinRepository(this._prefs);

  static const String _kPinned = 'polaris.life_pin.v1.pinned';
  static const String _kCustomMessage = 'polaris.life_pin.v1.custom_message';

  final SharedPreferences _prefs;
  final StreamController<LifePinPreferences> _controller =
      StreamController<LifePinPreferences>.broadcast();

  /// Snapshot read — synchronous because SharedPreferences caches.
  LifePinPreferences read() {
    final bool pinned = _prefs.getBool(_kPinned) ?? false;
    final String? message = _prefs.getString(_kCustomMessage);
    return LifePinPreferences(pinned: pinned, customMessage: message);
  }

  /// Emits the current snapshot then every subsequent successful write.
  Stream<LifePinPreferences> watch() async* {
    yield read();
    yield* _controller.stream;
  }

  /// Atomically writes [next] and notifies stream listeners.
  ///
  /// Always succeeds for valid inputs (SharedPreferences errors are
  /// rare and non-recoverable here — we don't wrap in Result because
  /// the caller can't meaningfully retry).
  Future<void> save(LifePinPreferences next) async {
    await _prefs.setBool(_kPinned, next.pinned);
    if (next.customMessage == null) {
      await _prefs.remove(_kCustomMessage);
    } else {
      await _prefs.setString(_kCustomMessage, next.customMessage!);
    }
    _controller.add(next);
  }

  /// Removes both prefs keys and emits the default state.
  /// Useful for "clear all data" wipes.
  Future<void> clear() async {
    await _prefs.remove(_kPinned);
    await _prefs.remove(_kCustomMessage);
    _controller.add(LifePinPreferences.unpinned);
  }
}
