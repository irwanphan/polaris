import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/life_countdown/data/migrations/life_profile_sp_to_drift.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';

class _InMemoryRepo implements LifeProfileRepository {
  _InMemoryRepo([this._profile]);

  LifeProfile? _profile;
  bool clearWasCalled = false;

  @override
  Future<Result<LifeProfile?, Failure>> read() async => Result.ok(_profile);

  @override
  Future<Result<void, Failure>> save(LifeProfile profile) async {
    _profile = profile;
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> clear() async {
    clearWasCalled = true;
    _profile = null;
    return const Result.ok(null);
  }
}

class _AlwaysFailingSaveRepo extends _InMemoryRepo {
  @override
  Future<Result<void, Failure>> save(LifeProfile profile) async {
    return const Result.err(StorageFailure(message: 'disk full'));
  }
}

LifeProfile _profile() {
  final now = DateTime(2026, 6, 12);
  return LifeProfile(
    dateOfBirth: DateOfBirth.tryFromDateTime(
      DateTime(1995, 5, 15),
      today: now,
    ).valueOrNull!,
    sex: Sex.female,
    countryCode: CountryCode.tryParse('ID').valueOrNull!,
    hideLifeCountdown: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('LifeProfileSpToDriftMigration', () {
    test('no-ops when legacy store is empty', () async {
      final legacy = _InMemoryRepo();
      final target = _InMemoryRepo();
      final migrated = await LifeProfileSpToDriftMigration(
        legacyRepository: legacy,
        targetRepository: target,
      ).run();

      expect(migrated, isFalse);
      expect((await target.read()).valueOrNull, isNull);
      expect(legacy.clearWasCalled, isFalse);
    });

    test('no-ops when target already has a profile', () async {
      final LifeProfile existing = _profile();
      final legacy = _InMemoryRepo(_profile());
      final target = _InMemoryRepo(existing);

      final migrated = await LifeProfileSpToDriftMigration(
        legacyRepository: legacy,
        targetRepository: target,
      ).run();

      expect(migrated, isFalse);
      expect(legacy.clearWasCalled, isFalse);
      expect((await target.read()).valueOrNull, same(existing));
    });

    test('migrates the legacy profile and clears the source', () async {
      final legacy = _InMemoryRepo(_profile());
      final target = _InMemoryRepo();

      final migrated = await LifeProfileSpToDriftMigration(
        legacyRepository: legacy,
        targetRepository: target,
      ).run();

      expect(migrated, isTrue);
      expect((await target.read()).valueOrNull, isNotNull);
      expect((await legacy.read()).valueOrNull, isNull);
      expect(legacy.clearWasCalled, isTrue);
    });

    test('does not clear legacy when target save fails', () async {
      final legacy = _InMemoryRepo(_profile());
      final target = _AlwaysFailingSaveRepo();

      final migrated = await LifeProfileSpToDriftMigration(
        legacyRepository: legacy,
        targetRepository: target,
      ).run();

      expect(migrated, isFalse);
      expect(legacy.clearWasCalled, isFalse);
      expect((await legacy.read()).valueOrNull, isNotNull);
    });

    test('idempotent: a second run after success does nothing', () async {
      final legacy = _InMemoryRepo(_profile());
      final target = _InMemoryRepo();
      final migration = LifeProfileSpToDriftMigration(
        legacyRepository: legacy,
        targetRepository: target,
      );

      expect(await migration.run(), isTrue);
      expect(await migration.run(), isFalse);
    });
  });
}
