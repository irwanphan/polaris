/// User-controlled preferences for pinning the life countdown to the
/// home-screen widget.
///
/// Pure value object — no Flutter, no platform deps. Persistence lives
/// in `LifePinRepository`, presentation lives in `LifePinSheet`.
///
/// Invariants:
///   - [customMessage] is either `null` or a non-empty trimmed string.
///     Empty strings normalize to `null` so the widget code can do a
///     simple null check.
final class LifePinPreferences {
  /// Convenience constructor: trims [customMessage] and converts
  /// empty strings to `null`.
  factory LifePinPreferences({
    required bool pinned,
    String? customMessage,
  }) {
    return LifePinPreferences._(
      pinned: pinned,
      customMessage: _normalize(customMessage),
    );
  }

  const LifePinPreferences._({required this.pinned, this.customMessage});

  /// The default state — not pinned, no custom message. Used by the
  /// repository when no prefs row has been persisted yet.
  static const LifePinPreferences unpinned = LifePinPreferences._(
    pinned: false,
  );

  final bool pinned;
  final String? customMessage;

  LifePinPreferences copyWith({bool? pinned, String? customMessage}) {
    return LifePinPreferences(
      pinned: pinned ?? this.pinned,
      customMessage: customMessage ?? this.customMessage,
    );
  }

  /// Explicit "unpinned and cleared" factory used when the parent
  /// wants to revert the user's customization (e.g. clearing all data).
  LifePinPreferences asUnpinned() =>
      LifePinPreferences(pinned: false, customMessage: customMessage);

  static String? _normalize(String? raw) {
    if (raw == null) return null;
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifePinPreferences &&
        other.pinned == pinned &&
        other.customMessage == customMessage;
  }

  @override
  int get hashCode => Object.hash(pinned, customMessage);

  @override
  String toString() =>
      'LifePinPreferences(pinned: $pinned, customMessage: $customMessage)';
}
