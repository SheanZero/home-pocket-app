import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_joy_breakdown.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/per_category_breakdown_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/daily_vs_joy_card.dart';

import '../../../../../helpers/test_localizations.dart';

/// D-14 anti-toxicity widget sweep — verifies that Phase 16's two new
/// AnalyticsScreen Distribution-group cards (PerCategoryBreakdownCard +
/// DailyVsJoyCard) never leak forbidden value-judgment / comparison
/// substrings into rendered output in any of the three supported locales
/// (en / ja / zh) across the canonical user-visible state matrix.
///
/// Rationale (CONTEXT D-14 + RESEARCH "Specific Ideas" line 224):
/// Anti-toxicity intent shifts from "copy review" (manual, error-prone) to
/// "compile-and-test gate" (automated, audit-friendly). The test pumps the
/// WHOLE card for each state so future ARB additions are auto-vetted.
///
/// Failure modes are silent: a single locale slipping a "比較" header would
/// ship a regression unnoticed without this sweep.

// ---------------------------------------------------------------------------
// LOCKED forbidden substring lists (CONTEXT D-14 + UI-SPEC §Forbidden
// substrings, lines 117-122). Do not relax these without an explicit
// product/ADR sign-off.
// ---------------------------------------------------------------------------

const forbiddenEn = <String>[
  'better',
  'worse',
  'winner',
  'loser',
  'vs',
  'versus',
  'compare',
  'comparison',
  'higher is good',
  'lower is bad',
  'score',
  'rank',
  'ranking',
  'wins',
  'loses',
];

const forbiddenZh = <String>[
  '更好',
  '更差',
  '赢',
  '输',
  '胜',
  '败',
  'vs',
  '对比',
  '比较',
  '排名',
  '分数',
  '胜出',
  '落败',
];

const forbiddenJa = <String>[
  '勝ち',
  '負け',
  'より良い',
  'より悪い',
  '比較',
  '対決',
  'スコア',
  'ランキング',
  '勝つ',
  '負ける',
];

const locales = <Locale>[Locale('en'), Locale('ja'), Locale('zh')];

List<String> _forbiddenFor(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return forbiddenEn;
    case 'ja':
      return forbiddenJa;
    case 'zh':
      return forbiddenZh;
  }
  throw StateError('Unsupported locale: ${locale.languageCode}');
}

// ---------------------------------------------------------------------------
// Card harness constants.
// ---------------------------------------------------------------------------

const _bookId = 'book-a';
const _currencyCode = 'JPY';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 6, 1);

// ---------------------------------------------------------------------------
// Fixture helpers.
// ---------------------------------------------------------------------------

PerCategoryJoyBreakdownItem _item(String id, double avg, int count) =>
    PerCategoryJoyBreakdownItem(
      categoryId: id,
      avgSatisfaction: avg,
      totalCount: count,
    );

PerCategoryJoyBreakdown _breakdownSubMinN() => const PerCategoryJoyBreakdown(
      items: [],
      totalCount: 5,
      otherCount: 5,
      otherCategoryCount: 2,
    );

PerCategoryJoyBreakdown _breakdownValue() => PerCategoryJoyBreakdown(
      items: [
        _item('cat_a', 9.0, 4),
        _item('cat_b', 8.0, 3),
        _item('cat_c', 6.5, 3),
      ],
      totalCount: 12,
      otherCount: 2,
      otherCategoryCount: 1,
    );

JoyLedgerSnapshot _joy({
  int entryCount = 5,
  int totalSpend = 1500,
  double avgSat = 7.4,
}) => JoyLedgerSnapshot(
      entryCount: entryCount,
      totalSpend: totalSpend,
      avgSatisfaction: avgSat,
    );

DailyLedgerSnapshot _daily({
  int entryCount = 8,
  int totalSpend = 12000,
}) => DailyLedgerSnapshot(entryCount: entryCount, totalSpend: totalSpend);

