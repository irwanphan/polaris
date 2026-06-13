/// Visual + semantic tier of a recommendation.
///
/// Severity is the only knob the UI needs to colour-code, sort, and
/// rate-limit insights. Adding a new tier means updating the
/// `InsightCard` styling switch and (optionally) the engine's sort
/// order — no rule needs to change.
///
/// Ordering matters: higher index = more urgent. The engine uses
/// `index` to surface the most important card first.
enum InsightSeverity {
  /// Neutral informational nudge (e.g. life-phase milestones).
  info,

  /// Positive reinforcement, gentle suggestion (e.g. "log your first
  /// entry", "great streak — keep it up").
  encourage,

  /// User behaviour drifted from a healthy baseline — actionable but
  /// not urgent (most lifestyle rules sit here).
  warn,

  /// Reserved for future health-flag rules (e.g. sleep deprivation
  /// for 7+ consecutive days). No M5 rule emits this yet — the tier
  /// exists so the UI styling is already in place.
  critical,
}
