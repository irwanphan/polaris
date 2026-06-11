import 'package:polaris/core/errors/failure.dart';
import 'package:polaris/core/result/result.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';

/// Persists the single user [LifeProfile].
///
/// Implementations live in `data/`. The `application/` layer depends only
/// on this abstraction so we can swap `SharedPreferences` for Drift (M2)
/// or cloud sync (Phase 2) without touching feature controllers.
abstract interface class LifeProfileRepository {
  /// Returns the stored profile, or [Ok] with `null` when nothing has been
  /// saved yet (first-run state).
  Future<Result<LifeProfile?, Failure>> read();

  /// Replaces any previously stored profile.
  Future<Result<void, Failure>> save(LifeProfile profile);

  /// Removes the stored profile (used by "Reset" in settings, future).
  Future<Result<void, Failure>> clear();
}
