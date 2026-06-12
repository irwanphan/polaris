import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_profile_drift_repository.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';

LifeProfile _sample({
  DateTime? birth,
  Sex sex = Sex.female,
  String country = 'ID',
  bool hide = false,
}) {
  final DateTime b = birth ?? DateTime(1995, 5, 15);
  final DateTime now = DateTime(2026, 6, 12);
  return LifeProfile(
    dateOfBirth: DateOfBirth.tryFromDateTime(b, today: now).valueOrNull!,
    sex: sex,
    countryCode: CountryCode.tryParse(country).valueOrNull!,
    hideLifeCountdown: hide,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LifeProfileDriftRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LifeProfileDriftRepository(db.lifeProfilesDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('LifeProfileDriftRepository', () {
    test('read returns Ok(null) when no row has been written', () async {
      final result = await repo.read();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('save then read returns the same profile', () async {
      final LifeProfile profile = _sample();
      final saved = await repo.save(profile);
      expect(saved.isOk, isTrue);

      final read = await repo.read();
      expect(read.isOk, isTrue);
      final LifeProfile? loaded = read.valueOrNull;
      expect(loaded, isNotNull);
      expect(loaded!.sex, Sex.female);
      expect(loaded.countryCode.value, 'ID');
      expect(loaded.dateOfBirth.date.year, 1995);
      expect(loaded.dateOfBirth.date.month, 5);
      expect(loaded.dateOfBirth.date.day, 15);
      expect(loaded.hideLifeCountdown, isFalse);
    });

    test('save overwrites the existing singleton row', () async {
      await repo.save(_sample(country: 'ID', sex: Sex.female));
      await repo.save(_sample(country: 'JP', sex: Sex.male));

      final read = await repo.read();
      expect(read.valueOrNull!.countryCode.value, 'JP');
      expect(read.valueOrNull!.sex, Sex.male);
    });

    test('clear removes the stored profile', () async {
      await repo.save(_sample());
      await repo.clear();

      final read = await repo.read();
      expect(read.valueOrNull, isNull);
    });

    test('hideLifeCountdown round-trips both true and false', () async {
      await repo.save(_sample(hide: true));
      expect((await repo.read()).valueOrNull!.hideLifeCountdown, isTrue);

      await repo.save(_sample());
      expect((await repo.read()).valueOrNull!.hideLifeCountdown, isFalse);
    });
  });
}
