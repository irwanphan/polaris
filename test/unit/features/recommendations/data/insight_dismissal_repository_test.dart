import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/recommendations/data/repositories/insight_dismissal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kKey = 'polaris.insight_dismissals.v1';

Future<InsightDismissalRepository> _repo({
  Map<String, Object> initial = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return InsightDismissalRepository(prefs);
}

void main() {
  group('read()', () {
    test('returns empty map when nothing stored', () async {
      final InsightDismissalRepository repo = await _repo();
      expect(repo.read(), isEmpty);
    });

    test('round-trips stored ids → cooldowns', () async {
      final Map<String, int> stored = <String, int>{
        'water_target': 1700000000000,
        'life_phase:50': 1800000000000,
      };
      final InsightDismissalRepository repo = await _repo(
        initial: <String, Object>{_kKey: jsonEncode(stored)},
      );
      expect(repo.read(), stored);
    });

    test('survives a corrupted blob without throwing', () async {
      final InsightDismissalRepository repo = await _repo(
        initial: <String, Object>{_kKey: '{not json'},
      );
      expect(repo.read(), isEmpty);
    });

    test('drops non-string keys / non-int values defensively', () async {
      final InsightDismissalRepository repo = await _repo(
        initial: <String, Object>{
          _kKey: jsonEncode(<String, dynamic>{
            'water_target': 1700000000000,
            'mood_trend': 'oops',
          }),
        },
      );
      final Map<String, int> read = repo.read();
      expect(read.keys, <String>['water_target']);
    });
  });

  group('dismiss()', () {
    test('writes the cooldown timestamp and emits on the stream', () async {
      final InsightDismissalRepository repo = await _repo();
      final DateTime now = DateTime(2026, 6, 13, 10);
      final List<Map<String, int>> seen = <Map<String, int>>[];
      // Subscribe explicitly so the broadcast listener is fully
      // attached before we trigger the write — yielding from an
      // async* generator does not guarantee subscription readiness
      // by the time the next statement runs.
      final StreamSubscription<Map<String, int>> sub = repo
          .watch()
          .listen(seen.add);
      await Future<void>.delayed(Duration.zero);

      await repo.dismiss(
        'water_target',
        cooldown: const Duration(days: 3),
        now: now,
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final int expected = now
          .add(const Duration(days: 3))
          .millisecondsSinceEpoch;
      expect(repo.read(), <String, int>{'water_target': expected});
      expect(seen.first, isEmpty);
      expect(seen.last, <String, int>{'water_target': expected});
    });

    test('zero / negative cooldown is a no-op', () async {
      final InsightDismissalRepository repo = await _repo();
      await repo.dismiss('x', cooldown: Duration.zero);
      await repo.dismiss('y', cooldown: const Duration(seconds: -1));
      expect(repo.read(), isEmpty);
    });

    test('overwrites a previous dismissal for the same id', () async {
      final InsightDismissalRepository repo = await _repo();
      final DateTime now = DateTime(2026, 6, 13);
      await repo.dismiss('x', cooldown: const Duration(days: 1), now: now);
      await repo.dismiss('x', cooldown: const Duration(days: 7), now: now);
      expect(
        repo.read()['x'],
        now.add(const Duration(days: 7)).millisecondsSinceEpoch,
      );
    });

    test('prunes expired entries from the underlying blob on write', () async {
      final DateTime now = DateTime(2026, 6, 13, 10);
      final InsightDismissalRepository repo = await _repo(
        initial: <String, Object>{
          _kKey: jsonEncode(<String, int>{
            // already expired
            'old': now
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch,
          }),
        },
      );
      await repo.dismiss('new', cooldown: const Duration(days: 1), now: now);
      expect(repo.read().keys, <String>['new']);
    });
  });

  group('undo()', () {
    test('removes a single id without touching the others', () async {
      final InsightDismissalRepository repo = await _repo();
      final DateTime now = DateTime(2026, 6, 13);
      await repo.dismiss('a', cooldown: const Duration(days: 1), now: now);
      await repo.dismiss('b', cooldown: const Duration(days: 1), now: now);

      await repo.undo('a', now: now);
      expect(repo.read().keys, <String>['b']);
    });

    test('is a no-op for unknown ids — no emit, no write', () async {
      final InsightDismissalRepository repo = await _repo();
      final List<Map<String, int>> seen = <Map<String, int>>[];
      final StreamSubscription<Map<String, int>> sub = repo
          .watch()
          .listen(seen.add);
      await Future<void>.delayed(Duration.zero);
      await repo.undo('does-not-exist');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      // Only the initial empty snapshot — no second emit because
      // the underlying map didn't actually change.
      expect(seen, hasLength(1));
      expect(seen.first, isEmpty);
    });
  });

  group('clear()', () {
    test('wipes every entry and emits an empty map', () async {
      final InsightDismissalRepository repo = await _repo();
      final DateTime now = DateTime(2026, 6, 13);
      await repo.dismiss('a', cooldown: const Duration(days: 1), now: now);
      await repo.dismiss('b', cooldown: const Duration(days: 1), now: now);
      await repo.clear();
      expect(repo.read(), isEmpty);
    });
  });

  group('activeAt() helper', () {
    test('returns only ids whose cooldown extends past now', () {
      final DateTime now = DateTime(2026, 6, 13, 12);
      final Map<String, int> all = <String, int>{
        'live': now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        'dead': now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      };
      final Map<String, int> active = InsightDismissalRepository.activeAt(
        all,
        now,
      );
      expect(active.keys, <String>['live']);
    });

    test('treats a cooldown exactly at now as expired (strict >)', () {
      final DateTime now = DateTime(2026, 6, 13, 12);
      final Map<String, int> all = <String, int>{
        'boundary': now.millisecondsSinceEpoch,
      };
      expect(InsightDismissalRepository.activeAt(all, now), isEmpty);
    });
  });
}
