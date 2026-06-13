import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';

/// Persists [LifestyleLog]s.
///
/// Range queries are expressed in *local* `DateTime` so callers don't
/// have to think about timezones; the data layer converts to UTC
/// milliseconds at the boundary (mirrors `EventRepository`).
abstract interface class LifestyleLogRepository {
  /// Reactive stream of every log in `[from, to]` (inclusive on both
  /// ends), ordered newest-first. Use this for the today summary and
  /// the rolling 7-day history.
  Stream<List<LifestyleLog>> watchBetween({
    required DateTime from,
    required DateTime to,
  });

  /// One-shot read, same range semantics as [watchBetween].
  Future<Result<List<LifestyleLog>, Failure>> listBetween({
    required DateTime from,
    required DateTime to,
  });

  /// Inserts or replaces by `log.id`.
  Future<Result<void, Failure>> upsert(LifestyleLog log);

  Future<Result<void, Failure>> delete(String id);
}
