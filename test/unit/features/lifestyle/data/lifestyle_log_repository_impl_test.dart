import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/data/database/app_database.dart';
import 'package:polaris/features/lifestyle/data/repositories/lifestyle_log_repository_impl.dart';
import 'package:polaris/features/lifestyle/domain/entities/lifestyle_log.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';

LifestyleLog _sample({
  String id = 'log-1',
  LogCategory category = LogCategory.water,
  double value = 1,
  DateTime? loggedAt,
  String? note,
}) {
  final DateTime stamp = loggedAt ?? DateTime(2026, 6, 13, 9);
  return LifestyleLog(
    id: id,
    category: category,
    value: value,
    note: note,
    loggedAt: stamp,
    createdAt: stamp,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LifestyleLogRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LifestyleLogRepositoryImpl(db.lifestyleLogsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('LifestyleLogRepositoryImpl', () {
    final DateTime windowStart = DateTime(2026, 6, 13);
    final DateTime windowEnd = DateTime(2026, 6, 13, 23, 59, 59);

    test('watchBetween starts empty', () async {
      final List<LifestyleLog> first = await repo
          .watchBetween(from: windowStart, to: windowEnd)
          .first;
      expect(first, isEmpty);
    });

    test('upsert then watchBetween emits the log', () async {
      final LifestyleLog log = _sample(value: 2);
      final upsertResult = await repo.upsert(log);
      expect(upsertResult.isOk, isTrue);

      final List<LifestyleLog> emitted = await repo
          .watchBetween(from: windowStart, to: windowEnd)
          .first;
      expect(emitted, hasLength(1));
      expect(emitted.single.id, log.id);
      expect(emitted.single.category, LogCategory.water);
      expect(emitted.single.value, 2);
    });

    test('upsert replaces by id', () async {
      await repo.upsert(_sample(value: 1));
      await repo.upsert(_sample(value: 5));

      final List<LifestyleLog> emitted = await repo
          .watchBetween(from: windowStart, to: windowEnd)
          .first;
      expect(emitted, hasLength(1));
      expect(emitted.single.value, 5);
    });

    test('range excludes entries outside the window', () async {
      // Yesterday — out of window.
      await repo.upsert(
        _sample(id: 'old', loggedAt: DateTime(2026, 6, 12, 10)),
      );
      // Today — in window.
      await repo.upsert(_sample(id: 'today'));

      final List<LifestyleLog> emitted = await repo
          .watchBetween(from: windowStart, to: windowEnd)
          .first;
      expect(emitted.map((l) => l.id).toList(), <String>['today']);
    });

    test('watchBetween emits newest first', () async {
      await repo.upsert(
        _sample(id: 'morning', loggedAt: DateTime(2026, 6, 13, 7)),
      );
      await repo.upsert(
        _sample(id: 'evening', loggedAt: DateTime(2026, 6, 13, 20)),
      );

      final List<LifestyleLog> emitted = await repo
          .watchBetween(from: windowStart, to: windowEnd)
          .first;
      expect(emitted.map((l) => l.id).toList(), <String>['evening', 'morning']);
    });

    test('listBetween mirrors watchBetween semantics', () async {
      await repo.upsert(_sample(category: LogCategory.water, value: 3));
      await repo.upsert(
        _sample(id: 'sleep', category: LogCategory.sleep, value: 7.5),
      );

      final result = await repo.listBetween(from: windowStart, to: windowEnd);
      expect(result.isOk, isTrue);
      final List<LifestyleLog> rows = result.fold(
        onOk: (v) => v,
        onErr: (_) => <LifestyleLog>[],
      );
      expect(rows, hasLength(2));
      expect(rows.map((l) => l.category).toSet(), <LogCategory>{
        LogCategory.water,
        LogCategory.sleep,
      });
    });

    test('delete removes the log', () async {
      final LifestyleLog log = _sample();
      await repo.upsert(log);
      final deleteResult = await repo.delete(log.id);
      expect(deleteResult.isOk, isTrue);

      final List<LifestyleLog> emitted = await repo
          .watchBetween(from: windowStart, to: windowEnd)
          .first;
      expect(emitted, isEmpty);
    });

    test('note round-trips including null', () async {
      await repo.upsert(_sample(id: 'with-note', note: 'after lunch'));
      await repo.upsert(_sample(id: 'no-note', note: null));

      final List<LifestyleLog> emitted = await repo
          .watchBetween(from: windowStart, to: windowEnd)
          .first;
      final Map<String, String?> notes = <String, String?>{
        for (final LifestyleLog l in emitted) l.id: l.note,
      };
      expect(notes['with-note'], 'after lunch');
      expect(notes['no-note'], isNull);
    });
  });
}
