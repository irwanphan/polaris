import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';

void main() {
  group('CountryCode.tryParse', () {
    test('accepts a valid 2-letter code and normalizes to uppercase', () {
      final Result<CountryCode, ValidationFailure> r =
          CountryCode.tryParse('id');
      expect(r.isOk, isTrue);
      expect(r.valueOrNull!.value, 'ID');
    });

    test('rejects codes that are not 2 letters', () {
      expect(CountryCode.tryParse('I').isErr, isTrue);
      expect(CountryCode.tryParse('IDN').isErr, isTrue);
      expect(CountryCode.tryParse('').isErr, isTrue);
    });

    test('rejects codes containing non-letters', () {
      expect(CountryCode.tryParse('1A').isErr, isTrue);
      expect(CountryCode.tryParse('I!').isErr, isTrue);
    });

    test('equality is structural (case-normalized)', () {
      final CountryCode a = CountryCode.tryParse('us').valueOrNull!;
      final CountryCode b = CountryCode.tryParse('US').valueOrNull!;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('default Indonesia constant is "ID"', () {
      expect(CountryCode.indonesia.value, 'ID');
    });
  });
}
