import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/life_countdown/application/life_profile_controller.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_estimate.dart';
import 'package:polaris/features/life_countdown/domain/entities/life_profile.dart';

/// Recomputes the [LifeEstimate] whenever the profile changes.
///
/// Returns `null` when there is no stored profile yet (first-run); the UI
/// uses that signal to route to onboarding rather than rendering a count.
class LifeCountdownController extends AsyncNotifier<LifeEstimate?> {
  @override
  Future<LifeEstimate?> build() async {
    final LifeProfile? profile = await ref.watch(
      lifeProfileControllerProvider.future,
    );
    if (profile == null) return null;

    final computeEstimate = ref.watch(computeLifeEstimateProvider);
    final result = await computeEstimate(profile);
    return result.fold<LifeEstimate?>(
      onOk: (LifeEstimate estimate) => estimate,
      onErr: (failure) => throw _EstimateException(failure.message),
    );
  }

  /// Re-runs the computation against the current wall clock.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final AsyncNotifierProvider<LifeCountdownController, LifeEstimate?>
lifeCountdownControllerProvider =
    AsyncNotifierProvider<LifeCountdownController, LifeEstimate?>(
      LifeCountdownController.new,
    );

class _EstimateException implements Exception {
  _EstimateException(this.message);
  final String message;
  @override
  String toString() => message;
}
