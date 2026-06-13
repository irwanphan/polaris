import 'package:drift/drift.dart';

/// Per-entry lifestyle log row.
///
/// Each row records a single quantitative observation at a point in
/// time. Aggregation (e.g. "total glasses today") happens at query
/// time in the DAO — we never store derived state, which keeps the
/// schema simple and lets future categories swap their aggregation
/// rule without a migration.
///
/// Schema notes:
///   - [category] uses the storage-stable enum key (see `LogCategory.storageKey`).
///   - [value] is stored as `REAL` so the same column type handles
///     both integer-like categories (water glasses) and decimal ones
///     (sleep hours). Validation happens in the domain layer.
///   - All timestamps are UTC milliseconds; the repository converts
///     to/from local `DateTime` at the boundary, mirroring the
///     pattern used by [EventsTable] / [LifeProfilesTable].
@DataClassName('LifestyleLogRow')
class LifestyleLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get category => text().withLength(min: 1, max: 32)();
  RealColumn get value => real()();
  TextColumn get note => text().nullable()();
  IntColumn get loggedAtEpochMs => integer()();
  IntColumn get createdAtEpochMs => integer()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
