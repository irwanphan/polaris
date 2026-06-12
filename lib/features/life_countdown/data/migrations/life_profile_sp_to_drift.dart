import 'package:polaris/core/logging/app_logger.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';

/// One-shot migration that lifts the [LifeProfile] saved by M1 (in
/// SharedPreferences) into the Drift-backed store introduced in M2.
///
/// Idempotent: if the destination already has a profile it does
/// nothing, and if the legacy store is empty it does nothing. Safe to
/// run on every cold boot — bootstrap calls it before mounting the
/// `ProviderScope`.
class LifeProfileSpToDriftMigration {
  const LifeProfileSpToDriftMigration({
    required this.legacyRepository,
    required this.targetRepository,
    this.logger,
  });

  /// The SharedPreferences-backed M1 repository.
  final LifeProfileRepository legacyRepository;

  /// The Drift-backed M2 repository.
  final LifeProfileRepository targetRepository;

  final AppLogger? logger;

  /// Runs the migration. Returns `true` if a profile was migrated,
  /// `false` if there was nothing to do.
  Future<bool> run() async {
    final destination = await targetRepository.read();
    if (destination.isOk && destination.valueOrNull != null) {
      return false;
    }

    final legacy = await legacyRepository.read();
    if (legacy.isErr) {
      logger?.warn('Legacy LifeProfile read failed; skipping migration.');
      return false;
    }
    final LifeProfile? profile = legacy.valueOrNull;
    if (profile == null) return false;

    final saved = await targetRepository.save(profile);
    if (saved.isErr) {
      logger?.error(
        'Failed to copy LifeProfile into Drift; legacy data preserved.',
      );
      return false;
    }

    final cleared = await legacyRepository.clear();
    if (cleared.isErr) {
      logger?.warn(
        'Migrated LifeProfile to Drift but failed to clear legacy '
        'SharedPreferences entry; will retry on next launch.',
      );
    } else {
      logger?.info('Migrated LifeProfile from SharedPreferences to Drift.');
    }
    return true;
  }
}
