import 'dart:convert' as convert;
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
/// Serializes every currently-pinned subject (life-countdown + each
/// pinned event) as a JSON array stored under
/// [kItemsJsonKey] in the Android `SharedPreferences` bridge. The
/// native side parses this list and renders it as a scrollable
/// `ListView` collection widget — see
/// `PolarisWidgetRemoteViewsService.kt` for the wire reader.
///
/// Ordering: life pin (if any) first, then events sorted by
/// `targetAt` ascending (soonest first). Life is treated as a
/// "meta" subject — it's the most stable countdown so it's a useful
/// anchor at the top of the list.
///
/// Per-item subtitle resolution:
///   * Life:  custom message → otherwise "Ends ~{estimatedEndDate}".
///   * Event: [Event.widgetMessage] → otherwise
///            "{date} · {recurrence}".
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

  /// Mirrors the key used by `LocaleController`. Hardcoded here
  /// instead of importing the controller to avoid a Flutter-only
  /// dependency in this isolate-friendly class.
  static const String _kLocalePrefsKey = 'polaris.locale.v1';
  static const Set<String> _kSupportedLocales = <String>{'en', 'id'};

  /// Stored display name for the widget greeting. Read at refresh
  /// time and folded into `l.widgetGreeting(...)`. Designed as a
  /// stop-gap until proper auth lands — once Polaris has a
  /// `currentUser` notion, swap [_resolveUserName] to read from
  /// that source instead and this key becomes obsolete (we can
  /// migrate by writing the auth name into this same key on
  /// login, then deleting the key after the next major version).
  static const String _kUserNamePrefsKey = 'polaris.user.name.v1';

  /// Visible when the user has not set a display name yet. Kept
  /// English-neutral on purpose: the Indonesian "Halo, User" still
  /// reads naturally and avoids a second localization round-trip.
  static const String _kFallbackUserName = 'User';

  /// JSON-encoded list of widget items. Mirrored in
  /// `PolarisWidgetRemoteViewsService.kt` (`KEY_ITEMS_JSON`).
  static const String kItemsJsonKey = 'polaris_widget_items_json';

  /// Localized title shown above the list (e.g. "Polaris").
  /// Mirrored in `PolarisWidgetProvider.kt` (`KEY_HEADER_TITLE`).
  static const String kHeaderTitleKey = 'polaris_widget_header_title';

  /// Localized empty-state copy. Mirrored in `PolarisWidgetProvider.kt`
  /// (`KEY_EMPTY_TITLE` / `KEY_EMPTY_SUBTITLE`).
  static const String kEmptyTitleKey = 'polaris_widget_empty_title';
  static const String kEmptySubtitleKey = 'polaris_widget_empty_subtitle';

  /// Matches the class name registered in `AndroidManifest.xml`.
  static const String _kAndroidProvider = 'PolarisWidgetProvider';

  /// Wire-format kind tags. Mirrored in `PolarisWidgetItemsFactory.kt`.
  static const String _kKindLife = 'life';
  static const String _kKindEvent = 'event';

  @override
  Future<void> refresh() async {
    try {
      final ui.Locale locale = _resolveLocale();
      final AppL l = await _loadLocalizations(locale);
      final String localeTag = locale.toLanguageTag();

      final List<_WidgetItem> items = await _buildItems(l, localeTag);

      await _writeHeader(l);
      await _writeItems(items);
      await _triggerUpdate(androidName: _kAndroidProvider);
    } catch (e, st) {
      logger.warn(
        'Home-screen widget refresh failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<List<_WidgetItem>> _buildItems(AppL l, String localeTag) async {
    final List<_WidgetItem> items = <_WidgetItem>[];

    final lifePin = lifePinRepository.read();
    if (lifePin.pinned) {
      final _WidgetItem? life =
          await _buildLifeItem(l, localeTag, lifePin.customMessage);
      if (life != null) items.add(life);
    }

    final eventsResult = await eventRepository.getAllPinned();
    final List<Event> events = eventsResult.fold(
      onOk: (list) => list,
      onErr: (failure) {
        logger.warn(
          'Widget refresh: failed to read pinned events',
          error: failure,
        );
        return const <Event>[];
      },
    );
    for (final event in events) {
      items.add(_buildEventItem(l, localeTag, event));
    }

    return items;
  }

  Future<_WidgetItem?> _buildLifeItem(
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

    return _WidgetItem(
      id: 'life',
      kind: _kKindLife,
      title: l.lifeTitle,
      hero: hero,
      subtitle: subtitle,
      // Amber matches the POLARIS brand pill and contrasts the
      // indigo widget surface — indigo-on-indigo accent disappears
      // visually.
      accentColorHex: '#FBBF24',
    );
  }

  _WidgetItem _buildEventItem(AppL l, String localeTag, Event event) {
    final DateTime now = _now();
    final DateTime next = event.nextOccurrence(now);
    final int days = event.daysUntil(now);
    final String hero = l.widgetEventDays(days);
    final String subtitle = event.widgetMessage ??
        l.widgetEventSubtitleDefault(
          DateFormat('EEE, MMM d', localeTag).format(next),
          _localizedRecurrence(l, event.recurrence.storageKey),
        );
    return _WidgetItem(
      id: event.id,
      kind: _kKindEvent,
      title: event.title,
      hero: hero,
      subtitle: subtitle,
      accentColorHex: event.colorHex,
    );
  }

  Future<void> _writeHeader(AppL l) async {
    await _saveData(kHeaderTitleKey, l.widgetGreeting(_resolveUserName()));
    await _saveData(kEmptyTitleKey, l.widgetEmptyTitle);
    await _saveData(kEmptySubtitleKey, l.widgetEmptySubtitle);
  }

  /// Resolves the display name shown in the widget header greeting.
  ///
  /// Lookup order:
  ///   1. SharedPreferences[`_kUserNamePrefsKey`] — manual override
  ///      and (eventually) the bridge that auth writes into.
  ///   2. [_kFallbackUserName] — generic stand-in until login is
  ///      implemented, so the widget never reads "Hello, ".
  ///
  /// Whitespace-only values are treated as missing.
  String _resolveUserName() {
    final String? stored = sharedPreferences.getString(_kUserNamePrefsKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    return _kFallbackUserName;
  }

  Future<void> _writeItems(List<_WidgetItem> items) async {
    final List<Map<String, Object?>> rows =
        items.map((i) => i.toJson()).toList(growable: false);
    await _saveData(kItemsJsonKey, convert.json.encode(rows));
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

/// Wire-format struct serialized to a single JSON array string and
/// read by the native `PolarisWidgetItemsFactory`.
class _WidgetItem {
  const _WidgetItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.hero,
    required this.subtitle,
    required this.accentColorHex,
  });

  final String id;
  final String kind;
  final String title;
  final String hero;
  final String subtitle;
  final String accentColorHex;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'kind': kind,
        'title': title,
        'hero': hero,
        'subtitle': subtitle,
        'accent': accentColorHex,
      };
}
