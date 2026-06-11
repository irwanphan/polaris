import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/logging/app_logger.dart';

/// Composition root.
///
/// Owns process-wide concerns that must run before any widget is rendered:
/// binding initialization, global error handling, dependency injection
/// container creation, and (later) database warm-up.
///
/// Keep dependency wiring here — never deep in feature code — so the
/// Dependency Inversion principle stays enforced.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppLogger logger = AppLogger.create();

  FlutterError.onError = (FlutterErrorDetails details) {
    logger.error(
      'Uncaught Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    logger.error('Uncaught platform error', error: error, stackTrace: stack);
    return true;
  };

  runZonedGuarded<void>(
    () {
      runApp(
        ProviderScope(
          overrides: [
            appLoggerProvider.overrideWithValue(logger),
          ],
          child: const PolarisApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      logger.error('Uncaught zone error', error: error, stackTrace: stack);
    },
  );
}
