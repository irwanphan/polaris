import 'package:drift/drift.dart';

/// Singleton-row table for the user's [LifeProfile].
///
/// Polaris stores at most one profile per device, so [id] is always
/// hard-coded to 1 and the schema treats it as the primary key. This is
/// simpler than maintaining a separate "settings" key/value table and
/// keeps the API surface a regular Drift table for testing.
@DataClassName('LifeProfileRow')
class LifeProfilesTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get birthDateEpochMs => integer()();
  TextColumn get sex => text()();
  TextColumn get countryCode => text().withLength(min: 2, max: 2)();
  BoolColumn get hideLifeCountdown =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAtEpochMs => integer()();
  IntColumn get updatedAtEpochMs => integer()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
