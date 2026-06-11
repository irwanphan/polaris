import 'dart:async';
import 'dart:convert';

import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the single user [LifeProfile] as a JSON blob in
/// `SharedPreferences`.
///
/// This is intentionally lightweight for M1; once the Events feature in M2
/// pulls in Drift, the profile will be migrated into a typed row alongside
/// other entities. The repository abstraction shields callers from that
/// future change.
class LifeProfileRepositoryImpl implements LifeProfileRepository {
  LifeProfileRepositoryImpl(this._preferences);

  static const String _storageKey = 'polaris.life_profile.v1';

  final SharedPreferences _preferences;

  @override
  Future<Result<LifeProfile?, Failure>> read() async {
    try {
      final String? raw = _preferences.getString(_storageKey);
      if (raw == null) {
        return const Result.ok(null);
      }
      final Map<String, dynamic> decoded =
          json.decode(raw) as Map<String, dynamic>;
      return Result.ok(_fromJson(decoded));
    } catch (e, st) {
      return Result.err(
        StorageFailure(
          message: 'Failed to read life profile: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> save(LifeProfile profile) async {
    try {
      final String encoded = json.encode(_toJson(profile));
      final bool ok = await _preferences.setString(_storageKey, encoded);
      if (!ok) {
        return const Result.err(
          StorageFailure(message: 'SharedPreferences refused the write.'),
        );
      }
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(
        StorageFailure(
          message: 'Failed to save life profile: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> clear() async {
    try {
      await _preferences.remove(_storageKey);
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(
        StorageFailure(
          message: 'Failed to clear life profile: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  // --- Serialization -------------------------------------------------------

  Map<String, dynamic> _toJson(LifeProfile p) => <String, dynamic>{
        'birthDateIso': p.dateOfBirth.date.toIso8601String(),
        'sex': p.sex.storageKey,
        'countryCode': p.countryCode.value,
        'hideLifeCountdown': p.hideLifeCountdown,
        'createdAtIso': p.createdAt.toIso8601String(),
        'updatedAtIso': p.updatedAt.toIso8601String(),
      };

  LifeProfile? _fromJson(Map<String, dynamic> data) {
    final String birthIso = data['birthDateIso'] as String;
    final DateTime birth = DateTime.parse(birthIso);
    final DateOfBirth? dob =
        DateOfBirth.tryFromDateTime(birth, today: DateTime.now())
            .valueOrNull;
    if (dob == null) return null;

    final CountryCode? country =
        CountryCode.tryParse(data['countryCode'] as String).valueOrNull;
    if (country == null) return null;

    return LifeProfile(
      dateOfBirth: dob,
      sex: Sex.fromStorageKey(data['sex'] as String),
      countryCode: country,
      hideLifeCountdown: (data['hideLifeCountdown'] as bool?) ?? false,
      createdAt: DateTime.parse(data['createdAtIso'] as String),
      updatedAt: DateTime.parse(data['updatedAtIso'] as String),
    );
  }
}
