import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';

/// Persists user events.
///
/// Implementations live in `data/`. Returns reactive streams so the UI can
/// react to inserts / updates / deletes without polling.
abstract interface class EventRepository {
  /// Reactive list of all events. Recurrence is **not** materialised here;
  /// callers compute the next occurrence via [Event.nextOccurrence].
  Stream<List<Event>> watchAll();

  Future<Result<Event?, Failure>> getById(String id);

  /// Inserts or replaces by `event.id`.
  Future<Result<void, Failure>> upsert(Event event);

  Future<Result<void, Failure>> delete(String id);

  /// Unpins all events except [id], which is then pinned.
  ///
  /// Polaris allows exactly one pinned event at a time — the widget shows
  /// the pinned event. Pass `null` to clear the pin entirely.
  Future<Result<void, Failure>> pinExclusive(String? id);
}
