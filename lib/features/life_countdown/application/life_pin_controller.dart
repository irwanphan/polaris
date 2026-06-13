import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/core/widgets/providers.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_pin_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/life_pin_preferences.dart';

/// Imperative commands for the life-pin preference.
///
/// Owns two side effects:
///   1. Persist the new [LifePinPreferences] via [LifePinRepository].
///   2. Trigger the [HomeWidgetUpdater] so the on-screen widget
///      re-renders.
///
/// Life and events are independent — pinning life does not affect
/// any event pin, and vice versa. The widget renders a scrollable
/// list of every pinned subject.
class LifePinController {
  const LifePinController({
    required this.lifePinRepository,
    required this.widgetUpdater,
  });

  final LifePinRepository lifePinRepository;
  final HomeWidgetUpdater widgetUpdater;

  /// Pins the life countdown to the widget with an optional [customMessage].
  Future<void> pin({String? customMessage}) async {
    await lifePinRepository.save(
      LifePinPreferences(pinned: true, customMessage: customMessage),
    );
    await widgetUpdater.refresh();
  }

  /// Updates the custom message in place. If life isn't currently
  /// pinned this is a no-op for the widget but the message is still
  /// remembered for next time the user toggles on.
  Future<void> updateMessage(String? message) async {
    final LifePinPreferences current = lifePinRepository.read();
    await lifePinRepository.save(
      current.copyWith(customMessage: message),
    );
    if (current.pinned) {
      await widgetUpdater.refresh();
    }
  }

  /// Unpins the life countdown. The custom message is preserved so
  /// re-pinning later restores it without re-typing.
  Future<void> unpin() async {
    final LifePinPreferences current = lifePinRepository.read();
    await lifePinRepository.save(
      current.copyWith(pinned: false),
    );
    await widgetUpdater.refresh();
  }
}

final Provider<LifePinController> lifePinControllerProvider =
    Provider<LifePinController>(
      (ref) => LifePinController(
        lifePinRepository: ref.watch(lifePinRepositoryProvider),
        widgetUpdater: ref.watch(homeWidgetUpdaterProvider),
      ),
    );
