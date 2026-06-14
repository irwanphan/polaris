import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/core/deep_links/deep_link_router.dart';

void main() {
  group('DeepLinkRouter.resolve', () {
    test('returns null for null uri', () {
      expect(DeepLinkRouter.resolve(null), isNull);
    });

    test('returns null for non-polaris scheme', () {
      expect(
        DeepLinkRouter.resolve(Uri.parse('https://events/abc')),
        isNull,
      );
      expect(
        DeepLinkRouter.resolve(Uri.parse('mailto:foo@example.com')),
        isNull,
      );
    });

    test('returns null for unknown host', () {
      expect(
        DeepLinkRouter.resolve(Uri.parse('polaris://unknown/abc')),
        isNull,
      );
      // 'life' host is reserved for future use but not wired yet —
      // resolver must skip it rather than crash.
      expect(
        DeepLinkRouter.resolve(Uri.parse('polaris://life')),
        isNull,
      );
    });

    test('returns null for events without id segment', () {
      expect(
        DeepLinkRouter.resolve(Uri.parse('polaris://events')),
        isNull,
      );
      expect(
        DeepLinkRouter.resolve(Uri.parse('polaris://events/')),
        isNull,
      );
    });

    test('resolves polaris://events/<id> to event detail path', () {
      expect(
        DeepLinkRouter.resolve(Uri.parse('polaris://events/abc-123')),
        equals('${AppRoutes.events}/abc-123'),
      );
    });

    test('uses AppRoutes.eventDetail builder for the path', () {
      // Catches accidental drift between the resolver and the
      // route-table helper everyone else uses.
      const String id = 'uuid-xyz';
      expect(
        DeepLinkRouter.resolve(Uri.parse('polaris://events/$id')),
        equals(AppRoutes.eventDetail(id)),
      );
    });

    test('preserves percent-encoded id segments', () {
      // Native side `Uri.encode`s ids defensively; the resolver
      // should hand back the decoded form so the GoRoute path
      // parameter matches the database id exactly.
      final Uri uri = Uri.parse(
        'polaris://events/${Uri.encodeComponent('id with space')}',
      );
      expect(
        DeepLinkRouter.resolve(uri),
        equals('${AppRoutes.events}/id with space'),
      );
    });
  });

  group('DeepLinkRouter.eventDetailUri', () {
    test('builds canonical polaris://events/<id> uri', () {
      final Uri uri = DeepLinkRouter.eventDetailUri('xyz');
      expect(uri.scheme, equals('polaris'));
      expect(uri.host, equals('events'));
      expect(uri.pathSegments, equals(<String>['xyz']));
    });

    test('round-trips through resolve()', () {
      const String id = 'abc';
      final Uri uri = DeepLinkRouter.eventDetailUri(id);
      expect(
        DeepLinkRouter.resolve(uri),
        equals(AppRoutes.eventDetail(id)),
      );
    });
  });

  group('DeepLinkRouter.notificationPayloadToUri', () {
    test('returns null for null / empty / whitespace payloads', () {
      expect(DeepLinkRouter.notificationPayloadToUri(null), isNull);
      expect(DeepLinkRouter.notificationPayloadToUri(''), isNull);
      expect(DeepLinkRouter.notificationPayloadToUri('   '), isNull);
    });

    test('wraps bare event id payloads in polaris://events/<id>', () {
      // Backwards-compat: the notification scheduler still stores
      // the bare event id as the payload — the deep-link layer
      // normalises it to a URI.
      final Uri? uri = DeepLinkRouter.notificationPayloadToUri('evt-1');
      expect(uri, isNotNull);
      expect(DeepLinkRouter.resolve(uri), equals(AppRoutes.eventDetail('evt-1')));
    });

    test('passes through already-formed polaris URIs', () {
      final Uri? uri = DeepLinkRouter.notificationPayloadToUri(
        'polaris://events/foo',
      );
      expect(uri, isNotNull);
      expect(DeepLinkRouter.resolve(uri), equals(AppRoutes.eventDetail('foo')));
    });
  });
}
