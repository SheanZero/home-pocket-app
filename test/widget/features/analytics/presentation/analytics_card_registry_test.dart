import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/presentation/analytics_card_registry.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/category_donut_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_calendar_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_spend_card.dart'
    show joySpendRefreshTargets;
import 'package:home_pocket/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/within_month_trend_card.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';

/// Phase 45 Plan 05 — D-B3 / GUARD-01 structural-invariant test.
///
/// Promotes Phase 45's "isolation by construction" from implicit to directly
/// asserted: the `_refresh` invalidation union the shell derives from
/// [analyticsCardRegistry] is enumerated here with a synthetic
/// [AnalyticsCardContext] and **no widget pump** (RESEARCH A3 — the spec
/// closures are pure over the ctx).
///
/// Asserts (round-5 B flat lineup, Phase 46 D-F2):
/// - (a) union ⊆ analytics provider families; **0 `home/*` providers** (D-B3).
/// - (b) render order: registry non-empty + declaration order is iteration
///   order (D-B1) — 6 specs (5 always-visible + 1 group-only family insight).
/// - (c) D-B4 visibility: ONLY the `FamilyInsightDataCard` spec is group-only;
///   all 5 round-5 B cards are always visible.
/// - (c2) D-B4 group-superset guard: group mode adds EXACTLY
///   `FamilyHappinessProvider`; `shadowBooksProvider` ∉ either union.
/// - (d) per-card structure: each `widgets/cards/*.dart` wrapper is < 400 LOC,
///   `extends ConsumerWidget` (or `StatelessWidget` for `analytics_data_card`),
///   and imports no `home/`.
/// - (e) D-B2 single-source keys: each `*RefreshTargets(ctx)` provider's
///   argument equals the ctx fields (trend/calendar keyed on `trendAnchor`).

/// The runtime type names of every analytics provider family that may legally
/// appear in the registry-derived `_refresh` union. Generated Riverpod family
/// instances each have a unique concrete type (e.g. `MonthlyReportProvider`),
/// so origin can be asserted by membership in this whitelist. NO `home/*`
/// provider type (`ShadowBooksProvider`/`ShadowAggregateProvider`) appears here.
const Set<String> _analyticsProviderTypeWhitelist = <String>{
  // Round-5 B lineup targets (Phase 46, D-F2).
  'WithinMonthCumulativeTrendProvider',
  'MonthlyReportProvider',
  'JoyCategoryAmountsProvider',
  'PerDayJoyCountsProvider',
  'SatisfactionDistributionProvider',
  'HappinessReportProvider',
  'EarliestTransactionMonthProvider',
  'FamilyHappinessProvider',
  // De-registered specs' providers (cards retained, no longer in the union) +
  // dead-card providers — kept as LEGAL (whitelist = "may appear", not
  // "required"); they simply never enter the round-5 B union anymore.
  'BestJoyMomentProvider',
  'LargestMonthlyExpenseProvider',
  'PerCategoryJoyBreakdownProvider',
  'PerCategoryJoyBreakdownFamilyProvider',
  'DailyVsJoySnapshotProvider',
  'DailyVsJoySnapshotFamilyProvider',
};

/// Builds a synthetic [AnalyticsCardContext] with fixed dates/variant/currency.
/// No widget context is needed — the spec closures are pure over the ctx.
AnalyticsCardContext _ctx({required bool isGroupMode}) {
  final startDate = DateTime(2026, 1, 1);
  final endDate = DateTime(2026, 1, 31);
  return AnalyticsCardContext(
    bookId: 'book-fixture',
    startDate: startDate,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    joyMetricVariant: JoyMetricVariant.all,
    isGroupMode: isGroupMode,
    locale: const Locale('ja'),
  );
}

/// The registry-derived `_refresh` invalidation union for [ctx]:
/// `registry.where(isVisible).expand(refreshTargets) ∪ shellRefreshTargets`.
/// This mirrors EXACTLY what Plan 04's shell `_refresh` computes.
Set<ProviderBase<Object?>> _union(AnalyticsCardContext ctx) {
  return <ProviderBase<Object?>>{
    ...analyticsCardRegistry
        .where((spec) => spec.isVisible(ctx))
        .expand((spec) => spec.refreshTargets(ctx)),
    ...shellRefreshTargets(ctx),
  };
}

