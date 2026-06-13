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

  /// Returns the single pinned row, if any. The repository enforces
  /// at most one pin via [pinExclusive], so `LIMIT 1` is safe.
  Future<EventRow?> getPinned() {
    return (select(eventsTable)
          ..where((t) => t.isPinnedToWidget.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Inserts or replaces by primary key.
  Future<void> upsert(EventsTableCompanion row) {
    return into(eventsTable).insertOnConflictUpdate(row);
  }

  Future<int> deleteById(String id) {
    return (delete(eventsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Atomically clears every pin and (optionally) sets exactly one.
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
