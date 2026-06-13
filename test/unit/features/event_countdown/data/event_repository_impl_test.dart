import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/features/event_countdown/data/repositories/event_repository_impl.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';

Event _sample({
  String id = 'evt-1',
  String title = 'Holiday',
  DateTime? targetAt,
  bool pinned = false,
  Recurrence recurrence = Recurrence.none,
  String? note,
}) {
  final DateTime now = DateTime(2026, 6, 12);
  return Event(
    id: id,
    title: title,
    targetAt: targetAt ?? DateTime(2026, 12, 25),
    colorHex: '#6366F1',
    iconKey: 'event',
    note: note,
    recurrence: recurrence,
    isPinnedToWidget: pinned,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late EventRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = EventRepositoryImpl(db.eventsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('EventRepositoryImpl', () {
    test('watchAll starts empty', () async {
      final List<Event> first = await repo.watchAll().first;
      expect(first, isEmpty);
    });

    test('upsert then watchAll emits the event', () async {
      final Event e = _sample();
      final upsertResult = await repo.upsert(e);
      expect(upsertResult.isOk, isTrue);

      final List<Event> emitted = await repo.watchAll().first;
      expect(emitted, hasLength(1));
      expect(emitted.single.id, e.id);
      expect(emitted.single.title, 'Holiday');
      expect(emitted.single.recurrence, Recurrence.none);
    });

    test('upsert replaces by id', () async {
      await repo.upsert(_sample(title: 'v1'));
      await repo.upsert(_sample(title: 'v2'));

      final List<Event> emitted = await repo.watchAll().first;
      expect(emitted, hasLength(1));
      expect(emitted.single.title, 'v2');
    });

    test('getById returns the stored event', () async {
      final Event e = _sample();
      await repo.upsert(e);
      final result = await repo.getById(e.id);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.title, 'Holiday');
    });

    test('getById returns null Ok for unknown ids', () async {
      final result = await repo.getById('nope');
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('delete removes the event', () async {
      final Event e = _sample();
      await repo.upsert(e);
      await repo.delete(e.id);
      final List<Event> emitted = await repo.watchAll().first;
      expect(emitted, isEmpty);
    });

    test('pinExclusive pins exactly one and unpins others', () async {
      await repo.upsert(_sample(id: 'a', title: 'A', pinned: true));
      await repo.upsert(_sample(id: 'b', title: 'B'));
      await repo.upsert(_sample(id: 'c', title: 'C'));

      await repo.pinExclusive('b');

      final List<Event> emitted = await repo.watchAll().first;
      final Map<String, bool> pins = <String, bool>{
        for (final Event e in emitted) e.id: e.isPinnedToWidget,
      };
      expect(pins['a'], isFalse);
      expect(pins['b'], isTrue);
      expect(pins['c'], isFalse);
    });

    test('pinExclusive(null) clears every pin', () async {
      await repo.upsert(_sample(id: 'a', pinned: true));
      await repo.upsert(_sample(id: 'b', pinned: true));

      await repo.pinExclusive(null);

      final List<Event> emitted = await repo.watchAll().first;
      expect(emitted.every((Event e) => !e.isPinnedToWidget), isTrue);
    });

    test('getPinned returns Ok(null) when nothing is pinned', () async {
      await repo.upsert(_sample(id: 'a'));
      await repo.upsert(_sample(id: 'b'));

      final result = await repo.getPinned();
      expect(result.isOk, isTrue);
      expect(result.fold(onOk: (e) => e, onErr: (_) => _sample()), isNull);
    });

    test('getPinned returns the pinned event after pinExclusive', () async {
      await repo.upsert(_sample(id: 'a', title: 'A'));
      await repo.upsert(_sample(id: 'b', title: 'B'));
      await repo.pinExclusive('b');

      final result = await repo.getPinned();
      final Event? pinned = result.fold(onOk: (e) => e, onErr: (_) => null);
      expect(pinned?.id, 'b');
      expect(pinned?.isPinnedToWidget, isTrue);
    });

    test('events are returned sorted by targetAt ascending', () async {
      await repo.upsert(_sample(id: 'b', targetAt: DateTime(2026, 12, 25)));
      await repo.upsert(_sample(id: 'a', targetAt: DateTime(2026, 7, 1)));
      await repo.upsert(_sample(id: 'c', targetAt: DateTime(2027, 1, 1)));

      final List<Event> emitted = await repo.watchAll().first;
      expect(emitted.map((Event e) => e.id).toList(), <String>['a', 'b', 'c']);
    });

    test('note round-trips including null', () async {
      await repo.upsert(_sample(id: 'with', note: 'Bring camera'));
      await repo.upsert(_sample(id: 'without', note: null));

      final List<Event> emitted = await repo.watchAll().first;
      final Map<String, String?> notes = <String, String?>{
        for (final Event e in emitted) e.id: e.note,
      };
      expect(notes['with'], 'Bring camera');
      expect(notes['without'], isNull);
    });
  });
}
