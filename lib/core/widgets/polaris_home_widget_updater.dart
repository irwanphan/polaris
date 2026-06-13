import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';

/// Concrete [HomeWidgetUpdater] backed by the `home_widget` plugin.
///
/// Pushes three string keys to the Android `SharedPreferences` that
/// the native `PolarisWidgetProvider` reads — see the companion
/// constants on that class for the wire contract.
///
/// On every [refresh] call this:
///   1. Reads the currently pinned event (none → empty state).
///   2. Formats the user-visible strings in Dart (so the RemoteViews
///      side stays a dumb sink).
///   3. Writes the strings via `HomeWidget.saveWidgetData`.
///   4. Triggers the Android widget provider to re-render via
///      `HomeWidget.updateWidget(androidName: PolarisWidgetProvider)`.
///
/// All failures are logged and swallowed — a widget refresh glitch
/// must never block an event mutation.
class PolarisHomeWidgetUpdater implements HomeWidgetUpdater {
  PolarisHomeWidgetUpdater({
    required this.repository,
    required this.logger,
    DateTime Function()? now,
    Future<bool?> Function(String, String?)? saveData,
    Future<bool?> Function({String? androidName})? triggerUpdate,
  }) : _now = now ?? DateTime.now,
       _saveData = saveData ?? _defaultSave,
       _triggerUpdate = triggerUpdate ?? _defaultUpdate;

  final EventRepository repository;
  final AppLogger logger;
  final DateTime Function() _now;
  final Future<bool?> Function(String, String?) _saveData;
  final Future<bool?> Function({String? androidName}) _triggerUpdate;

  /// Wire-contract keys mirrored in
  /// `android/.../kotlin/.../PolarisWidgetProvider.kt`.
  static const String _kTitle = 'polaris_pinned_title';
  static const String _kDays = 'polaris_pinned_days';
  static const String _kSubtitle = 'polaris_pinned_subtitle';

  /// Matches the class name registered in `AndroidManifest.xml`.
  static const String _kAndroidProvider = 'PolarisWidgetProvider';

  @override
  Future<void> refresh() async {
    try {
      final result = await repository.getPinned();
      final Event? pinned = result.fold(
        onOk: (e) => e,
        onErr: (failure) {
          logger.warn(
            'Widget refresh: failed to read pinned event, treating as empty',
            error: failure,
          );
          return null;
        },
      );

      await _writeWidgetData(pinned);
      await _triggerUpdate(androidName: _kAndroidProvider);
    } catch (e, st) {
      logger.warn(
        'Home-screen widget refresh failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _writeWidgetData(Event? pinned) async {
    if (pinned == null) {
      await _saveData(_kTitle, null);
      await _saveData(_kDays, null);
      await _saveData(_kSubtitle, null);
      return;
    }

    final DateTime now = _now();
    final DateTime next = pinned.nextOccurrence(now);
    final int days = pinned.daysUntil(now);

    await _saveData(_kTitle, pinned.title);
    await _saveData(_kDays, _formatDays(days));
    await _saveData(_kSubtitle, _formatSubtitle(next, pinned));
  }

  static String _formatDays(int days) {
    if (days == 0) return 'Today';
    if (days == 1) return '1 day';
    if (days < 0) {
      // Should not happen in practice — nextOccurrence is always
      // forward-looking for recurring events, and one-shot past
      // events are excluded by the FAB save flow. Keep it
      // defensive in case the user manually back-dates.
      return 'Past';
    }
    return '$days days';
  }

  static String _formatSubtitle(DateTime when, Event event) {
    final String date = DateFormat('EEE, MMM d').format(when);
    if (event.recurrence.storageKey == 'none') return date;
    return '$date · ${event.recurrence.label}';
  }

  // Default thunks delegate to the real plugin. Tests inject fakes
  // via the constructor so they don't hit MethodChannel.
  static Future<bool?> _defaultSave(String key, String? value) =>
      HomeWidget.saveWidgetData<String?>(key, value);

  static Future<bool?> _defaultUpdate({String? androidName}) =>
      HomeWidget.updateWidget(androidName: androidName);
}
