import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/life_countdown/data/datasources/life_expectancy_asset_data_source.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';

/// Concrete repository that resolves expectancy values from the bundled
/// JSON. Caches the parsed table after the first read.
class LifeExpectancyRepositoryImpl implements LifeExpectancyRepository {
  LifeExpectancyRepositoryImpl(this._dataSource);

  final LifeExpectancyAssetDataSource _dataSource;
  LifeExpectancyTable? _cache;

  Future<LifeExpectancyTable> _table() async {
    final LifeExpectancyTable? cached = _cache;
    if (cached != null) return cached;
    final LifeExpectancyTable fresh = await _dataSource.load();
    _cache = fresh;
    return fresh;
  }

  @override
  Future<Result<double, Failure>> lookup({
    required CountryCode countryCode,
    required Sex sex,
  }) async {
    try {
      final LifeExpectancyTable table = await _table();
      final LifeExpectancyRow row = table.byCountry.firstWhere(
        (LifeExpectancyRow r) => r.countryCode == countryCode.value,
        orElse: () => table.global,
      );
      return Result.ok(_pickValue(row, sex));
    } catch (e, st) {
      return Result.err(
        StorageFailure(
          message: 'Failed to load life-expectancy seed: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<CountryOption>, Failure>> listSupportedCountries() async {
    try {
      final LifeExpectancyTable table = await _table();
      final List<CountryOption> options =
          table.byCountry
              .map(
                (LifeExpectancyRow r) => CountryOption(
                  code: CountryCode.tryParse(r.countryCode).valueOrNull!,
                  displayName: r.displayName,
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => a.displayName.compareTo(b.displayName));
      return Result.ok(options);
    } catch (e, st) {
      return Result.err(
        StorageFailure(
          message: 'Failed to list countries: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  double _pickValue(LifeExpectancyRow row, Sex sex) {
    return switch (sex) {
      Sex.male => row.male,
      Sex.female => row.female,
      Sex.undisclosed => (row.male + row.female) / 2.0,
    };
  }
}
