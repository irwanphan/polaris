import 'package:drift/drift.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/tables/events_table.dart';

part 'events_dao.g.dart';

/// Encapsulates all SQL for the `events` table.
///
/// Single Responsibility: typed query surface for one aggregate.
/// Reactive reads use Drift's stream helpers so the UI updates without
/// manual cache invalidation.
@DriftAccessor(tables: <Type>[EventsTable])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  Stream<List<EventRow>> watchAll() {
    return (select(eventsTable)
          ..orderBy(<OrderClauseGenerator<$EventsTableTable>>[
            (t) => OrderingTerm.asc(t.targetAtEpochMs),
          ]))
        .watch();
  }

  Future<EventRow?> getById(String id) {
    return (select(
      eventsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Returns the first pinned row by id, if any. Multi-pin is now
  /// allowed (since the home-screen widget renders a scrollable list);
  /// this exists for legacy callers — prefer [watchPinned] for the
  /// modern path.
  Future<EventRow?> getPinned() {
    return (select(eventsTable)
          ..where((t) => t.isPinnedToWidget.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Snapshot read of every pinned event, ordered by target date
  /// ascending so the widget shows soonest-first.
  Future<List<EventRow>> getAllPinned() {
    return (select(eventsTable)
          ..where((t) => t.isPinnedToWidget.equals(true))
          ..orderBy(<OrderClauseGenerator<$EventsTableTable>>[
            (t) => OrderingTerm.asc(t.targetAtEpochMs),
          ]))
        .get();
  }

  /// Reactive variant of [getAllPinned] — emits a fresh list every
  /// time the pin state of any row changes.
  Stream<List<EventRow>> watchAllPinned() {
    return (select(eventsTable)
          ..where((t) => t.isPinnedToWidget.equals(true))
          ..orderBy(<OrderClauseGenerator<$EventsTableTable>>[
            (t) => OrderingTerm.asc(t.targetAtEpochMs),
          ]))
        .watch();
  }

  /// Inserts or replaces by primary key.
  Future<void> upsert(EventsTableCompanion row) {
    return into(eventsTable).insertOnConflictUpdate(row);
  }

  Future<int> deleteById(String id) {
    return (delete(eventsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Sets the pin state of a single event without touching the
  /// others. Multi-pin is now allowed because the widget renders a
  /// scrollable list of all pinned subjects.
  Future<void> setPinned(String id, bool isPinned) {
    return (update(eventsTable)..where((t) => t.id.equals(id))).write(
      EventsTableCompanion(isPinnedToWidget: Value(isPinned)),
    );
  }

  /// Legacy single-pin entrypoint kept for backward compat — callers
  /// that still want exclusive pin semantics can use it. New code
  /// should use [setPinned] instead.
  Future<void> pinExclusive(String? id) {
    return transaction(() async {
      await (update(eventsTable)..where((t) => t.isPinnedToWidget.equals(true)))
          .write(const EventsTableCompanion(isPinnedToWidget: Value(false)));
      if (id != null) {
        await (update(eventsTable)..where((t) => t.id.equals(id))).write(
          const EventsTableCompanion(isPinnedToWidget: Value(true)),
        );
      }
    });
  }
}
