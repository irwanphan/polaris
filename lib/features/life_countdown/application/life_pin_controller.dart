import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/widgets/home_widget_updater.dart';
import 'package:polaris/core/widgets/providers.dart';
import 'package:polaris/features/event_countdown/application/providers.dart';
import 'package:polaris/features/event_countdown/domain/repositories/event_repository.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_pin_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/life_pin_preferences.dart';

/// Imperative commands for the life-pin preference.
///
/// Owns three side effects in order:
///   1. Persist the new [LifePinPreferences] via [LifePinRepository].
///   2. When pinning life ON, call `eventRepo.pinExclusive(null)` to
///      unpin every event. This is the mutual-exclusivity invariant
///      enforced by the widget: only one subject can occupy the
///      pinned slot at a time. Unpinning life does NOT auto-pin an
///      event — that would be a surprising side effect.
///   3. Trigger the [HomeWidgetUpdater] so the on-screen widget
///      re-renders with the new pinned source (or empty state).
///
/// Errors at step 1 propagate; steps 2 and 3 are best-effort and
/// logged (already handled inside their respective subsystems).
class LifePinController {
  const LifePinController({
    required this.lifePinRepository,
    required this.eventRepository,
    required this.widgetUpdater,
  });

  final LifePinRepository lifePinRepository;
  final EventRepository eventRepository;
  final HomeWidgetUpdater widgetUpdater;

  /// Pins the life countdown to the widget with an optional [customMessage].
  /// Unpins any pinned event as a side effect.
  Future<void> pin({String? customMessage}) async {
    await lifePinRepository.save(
      LifePinPreferences(pinned: true, customMessage: customMessage),
    );
    await eventRepository.pinExclusive(null);
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
        eventRepository: ref.watch(eventRepositoryProvider),
        widgetUpdater: ref.watch(homeWidgetUpdaterProvider),
      ),
    );
