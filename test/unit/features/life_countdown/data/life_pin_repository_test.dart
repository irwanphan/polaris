import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/life_countdown/data/repositories/life_pin_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/life_pin_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LifePinRepository> _build([Map<String, Object>? seed]) async {
  SharedPreferences.setMockInitialValues(seed ?? <String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return LifePinRepository(prefs);
}

void main() {
  group('LifePinRepository', () {
    test('read() returns defaults when no prefs row exists', () async {
      final repo = await _build();
      final prefs = repo.read();
      expect(prefs.pinned, isFalse);
      expect(prefs.customMessage, isNull);
    });

    test('save() persists pinned state and custom message', () async {
      final repo = await _build();
      await repo.save(
        LifePinPreferences(pinned: true, customMessage: 'Stay grounded'),
      );
      final reloaded = repo.read();
      expect(reloaded.pinned, isTrue);
      expect(reloaded.customMessage, 'Stay grounded');
    });

    test('save() with empty/whitespace message normalizes to null', () async {
      final repo = await _build();
      await repo.save(LifePinPreferences(pinned: true, customMessage: '   '));
      expect(repo.read().customMessage, isNull);
    });

    test('clear() removes both keys and emits unpinned default', () async {
      final repo = await _build();
      await repo.save(
        LifePinPreferences(pinned: true, customMessage: 'msg'),
      );
      final emissions = <LifePinPreferences>[];
      final sub = repo.watch().listen(emissions.add);

      await repo.clear();
      // Allow microtasks to drain so the broadcast emission lands.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(repo.read(), LifePinPreferences.unpinned);
      // First emission is the initial snapshot, second is the clear.
      expect(emissions.last, LifePinPreferences.unpinned);
    });

    test('watch() emits current snapshot then every save', () async {
      final repo = await _build();
      final emissions = <LifePinPreferences>[];
      final sub = repo.watch().listen(emissions.add);

      await Future<void>.delayed(Duration.zero); // initial snapshot
      await repo.save(LifePinPreferences(pinned: true));
      await Future<void>.delayed(Duration.zero);
      await repo.save(
        LifePinPreferences(pinned: true, customMessage: 'breathe'),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions, hasLength(3));
      expect(emissions[0].pinned, isFalse);
      expect(emissions[1].pinned, isTrue);
      expect(emissions[1].customMessage, isNull);
      expect(emissions[2].customMessage, 'breathe');
    });
  });
}
