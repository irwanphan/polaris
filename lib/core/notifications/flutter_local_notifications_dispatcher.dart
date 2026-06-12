import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/notifications/notification_dispatcher.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Production implementation backed by the `flutter_local_notifications`
/// plugin. Encapsulates plugin initialization, timezone setup, channel
/// configuration, and the per-platform permission handshake.
///
/// Kept inside `core/` so feature schedulers depend only on the
/// abstract [NotificationDispatcher] interface, not on the plugin.
class FlutterLocalNotificationsDispatcher implements NotificationDispatcher {
  FlutterLocalNotificationsDispatcher({
    FlutterLocalNotificationsPlugin? plugin,
    this.logger,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Stable Android notification channel id. Bumping this resets user
  /// channel-level customizations (importance, sound) — avoid unless
  /// the channel semantics change.
  static const String _androidChannelId = 'polaris_event_reminders';
  static const String _androidChannelName = 'Event reminders';
  static const String _androidChannelDescription =
      'Reminders for events you have scheduled in Polaris.';

  final FlutterLocalNotificationsPlugin _plugin;
  final AppLogger? logger;

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e, st) {
      // Fall back to UTC so scheduling still works, just at the wrong
      // wall-clock time — better than crashing the bootstrap.
      logger?.warn(
        'Could not resolve local timezone; falling back to UTC',
        error: e,
        stackTrace: st,
      );
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  @override
  Future<bool> ensurePermission() async {
    if (!_initialized) await initialize();

    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted =
          await androidImpl?.requestNotificationsPermission();
      return granted ?? false;
    }
    if (Platform.isIOS) {
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final bool? granted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    // Desktop / web: assume granted; the plugin no-ops if unsupported.
    return true;
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);

    const AndroidNotificationDetails android = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzWhen,
      notificationDetails:
          const NotificationDetails(android: android, iOS: darwin),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
