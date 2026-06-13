import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/notifications/flutter_local_notifications_dispatcher.dart';
import 'package:polaris/core/notifications/notification_dispatcher.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/core/widgets/polaris_home_widget_updater.dart';
import 'package:polaris/core/widgets/providers.dart' as widget_providers;
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/providers.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/data/repositories/event_repository_impl.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/data/datasources/life_expectancy_asset_data_source.dart';
import 'package:polaris/features/life_countdown/data/migrations/life_profile_sp_to_drift.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_expectancy_repository_impl.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_pin_repository.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_profile_drift_repository.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_profile_repository_impl.dart';
import 'package:polaris/features/life_countdown/domain/usecases/compute_life_estimate.dart';
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

      // Load `intl` date symbol tables for every locale we ship before
      // anything that uses `DateFormat(pattern, localeTag)` — most
      // notably the headless home-widget updater, which runs without
      // a `Localizations` ancestor. Done once at boot to keep widget
      // refreshes synchronous and crash-free.
      await initializeDateFormatting('en');
      await initializeDateFormatting('id');

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

      // Home-screen widget updater shares the event repository, life
      // pin preferences, and the life-estimate use case so it can
      // render either a pinned event or the pinned life countdown
      // with the user's custom message. Built here (rather than in a
      // Riverpod provider) so we can synchronously trigger an initial
      // refresh during boot — the OS may render the widget before
      // any UI loads.
      final lifeProfileRepo = LifeProfileDriftRepository(
        database.lifeProfilesDao,
      );
      final HomeWidgetUpdater widgetUpdater = PolarisHomeWidgetUpdater(
        eventRepository: EventRepositoryImpl(database.eventsDao),
        lifePinRepository: LifePinRepository(preferences),
        lifeProfileRepository: lifeProfileRepo,
        computeLifeEstimate: ComputeLifeEstimate(
          LifeExpectancyRepositoryImpl(LifeExpectancyAssetDataSource()),
        ),
        sharedPreferences: preferences,
        logger: logger,
      );
      // Best-effort initial render — the OS may show the widget
      // before the user touches the app.
      await widgetUpdater.refresh();

      FlutterError.onError = (FlutterErrorDetails details) {
        logger.error(
          'Uncaught Flutter error',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
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
            widget_providers.homeWidgetUpdaterProvider.overrideWithValue(
              widgetUpdater,
            ),
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
