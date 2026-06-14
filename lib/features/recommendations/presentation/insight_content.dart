import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

/// Resolves an [InsightSpec] (l10n-free, rule-emitted) into a
/// renderable [Insight] (localized strings, ready for the card).
///
/// All knowledge about ARB keys and number formatting lives here so
/// rules stay pure and the UI never branches on `contentKey`. Adding
/// a new rule is a two-step pattern:
///   1. Rule emits a spec with a unique [InsightSpec.contentKey] and
///      typed `args` (documented inline below).
///   2. Add a case here mapping that contentKey to the new ARB
///      strings, including any per-arg formatting.
///
/// Unknown content keys degrade gracefully to a placeholder card so
/// a missing translation never crashes the home screen — the
/// "missing" copy is intentionally human-readable so QA can spot it.
class InsightContent {
  const InsightContent._();

  /// Pure resolver — no `BuildContext`, no I/O. Callers feed in
  /// [AppL] and [Locale] (typically obtained from `BuildContext`).
  static Insight resolve({
    required InsightSpec spec,
    required AppL l,
    required Locale locale,
  }) {
    final _Formatters f = _Formatters.forLocale(locale);

    switch (spec.contentKey) {
      case 'water_target':
        return Insight(
          id: spec.id,
          severity: spec.severity,
          relatedCategory: spec.relatedCategory,
          ctaRoute: spec.ctaRoute,
          title: l.insightWaterTargetTitle,
          body: l.insightWaterTargetBody(
            _intArg(spec.args, 'windowDays', fallback: 7),
            f.smart(_doubleArg(spec.args, 'avg')),
            f.smart(_doubleArg(spec.args, 'target')),
          ),
          ctaLabel: l.insightWaterTargetCta,
        );

      case 'sleep_regularity':
        return Insight(
          id: spec.id,
          severity: spec.severity,
          relatedCategory: spec.relatedCategory,
          ctaRoute: spec.ctaRoute,
          title: l.insightSleepRegularityTitle,
          body: l.insightSleepRegularityBody(
            _intArg(spec.args, 'shortCount'),
            _intArg(spec.args, 'totalCount'),
            f.smart(_doubleArg(spec.args, 'minHours')),
          ),
          ctaLabel: l.insightSleepRegularityCta,
        );

      case 'exercise_streak':
        return Insight(
          id: spec.id,
          severity: spec.severity,
          relatedCategory: spec.relatedCategory,
          ctaRoute: spec.ctaRoute,
          title: l.insightExerciseStreakTitle,
          body: l.insightExerciseStreakBody(
            _intArg(spec.args, 'windowDays', fallback: 7),
          ),
          ctaLabel: l.insightExerciseStreakCta,
        );

      case 'mood_trend':
        return Insight(
          id: spec.id,
          severity: spec.severity,
          relatedCategory: spec.relatedCategory,
          ctaRoute: spec.ctaRoute,
          title: l.insightMoodTrendTitle,
          body: l.insightMoodTrendBody(
            _intArg(spec.args, 'run', fallback: 3),
          ),
          ctaLabel: l.insightMoodTrendCta,
        );

      case 'life_phase':
        final int pct = _intArg(spec.args, 'pct');
        return Insight(
          id: spec.id,
          severity: spec.severity,
          ctaRoute: spec.ctaRoute,
          title: l.insightLifePhaseTitle(pct),
          body: l.insightLifePhaseBody(
            f.oneDecimal.format(_doubleArg(spec.args, 'remainingYears')),
            _intArg(spec.args, 'remainingDays'),
          ),
          ctaLabel: l.insightLifePhaseCta,
        );

      case 'no_data':
        return Insight(
          id: spec.id,
          severity: spec.severity,
          ctaRoute: spec.ctaRoute,
          title: l.insightNoDataTitle,
          body: l.insightNoDataBody,
          ctaLabel: l.insightNoDataCta,
        );

      case 'positive_exercise_streak':
        return Insight(
          id: spec.id,
          severity: spec.severity,
          relatedCategory: spec.relatedCategory,
          ctaRoute: spec.ctaRoute,
          title: l.insightPositiveExerciseStreakTitle,
          body: l.insightPositiveExerciseStreakBody(
            _intArg(spec.args, 'activeDays'),
            _intArg(spec.args, 'windowDays', fallback: 7),
            f.thousands.format(_doubleArg(spec.args, 'totalMinutes')),
          ),
          ctaLabel: l.insightPositiveExerciseStreakCta,
        );

      case 'low_sleep_hydration':
        return Insight(
          id: spec.id,
          severity: spec.severity,
          relatedCategory: spec.relatedCategory ?? LogCategory.water,
          ctaRoute: spec.ctaRoute,
          title: l.insightLowSleepHydrationTitle,
          body: l.insightLowSleepHydrationBody(
            f.smart(_doubleArg(spec.args, 'minHours')),
          ),
          ctaLabel: l.insightLowSleepHydrationCta,
        );

      case 'logging_streak':
        final int streak = _intArg(spec.args, 'streak');
        return Insight(
          id: spec.id,
          severity: spec.severity,
          ctaRoute: spec.ctaRoute,
          title: l.insightLoggingStreakTitle(streak),
          body: l.insightLoggingStreakBody(streak),
          ctaLabel: l.insightLoggingStreakCta,
        );

      default:
        // Unknown content key → render something visible but
        // obviously wrong so QA notices. Better than crashing.
        return Insight(
          id: spec.id,
          severity: spec.severity,
          title: '(missing copy: ${spec.contentKey})',
          body: 'No localization mapped for this insight yet.',
        );
    }
  }

  static int _intArg(
    Map<String, Object> args,
    String key, {
    int fallback = 0,
  }) {
    final Object? v = args[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  static double _doubleArg(
    Map<String, Object> args,
    String key, {
    double fallback = 0,
  }) {
    final Object? v = args[key];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return fallback;
  }
}

/// Locale-aware number formatters cached per call so each `resolve`
/// re-uses the same trio (cheap but worth not allocating four times
/// per card).
class _Formatters {
  _Formatters._(this.thousands, this.oneDecimal);

  factory _Formatters.forLocale(Locale locale) {
    final String tag = locale.toLanguageTag();
    return _Formatters._(
      NumberFormat.decimalPattern(tag),
      NumberFormat('#,##0.0', tag),
    );
  }

  final NumberFormat thousands;
  final NumberFormat oneDecimal;

  /// Whole numbers render without a trailing `.0`; everything else
  /// gets one decimal so "3.0 glasses" doesn't become "3" and
  /// "6 glasses" doesn't become "6.0".
  String smart(double value) {
    if (value == value.roundToDouble()) {
      return thousands.format(value);
    }
    return oneDecimal.format(value);
  }
}
