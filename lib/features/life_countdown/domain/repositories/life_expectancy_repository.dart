import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';

/// Looks up life-expectancy values from a static seed (or future remote
/// source). Returns expectancy in years.
abstract interface class LifeExpectancyRepository {
  /// Resolves the expected lifespan, in years, for the given [countryCode]
  /// and [sex]. Falls back to the global average when the country is not
  /// present in the seed.
  Future<Result<double, Failure>> lookup({
    required CountryCode countryCode,
    required Sex sex,
  });

  /// Returns the set of countries explicitly covered by the underlying
  /// dataset, ordered by display label. Used by the onboarding picker.
  Future<Result<List<CountryOption>, Failure>> listSupportedCountries();
}

/// View-model-shaped value used by the country picker.
final class CountryOption {
  const CountryOption({
    required this.code,
    required this.displayName,
  });

  final CountryCode code;
  final String displayName;
}
