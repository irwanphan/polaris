import 'package:drift/drift.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/data/database/daos/life_profiles_dao.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';

/// Drift-backed singleton-row repository for [LifeProfile].
///
/// Successor to the M1 `LifeProfileRepositoryImpl` (SharedPreferences).
/// The SP impl is kept around as a legacy reader for the one-shot
/// migration on first launch.
class LifeProfileDriftRepository implements LifeProfileRepository {
  LifeProfileDriftRepository(this._dao);

  final LifeProfilesDao _dao;

  @override
  Future<Result<LifeProfile?, Failure>> read() async {
    try {
      final LifeProfileRow? row = await _dao.read();
      if (row == null) return const Result.ok(null);
      final LifeProfile? profile = _fromRow(row);
      return Result.ok(profile);
    } catch (e, st) {
      return Result.err(
        StorageFailure(
          message: 'Failed to read life profile from Drift: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> save(LifeProfile profile) async {
    try {
      await _dao.upsert(_toCompanion(profile));
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(
        StorageFailure(
          message: 'Failed to save life profile to Drift: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> clear() async {
    try {
      await _dao.clear();
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(
        StorageFailure(
          message: 'Failed to clear life profile in Drift: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  // --- Mapping -------------------------------------------------------------

  LifeProfile? _fromRow(LifeProfileRow row) {
    final DateTime birth = DateTime.fromMillisecondsSinceEpoch(
      row.birthDateEpochMs,
      isUtc: true,
    ).toLocal();
    final DateOfBirth? dob = DateOfBirth.tryFromDateTime(
      birth,
      today: DateTime.now(),
    ).valueOrNull;
    if (dob == null) return null;

    final CountryCode? country = CountryCode.tryParse(
      row.countryCode,
    ).valueOrNull;
    if (country == null) return null;

    return LifeProfile(
      dateOfBirth: dob,
      sex: Sex.fromStorageKey(row.sex),
      countryCode: country,
      hideLifeCountdown: row.hideLifeCountdown,
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

  LifeProfilesTableCompanion _toCompanion(LifeProfile profile) {
    return LifeProfilesTableCompanion(
      birthDateEpochMs: Value(
        profile.dateOfBirth.date.toUtc().millisecondsSinceEpoch,
      ),
      sex: Value(profile.sex.storageKey),
      countryCode: Value(profile.countryCode.value),
      hideLifeCountdown: Value(profile.hideLifeCountdown),
      createdAtEpochMs: Value(profile.createdAt.toUtc().millisecondsSinceEpoch),
      updatedAtEpochMs: Value(profile.updatedAt.toUtc().millisecondsSinceEpoch),
    );
  }
}
