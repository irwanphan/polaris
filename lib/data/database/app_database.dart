import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:polaris/data/database/daos/events_dao.dart';
import 'package:polaris/data/database/tables/events_table.dart';

part 'app_database.g.dart';

/// Single Drift database for Polaris.
///
/// All tables live here; per-aggregate query surfaces are exposed as
/// DAOs (see [eventsDao]). Schema migrations live in
/// `data/database/migrations/` once we need them — for v1 the default
/// auto-created schema is enough.
@DriftDatabase(
  tables: <Type>[EventsTable],
  daos: <Type>[EventsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// Test constructor — pass an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() {
    return driftDatabase(name: 'polaris');
  }
}
