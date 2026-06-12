import 'package:drift/drift.dart';

/// Persisted shape of an event.
///
/// Field-naming conventions:
///  - `*EpochMs` columns store UTC milliseconds since epoch; presentation
///    code converts to local timezone via the entity layer.
///  - Enum-like values (recurrence) are stored as their `storageKey`
///    string, never as their ordinal — protects us from re-ordering enums.
@DataClassName('EventRow')
class EventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  IntColumn get targetAtEpochMs => integer()();
  TextColumn get colorHex =>
      text().withLength(min: 4, max: 9).withDefault(const Constant('#6366F1'))();
  TextColumn get iconKey =>
      text().withLength(min: 1, max: 64).withDefault(const Constant('event'))();
  TextColumn get note => text().nullable()();
  TextColumn get recurrence =>
      text().withDefault(const Constant('none'))();
  BoolColumn get isPinnedToWidget =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAtEpochMs => integer()();
  IntColumn get updatedAtEpochMs => integer()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
