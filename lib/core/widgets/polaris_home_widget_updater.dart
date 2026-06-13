import 'dart:ui' as ui;

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_pin_repository.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/usecases/compute_life_estimate.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Concrete [HomeWidgetUpdater] backed by the `home_widget` plugin.
///
/// Pushes three string keys to the Android `SharedPreferences` that
/// the native `PolarisWidgetProvider` reads — see the companion
/// constants on that class for the wire contract.
///
/// Subject resolution (highest priority first):
///   1. Life-countdown pin (`LifePinPreferences.pinned == true`) →
///      title is the localized "Sisa Hariku" label, hero is days
///      remaining, subtitle is either the user's custom message or
///      "Ends ~{estimatedEndDate}".
///   2. Pinned event → title is the event title, hero is days until
///      the next occurrence, subtitle is either the event's
///      [Event.widgetMessage] or the auto "{date} · {recurrence}"
///      line.
///   3. Neither → all three keys cleared so the native layout falls
///      back to the empty state.
///
/// Strings are formatted in Dart using [AppL] loaded with the user's
/// preferred locale (or the OS locale when "system" is selected) so
/// the RemoteViews side stays a dumb sink. Recurrence labels are
/// localized via a switch on [Recurrence.storageKey] — we can't reach
/// the original `enum_labels.dart` helper because that function needs
/// a `BuildContext`.
///
/// All failures are logged and swallowed — a widget refresh glitch
/// must never block an event mutation.
class PolarisHomeWidgetUpdater implements HomeWidgetUpdater {
  PolarisHomeWidgetUpdater({
    required this.eventRepository,
    required this.lifePinRepository,
    required this.lifeProfileRepository,
    required this.computeLifeEstimate,
    required this.sharedPreferences,
    required this.logger,
    DateTime Function()? now,
    Future<bool?> Function(String, String?)? saveData,
    Future<bool?> Function({String? androidName})? triggerUpdate,
    Future<AppL> Function(ui.Locale)? loadLocalizations,
  }) : _now = now ?? DateTime.now,
       _saveData = saveData ?? _defaultSave,
       _triggerUpdate = triggerUpdate ?? _defaultUpdate,
       _loadLocalizations = loadLocalizations ?? AppL.delegate.load;

  final EventRepository eventRepository;
  final LifePinRepository lifePinRepository;
  final LifeProfileRepository lifeProfileRepository;
  final ComputeLifeEstimate computeLifeEstimate;
  final SharedPreferences sharedPreferences;
  final AppLogger logger;
  final DateTime Function() _now;
  final Future<bool?> Function(String, String?) _saveData;
  final Future<bool?> Function({String? androidName}) _triggerUpdate;
  final Future<AppL> Function(ui.Locale) _loadLocalizations;

  /// Mirrors the key used by [LocaleController]. Hardcoded here
  /// instead of importing the controller to avoid a Flutter-only
  /// dependency in this isolate-friendly class.
  static const String _kLocalePrefsKey = 'polaris.locale.v1';
  static const Set<String> _kSupportedLocales = <String>{'en', 'id'};

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
      final ui.Locale locale = _resolveLocale();
      final AppL l = await _loadLocalizations(locale);
      final String localeTag = locale.toLanguageTag();

