import 'package:drift/drift.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/tables/life_profiles_table.dart';

part 'life_profiles_dao.g.dart';

/// Singleton-row accessor for the `life_profiles` table.
///
/// All reads and writes operate on the row with `id = 1` — the table
/// schema enforces that invariant via its primary key default. Callers
/// never need to think about the id.
@DriftAccessor(tables: <Type>[LifeProfilesTable])
class LifeProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$LifeProfilesDaoMixin {
  LifeProfilesDao(super.db);

  static const int _singletonId = 1;

  Future<LifeProfileRow?> read() {
    return (select(lifeProfilesTable)
          ..where((t) => t.id.equals(_singletonId)))
        .getSingleOrNull();
  }

  Future<void> upsert(LifeProfilesTableCompanion row) {
    return into(lifeProfilesTable)
        .insertOnConflictUpdate(row.copyWith(id: const Value(_singletonId)));
  }

  Future<int> clear() {
    return (delete(lifeProfilesTable)
          ..where((t) => t.id.equals(_singletonId)))
        .go();
  }
}
