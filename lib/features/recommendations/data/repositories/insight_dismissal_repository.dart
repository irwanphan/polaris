import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-insight dismissal cooldowns and exposes a reactive
/// stream.
///
/// One small SharedPreferences-backed JSON blob (`{insightId →
/// cooldownUntilEpochMs}`) is the right substrate here:
///   - Volume is tiny (≤ a few dozen entries even for a power user).
///   - There is no relational shape — each dismissal stands alone.
///   - It survives app upgrades without a Drift migration story, and
///     "Clear all data" already wipes SharedPreferences.
///
/// The stream is fed by an internal broadcast controller so the
/// `insightsProvider` re-evaluates the visible list every time a
/// dismiss / undo / clear write lands, without manual invalidation.
class InsightDismissalRepository {
  InsightDismissalRepository(this._prefs);

  /// Versioned key. Bump the suffix if the on-disk shape ever
  /// changes (today it is `Map<String, int>` of cooldown-until
  /// epoch ms).
  static const String _kKey = 'polaris.insight_dismissals.v1';

  final SharedPreferences _prefs;
  final StreamController<Map<String, int>> _controller =
      StreamController<Map<String, int>>.broadcast();

  /// Snapshot read — every stored dismissal, including expired ones.
  ///
  /// Consumers should filter against the wall clock themselves; we
  /// intentionally do not prune on read because pruning is a write
  /// (and reads should be pure). Pruning happens implicitly on the
  /// next write via [_pruneExpired].
  Map<String, int> read() {
    final String? raw = _prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return const <String, int>{};
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, int>{};
      final Map<String, int> result = <String, int>{};
      decoded.forEach((dynamic key, dynamic value) {
        if (key is String && value is int) {
          result[key] = value;
        }
      });
      return result;
    } on FormatException {
      // Corrupted entry — surface as "no dismissals" rather than
      // crashing the home screen. Worst case: insights re-appear,
      // which is the safer-than-silent failure mode.
      return const <String, int>{};
    }
  }

  /// Emits the current snapshot then every subsequent successful
  /// write.
  ///
  /// The first emission is synchronous (yielded before any await),
  /// so widgets that wrap this stream in an `AsyncValue` never see
  /// a `loading` flash on first frame.
  Stream<Map<String, int>> watch() async* {
    yield read();
    yield* _controller.stream;
  }

  /// Hides an insight by [id] until `now + cooldown`.
  ///
  /// Passing a [cooldown] of `Duration.zero` is a no-op (re-shows
  /// immediately) — call [undo] instead if that's the intent. We
  /// also prune any previously-expired entries on the way out so
  /// the blob stays bounded.
  Future<void> dismiss(
    String id, {
    required Duration cooldown,
    DateTime? now,
  }) async {
    if (cooldown <= Duration.zero) return;
    final DateTime when = now ?? DateTime.now();
    final int until = when.add(cooldown).millisecondsSinceEpoch;

    final Map<String, int> next = Map<String, int>.from(read());
    next[id] = until;
    await _writeAndNotify(_pruneExpired(next, when));
  }

  /// Removes a single dismissal so its insight can re-surface
  /// immediately. Drives the Snackbar "Undo" action.
  Future<void> undo(String id, {DateTime? now}) async {
    final Map<String, int> next = Map<String, int>.from(read());
    if (next.remove(id) == null) return; // no-op; avoid spurious emit
    await _writeAndNotify(_pruneExpired(next, now ?? DateTime.now()));
  }

  /// Wipes every dismissal. Used by "Clear all data" / tests.
  Future<void> clear() async {
    await _prefs.remove(_kKey);
    _controller.add(const <String, int>{});
  }

  /// Returns the subset of [all] whose cooldown still extends past
  /// [now]. Helper for consumers that already have the snapshot in
  /// hand and want to avoid a redundant read.
  static Map<String, int> activeAt(
    Map<String, int> all,
    DateTime now,
  ) {
    final int nowMs = now.millisecondsSinceEpoch;
    final Map<String, int> out = <String, int>{};
    all.forEach((String id, int until) {
      if (until > nowMs) out[id] = until;
    });
    return out;
  }

  Future<void> _writeAndNotify(Map<String, int> next) async {
    if (next.isEmpty) {
      await _prefs.remove(_kKey);
    } else {
      await _prefs.setString(_kKey, jsonEncode(next));
    }
    _controller.add(Map<String, int>.unmodifiable(next));
  }

  static Map<String, int> _pruneExpired(
    Map<String, int> source,
    DateTime now,
  ) {
    final int nowMs = now.millisecondsSinceEpoch;
    final Map<String, int> out = <String, int>{};
    source.forEach((String id, int until) {
      if (until > nowMs) out[id] = until;
    });
    return out;
  }
}
