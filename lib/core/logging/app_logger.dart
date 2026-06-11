import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Severity levels exposed by [AppLogger].
enum LogLevel { trace, debug, info, warn, error }

/// Thin facade over the `logger` package.
///
/// Wrapping the library protects feature code from breaking changes in the
/// underlying logger and gives us a single seam to redirect logs to Sentry,
/// PostHog, or a no-op sink without touching call sites.
class AppLogger {
  AppLogger._(this._delegate);

  factory AppLogger.create({LogLevel minLevel = LogLevel.debug}) {
    final Logger delegate = Logger(
      level: _toPackageLevel(minLevel),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 100,
        colors: true,
        printEmojis: false,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
    return AppLogger._(delegate);
  }

  /// Logger that discards everything — useful in tests.
  factory AppLogger.silent() =>
      AppLogger._(Logger(filter: _NoopFilter(), printer: PrettyPrinter()));

  final Logger _delegate;

  void trace(String message, {Object? error, StackTrace? stackTrace}) {
    _delegate.t(message, error: error, stackTrace: stackTrace);
  }

  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _delegate.d(message, error: error, stackTrace: stackTrace);
  }

  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _delegate.i(message, error: error, stackTrace: stackTrace);
  }

  void warn(String message, {Object? error, StackTrace? stackTrace}) {
    _delegate.w(message, error: error, stackTrace: stackTrace);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _delegate.e(message, error: error, stackTrace: stackTrace);
  }

  void dispose() {
    _delegate.close();
  }

  static Level _toPackageLevel(LogLevel level) => switch (level) {
        LogLevel.trace => Level.trace,
        LogLevel.debug => Level.debug,
        LogLevel.info => Level.info,
        LogLevel.warn => Level.warning,
        LogLevel.error => Level.error,
      };
}

class _NoopFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

/// Globally available logger. Tests should override this provider to
/// [AppLogger.silent].
final Provider<AppLogger> appLoggerProvider = Provider<AppLogger>((ref) {
  final AppLogger logger = AppLogger.create();
  ref.onDispose(logger.dispose);
  return logger;
});
