import 'package:polaris/app/router.dart';

/// Pure mapper from external launch URIs into in-app GoRouter paths.
///
/// Lives in `core/` because both the home-screen widget and the
/// notification system funnel external taps through the same scheme:
///
///     polaris://<host>/<segments>
///
/// Today only a single host is wired:
///
///     polaris://events/<eventId>   →   /events/<eventId>
///
/// Designed to be:
///   * Pure — no side effects, no router dependency — so it can be
///     unit-tested with `expect`s over a static table.
///   * Tolerant — unknown / malformed URIs return `null` rather than
///     throwing, because the caller already runs in an async tap
///     handler and shouldn't have to wrap every parse in try/catch.
///
/// Side-effecting navigation is the responsibility of
/// `PolarisDeepLinkHandler` (see `core/deep_links/deep_link_handler.dart`).
abstract final class DeepLinkRouter {
  /// Stable scheme advertised in the Android widget intent URI and
  /// in notification payloads. Keep in sync with
  /// `PolarisWidgetItemsFactory.kt` (Android).
  static const String scheme = 'polaris';

  /// Translates [uri] into a GoRouter path, or `null` when the URI
  /// does not address any known surface.
  ///
  /// Defensive against the most common malformed inputs:
  ///   * empty / null id segments → `null`
  ///   * wrong scheme → `null`
  ///   * unknown host → `null`
  static String? resolve(Uri? uri) {
    if (uri == null) return null;
    if (uri.scheme != scheme) return null;

    switch (uri.host) {
      case 'events':
        // URI.parse('polaris://events/abc') puts 'abc' in pathSegments[0].
        final List<String> segments = uri.pathSegments;
        if (segments.isEmpty) return null;
        final String id = segments.first.trim();
        if (id.isEmpty) return null;
        return AppRoutes.eventDetail(id);
      default:
        return null;
    }
  }

  /// Builds the URI for an event detail deep link. Centralized so
  /// every producer (native widget, notification payload, tests)
  /// uses the same wire format.
  static Uri eventDetailUri(String eventId) {
    return Uri(scheme: scheme, host: 'events', pathSegments: <String>[eventId]);
  }

  /// Normalizes the *legacy* notification payload format — bare
  /// event id strings — into a URI the rest of the pipeline
  /// understands. Idempotent: payloads that are already valid
  /// `polaris://…` URIs pass through unchanged.
  ///
  /// Returns `null` for empty / whitespace payloads.
  static Uri? notificationPayloadToUri(String? payload) {
    if (payload == null) return null;
    final String trimmed = payload.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('$scheme://')) {
      final Uri? parsed = Uri.tryParse(trimmed);
      return parsed;
    }
    // Backwards-compat: pre-deep-link notifications stored the bare
    // event id as the payload. Wrap it so the resolver sees the
    // canonical form.
    return eventDetailUri(trimmed);
  }
}
