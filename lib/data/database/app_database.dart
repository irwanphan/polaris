import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:polaris/data/database/daos/events_dao.dart';
import 'package:polaris/data/database/daos/life_profiles_dao.dart';
import 'package:polaris/data/database/tables/events_table.dart';
import 'package:polaris/data/database/tables/life_profiles_table.dart';

part 'app_database.g.dart';

/// Single Drift database for Polaris.
///
/// All tables live here; per-aggregate query surfaces are exposed as
/// DAOs (see [eventsDao], [lifeProfilesDao]). Schema migrations are
/// declared via [migration]; bump [schemaVersion] whenever a table or
/// column is added/changed and append a handler to `onUpgrade`.
@DriftDatabase(
  tables: <Type>[EventsTable, LifeProfilesTable],
  daos: <Type>[EventsDao, LifeProfilesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// Test constructor — pass an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // v1 → v2: introduced LifeProfilesTable when the M1 profile
            // moved from SharedPreferences into Drift.
            await m.createTable(lifeProfilesTable);
          }
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(name: 'polaris');
  }
}
