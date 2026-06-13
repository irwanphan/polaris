import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/data/database/providers.dart';
import 'package:polaris/features/life_countdown/data/datasources/life_expectancy_asset_data_source.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_expectancy_repository_impl.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_pin_repository.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_profile_drift_repository.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/usecases/compute_life_estimate.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/life_pin_preferences.dart';
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
lifeExpectancyAssetDataSourceProvider = Provider<LifeExpectancyAssetDataSource>(
  (ref) => LifeExpectancyAssetDataSource(),
);

final Provider<LifeExpectancyRepository> lifeExpectancyRepositoryProvider =
    Provider<LifeExpectancyRepository>(
      (ref) => LifeExpectancyRepositoryImpl(
        ref.watch(lifeExpectancyAssetDataSourceProvider),
      ),
    );

/// Production-default uses the Drift-backed implementation introduced in
/// M2; tests typically override this with an in-memory fake. The legacy
/// SharedPreferences-backed `LifeProfileRepositoryImpl` is still wired
/// up in `bootstrap.dart` exclusively for the one-shot SP → Drift
/// migration on first launch.
final Provider<LifeProfileRepository> lifeProfileRepositoryProvider =
    Provider<LifeProfileRepository>(
      (ref) => LifeProfileDriftRepository(
        ref.watch(appDatabaseProvider).lifeProfilesDao,
      ),
    );

final Provider<ComputeLifeEstimate> computeLifeEstimateProvider =
    Provider<ComputeLifeEstimate>(
      (ref) => ComputeLifeEstimate(ref.watch(lifeExpectancyRepositoryProvider)),
    );

/// Single-instance [LifePinRepository] backed by the bootstrap-supplied
/// [SharedPreferences]. Tests typically override [sharedPreferencesProvider]
/// with `SharedPreferences.setMockInitialValues({...})` and let this
/// provider build the real repository on top.
final Provider<LifePinRepository> lifePinRepositoryProvider =
    Provider<LifePinRepository>(
      (ref) => LifePinRepository(ref.watch(sharedPreferencesProvider)),
    );

/// Reactive snapshot of the user's life-pin preferences.
///
/// Defaults to [LifePinPreferences.unpinned] until the first emission
/// arrives so the UI never sees a `loading` shimmer for a synchronous
/// SharedPreferences read.
final StreamProvider<LifePinPreferences> lifePinStreamProvider =
    StreamProvider<LifePinPreferences>(
      (ref) => ref.watch(lifePinRepositoryProvider).watch(),
    );
