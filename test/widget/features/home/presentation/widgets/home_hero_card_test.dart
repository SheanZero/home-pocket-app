import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/family_happiness.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_hero_card.dart';

import '../../../../../helpers/happiness_test_fixtures.dart';
import '../../helpers/test_localizations.dart';

/// Snapshot helper composing the parameter set HomeHeroCard requires.
///
/// HomeHeroCard is a pure StatelessWidget (UI-SPEC line 277): all data flows
/// in through the constructor, no provider scope needed.
class _FixtureSnapshot {
  const _FixtureSnapshot({
    required this.monthlyReport,
    required this.happiness,
    required this.bestJoy,
    this.family,
    this.shadowBooks,
    this.shadowAggregate,
  });

  final MonthlyReport monthlyReport;
  final HappinessReport happiness;
  final MetricResult<BestJoyMomentRow> bestJoy;
  final FamilyHappiness? family;
  final List<ShadowBookInfo>? shadowBooks;
  final ShadowAggregate? shadowAggregate;
}

_FixtureSnapshot _singleRich() => _FixtureSnapshot(
  monthlyReport: fixtureMonthlyReportRich(),
  happiness: fixtureHappinessReportRich(),
  bestJoy: fixtureBestJoyResultRich(),
);

_FixtureSnapshot _singleEmpty() => _FixtureSnapshot(
  monthlyReport: fixtureMonthlyReportEmpty(),
  happiness: fixtureHappinessReportEmpty(),
  bestJoy: fixtureBestJoyResultEmpty(),
);

_FixtureSnapshot _singleThin() => _FixtureSnapshot(
  monthlyReport: fixtureMonthlyReportRich(),
  happiness: fixtureHappinessReportThin(),
  bestJoy: fixtureBestJoyResultThin(),
);

_FixtureSnapshot _singleWithJoy(double joyContribution) => _FixtureSnapshot(
  monthlyReport: fixtureMonthlyReportRich(),
  happiness: fixtureHappinessReportRich().copyWith(
    joyContribution: Value(joyContribution, 4),
  ),
  bestJoy: fixtureBestJoyResultRich(),
);

_FixtureSnapshot _singleAllNeutral() => _FixtureSnapshot(
  monthlyReport: fixtureMonthlyReportRich(),
  happiness: fixtureHappinessReportRich(),
  bestJoy: fixtureBestJoyResultAllNeutral(),
);

_FixtureSnapshot _groupRich() => _FixtureSnapshot(
  monthlyReport: fixtureMonthlyReportRich(),
  happiness: fixtureHappinessReportRich(),
  bestJoy: fixtureBestJoyResultRich(),
  family: fixtureFamilyHappinessRich(),
  shadowBooks: fixtureShadowBooksThree(),
  shadowAggregate: fixtureShadowAggregateThree(),
);

_FixtureSnapshot _groupEmptyShadows() => _FixtureSnapshot(
  monthlyReport: fixtureMonthlyReportRich(),
  happiness: fixtureHappinessReportRich(),
  bestJoy: fixtureBestJoyResultRich(),
  family: fixtureFamilyHappinessRich(),
  shadowBooks: const [],
  shadowAggregate: fixtureShadowAggregateThree(),
);

Widget _buildSubject({
  Locale locale = const Locale('ja'),
  bool isGroupMode = false,
  String currencyCode = 'JPY',
  int activeMonthlyJoyTarget = 50,
  int? recommendedMonthlyJoyTarget = 50,
  bool isMonthlyJoyTargetConfigured = false,
  required _FixtureSnapshot snapshot,
  VoidCallback? onTap,
}) {
  return testLocalizedApp(
    locale: locale,
    child: Scaffold(
      body: SingleChildScrollView(
        child: HomeHeroCard(
          report: snapshot.monthlyReport,
          happiness: snapshot.happiness,
          bestJoy: snapshot.bestJoy,
          family: snapshot.family,
          shadowBooks: snapshot.shadowBooks,
          shadowAggregate: snapshot.shadowAggregate,
          currencyCode: currencyCode,
          locale: locale,
          isGroupMode: isGroupMode,
          activeMonthlyJoyTarget: activeMonthlyJoyTarget,
          recommendedMonthlyJoyTarget: recommendedMonthlyJoyTarget,
          isMonthlyJoyTargetConfigured: isMonthlyJoyTargetConfigured,
          onTap: onTap ?? () {},
        ),
      ),
    ),
  );
}

