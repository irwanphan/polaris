/// Domain-level failure hierarchy.
///
/// Infrastructure exceptions (Drift, dio, platform channels) are caught at
/// the `data` boundary and mapped to one of these failures so the
/// `application` and `presentation` layers never depend on infrastructure
/// types.
sealed class Failure {
  const Failure({required this.message, this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

/// Catch-all when no more specific failure applies.
final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred.',
    super.cause,
    super.stackTrace,
  });
}

/// User input that failed validation before reaching infrastructure.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.field,
    super.cause,
    super.stackTrace,
  });

  /// Optional field key for highlighting in forms (e.g. `'birthDate'`).
  final String? field;
}

/// Local database or shared-preferences error.
final class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.cause, super.stackTrace});
}

/// Network or remote-service error (used once cloud sync lands).
final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

/// Required data was missing (e.g. life-expectancy table for a country).
final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
