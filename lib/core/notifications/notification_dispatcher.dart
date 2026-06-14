/// A thin facade over the OS local-notifications API.
///
/// Lives in `core/` so it has zero knowledge of any feature's domain
/// (events, lifestyle, etc.) — it just delivers payloads. Feature
/// schedulers compose this with their own logic.
///
/// All methods are idempotent where the underlying platform allows it.
abstract interface class NotificationDispatcher {
  /// Initializes the platform plugin and the timezone database.
  /// Must be called once, before any other method, typically from
  /// `bootstrap()`. Subsequent calls are no-ops.
  Future<void> initialize();

  /// Returns `true` if the OS currently allows the app to post
  /// notifications. May prompt the user the first time it is called
  /// on platforms that require runtime permission (Android 13+, iOS).
  Future<bool> ensurePermission();

  /// Schedules a single one-shot notification at the given absolute
  /// wall-clock time. Calling with an existing [id] replaces the
  /// previous schedule on every supported platform.
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  });

  /// Cancels a previously scheduled notification. Silently no-ops if
  /// the platform doesn't know about [id].
  Future<void> cancel(int id);

  /// Cancels every notification scheduled by the app — useful when
  /// the user revokes notification permission or resets state.
  Future<void> cancelAll();

  /// Broadcast stream of payload strings from foreground / background
  /// notification taps. The stream is hot — late listeners miss
  /// taps that arrived before subscription. For the cold-start case
  /// (app launched by a notification before any listener attaches),
  /// pair this with [consumeColdStartPayload].
  Stream<String?> get tapPayloads;

  /// One-shot read of the payload that launched the app, if any.
  /// Returns `null` when the app was started normally (i.e. *not*
  /// from a notification tap). Idempotent — subsequent invocations
  /// always return `null` so deep-link handling doesn't fire twice.
  Future<String?> consumeColdStartPayload();
}
