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
  TextColumn get colorHex => text()
      .withLength(min: 4, max: 9)
      .withDefault(const Constant('#6366F1'))();
  TextColumn get iconKey =>
      text().withLength(min: 1, max: 64).withDefault(const Constant('event'))();
  TextColumn get note => text().nullable()();
  TextColumn get recurrence => text().withDefault(const Constant('none'))();
  BoolColumn get isPinnedToWidget =>
      boolean().withDefault(const Constant(false))();

  /// Optional user-authored line shown on the home-screen widget in place
  /// of the auto-generated `<date> · <recurrence>` subtitle.
  ///
  /// Kept separate from [note] (which is private context) so that
  /// pinning an event to the widget can surface a different, more
  /// distilled phrase ("Lunch with Mom", "Mom's birthday gift") without
  /// changing the in-app card detail.
  ///
  /// Trimmed in the entity factory; empty strings are normalized to null
  /// before persistence so the updater never has to special-case them.
  TextColumn get widgetMessage =>
      text().nullable().withLength(max: 80)();
  IntColumn get createdAtEpochMs => integer()();
  IntColumn get updatedAtEpochMs => integer()();

  /// Soft-delete marker. `null` = live row, non-null = tombstone left
  /// behind so a future cloud-sync engine (Phase 2 per BRD §6 / M9)
  /// can propagate deletes without losing the row id. Local code
  /// still issues hard `DELETE`s today; the sync layer will be the
  /// first caller that sets this and the first to filter on it.
  IntColumn get deletedAtEpochMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
