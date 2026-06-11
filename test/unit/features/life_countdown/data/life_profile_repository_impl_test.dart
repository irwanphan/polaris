import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_profile_repository_impl.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LifeProfileRepositoryImpl> _newRepo([
  Map<String, Object> initial = const <String, Object>{},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final SharedPreferences sp = await SharedPreferences.getInstance();
  return LifeProfileRepositoryImpl(sp);
}

LifeProfile _sampleProfile() {
  final DateTime today = DateTime(2026, 6, 12);
  return LifeProfile(
    dateOfBirth: DateOfBirth.tryFromDateTime(
      DateTime(1990, 7, 15),
      today: today,
    ).valueOrNull!,
    sex: Sex.male,
    countryCode: CountryCode.indonesia,
    createdAt: today,
    updatedAt: today,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LifeProfileRepositoryImpl', () {
    test('read returns null when nothing is stored', () async {
      final repo = await _newRepo();
      final result = await repo.read();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('save then read round-trips the profile', () async {
      final repo = await _newRepo();
      final LifeProfile original = _sampleProfile();

      final saveResult = await repo.save(original);
      expect(saveResult.isOk, isTrue);

      final readResult = await repo.read();
      expect(readResult.isOk, isTrue);
      expect(readResult.valueOrNull, original);
    });

    test('clear removes the stored profile', () async {
      final repo = await _newRepo();
      await repo.save(_sampleProfile());

      final clearResult = await repo.clear();
      expect(clearResult.isOk, isTrue);

      final readResult = await repo.read();
      expect(readResult.valueOrNull, isNull);
    });

    test('save overwrites a previously stored profile', () async {
      final repo = await _newRepo();
      await repo.save(_sampleProfile());

      final LifeProfile updated =
          _sampleProfile().copyWith(hideLifeCountdown: true);
      await repo.save(updated);

      final readResult = await repo.read();
      expect(readResult.valueOrNull!.hideLifeCountdown, isTrue);
    });
  });
}
