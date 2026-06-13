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

  /// Returns the first pinned event (legacy single-pin reader).
  /// Kept for backward compatibility — modern callers should use
  /// [getAllPinned] since the widget now renders a scrollable list.
  Future<Result<Event?, Failure>> getPinned();

  /// Snapshot read of every currently-pinned event, ordered by
  /// `targetAt` ascending (soonest first). Drives the home-screen
  /// widget's scrollable list.
  Future<Result<List<Event>, Failure>> getAllPinned();

  /// Inserts or replaces by `event.id`.
  Future<Result<void, Failure>> upsert(Event event);

  Future<Result<void, Failure>> delete(String id);

  /// Sets the pin state of a single event independently of the
  /// others. Multi-pin is now allowed because the widget shows a
  /// scrollable list of every pinned subject.
  Future<Result<void, Failure>> setPinned(String id, bool isPinned);

  /// Legacy single-pin entrypoint — kept for backward compat with
  /// callers that explicitly need "clear every pin, then optionally
  /// set one". New code should call [setPinned] instead.
  Future<Result<void, Failure>> pinExclusive(String? id);
}
