import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/presentation/analytics_card_registry.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/best_joy_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/category_donut_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/kpi_hero_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/largest_expense_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';

/// Phase 45 Plan 05 — D-B3 / GUARD-01 structural-invariant test.
///
/// Promotes Phase 45's "isolation by construction" from implicit to directly
/// asserted: the `_refresh` invalidation union the shell derives from
/// [analyticsCardRegistry] is enumerated here with a synthetic
/// [AnalyticsCardContext] and **no widget pump** (RESEARCH A3 — the spec
/// closures are pure over the ctx).
///
/// Asserts:
/// - (a) union ⊆ analytics provider families; **0 `home/*` providers** (D-B3).
/// - (b) render order: registry non-empty + declaration order is iteration
///   order (D-B1).
/// - (c) D-B4 visibility: the two family specs (family `PerCategoryBreakdownCard`
///   + `FamilyInsightDataCard`) are group-only; all others always visible.
/// - (c2) D-A1 union==today (Blocker-1 guard): `dailyVsJoySnapshotFamilyProvider`
///   ∈ group union ∧ ∉ solo union; `shadowBooksProvider` ∉ either union.
/// - (d) per-card structure: each `widgets/cards/*.dart` wrapper is < 400 LOC,
///   `extends ConsumerWidget` (or `StatelessWidget` for `analytics_data_card`),
///   and imports no `home/`.
/// - (e) D-B2 single-source keys: each `*RefreshTargets(ctx)` provider's
///   argument equals the ctx fields (TotalSixMonth keyed on `trendAnchor`).

/// The runtime type names of every analytics provider family that may legally
/// appear in the registry-derived `_refresh` union. Generated Riverpod family
/// instances each have a unique concrete type (e.g. `MonthlyReportProvider`),
/// so origin can be asserted by membership in this whitelist. NO `home/*`
/// provider type (`ShadowBooksProvider`/`ShadowAggregateProvider`) appears here.
const Set<String> _analyticsProviderTypeWhitelist = <String>{
  'MonthlyReportProvider',
  'SatisfactionDistributionProvider',
  'EarliestTransactionMonthProvider',
  'HappinessReportProvider',
  'BestJoyMomentProvider',
  'LargestMonthlyExpenseProvider',
  'FamilyHappinessProvider',
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
    currencyCode: 'JPY',
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
      // order. 46-01 removed the TotalSixMonth trend spec (its data layer is
      // deleted, D-E2) → 9 specs (was 10). The round-5 B card additions + the
      // registry re-order land in wave-3 46-07.
      expect(
        analyticsCardRegistry.length,
        9,
        reason: 'D-B1: 9 specs in stable render order (7 always-visible + 2 '
            'group-only) after the 46-01 TotalSixMonth removal.',
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

    test('(c) D-B4 visibility: exactly the 2 family specs are group-gated', () {
      final groupOnly =
          analyticsCardRegistry.where((s) => !s.isVisible(soloCtx)).toList();
      expect(
        groupOnly.length,
        2,
        reason: 'D-B4: exactly the family-scope PerCategoryBreakdownCard spec '
            'and the FamilyInsightDataCard spec are gated behind isGroupMode.',
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
      // Group makes all 9 specs visible (was 10 before the 46-01 TotalSixMonth
      // removal).
      expect(
        analyticsCardRegistry.where((s) => s.isVisible(groupCtx)).length,
        9,
      );
      expect(
        analyticsCardRegistry.where((s) => s.isVisible(soloCtx)).length,
        7,
      );
    });

    test('(c2) Blocker-1 guard: dailyVsJoySnapshotFamilyProvider ∈ group union '
        '∧ ∉ solo union (D-A1 union==today)', () {
      final soloUnion = _union(soloCtx);
      final groupUnion = _union(groupCtx);

      final groupHasDailyVsJoyFamily = groupUnion.any(
        (p) => p == dailyVsJoySnapshotFamilyProvider(
          startDate: groupCtx.startDate,
          endDate: groupCtx.endDate,
          joyMetricVariant: groupCtx.joyMetricVariant,
        ),
      );
      final soloHasDailyVsJoyFamily = soloUnion.any(
        (p) => p == dailyVsJoySnapshotFamilyProvider(
          startDate: soloCtx.startDate,
          endDate: soloCtx.endDate,
          joyMetricVariant: soloCtx.joyMetricVariant,
        ),
      );

      expect(
        groupHasDailyVsJoyFamily,
        isTrue,
        reason: 'D-A1: the group-aware DailyVsJoy spec MUST invalidate the '
            'family snapshot under group mode — preserving today\'s '
            '_refresh:314 behavior goldens cannot catch.',
      );
      expect(
        soloHasDailyVsJoyFamily,
        isFalse,
        reason: 'D-A1: the family snapshot must NOT be invalidated in solo '
            'mode (the card does not watch it there).',
      );
    });

    test('(c2) GROUP union is a strict superset of SOLO adding exactly '
        'familyHappiness + perCategoryJoyBreakdownFamily + '
        'dailyVsJoySnapshotFamily', () {
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
        <String>{
          'FamilyHappinessProvider',
          'PerCategoryJoyBreakdownFamilyProvider',
          'DailyVsJoySnapshotFamilyProvider',
        },
        reason: 'D-A1/D-B4: group mode adds exactly the three family-scoped '
            'targets (FamilyInsight happiness, family per-category, family '
            'daily-vs-joy snapshot).',
      );
    });

    test('(e) D-B2 single-source keys: each card *RefreshTargets argument '
        'equals the ctx fields (no build/invalidation drift)', () {
      final ctx = soloCtx;

      // KPI hero: monthlyReport + happinessReport, keyed on book/start/end.
      expect(
        kpiHeroRefreshTargets(ctx),
        containsAllInOrder(<ProviderBase<Object?>>[
          monthlyReportProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
          happinessReportProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            currencyCode: ctx.currencyCode,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
        ]),
      );

      // (TotalSixMonth trend-anchor key assertion removed in 46-01 — the
      // expenseTrend provider + TotalSixMonthCard are deleted with the 6-month
      // stack, D-E2. The within-month trend card + its key assertion land in
      // wave-3 46-07.)

      // CategoryDonut: monthlyReport (same key tuple as KPI — deduped by Set).
      expect(
        categoryDonutRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          monthlyReportProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
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
            currencyCode: ctx.currencyCode,
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

      // LargestExpense + BestJoy single targets.
      expect(
        largestExpenseRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          largestMonthlyExpenseProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
        ],
      );
      expect(
        bestJoyRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          bestJoyMomentProvider(
            bookId: ctx.bookId,
            startDate: ctx.startDate,
            endDate: ctx.endDate,
            joyMetricVariant: ctx.joyMetricVariant,
          ),
        ],
      );

      // Solo per-category (you/solo scope) keyed on book/start/end.
      expect(
        perCategorySoloRefreshTargets(ctx),
        <ProviderBase<Object?>>[
          perCategoryJoyBreakdownProvider(
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