DailyVsJoySnapshot _snapshotValueSolo() =>
    DailyVsJoySnapshot(joy: _joy(), daily: _daily());

DailyVsJoySnapshot _snapshotValueGroupFamily() => DailyVsJoySnapshot(
      joy: _joy(entryCount: 12, totalSpend: 3500, avgSat: 6.8),
      daily: _daily(entryCount: 18, totalSpend: 24000),
    );

// ---------------------------------------------------------------------------
// Subject builders.
// ---------------------------------------------------------------------------

Widget _buildPerCategoryCard({
  required Locale locale,
  required PerCategoryScope scope,
}) =>
    PerCategoryBreakdownCard(
      bookId: _bookId,
      startDate: _startDate,
      endDate: _endDate,
      locale: locale,
      scope: scope,
    );

Widget _buildDailyVsJoyCard({
  required Locale locale,
  required bool isGroupMode,
}) =>
    DailyVsJoyCard(
      bookId: _bookId,
      startDate: _startDate,
      endDate: _endDate,
      currencyCode: _currencyCode,
      locale: locale,
      isGroupMode: isGroupMode,
    );

// ---------------------------------------------------------------------------
// Override builders — keep each state's override list local so a missing
// provider override is loud (the unoverridden auto-dispose provider would
// throw at runtime instead of silently passing the sweep).
// ---------------------------------------------------------------------------

List<Override> _perCategoryEmptyOverrides() => [
      perCategoryJoyBreakdownProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => const Empty<PerCategoryJoyBreakdown>()),
    ];

List<Override> _perCategorySubMinNOverrides() => [
      perCategoryJoyBreakdownProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => Value(_breakdownSubMinN(), 5)),
    ];

List<Override> _perCategoryValueSoloOverrides() => [
      perCategoryJoyBreakdownProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => Value(_breakdownValue(), 12)),
    ];

List<Override> _perCategoryValueGroupOverrides() => [
      perCategoryJoyBreakdownFamilyProvider(
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => Value(_breakdownValue(), 12)),
    ];

List<Override> _dailyVsJoyEmptyOverrides() => [
      dailyVsJoySnapshotProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => const Empty<DailyVsJoySnapshot>()),
    ];

List<Override> _dailyVsJoyValueSoloOverrides() => [
      dailyVsJoySnapshotProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => Value(_snapshotValueSolo(), 13)),
    ];

List<Override> _dailyVsJoyValueGroupCompleteOverrides() => [
      dailyVsJoySnapshotProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => Value(_snapshotValueSolo(), 13)),
      dailyVsJoySnapshotFamilyProvider(
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith(
        (_) async => Value(_snapshotValueGroupFamily(), 30),
      ),
    ];

List<Override> _dailyVsJoyValueGroupFamilyEmptyOverrides() => [
      dailyVsJoySnapshotProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => Value(_snapshotValueSolo(), 13)),
      dailyVsJoySnapshotFamilyProvider(
        startDate: _startDate,
        endDate: _endDate,
      ).overrideWith((_) async => const Empty<DailyVsJoySnapshot>()),
    ];

// ---------------------------------------------------------------------------
// Sweep helper — runs the forbidden-substring sweep against the rendered
// widget tree. Embeds card / locale / state / substring in the failure
// reason for fast triage (per Plan acceptance criteria).
// ---------------------------------------------------------------------------

void _sweepForbiddenSubstrings({
  required Locale locale,
  required String card,
  required String state,
}) {
  for (final substring in _forbiddenFor(locale)) {
    expect(
      find.textContaining(substring, findRichText: true),
      findsNothing,
      reason:
          'D-14 anti-toxicity violation — $card / ${locale.languageCode} / $state — '
          'forbidden substring "$substring" leaked into rendered output. '
          'Either revert the offending ARB change or extend the locked '
          'forbidden list (requires CONTEXT D-14 update).',
    );
  }
}

