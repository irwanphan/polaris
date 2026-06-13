import 'package:drift/drift.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/tables/lifestyle_logs_table.dart';

part 'lifestyle_logs_dao.g.dart';

/// Typed query surface for the `lifestyle_logs` table.
///
/// Reactive reads use Drift's `watch()` helpers so the UI never has
/// to invalidate caches manually. Date-range queries are inclusive
/// on both ends (callers pass the local midnight bounds they want).
@DriftAccessor(tables: <Type>[LifestyleLogsTable])
class LifestyleLogsDao extends DatabaseAccessor<AppDatabase>
    with _$LifestyleLogsDaoMixin {
  LifestyleLogsDao(super.db);

  /// Reactive stream of every log whose [LifestyleLogsTable.loggedAtEpochMs]
  /// falls within `[fromEpochMs, toEpochMs]`, ordered newest-first.
  Stream<List<LifestyleLogRow>> watchBetween({
    required int fromEpochMs,
    required int toEpochMs,
  }) {
    return (select(lifestyleLogsTable)
          ..where(
            (t) =>
                t.loggedAtEpochMs.isBiggerOrEqualValue(fromEpochMs) &
                t.loggedAtEpochMs.isSmallerOrEqualValue(toEpochMs),
          )
          ..orderBy(<OrderClauseGenerator<$LifestyleLogsTableTable>>[
            (t) => OrderingTerm.desc(t.loggedAtEpochMs),
          ]))
        .watch();
  }

  /// One-shot read for repository methods that don't need reactivity
  /// (e.g. snapshot tests, migrations, manual export).
  Future<List<LifestyleLogRow>> listBetween({
    required int fromEpochMs,
    required int toEpochMs,
  }) {
    return (select(lifestyleLogsTable)
          ..where(
            (t) =>
                t.loggedAtEpochMs.isBiggerOrEqualValue(fromEpochMs) &
                t.loggedAtEpochMs.isSmallerOrEqualValue(toEpochMs),
          )
          ..orderBy(<OrderClauseGenerator<$LifestyleLogsTableTable>>[
            (t) => OrderingTerm.desc(t.loggedAtEpochMs),
          ]))
        .get();
  }

  Future<void> upsert(LifestyleLogsTableCompanion row) {
    return into(lifestyleLogsTable).insertOnConflictUpdate(row);
  }

  Future<int> deleteById(String id) {
    return (delete(lifestyleLogsTable)..where((t) => t.id.equals(id))).go();
  }
}
