import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:polaris/data/database/daos/events_dao.dart';
import 'package:polaris/data/database/daos/life_profiles_dao.dart';
import 'package:polaris/data/database/daos/lifestyle_logs_dao.dart';
import 'package:polaris/data/database/daos/notifications_dao.dart';
import 'package:polaris/data/database/tables/events_table.dart';
import 'package:polaris/data/database/tables/life_profiles_table.dart';
import 'package:polaris/data/database/tables/lifestyle_logs_table.dart';
import 'package:polaris/data/database/tables/notification_schedules_table.dart';

part 'app_database.g.dart';

/// Single Drift database for Polaris.
///
/// All tables live here; per-aggregate query surfaces are exposed as
/// DAOs (see [eventsDao], [lifeProfilesDao], [notificationsDao],
/// [lifestyleLogsDao]). Schema migrations are declared via
/// [migration]; bump [schemaVersion] whenever a table or column is
/// added/changed and append a handler to `onUpgrade`.
@DriftDatabase(
  tables: <Type>[
    EventsTable,
    LifeProfilesTable,
    NotificationSchedulesTable,
    LifestyleLogsTable,
  ],
  daos: <Type>[EventsDao, LifeProfilesDao, NotificationsDao, LifestyleLogsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// Test constructor — pass an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

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
      if (from < 3) {
        // v2 → v3: notifications bookkeeping for scheduled local
        // reminders (T-7d / T-1d / T-1h per event).
        await m.createTable(notificationSchedulesTable);
      }
      if (from < 4) {
        // v3 → v4: lifestyle logging (water, sleep, exercise, mood).
        // Powers the recommendation engine landing in M5.
        await m.createTable(lifestyleLogsTable);
      }
      if (from < 5) {
        // v4 → v5: optional per-event message shown on the home-screen
        // widget (overrides the auto `<date> · <recurrence>` subtitle).
        // Nullable column, no default, no backfill needed.
        await m.addColumn(eventsTable, eventsTable.widgetMessage);
      }
      if (from < 6) {
        // v5 → v6: cloud-sync insurance columns. Adds nullable
        // `deletedAtEpochMs` to events_table and BOTH
        // `updatedAtEpochMs` + `deletedAtEpochMs` to
        // lifestyle_logs_table. No functional change today — the
        // columns sit empty until the Phase 2 sync engine (M9 per
        // BRD §6 / docs/Auth-Strategy.md) lands and starts writing
        // them. Cheap insurance to avoid a backfill migration later.
        await m.addColumn(eventsTable, eventsTable.deletedAtEpochMs);
        await m.addColumn(
          lifestyleLogsTable,
          lifestyleLogsTable.updatedAtEpochMs,
        );
        await m.addColumn(
          lifestyleLogsTable,
          lifestyleLogsTable.deletedAtEpochMs,
        );
      }
    },
  );

  static QueryExecutor _open() {
    return driftDatabase(name: 'polaris');
  }
}
