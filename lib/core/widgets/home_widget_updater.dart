/// Re-renders the OS home-screen widget (Android AppWidget / iOS
/// WidgetKit) with the latest pinned-event state.
///
/// Lives in `core/` so feature controllers (event_countdown,
/// life_countdown later) can request a refresh without knowing
/// anything about RemoteViews, Glance, or WidgetKit. Concrete
/// implementations resolve their own data sources.
///
/// Idempotent: calling [refresh] when there is no pinned event
/// must clear the widget into an empty state, not crash.
abstract interface class HomeWidgetUpdater {
  Future<void> refresh();
}
