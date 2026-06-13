import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/notifications/flutter_local_notifications_dispatcher.dart';
import 'package:polaris/core/notifications/notification_dispatcher.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/providers.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/data/migrations/life_profile_sp_to_drift.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_profile_drift_repository.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_profile_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Composition root.
///
/// Owns process-wide concerns that must run before any widget is rendered:
/// binding initialization, global error handling, dependency injection
/// container creation, and (later) database warm-up.
///
/// Keep dependency wiring here — never deep in feature code — so the
/// Dependency Inversion principle stays enforced.
Future<void> bootstrap() async {
  // Everything — including `ensureInitialized` and `runApp` — must
  // happen in the *same* zone so Flutter's binding zone check passes.
  // See https://docs.flutter.dev/testing/errors#errors-not-caught-by-flutter
  // for the rationale.
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final AppLogger logger = AppLogger.create();
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final AppDatabase database = AppDatabase();

      // One-shot migration: move any M1 SharedPreferences profile into
      // the Drift store introduced in M2. Safe to call every boot —
      // the migrator is idempotent.
      await LifeProfileSpToDriftMigration(
        legacyRepository: LifeProfileRepositoryImpl(preferences),
        targetRepository: LifeProfileDriftRepository(database.lifeProfilesDao),
        logger: logger,
      ).run();

      // Initialise the local-notifications plugin up-front so per-event
      // scheduling later in the session doesn't pay the timezone /
      // channel setup cost.
      final NotificationDispatcher notifications =
          FlutterLocalNotificationsDispatcher(logger: logger);
      await notifications.initialize();

      FlutterError.onError = (FlutterErrorDetails details) {
        logger.error(
          'Uncaught Flutter error',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError =
          (Object error, StackTrace stack) {
        logger.error(
          'Uncaught platform error',
          error: error,
          stackTrace: stack,
        );
        return true;
      };

      runApp(
        ProviderScope(
          overrides: [
            appLoggerProvider.overrideWithValue(logger),
            sharedPreferencesProvider.overrideWithValue(preferences),
            appDatabaseProvider.overrideWithValue(database),
            notificationDispatcherProvider.overrideWithValue(notifications),
          ],
          child: const PolarisApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      // Last-resort handler. The logger may not have been constructed
      // yet (e.g. if `AppLogger.create()` itself threw), so fall back
      // to `debugPrint` here rather than depending on a captured
      // logger reference.
      debugPrint('Uncaught zone error: $error\n$stack');
    },
  );
}
