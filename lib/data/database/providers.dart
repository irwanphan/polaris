import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/data/database/app_database.dart';

/// The shared Drift database used across every feature.
///
/// Lives in `data/database/` (not under any single feature) because
/// multiple features depend on it. Bootstrap eagerly opens an instance
/// and overrides this provider; tests typically override it with an
/// in-memory executor via `AppDatabase.forTesting(NativeDatabase.memory())`
/// or override the per-feature repository providers directly.
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider must be overridden in bootstrap()',
  ),
);