void main() {
  // -------------------------------------------------------------------------
  // PerCategoryBreakdownCard — 3 locales × 4 states.
  // -------------------------------------------------------------------------
  group('D-14 / PerCategoryBreakdownCard / forbidden substring sweep', () {
    for (final locale in locales) {
      testWidgets(
        'PerCategoryBreakdownCard / ${locale.languageCode} / empty',
        (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              _buildPerCategoryCard(
                locale: locale,
                scope: PerCategoryScope.solo,
              ),
              locale: locale,
              overrides: _perCategoryEmptyOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          _sweepForbiddenSubstrings(
            locale: locale,
            card: 'PerCategoryBreakdownCard',
            state: 'empty',
          );
        },
      );

      testWidgets(
        'PerCategoryBreakdownCard / ${locale.languageCode} / sub_min_n',
        (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              _buildPerCategoryCard(
                locale: locale,
                scope: PerCategoryScope.solo,
              ),
              locale: locale,
              overrides: _perCategorySubMinNOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          _sweepForbiddenSubstrings(
            locale: locale,
            card: 'PerCategoryBreakdownCard',
            state: 'sub_min_n',
          );
        },
      );

      testWidgets(
        'PerCategoryBreakdownCard / ${locale.languageCode} / value_solo',
        (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              _buildPerCategoryCard(
                locale: locale,
                scope: PerCategoryScope.solo,
              ),
              locale: locale,
              overrides: _perCategoryValueSoloOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          _sweepForbiddenSubstrings(
            locale: locale,
            card: 'PerCategoryBreakdownCard',
            state: 'value_solo',
          );
        },
      );

      testWidgets(
        'PerCategoryBreakdownCard / ${locale.languageCode} / value_group',
        (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              _buildPerCategoryCard(
                locale: locale,
                scope: PerCategoryScope.family,
              ),
              locale: locale,
              overrides: _perCategoryValueGroupOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          _sweepForbiddenSubstrings(
            locale: locale,
            card: 'PerCategoryBreakdownCard',
            state: 'value_group',
          );
        },
      );
    }
  });

  // -------------------------------------------------------------------------
  // DailyVsJoyCard — 3 locales × 4 states.
  // -------------------------------------------------------------------------
  group('D-14 / DailyVsJoyCard / forbidden substring sweep', () {
    for (final locale in locales) {
      testWidgets(
        'DailyVsJoyCard / ${locale.languageCode} / empty',
        (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              _buildDailyVsJoyCard(locale: locale, isGroupMode: false),
              locale: locale,
              overrides: _dailyVsJoyEmptyOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          _sweepForbiddenSubstrings(
            locale: locale,
            card: 'DailyVsJoyCard',
            state: 'empty',
          );
        },
      );

      testWidgets(
        'DailyVsJoyCard / ${locale.languageCode} / value_solo',
        (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              _buildDailyVsJoyCard(locale: locale, isGroupMode: false),
              locale: locale,
              overrides: _dailyVsJoyValueSoloOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          _sweepForbiddenSubstrings(
            locale: locale,
            card: 'DailyVsJoyCard',
            state: 'value_solo',
          );
        },
      );

      testWidgets(
        'DailyVsJoyCard / ${locale.languageCode} / value_group_complete',
        (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              _buildDailyVsJoyCard(locale: locale, isGroupMode: true),
              locale: locale,
              overrides: _dailyVsJoyValueGroupCompleteOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          _sweepForbiddenSubstrings(
            locale: locale,
            card: 'DailyVsJoyCard',
            state: 'value_group_complete',
          );
        },
      );

      testWidgets(
        'DailyVsJoyCard / ${locale.languageCode} / value_group_family_empty',
        (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              _buildDailyVsJoyCard(locale: locale, isGroupMode: true),
              locale: locale,
              overrides: _dailyVsJoyValueGroupFamilyEmptyOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          _sweepForbiddenSubstrings(
            locale: locale,
            card: 'DailyVsJoyCard',
            state: 'value_group_family_empty',
          );
        },
      );
    }
  });
}