void main() {
  group('analyticsCardRegistry — D-B3 / GUARD-01 structural invariants', () {
    final soloCtx = _ctx(isGroupMode: false);
    final groupCtx = _ctx(isGroupMode: true);

    test('registry is non-empty and declaration order == iteration order '
        '(D-B1 render order)', () {
      expect(
        analyticsCardRegistry,
        isNotEmpty,
        reason: 'A vacuously-empty registry would make every union assertion '
            'pass falsely (T-45-10).',
      );
      // The registry is a `final List` whose iteration order is its declaration
      // order. Round-5 r5 (260620-lfp D2): 5 specs total — 4 always-visible
      // (within_month_trend, category_donut[+joy drawer], joy_calendar,
      // satisfaction_histogram) + 1 group-only (family_insight). JoySpendCard is
      // de-registered (its joybar moved into category_donut).
      expect(
        analyticsCardRegistry.length,
        5,
        reason: 'D-B1/D2: 5 specs in stable round-5 r5 render order (4 '
            'always-visible + 1 group-only family insight); JoySpendCard '
            'de-registered (joybar nested in the donut card).',
      );
    });

    test('(a) SOLO union ⊆ analytics families; 0 home/* providers '
        '(D-B3 / GUARD-01 core)', () {
      final union = _union(soloCtx);
      expect(union, isNotEmpty);

      for (final provider in union) {
        final typeName = provider.runtimeType.toString();
        expect(
          _analyticsProviderTypeWhitelist.contains(typeName),
          isTrue,
          reason: 'D-B3: every union member must originate from an analytics '
              'state_* family; "$typeName" is not in the analytics whitelist.',
        );
      }

      // Negative: the home-feature shadowBooksProvider must NEVER appear.
      expect(
        union.any((p) => p.runtimeType == shadowBooksProvider.runtimeType),
        isFalse,
        reason: 'D-B3 Option A: shadowBooksProvider (home/*) is dropped from '
            'the union — FamilyInsightDataCard reads it display-only via a '
            'shell-injected prop, never as an invalidation target.',
      );

      // D2 / Pitfall-3: after JoySpendCard de-registration, the folded
      // joyCategoryAmountsProvider (now carried by categoryDonutRefreshTargets)
      // MUST still be in the SOLO union so pull-to-refresh invalidates the nested
      // joy drawer.
      expect(
        union.contains(
          joyCategoryAmountsProvider(
            bookId: soloCtx.bookId,
            startDate: soloCtx.startDate,
            endDate: soloCtx.endDate,
            joyMetricVariant: soloCtx.joyMetricVariant,
          ),
        ),
        isTrue,
        reason: 'D2 / Pitfall-3: the joy drawer refresh target must survive '
            'JoySpendCard de-registration by being folded into the donut '
            "card's targets.",
      );
    });

    test('(a) GROUP union ⊆ analytics families; 0 home/* providers (D-B3)', () {
      final union = _union(groupCtx);
      expect(union, isNotEmpty);

      for (final provider in union) {
        final typeName = provider.runtimeType.toString();
        expect(
          _analyticsProviderTypeWhitelist.contains(typeName),
          isTrue,
          reason: 'D-B3: group-mode union member "$typeName" is not an '
              'analytics family.',
        );
      }
      expect(
        union.any((p) => p.runtimeType == shadowBooksProvider.runtimeType),
        isFalse,
        reason: 'D-B3 Option A: shadowBooksProvider absent in group mode too.',
      );
    });

    test('(c) D-B4 visibility: exactly the 1 family spec is group-gated', () {
      final groupOnly =
          analyticsCardRegistry.where((s) => !s.isVisible(soloCtx)).toList();
      expect(
        groupOnly.length,
        1,
        reason: 'D-F1/D-B4: ONLY the FamilyInsightDataCard spec is gated behind '
            'isGroupMode in the round-5 B lineup (the family '
            'PerCategoryBreakdownCard spec was de-registered).',
      );
      // All specs visible in solo are also visible in group (group is a
      // superset of the visible set).
      for (final spec in analyticsCardRegistry) {
        if (spec.isVisible(soloCtx)) {
          expect(
            spec.isVisible(groupCtx),
            isTrue,
            reason: 'D-B4: any solo-visible spec must remain visible in group '
                'mode (group is a superset).',
          );
        }
      }
      // Group makes all 5 specs visible; solo makes the 4 round-5 r5 cards.
      expect(
        analyticsCardRegistry.where((s) => s.isVisible(groupCtx)).length,
        5,
      );
      expect(
        analyticsCardRegistry.where((s) => s.isVisible(soloCtx)).length,
        4,
      );
    });

    test('(c2) GROUP union is a strict superset of SOLO adding EXACTLY '
        'familyHappiness (round-5 B family insight only)', () {
      final soloUnion = _union(soloCtx);
      final groupUnion = _union(groupCtx);

      // Solo is a subset of group.
      expect(
        soloUnion.difference(groupUnion),
        isEmpty,
        reason: 'D-B4: group mode only ADDS targets; it never drops a '
            'solo-visible target.',
      );

      final added = groupUnion.difference(soloUnion);
      final addedTypes =
          added.map((p) => p.runtimeType.toString()).toSet();
      expect(
        addedTypes,
        <String>{'FamilyHappinessProvider'},
        reason: 'D-F1/D-B4: in the round-5 B lineup the ONLY group-only spec is '
            'FamilyInsightDataCard, so group mode adds exactly its '
            'familyHappinessProvider target (the family PerCategory + DailyVsJoy '
            'family specs were de-registered).',
      );
    });

    test('(e) D-B2 single-source keys: each card *RefreshTargets argument '
        'equals the ctx fields (no build/invalidation drift)', () {
      final ctx = soloCtx;

      // WithinMonthTrend: withinMonthCumulativeTrend keyed on book + trendAnchor.
      expect(
        withinMonthTrendRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          withinMonthCumulativeTrendProvider(
            bookId: ctx.bookId,
            anchor: ctx.trendAnchor,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
        ],
      );

      // CategoryDonut: monthlyReport + the FOLDED joyCategoryAmounts (D2 /
      // Pitfall-3 — the nested joy drawer's refresh target now lives here so
      // pull-to-refresh still invalidates it after JoySpendCard de-registration).
      expect(
        categoryDonutRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          monthlyReportProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
          joyCategoryAmountsProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
        ],
      );

      // The de-registered JoySpendCard's single-source function is retained (its
      // wrapper + tests still consume it) and returns its joyCategoryAmounts
      // target — the SAME provider instance now folded into the donut's targets.
      expect(
        joySpendRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          joyCategoryAmountsProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
        ],
      );

      // JoyCalendar: perDayJoyCounts keyed on book + trendAnchor.
      expect(
        joyCalendarRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          perDayJoyCountsProvider(
            bookId: ctx.bookId,
            anchor: ctx.trendAnchor,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
        ],
      );

      // SatisfactionHistogram: happinessReport + satisfactionDistribution.
      expect(
        satisfactionHistogramRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          happinessReportProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            // Matches the card's literal 'JPY' (WR-01 / D-02) — currencyCode was
            // removed from AnalyticsCardContext, kept as a provider key literal.
            currencyCode: 'JPY',
            joyMetricVariant: ctx.joyMetricVariant,
          ),
          satisfactionDistributionProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
        ],
      );

      // shell-level target: earliestTransactionMonth keyed on bookId.
      expect(
        shellRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          earliestTransactionMonthProvider(bookId: ctx.bookId),
        ],
      );
    });
  });

  group('analytics_card_registry.dart — D-B3 file-wide import gate '
      '(source grep)', () {
    test('registry imports no home/presentation/providers and references no '
        'shadowBooksProvider', () {
      final source = File(
        'lib/features/analytics/presentation/analytics_card_registry.dart',
      ).readAsStringSync();

      expect(
        source.contains('home/presentation/providers'),
        isFalse,
        reason: 'D-B3 file-wide gate: the registry must not import any '
            'home-feature provider.',
      );
      expect(
        source.contains('shadowBooksProvider'),
        isFalse,
        reason: 'D-B3 Option A: shadowBooksProvider must not appear in any '
            'refreshTargets/shellRefreshTargets — it is display-only and '
            'shell-injected.',
      );
    });
  });

  group('widgets/cards/*.dart — REDES-01 per-card structure', () {
    const cardsDir = 'lib/features/analytics/presentation/widgets/cards';

    /// Pre-existing leaf widgets are NOT newly-extracted wrappers (Assumption
    /// A2); the bound applies to the `cards/` wrappers only — every file in
    /// this directory IS a newly-extracted wrapper, so none are exempt here.
    const statelessShellFile = 'analytics_data_card.dart';

    test('each cards/*.dart is < 400 LOC, is a ConsumerWidget (or the '
        'StatelessWidget shell), and imports no home/', () {
      final dir = Directory(cardsDir);
      expect(
        dir.existsSync(),
        isTrue,
        reason: 'The newly-extracted card wrappers must live under $cardsDir.',
      );

      final cardFiles = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(
        cardFiles,
        isNotEmpty,
        reason: 'T-45-10: a vacuous (empty) cards/ dir would pass the loop '
            'falsely.',
      );

      for (final file in cardFiles) {
        final source = file.readAsStringSync();
        final fileName = file.uri.pathSegments.last;
        final loc = '\n'.allMatches(source).length + 1;

        expect(
          loc,
          lessThan(400),
          reason: 'REDES-01: $fileName is $loc LOC (must be < 400).',
        );

        if (fileName == statelessShellFile) {
          expect(
            source.contains('extends StatelessWidget'),
            isTrue,
            reason: 'REDES-01: $fileName is the shared shell StatelessWidget.',
          );
        } else {
          expect(
            source.contains('extends ConsumerWidget'),
            isTrue,
            reason: 'REDES-01: $fileName must be a ConsumerWidget.',
          );
        }

        expect(
          source.contains('home/'),
          isFalse,
          reason: 'D-B3 / REDES-01: $fileName must import no home/ path.',
        );
      }
    });
  });
}
