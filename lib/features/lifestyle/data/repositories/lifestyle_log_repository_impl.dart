import 'package:drift/drift.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/daos/lifestyle_logs_dao.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/repositories/lifestyle_log_repository.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';

/// Drift-backed [LifestyleLogRepository].
///
/// All conversion concerns (UTC ms ↔ local `DateTime`, enum
/// `storageKey` ↔ `LogCategory`) live here so the domain layer
/// stays platform- and storage-free.
///
/// Rows with an unknown category storageKey are silently dropped
/// from reads — forward-compatible behaviour for older clients that
/// don't yet recognise a newly-added category. The data is still
/// persisted, so a future app version will pick it up.
class LifestyleLogRepositoryImpl implements LifestyleLogRepository {
  LifestyleLogRepositoryImpl(this._dao);

  final LifestyleLogsDao _dao;

  @override
  Stream<List<LifestyleLog>> watchBetween({
    required DateTime from,
    required DateTime to,
  }) {
    return _dao
        .watchBetween(
          fromEpochMs: from.toUtc().millisecondsSinceEpoch,
          toEpochMs: to.toUtc().millisecondsSinceEpoch,
        )
        .map(
          (List<LifestyleLogRow> rows) => rows
              .map(_fromRow)
              .whereType<LifestyleLog>()
              .toList(growable: false),
        );
  }

  @override
  Future<Result<List<LifestyleLog>, Failure>> listBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final List<LifestyleLogRow> rows = await _dao.listBetween(
        fromEpochMs: from.toUtc().millisecondsSinceEpoch,
        toEpochMs: to.toUtc().millisecondsSinceEpoch,
      );
      return Result.ok(
        rows.map(_fromRow).whereType<LifestyleLog>().toList(growable: false),
      );
    } catch (e, st) {
      return Result.err(_failure('Failed to read lifestyle logs', e, st));
    }
  }

  @override
  Future<Result<void, Failure>> upsert(LifestyleLog log) async {
    try {
      await _dao.upsert(_toCompanion(log));
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(_failure('Failed to save lifestyle log', e, st));
    }
  }

  @override
  Future<Result<void, Failure>> delete(String id) async {
    try {
      await _dao.deleteById(id);
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(_failure('Failed to delete lifestyle log', e, st));
    }
  }

  // --- Mapping -------------------------------------------------------------

  LifestyleLog? _fromRow(LifestyleLogRow row) {
    final LogCategory? category = LogCategory.fromStorageKey(row.category);
    if (category == null) return null;
    return LifestyleLog(
      id: row.id,
      category: category,
      value: row.value,
      note: row.note,
      loggedAt: DateTime.fromMillisecondsSinceEpoch(
        row.loggedAtEpochMs,
        isUtc: true,
      ).toLocal(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtEpochMs,
        isUtc: true,
      ).toLocal(),
    );
  }

  LifestyleLogsTableCompanion _toCompanion(LifestyleLog log) {
    return LifestyleLogsTableCompanion(
      id: Value(log.id),
      category: Value(log.category.storageKey),
      value: Value(log.value),
      note: Value(log.note),
      loggedAtEpochMs: Value(log.loggedAt.toUtc().millisecondsSinceEpoch),
      createdAtEpochMs: Value(log.createdAt.toUtc().millisecondsSinceEpoch),
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
