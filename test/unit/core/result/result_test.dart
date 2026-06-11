import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/result/result.dart';

void main() {
  group('Result', () {
    test('Ok carries its value and identifies as success', () {
      const Result<int, String> r = Result<int, String>.ok(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.failureOrNull, isNull);
    });

    test('Err carries its failure and identifies as failure', () {
      const Result<int, String> r = Result<int, String>.err('boom');
      expect(r.isOk, isFalse);
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.failureOrNull, 'boom');
    });

    test('map transforms Ok and preserves Err', () {
      const Result<int, String> ok = Result<int, String>.ok(3);
      const Result<int, String> err = Result<int, String>.err('nope');

      expect(ok.map((v) => v * 2).valueOrNull, 6);
      expect(err.map((v) => v * 2).failureOrNull, 'nope');
    });

    test('mapErr transforms Err and preserves Ok', () {
      const Result<int, String> ok = Result<int, String>.ok(3);
      const Result<int, String> err = Result<int, String>.err('nope');

      expect(ok.mapErr((f) => f.length).valueOrNull, 3);
      expect(err.mapErr((f) => f.length).failureOrNull, 4);
    });

    test('fold collapses both branches', () {
      const Result<int, String> ok = Result<int, String>.ok(10);
      const Result<int, String> err = Result<int, String>.err('x');

      final String s1 = ok.fold(
        onOk: (v) => 'value=$v',
        onErr: (f) => 'fail=$f',
      );
      final String s2 = err.fold(
        onOk: (v) => 'value=$v',
        onErr: (f) => 'fail=$f',
      );
      expect(s1, 'value=10');
      expect(s2, 'fail=x');
    });

    test('equality compares by inner value', () {
      expect(const Result<int, String>.ok(1) == const Result<int, String>.ok(1),
          isTrue);
      expect(
          const Result<int, String>.err('a') ==
              const Result<int, String>.err('a'),
          isTrue);
      expect(
          const Result<int, String>.ok(1) == const Result<int, String>.err('a'),
          isFalse);
    });
  });
}