/// Group structure mirrors requirement / decision IDs from
/// `.planning/phases/10-homepage-joyfullnesscard-redesign/10-CONTEXT.md`:
///   - HOMEUI-01..07 = HomeHeroCard rendering requirements
///   - FAMILY-03    = group-mode member rows
///   - D-09         = empty / all-neutral state behavior
///   - D-10         = info-icon tooltip behavior
///   - D-11         = card tap target
///   - D-12         = currency resolution from constructor
void main() {
  group('HomeHeroCard — Joy target progress color', () {
    test('interpolates from daily teal to joy gold and clamps overflow', () {
      final palette = AppPalette.light;
      expect(joyTargetProgressColor(0, palette), palette.daily);
      expect(joyTargetProgressColor(1, palette), palette.joy);
      expect(joyTargetProgressColor(1.6, palette), palette.joy);

      final midpoint = joyTargetProgressColor(0.5, palette);
      expect(midpoint, isNot(palette.daily));
      expect(midpoint, isNot(palette.joy));
    });
  });

  group('HomeHeroCard — single mode (HOMEUI-01, HOMEUI-05, HOMEUI-06)', () {
    testWidgets(
      'shows zero cumulative Joy and target reference without percentage',
      (tester) async {
        await tester.pumpWidget(_buildSubject(snapshot: _singleWithJoy(0)));
        await tester.pumpAndSettle();

        expect(find.text('0'), findsWidgets);
        // Target reference now lives on the center value's Semantics label
      // (homeJoyTargetSemantics), not standalone visible Text — the 2026-05
      // ring-polish change (64168f81 / c54e06fc) moved it to the a11y layer.
      expect(find.bySemanticsLabel(RegExp('目標 50')), findsOneWidget);
        expect(find.textContaining('0%'), findsNothing);
      },
    );

    testWidgets('shows half-target cumulative Joy without percentage', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(snapshot: _singleWithJoy(25)));
      await tester.pumpAndSettle();

      expect(find.text('25'), findsWidgets);
      // Target reference now lives on the center value's Semantics label
      // (homeJoyTargetSemantics), not standalone visible Text — the 2026-05
      // ring-polish change (64168f81 / c54e06fc) moved it to the a11y layer.
      expect(find.bySemanticsLabel(RegExp('目標 50')), findsOneWidget);
      expect(find.textContaining('50%'), findsNothing);
    });

    testWidgets('shows target-level cumulative Joy without percentage', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(snapshot: _singleWithJoy(50)));
      await tester.pumpAndSettle();

      expect(find.text('50'), findsWidgets);
      // Target reference now lives on the center value's Semantics label
      // (homeJoyTargetSemantics), not standalone visible Text — the 2026-05
      // ring-polish change (64168f81 / c54e06fc) moved it to the a11y layer.
      expect(find.bySemanticsLabel(RegExp('目標 50')), findsOneWidget);
      expect(find.textContaining('100%'), findsNothing);
    });

    testWidgets(
      'shows over-target cumulative Joy uncapped without percentage',
      (tester) async {
        await tester.pumpWidget(_buildSubject(snapshot: _singleWithJoy(80)));
        await tester.pumpAndSettle();

        expect(find.text('80'), findsWidgets);
        // Target reference now lives on the center value's Semantics label
      // (homeJoyTargetSemantics), not standalone visible Text — the 2026-05
      // ring-polish change (64168f81 / c54e06fc) moved it to the a11y layer.
      expect(find.bySemanticsLabel(RegExp('目標 50')), findsOneWidget);
        expect(find.textContaining('>100%'), findsNothing);
        expect(find.textContaining('160%'), findsNothing);
      },
    );

    testWidgets('target threshold states do not emit celebratory UI', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(snapshot: _singleWithJoy(80)));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('achievement'), findsNothing);
      expect(find.textContaining('milestone'), findsNothing);
      expect(find.textContaining('120%'), findsNothing);
      expect(find.textContaining('160%'), findsNothing);
      expect(find.textContaining('>100%'), findsNothing);
    });

    testWidgets('renders all 4 personal metrics from HappinessReport', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(snapshot: _singleRich()));
      await tester.pumpAndSettle();

      expect(find.byType(HomeHeroCard), findsOneWidget);
      // avgSatisfaction remains visible as a supporting ring metric.
      expect(find.text('7.8'), findsWidgets);
      // Monthly Joy target progress is the outer ring label.
      expect(find.text('ときめき目標'), findsOneWidget);
      // 小確幸 (12) highlights count legend
      expect(find.textContaining('小確幸'), findsWidgets);
    });

    testWidgets(
      'hero header renders total + +X% trend chip + previous-month sub-line',
      (tester) async {
        await tester.pumpWidget(_buildSubject(snapshot: _singleRich()));
        await tester.pumpAndSettle();

        // total = 142,800 (JPY)
        expect(find.textContaining('142,800'), findsWidgets);
        // 142800 > 137000 ⇒ positive trend
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
        // ja sub-line label "先月 ¥137,000"
        expect(find.textContaining('先月'), findsOneWidget);
      },
    );

    testWidgets('split bar renders ときめき帳 / 日々の帳 absolute amounts (no % glyph)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(snapshot: _singleRich()));
      await tester.pumpAndSettle();

      expect(find.textContaining('40,600'), findsWidgets);
      expect(find.textContaining('102,200'), findsWidgets);
      // The trend chip is the only element with `%`; no `%` glyph appears in
      // the joy / daily amount strings.
      final joyText = find.textContaining('40,600');
      expect(joyText, findsWidgets);
      tester.widgetList<Text>(joyText).forEach((t) {
        expect(t.data ?? '', isNot(contains('%')));
      });
      final survText = find.textContaining('102,200');
      tester.widgetList<Text>(survText).forEach((t) {
        expect(t.data ?? '', isNot(contains('%')));
      });
    });
  });

  group('HomeHeroCard — group mode (HOMEUI-03, HOMEUI-07, FAMILY-03)', () {
    testWidgets(
      'renders FamilyHappiness rings when isGroupMode == true && shadowBooks.isNotEmpty',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(snapshot: _groupRich(), isGroupMode: true),
        );
        await tester.pumpAndSettle();

        // group-mode hero label
        expect(find.textContaining('家族の支出'), findsOneWidget);
        // familyHighlightsSum center text 27 — also appears in the legend value,
        // so at least 1 occurrence is the strict assertion.
        expect(find.text('27'), findsAtLeastNWidgets(1));
        // group-mode ring section title 家族の小確幸
        expect(find.textContaining('家族の小確幸'), findsWidgets);
      },
    );

    testWidgets(
      'renders 3 member rows after Best Joy strip with avatar + name + ¥amount',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(snapshot: _groupRich(), isGroupMode: true),
        );
        await tester.pumpAndSettle();

        expect(find.text('TestMember1'), findsOneWidget);
        expect(find.text('TestMember2'), findsOneWidget);
        expect(find.text('TestMember3'), findsOneWidget);
        // At least one avatar emoji renders (🦊 / 🐻 / 🐼)
        expect(find.text('🦊'), findsOneWidget);
        expect(find.text('🐻'), findsOneWidget);
        expect(find.text('🐼'), findsOneWidget);
        // Per-member ¥amounts from perBookReports
        expect(find.textContaining('25,000'), findsWidgets);
        expect(find.textContaining('20,500'), findsWidgets);
        expect(find.textContaining('27,000'), findsWidgets);
      },
    );

    testWidgets(
      'hides member rows section when shadowBooks.isEmpty (D-08 minimum gate)',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(snapshot: _groupEmptyShadows(), isGroupMode: true),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('TestMember'), findsNothing);
        // ja section title homeMembersSectionTitle = "メンバー"
        expect(find.text('メンバー'), findsNothing);
      },
    );

    testWidgets('hides family region entirely when isGroupMode == false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(snapshot: _singleRich(), isGroupMode: false),
      );
      await tester.pumpAndSettle();

      // Single mode: no group hero label, no group ring title, no members.
      expect(find.textContaining('家族'), findsNothing);
      expect(find.text('メンバー'), findsNothing);
    });
  });

  group('HomeHeroCard — empty states (D-09)', () {
    testWidgets(
      'totalExpenses == 0: hero renders ¥0, trend chip hidden, split bar gray, rings Empty',
      (tester) async {
        await tester.pumpWidget(_buildSubject(snapshot: _singleEmpty()));
        await tester.pumpAndSettle();

        expect(find.textContaining('¥0'), findsWidgets);
        // hasAny == false ⇒ trend chip hidden
        expect(find.byIcon(Icons.trending_up), findsNothing);
        expect(find.byIcon(Icons.trending_down), findsNothing);
      },
    );

    testWidgets(
      'totalJoyTx == 0: rings track-only, legend "No data yet", Best Joy CTA empty variant',
      (tester) async {
        await tester.pumpWidget(_buildSubject(snapshot: _singleEmpty()));
        await tester.pumpAndSettle();

        // ja "まだ記録なし" — legend empty value
        expect(find.textContaining('まだ記録なし'), findsWidgets);
        // ja "今月の最愛がここに表示されます" — Best Joy Variant A empty Small.
        // homeBestJoyEmptyBig was removed by 260518-v4v Variant A redesign.
        expect(find.textContaining('今月の最愛がここに'), findsOneWidget);
      },
    );

    testWidgets('thin sample (n<5): rings render normally, no crash', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(snapshot: _singleThin()));
      await tester.pumpAndSettle();

      // Coverage caption removed (item 5 of pf5 polish).
      // Verify widget renders without error.
      expect(find.byType(HomeHeroCard), findsOneWidget);
    });

    testWidgets(
      'all-neutral Best Joy (sat<=2): Best Joy strip renders all-neutral CTA variant',
      (tester) async {
        await tester.pumpWidget(_buildSubject(snapshot: _singleAllNeutral()));
        await tester.pumpAndSettle();

        // ja: "あなたの今月の最愛にしよう" — Best Joy Variant A all-neutral Small.
        // homeBestJoyAllNeutralBig was removed by 260518-v4v Variant A redesign.
        expect(find.textContaining('あなたの今月の最愛にしよう'), findsOneWidget);
      },
    );
  });

  group('HomeHeroCard — info icons (HOMEUI-04, D-10)', () {
    testWidgets('exactly 2 Icons.info_outline instances total', (tester) async {
      await tester.pumpWidget(_buildSubject(snapshot: _singleRich()));
      await tester.pumpAndSettle();

      final iconFinder = find.descendant(
        of: find.byType(HomeHeroCard),
        matching: find.byIcon(Icons.info_outline),
      );
      expect(iconFinder, findsNWidgets(2));
    });

    testWidgets(
      'info icon tap shows tooltip dialog without firing card onTap',
      (tester) async {
        var tapped = 0;
        await tester.pumpWidget(
          _buildSubject(snapshot: _singleRich(), onTap: () => tapped++),
        );
        await tester.pumpAndSettle();

        // Tap the FIRST info icon.
        await tester.tap(find.byIcon(Icons.info_outline).first);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        // Card-level onTap MUST NOT fire when info icon absorbs the tap.
        expect(tapped, 0);
      },
    );
  });

  group('HomeHeroCard — tap target (D-11, Pitfall 3)', () {
    testWidgets('tapping any region of the card fires onTap exactly once', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _buildSubject(snapshot: _singleRich(), onTap: () => tapped++),
      );
      await tester.pumpAndSettle();

      // Tap the hero amount text — a non-info region.
      await tester.tap(find.textContaining('142,800').first);
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });
  });

  group(
    'HomeHeroCard — typography (CLAUDE.md Amount Display Style, Pitfall 10)',
    () {
      testWidgets(
        'hero total uses AppTextStyles.amountLarge with tabular figures',
        (tester) async {
          await tester.pumpWidget(_buildSubject(snapshot: _singleRich()));
          await tester.pumpAndSettle();

          // The hero total Text widget.
          final heroFinder = find.descendant(
            of: find.byType(HomeHeroCard),
            matching: find.textContaining('142,800'),
          );
          expect(heroFinder, findsWidgets);
          final heroTexts = tester.widgetList<Text>(heroFinder).toList();
          // The largest font (amountLarge fontSize: 30) is the hero total.
          Text? hero;
          double maxSize = 0;
          for (final t in heroTexts) {
            final size = t.style?.fontSize ?? 0;
            if (size > maxSize) {
              maxSize = size;
              hero = t;
            }
          }
          expect(hero, isNotNull);
          expect(
            hero!.style?.fontFeatures,
            contains(const FontFeature.tabularFigures()),
          );
        },
      );

      testWidgets('Best Joy small line ¥amount has fontFeatures.tabularFigures', (
        tester,
      ) async {
        await tester.pumpWidget(_buildSubject(snapshot: _singleRich()));
        await tester.pumpAndSettle();

        // Best Joy small line: "¥3,000・満足 10/10 ✨"
        final smallFinder = find.textContaining('3,000');
        expect(smallFinder, findsWidgets);
        final candidates = tester.widgetList<Text>(smallFinder).toList();
        // Find the Text whose style has tabularFigures (the Best Joy small line
        // explicitly sets this per Pitfall #10 gate).
        final tabular = candidates.where(
          (t) => (t.style?.fontFeatures ?? const []).contains(
            const FontFeature.tabularFigures(),
          ),
        );
        expect(tabular, isNotEmpty);
      });
    },
  );

  group('HomeHeroCard — currency resolution (D-12, CLAUDE.md Pitfall 9)', () {
    testWidgets('renders currencyCode from constructor (no hardcoded JPY)', (
      tester,
    ) async {
      // CNY also uses ¥ symbol but with 2 decimals (¥142,800.00 vs ¥142,800).
      await tester.pumpWidget(
        _buildSubject(snapshot: _singleRich(), currencyCode: 'CNY'),
      );
      await tester.pumpAndSettle();

      // Widget renders without throwing; ¥ symbol still present (CNY uses ¥).
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeHeroCard), findsOneWidget);
      expect(find.textContaining('¥'), findsWidgets);
      // CNY decimals (2) ⇒ formatted amount ends in ".00".
      expect(find.textContaining('142,800.00'), findsWidgets);
    });
  });

  group('HomeHeroCard — i18n parity (CLAUDE.md i18n rules)', () {
    testWidgets('renders correctly in ja locale', (tester) async {
      await tester.pumpWidget(
        _buildSubject(snapshot: _singleRich(), locale: const Locale('ja')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeHeroCard), findsOneWidget);
      // ja: homeHeroCardLabelSingle = "今月の支出"
      expect(find.textContaining('今月の支出'), findsOneWidget);
    });

    testWidgets('renders correctly in zh locale', (tester) async {
      await tester.pumpWidget(
        _buildSubject(snapshot: _singleRich(), locale: const Locale('zh')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeHeroCard), findsOneWidget);
      // zh: homeHeroCardLabelSingle = "本月支出"
      expect(find.textContaining('本月支出'), findsOneWidget);
    });

    testWidgets('renders correctly in en locale', (tester) async {
      await tester.pumpWidget(
        _buildSubject(snapshot: _singleRich(), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeHeroCard), findsOneWidget);
      // en: homeHeroCardLabelSingle = "This Month"
      expect(find.textContaining('This Month'), findsOneWidget);
    });
  });
}
