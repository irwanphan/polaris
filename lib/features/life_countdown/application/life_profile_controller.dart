import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_profile_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';

/// Owns the persistence of the single user [LifeProfile].
///
/// `AsyncValue<LifeProfile?>` is `null` after a successful read with no
/// stored profile (first run) — UI uses that to redirect to onboarding.
class LifeProfileController extends AsyncNotifier<LifeProfile?> {
  @override
  Future<LifeProfile?> build() async {
    final LifeProfileRepository repo =
        ref.watch(lifeProfileRepositoryProvider);
    final result = await repo.read();
    return result.fold<LifeProfile?>(
      onOk: (LifeProfile? profile) => profile,
      onErr: (failure) => throw _ProfileException(failure.message),
    );
  }

  /// Creates and persists a new profile from validated onboarding inputs.
  Future<void> completeOnboarding({
    required DateOfBirth dateOfBirth,
    required Sex sex,
    required CountryCode countryCode,
  }) async {
    final DateTime now = DateTime.now();
    final LifeProfile profile = LifeProfile(
      dateOfBirth: dateOfBirth,
      sex: sex,
      countryCode: countryCode,
      createdAt: now,
      updatedAt: now,
    );
    await _persist(profile);
  }

  Future<void> setHideLifeCountdown(bool hide) async {
    final LifeProfile? current = state.value;
    if (current == null) return;
    await _persist(
      current.copyWith(
        hideLifeCountdown: hide,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> reset() async {
    final LifeProfileRepository repo =
        ref.read(lifeProfileRepositoryProvider);
    state = const AsyncValue<LifeProfile?>.loading();
    final result = await repo.clear();
    state = result.fold(
      onOk: (_) => const AsyncValue<LifeProfile?>.data(null),
      onErr: (failure) => AsyncValue<LifeProfile?>.error(
        _ProfileException(failure.message),
        StackTrace.current,
      ),
    );
  }

  Future<void> _persist(LifeProfile profile) async {
    final LifeProfileRepository repo =
        ref.read(lifeProfileRepositoryProvider);
    state = const AsyncValue<LifeProfile?>.loading();
    final result = await repo.save(profile);
    state = result.fold(
      onOk: (_) => AsyncValue<LifeProfile?>.data(profile),
      onErr: (failure) => AsyncValue<LifeProfile?>.error(
        _ProfileException(failure.message),
        StackTrace.current,
      ),
    );
  }
}

final AsyncNotifierProvider<LifeProfileController, LifeProfile?>
    lifeProfileControllerProvider =
    AsyncNotifierProvider<LifeProfileController, LifeProfile?>(
  LifeProfileController.new,
);

class _ProfileException implements Exception {
  _ProfileException(this.message);
  final String message;
  @override
  String toString() => message;
}
