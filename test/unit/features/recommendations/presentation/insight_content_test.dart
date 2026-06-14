import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/recommendations/domain/entities/insight.dart';
import 'package:polaris/features/recommendations/domain/entities/insight_spec.dart';
import 'package:polaris/features/recommendations/domain/value_objects/insight_severity.dart';
import 'package:polaris/features/recommendations/presentation/insight_content.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';

const Locale _en = Locale('en');
const Locale _id = Locale('id');

Future<AppL> _loadL(Locale locale) async {
  // Use the official delegate so the test exercises the real ARB
  // load path rather than a hand-rolled lookup table.
  return AppL.delegate.load(locale);
}

void _ensureFlutter() {
  TestWidgetsFlutterBinding.ensureInitialized();
}

void main() {
  _ensureFlutter();

  group('InsightContent.resolve', () {
    test('water_target: builds title/body/CTA + preserves spec.id', () async {
      final AppL l = await _loadL(_en);
      const InsightSpec spec = InsightSpec(
        id: 'water_target',
        contentKey: 'water_target',
        severity: InsightSeverity.warn,
        relatedCategory: LogCategory.water,
        ctaRoute: '/lifestyle',
        args: <String, Object>{
          'avg': 3.2,
          'target': 6.0,
          'windowDays': 7,
        },
      );
      final Insight out = InsightContent.resolve(
        spec: spec,
        l: l,
        locale: _en,
      );
      expect(out.id, 'water_target');
      expect(out.severity, InsightSeverity.warn);
      expect(out.relatedCategory, LogCategory.water);
      expect(out.ctaRoute, '/lifestyle');
      expect(out.title, isNotEmpty);
      expect(out.body, contains('3.2'));
      // 6 should render WITHOUT a trailing ".0" (smart formatter
      // collapses whole-number doubles to plain integers).
      expect(out.body, contains('6+'));
      expect(out.body, isNot(contains('6.0')));
      expect(out.body, contains('7 days'));
      expect(out.ctaLabel, 'Log water');
    });

    test('life_phase: title interpolates the matched percentage', () async {
      final AppL l = await _loadL(_en);
      const InsightSpec spec = InsightSpec(
        id: 'life_phase:50',
        contentKey: 'life_phase',
        severity: InsightSeverity.info,
        ctaRoute: '/events',
        args: <String, Object>{
          'pct': 50,
          'remainingYears': 40.5,
          'remainingDays': 14787,
        },
      );
      final Insight out = InsightContent.resolve(
        spec: spec,
        l: l,
        locale: _en,
      );
      expect(out.id, 'life_phase:50');
      expect(out.title, contains('50%'));
      expect(out.body, contains('40.5'));
      expect(out.body, contains('14,787'));
    });

    test('logging_streak: streak interpolates in both title and body', () async {
      final AppL l = await _loadL(_en);
      const InsightSpec spec = InsightSpec(
        id: 'logging_streak:14',
        contentKey: 'logging_streak',
        severity: InsightSeverity.encourage,
        args: <String, Object>{'streak': 14},
      );
      final Insight out = InsightContent.resolve(
        spec: spec,
        l: l,
        locale: _en,
      );
      expect(out.title, contains('14'));
      expect(out.body, contains('14'));
    });

    test('Indonesian locale uses ID strings + ID number grouping', () async {
      final AppL l = await _loadL(_id);
      const InsightSpec spec = InsightSpec(
        id: 'life_phase:50',
        contentKey: 'life_phase',
        severity: InsightSeverity.info,
        args: <String, Object>{
          'pct': 50,
          'remainingYears': 40.5,
          'remainingDays': 14787,
        },
      );
      final Insight out = InsightContent.resolve(
        spec: spec,
        l: l,
        locale: _id,
      );
      // ID uses period as thousands separator.
      expect(out.body, contains('14.787'));
      // 40.5 in ID locale uses comma as decimal.
      expect(out.body, contains('40,5'));
      // ID strings should be present (the title contains the
      // characteristic ID phrase).
      expect(out.title, contains('menjalani'));
    });

    test('unknown contentKey falls back to a visible "missing" card', () async {
      final AppL l = await _loadL(_en);
      const InsightSpec spec = InsightSpec(
        id: 'mystery',
        contentKey: 'unrecognized',
        severity: InsightSeverity.warn,
      );
      final Insight out = InsightContent.resolve(
        spec: spec,
        l: l,
        locale: _en,
      );
      expect(out.title, contains('missing copy'));
      expect(out.body, isNotEmpty);
    });
  });
}
