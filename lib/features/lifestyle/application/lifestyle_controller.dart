import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/lifestyle/application/providers.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/repositories/lifestyle_log_repository.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';

/// Write-side commands for lifestyle logging. Reads happen through
/// the stream providers in `providers.dart` so the UI auto-refreshes
/// after every mutation without an explicit invalidate.
///
/// Each command returns a [Result] so callers can surface failures
/// (e.g. validation, DB) in the UI; we never throw out of the
/// controller for expected error paths.
class LifestyleController {
  const LifestyleController(this._repository, this._logger);

  final LifestyleLogRepository _repository;
  final AppLogger _logger;

  /// Records a single observation. Constructs a fresh [LifestyleLog]
  /// (new uuid, `loggedAt = now`) and persists it.
  ///
  /// Snapshot categories ([LogAggregation.snapshot]) still append a
  /// new row per call — the per-day "latest wins" semantic is
  /// applied at read time in the UI. That keeps the schema simple
  /// and preserves the full audit trail.
  Future<Result<void, Failure>> log({
    required LogCategory category,
    required double value,
    String? note,
  }) async {
    if (!category.isValid(value)) {
      return Result.err(
        ValidationFailure(
          message:
              'Value $value is out of range '
              '(${category.minValue}–${category.maxValue}) for ${category.label}',
        ),
      );
    }
    final LifestyleLog log = LifestyleLog.create(
      category: category,
      value: value,
      note: note,
    );
    final Result<void, Failure> result = await _repository.upsert(log);
    result.fold(
      onOk: (_) => _logger.info(
        'Logged ${category.label}=$value ${category.unit} (id=${log.id})',
      ),
      onErr: (failure) =>
          _logger.warn('Failed to log ${category.label}: $failure'),
    );
    return result;
  }

  Future<Result<void, Failure>> delete(String id) async {
    final Result<void, Failure> result = await _repository.delete(id);
    result.fold(
      onOk: (_) => _logger.info('Deleted lifestyle log $id'),
      onErr: (failure) => _logger.warn('Failed to delete log $id: $failure'),
    );
    return result;
  }
}

final Provider<LifestyleController> lifestyleControllerProvider =
    Provider<LifestyleController>(
      (ref) => LifestyleController(
        ref.watch(lifestyleLogRepositoryProvider),
        ref.watch(appLoggerProvider),
      ),
    );