      final _WidgetPayload? payload = await _resolvePayload(l, localeTag);
      await _writeWidgetData(payload);
      await _triggerUpdate(androidName: _kAndroidProvider);
    } catch (e, st) {
      logger.warn(
        'Home-screen widget refresh failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Resolves the subject in priority order. Returns `null` for the
  /// empty state so [_writeWidgetData] can blank the keys uniformly.
  Future<_WidgetPayload?> _resolvePayload(AppL l, String localeTag) async {
    final lifePin = lifePinRepository.read();
    if (lifePin.pinned) {
      final life = await _buildLifePayload(l, localeTag, lifePin.customMessage);
      if (life != null) return life;
      // Profile missing → fall through to event so we still show something.
    }

    final eventResult = await eventRepository.getPinned();
    final Event? pinnedEvent = eventResult.fold(
      onOk: (e) => e,
      onErr: (failure) {
        logger.warn(
          'Widget refresh: failed to read pinned event, treating as empty',
          error: failure,
        );
        return null;
      },
    );
    if (pinnedEvent != null) {
      return _buildEventPayload(l, localeTag, pinnedEvent);
    }
    return null;
  }

  Future<_WidgetPayload?> _buildLifePayload(
    AppL l,
    String localeTag,
    String? customMessage,
  ) async {
    final profileResult = await lifeProfileRepository.read();
    final LifeProfile? profile = profileResult.fold(
      onOk: (p) => p,
      onErr: (failure) {
        logger.warn(
          'Widget refresh: failed to read life profile',
          error: failure,
        );
        return null;
      },
    );
    if (profile == null) return null;

    final estimateResult = await computeLifeEstimate(profile, now: _now());
    final LifeEstimate? estimate = estimateResult.fold(
      onOk: (e) => e,
      onErr: (failure) {
        logger.warn(
          'Widget refresh: failed to compute life estimate',
          error: failure,
        );
        return null;
      },
    );
    if (estimate == null) return null;

    final String hero = l.lifeWidgetDaysRemainingShort(estimate.remainingDays);
    final String subtitle = customMessage ??
        l.lifeWidgetSubtitleDefault(
          DateFormat.yMMMd(localeTag).format(estimate.estimatedEndDate),
        );
    return _WidgetPayload(
      title: l.lifeTitle,
      days: hero,
      subtitle: subtitle,
    );
  }

  _WidgetPayload _buildEventPayload(AppL l, String localeTag, Event event) {
    final DateTime now = _now();
    final DateTime next = event.nextOccurrence(now);
    final int days = event.daysUntil(now);
    final String hero = l.widgetEventDays(days);
    final String subtitle = event.widgetMessage ??
        l.widgetEventSubtitleDefault(
          DateFormat('EEE, MMM d', localeTag).format(next),
          _localizedRecurrence(l, event.recurrence.storageKey),
        );
    return _WidgetPayload(
      title: event.title,
      days: hero,
      subtitle: subtitle,
    );
  }

  Future<void> _writeWidgetData(_WidgetPayload? payload) async {
    if (payload == null) {
      await _saveData(_kTitle, null);
      await _saveData(_kDays, null);
      await _saveData(_kSubtitle, null);
      return;
    }
    await _saveData(_kTitle, payload.title);
    await _saveData(_kDays, payload.days);
    await _saveData(_kSubtitle, payload.subtitle);
  }

  ui.Locale _resolveLocale() {
    final String? stored = sharedPreferences.getString(_kLocalePrefsKey);
    if (stored != null && _kSupportedLocales.contains(stored)) {
      return ui.Locale(stored);
    }
    final ui.Locale system = ui.PlatformDispatcher.instance.locale;
    if (_kSupportedLocales.contains(system.languageCode)) {
      return ui.Locale(system.languageCode);
    }
    return const ui.Locale('en');
  }

  /// Localizes the recurrence storage key. Hardcoded mapping mirrors
  /// `core/l10n/enum_labels.dart` — duplicated rather than imported
  /// because that helper requires a `BuildContext` and we have none
  /// here in the headless refresh path.
  static String _localizedRecurrence(AppL l, String storageKey) {
    switch (storageKey) {
      case 'yearly':
        return l.recurrenceYearly;
      case 'monthly':
        return l.recurrenceMonthly;
      case 'weekly':
        return l.recurrenceWeekly;
      case 'none':
      default:
        return l.recurrenceNone;
    }
  }

  static Future<bool?> _defaultSave(String key, String? value) =>
      HomeWidget.saveWidgetData<String?>(key, value);

  static Future<bool?> _defaultUpdate({String? androidName}) =>
      HomeWidget.updateWidget(androidName: androidName);
}

/// Internal struct so [_writeWidgetData] can stay agnostic of the
/// subject type. Not exported.
class _WidgetPayload {
  const _WidgetPayload({
    required this.title,
    required this.days,
    required this.subtitle,
  });
  final String title;
  final String days;
  final String subtitle;
}
