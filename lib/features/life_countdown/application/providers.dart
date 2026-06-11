import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/life_countdown/data/datasources/life_expectancy_asset_data_source.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_expectancy_repository_impl.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_profile_repository_impl.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/usecases/compute_life_estimate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lazily-resolved `SharedPreferences` instance.
///
/// Overridden in `bootstrap.dart` with the eagerly-awaited instance so
/// widgets can read it synchronously via `ref.watch`.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in bootstrap()',
  ),
);

final Provider<LifeExpectancyAssetDataSource>
    lifeExpectancyAssetDataSourceProvider =
    Provider<LifeExpectancyAssetDataSource>(
  (ref) => LifeExpectancyAssetDataSource(),
);

final Provider<LifeExpectancyRepository> lifeExpectancyRepositoryProvider =
    Provider<LifeExpectancyRepository>(
  (ref) => LifeExpectancyRepositoryImpl(
    ref.watch(lifeExpectancyAssetDataSourceProvider),
  ),
);

final Provider<LifeProfileRepository> lifeProfileRepositoryProvider =
    Provider<LifeProfileRepository>(
  (ref) => LifeProfileRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

final Provider<ComputeLifeEstimate> computeLifeEstimateProvider =
    Provider<ComputeLifeEstimate>(
  (ref) => ComputeLifeEstimate(ref.watch(lifeExpectancyRepositoryProvider)),
);
