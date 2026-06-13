import 'package:drift/drift.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/daos/events_dao.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';

/// Drift-backed repository.
///
/// All persistence concerns (millisecond conversion, enum encoding) live
/// here so the domain entity stays free of database knowledge.
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._dao);

  final EventsDao _dao;

  @override
  Stream<List<Event>> watchAll() {
    return _dao.watchAll().map(
      (List<EventRow> rows) => rows.map(_fromRow).toList(growable: false),
    );
  }

  @override
  Future<Result<Event?, Failure>> getById(String id) async {
    try {
      final EventRow? row = await _dao.getById(id);
      return Result.ok(row == null ? null : _fromRow(row));
    } catch (e, st) {
      return Result.err(_failure('Failed to read event', e, st));
    }
  }

  @override
  Future<Result<Event?, Failure>> getPinned() async {
    try {
      final EventRow? row = await _dao.getPinned();
      return Result.ok(row == null ? null : _fromRow(row));
    } catch (e, st) {
      return Result.err(_failure('Failed to read pinned event', e, st));
    }
  }

  @override
  Future<Result<void, Failure>> upsert(Event event) async {
    try {
      await _dao.upsert(_toCompanion(event));
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(_failure('Failed to save event', e, st));
    }
  }

  @override
  Future<Result<void, Failure>> delete(String id) async {
    try {
      await _dao.deleteById(id);
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(_failure('Failed to delete event', e, st));
    }
  }

  @override
  Future<Result<void, Failure>> pinExclusive(String? id) async {
    try {
      await _dao.pinExclusive(id);
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(_failure('Failed to pin event', e, st));
    }
  }

  // --- Mapping -------------------------------------------------------------

  Event _fromRow(EventRow row) {
    return Event(
      id: row.id,
      title: row.title,
      targetAt: DateTime.fromMillisecondsSinceEpoch(
        row.targetAtEpochMs,
        isUtc: true,
      ).toLocal(),
      colorHex: row.colorHex,
      iconKey: row.iconKey,
      note: row.note,
      widgetMessage: row.widgetMessage,
      recurrence: Recurrence.fromStorageKey(row.recurrence),
      isPinnedToWidget: row.isPinnedToWidget,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtEpochMs,
        isUtc: true,
      ).toLocal(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtEpochMs,
        isUtc: true,
      ).toLocal(),
    );
  }

  EventsTableCompanion _toCompanion(Event event) {
    return EventsTableCompanion(
      id: Value(event.id),
      title: Value(event.title),
      targetAtEpochMs: Value(event.targetAt.toUtc().millisecondsSinceEpoch),
      colorHex: Value(event.colorHex),
      iconKey: Value(event.iconKey),
      note: Value(event.note),
      widgetMessage: Value(event.widgetMessage),
      recurrence: Value(event.recurrence.storageKey),
      isPinnedToWidget: Value(event.isPinnedToWidget),
      createdAtEpochMs: Value(event.createdAt.toUtc().millisecondsSinceEpoch),
      updatedAtEpochMs: Value(event.updatedAt.toUtc().millisecondsSinceEpoch),
    );
  }

  StorageFailure _failure(String message, Object error, StackTrace stack) {
    return StorageFailure(
      message: '$message: $error',
      cause: error,
      stackTrace: stack,
    );
  }
}
