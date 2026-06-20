import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/joy_category_amount.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/domain/models/per_day_joy_count.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/category_donut_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_calendar_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_spend_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/within_month_trend_card.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../helpers/test_localizations.dart';

/// D-14 anti-toxicity widget sweep — Phase 47 (GUARD-02 wording-layer +
/// GUARD-03). Verifies that the FIVE round-5 B AnalyticsScreen cards
/// (WithinMonthTrendCard / CategoryDonutCard / JoySpendCard / JoyCalendarCard /
/// SatisfactionHistogramCard) never leak forbidden value-judgment / comparison /
/// ranking / streak / target substrings into rendered output in any of the
/// three supported locales (en / ja / zh) across the canonical user-visible
/// state matrix (default/value, empty, the WR-02 >10-L1 "Other" donut state, and
/// the calendar inline-expand panel state).
///
/// Rationale (CONTEXT D-14 + the Phase 43 GATE round-5 B lineup):
/// Anti-toxicity intent is a "compile-and-test gate" (automated, audit-friendly)
/// rather than manual copy review. The test pumps the WHOLE card for each state
/// so future ARB additions are auto-vetted. Depends on 47-01/02 so the cards
/// under sweep already carry the WR fixes (notably WR-02's neutral "Other"
/// label, which MUST be exercised and pass — D-03).
///
/// Failure modes are silent: a single locale slipping a "比較" header would ship
/// a regression unnoticed without this sweep.

// ---------------------------------------------------------------------------
// LOCKED forbidden substring lists — COPIED VERBATIM from
// anti_toxicity_phase16_test.dart (lines 33-78). Do NOT relax these without an
// explicit product/ADR sign-off (D-13). If a card's copy trips a forbidden
// substring, fix the COPY (escalate) — never shrink the list.
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
// Card harness constants. MONTH-anchored window so the month-keyed providers
// (within-month trend, per-day joy counts) resolve to a stable family key.
// ---------------------------------------------------------------------------

const _bookId = 'book-a';
final _startDate = DateTime(2026, 5);
final _endDate = DateTime(2026, 5, 31, 23, 59, 59);
// Month anchor the trend / calendar providers re-derive (DateTime(year, month)).
final _anchor = DateTime(2026, 5);
const _variant = JoyMetricVariant.all;

// ---------------------------------------------------------------------------
// Fixtures — FICTIONAL deterministic data (T-47-04-01: never seeded from real
// user financial data). Seeded from the 43-01 simulated sample-data numbers.
// ---------------------------------------------------------------------------

CumulativePoint _pt(int day, int amount) =>
    CumulativePoint(day: day, cumulativeAmount: amount);

WithinMonthCumulativeTrend _trendValue() => WithinMonthCumulativeTrend(
  currentMonthTotal: [_pt(3, 4000), _pt(12, 18000), _pt(20, 27000)],
  currentMonthDaily: [_pt(3, 3000), _pt(12, 12000), _pt(20, 18000)],
  currentMonthJoy: [_pt(3, 1000), _pt(12, 6000), _pt(20, 9000)],
  previousMonthTotal: [_pt(5, 5000), _pt(15, 16000), _pt(28, 26000)],
  previousMonthDaily: [_pt(5, 4000), _pt(15, 11000), _pt(28, 17000)],
);

WithinMonthCumulativeTrend _trendEmpty() => const WithinMonthCumulativeTrend(
  currentMonthTotal: [],
  currentMonthDaily: [],
  currentMonthJoy: [],
  previousMonthTotal: [],
  previousMonthDaily: [],
);

Category _cat(String id, {String? parent, required int level}) => Category(
  id: id,
  name: id,
  icon: 'icon',
  color: '#000000',
  parentId: parent,
  level: level,
  createdAt: DateTime(2026),
);

CategoryBreakdown _bd(String id, int amount) => CategoryBreakdown(
  categoryId: id,
  categoryName: id,
  icon: 'icon',
  color: '#000000',
  amount: amount,
  percentage: 0,
  transactionCount: 1,
);

MonthlyReport _report({
  required List<CategoryBreakdown> breakdowns,
  required int totalExpenses,
}) => MonthlyReport(
  year: 2026,
  month: 5,
  totalIncome: 0,
  totalExpenses: totalExpenses,
  savings: 0,
  savingsRate: 0,
  dailyTotal: totalExpenses,
  joyTotal: 0,
  categoryBreakdowns: breakdowns,
  dailyExpenses: const [],
);

// A modest <=10-L1 value report.
final _donutValueBreakdowns = [
  _bd('cat_food_lunch', 18000),
  _bd('cat_transport', 9000),
  _bd('cat_hobbies', 3000),
];

final _donutValueMap = <String, Category>{
  'cat_food': _cat('cat_food', level: 1),
  'cat_food_lunch': _cat('cat_food_lunch', parent: 'cat_food', level: 2),
  'cat_transport': _cat('cat_transport', level: 1),
  'cat_hobbies': _cat('cat_hobbies', level: 1),
};

// WR-02 / D-03: 12 distinct L1 categories so the rollup truncates to top-10 and
// the neutral "Other" (その他/其他/Other) long-tail slice + legend row renders.
final _donutOtherMap = <String, Category>{
  for (var i = 0; i < 12; i++) 'cat_$i': _cat('cat_$i', level: 1),
};
final _donutOtherBreakdowns = [
  for (var i = 0; i < 12; i++) _bd('cat_$i', 1000),
];

List<JoyCategoryAmount> _joyAmountsValue() => const [
  JoyCategoryAmount(categoryId: 'cat_hobbies', amount: 6000),
  JoyCategoryAmount(categoryId: 'cat_food', amount: 3000),
  JoyCategoryAmount(categoryId: 'cat_social', amount: 1500),
];

List<PerDayJoyCount> _joyCountsValue() => [
  PerDayJoyCount(date: DateTime(2026, 5, 3), count: 1),
  PerDayJoyCount(date: DateTime(2026, 5, 12), count: 4),
  PerDayJoyCount(date: DateTime(2026, 5, 20), count: 2),
];

Transaction _tx(String id, DateTime ts) => Transaction(
  id: id,
  bookId: _bookId,
  deviceId: 'dev',
  amount: 1200,
  type: TransactionType.expense,
  categoryId: 'cat_hobbies',
  ledgerType: LedgerType.joy,
  timestamp: ts,
  currentHash: 'h',
  createdAt: ts,
  joyFullness: 7,
  entrySource: EntrySource.manual,
);

MetricResult<T> _m<T>(T data, int n) => Value(data, n);

// A `totalJoyTx >= 5` happiness report so the histogram card does NOT self-hide.
HappinessReport _happinessVisible() => HappinessReport(
  year: 2026,
  month: 5,
  bookId: _bookId,
  totalJoyTx: 9,
  avgSatisfaction: _m(7.4, 9),
  joyContribution: _m(0.42, 9),
  medianSatisfaction: _m(7.0, 9),
  highlightsCount: _m(3, 9),
  topJoy: _m(
    BestJoyMomentRow(
      transactionId: 't-top',
      amount: 4200,
      joyFullness: 9,
      categoryId: 'cat_hobbies',
      timestamp: DateTime(2026, 5, 12),
    ),
    9,
  ),
);

List<SatisfactionScoreBucket> _bucketsValue() => const [
  SatisfactionScoreBucket(score: 1, count: 0),
  SatisfactionScoreBucket(score: 2, count: 1),
  SatisfactionScoreBucket(score: 3, count: 2),
  SatisfactionScoreBucket(score: 4, count: 3),
  SatisfactionScoreBucket(score: 5, count: 3),
];

// ---------------------------------------------------------------------------
// Subject builders — each card wrapped in a SingleChildScrollView so off-screen
// legend rows / inline panels still build (the bare card overflows the 800x600
// test viewport once 10 L1 rows + Other are shown).
// ---------------------------------------------------------------------------

Widget _scrollable(Widget card) =>
    Scaffold(body: SingleChildScrollView(child: card));

Widget _withinMonthTrendCard() => _scrollable(
  WithinMonthTrendCard(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ),
);

Widget _categoryDonutCard() => _scrollable(
  CategoryDonutCard(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ),
);

Widget _joySpendCard() => _scrollable(
  JoySpendCard(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ),
);

Widget _joyCalendarCard() => _scrollable(
  JoyCalendarCard(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ),
);

Widget _satisfactionHistogramCard() => _scrollable(
  SatisfactionHistogramCard(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ),
);

// ---------------------------------------------------------------------------
// Override builders — each state's override list is LOCAL and COMPLETE so a
// missing override is LOUD (the unoverridden auto-dispose provider would throw
// at runtime instead of silently passing the sweep — RESEARCH Pitfall 1). The
// locale override is included everywhere so card copy resolves in the swept
// locale (currentLocaleProvider drives CategoryLocalizationService + ¥ format).
// ---------------------------------------------------------------------------

Override _localeOverride(Locale locale) =>
    locale_providers.currentLocaleProvider.overrideWith((_) async => locale);

List<Override> _trendValueOverrides(Locale locale) => [
  _localeOverride(locale),
  withinMonthCumulativeTrendProvider(
    bookId: _bookId,
    anchor: _anchor,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => _trendValue()),
];

List<Override> _trendEmptyOverrides(Locale locale) => [
  _localeOverride(locale),
  withinMonthCumulativeTrendProvider(
    bookId: _bookId,
    anchor: _anchor,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => _trendEmpty()),
];

List<Override> _donutValueOverrides(Locale locale) => [
  _localeOverride(locale),
  monthlyReportProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith(
    (_) async => _report(
      breakdowns: _donutValueBreakdowns,
      totalExpenses: 30000,
    ),
  ),
  analyticsCategoriesMapProvider.overrideWith((_) async => _donutValueMap),
  // D2: the donut now nests the 悦己 joybar drawer, which watches
  // joyCategoryAmountsProvider — override it so the drawer copy is swept.
  joyCategoryAmountsProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => _joyAmountsValue()),
];

List<Override> _donutEmptyOverrides(Locale locale) => [
  _localeOverride(locale),
  monthlyReportProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith(
    (_) async => _report(breakdowns: const [], totalExpenses: 0),
  ),
  analyticsCategoriesMapProvider.overrideWith(
    (_) async => const <String, Category>{},
  ),
  joyCategoryAmountsProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => const <JoyCategoryAmount>[]),
];

// WR-02 / D-03: >10 L1 categories → the neutral "Other" long-tail row renders.
List<Override> _donutOtherOverrides(Locale locale) => [
  _localeOverride(locale),
  monthlyReportProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith(
    (_) async => _report(
      breakdowns: _donutOtherBreakdowns,
      // True total 12000 (full 12-cat spend); donut keeps top 10 (10000),
      // Other = 2000.
      totalExpenses: 12000,
    ),
  ),
  analyticsCategoriesMapProvider.overrideWith((_) async => _donutOtherMap),
  joyCategoryAmountsProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => _joyAmountsValue()),
];

List<Override> _joySpendValueOverrides(Locale locale) => [
  _localeOverride(locale),
  joyCategoryAmountsProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => _joyAmountsValue()),
];

List<Override> _joySpendEmptyOverrides(Locale locale) => [
  _localeOverride(locale),
  joyCategoryAmountsProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => const <JoyCategoryAmount>[]),
];

List<Override> _joyCalendarValueOverrides(Locale locale) => [
  _localeOverride(locale),
  perDayJoyCountsProvider(
    bookId: _bookId,
    anchor: _anchor,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => _joyCountsValue()),
  // Day-keyed inline-expand reads (local _JoyCalendarBody state, see sweep).
  joyDayTransactionsProvider(
    bookId: _bookId,
    day: DateTime(2026, 5, 12),
    joyMetricVariant: _variant,
  ).overrideWith(
    (_) async => [
      _tx('t1', DateTime(2026, 5, 12, 10)),
      _tx('t2', DateTime(2026, 5, 12, 14)),
    ],
  ),
];

List<Override> _joyCalendarEmptyOverrides(Locale locale) => [
  _localeOverride(locale),
  perDayJoyCountsProvider(
    bookId: _bookId,
    anchor: _anchor,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => const <PerDayJoyCount>[]),
];

List<Override> _histogramValueOverrides(Locale locale) => [
  _localeOverride(locale),
  happinessReportProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    currencyCode: 'JPY',
    joyMetricVariant: _variant,
  ).overrideWith((_) async => _happinessVisible()),
  satisfactionDistributionProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => _bucketsValue()),
];

List<Override> _histogramEmptyOverrides(Locale locale) => [
  _localeOverride(locale),
  happinessReportProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    currencyCode: 'JPY',
    joyMetricVariant: _variant,
  ).overrideWith(
    (_) async =>
        // totalJoyTx < 5 → the card self-hides (SizedBox.shrink); still a valid
        // user-visible state to sweep (it renders nothing forbidden).
        _happinessVisible().copyWith(totalJoyTx: 0),
  ),
  satisfactionDistributionProvider(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    joyMetricVariant: _variant,
  ).overrideWith((_) async => const <SatisfactionScoreBucket>[]),
];

// ---------------------------------------------------------------------------
// Sweep helper — COPIED VERBATIM (intent) from anti_toxicity_phase16_test.dart
// (lines 269-285). Embeds card / locale / state / substring in the failure
// reason for fast triage.
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

/// Asserts the card actually rendered SOME visible non-empty text, so a
/// silently-failed override (e.g. the card stuck in loading/error) cannot mask
/// the sweep into a trivial pass (RESEARCH Pitfall 1). Skipped for self-hidden
/// states (the histogram <5 self-hide renders nothing by design).
void _expectRenderedText() {
  final textWidgets = find.byWidgetPredicate(
    (w) => w is Text && (w.data?.trim().isNotEmpty ?? false),
  );
  expect(
    textWidgets,
    findsWidgets,
    reason:
        'sweep coverage guard — the card rendered no visible text, so the '
        'forbidden-substring sweep would trivially pass. A required provider '
        'override is likely missing (the card is stuck loading/error).',
  );
}

void main() {
  // -------------------------------------------------------------------------
  // WithinMonthTrendCard — 3 locales × {value, empty}.
  // -------------------------------------------------------------------------
  group('D-14 / WithinMonthTrendCard / forbidden substring sweep', () {
    for (final locale in locales) {
      testWidgets('WithinMonthTrendCard / ${locale.languageCode} / value', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _withinMonthTrendCard(),
            locale: locale,
            overrides: _trendValueOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'WithinMonthTrendCard',
          state: 'value',
        );
      });

      testWidgets('WithinMonthTrendCard / ${locale.languageCode} / empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _withinMonthTrendCard(),
            locale: locale,
            overrides: _trendEmptyOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'WithinMonthTrendCard',
          state: 'empty',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // CategoryDonutCard — 3 locales × {value, empty, other (>10 L1, WR-02/D-03)}.
  // -------------------------------------------------------------------------
  group('D-14 / CategoryDonutCard / forbidden substring sweep', () {
    for (final locale in locales) {
      testWidgets('CategoryDonutCard / ${locale.languageCode} / value', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _categoryDonutCard(),
            locale: locale,
            overrides: _donutValueOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'CategoryDonutCard',
          state: 'value',
        );
      });

      testWidgets('CategoryDonutCard / ${locale.languageCode} / empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _categoryDonutCard(),
            locale: locale,
            overrides: _donutEmptyOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'CategoryDonutCard',
          state: 'empty',
        );
      });

      // WR-02 / D-03: the >10-L1 "Other" long-tail row MUST be exercised so the
      // neutral analyticsCategoryDonutOther label (その他/其他/Other) sweeps clean.
      testWidgets('CategoryDonutCard / ${locale.languageCode} / other_rollup', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _categoryDonutCard(),
            locale: locale,
            overrides: _donutOtherOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        // Confirm the Other state actually rendered (coverage guard).
        expect(
          find.byKey(const ValueKey('donut_legend_row_other')),
          findsOneWidget,
          reason: 'WR-02 / D-03 — the >10-L1 "Other" rollup row must render so '
              'the analyticsCategoryDonutOther label is swept.',
        );
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'CategoryDonutCard',
          state: 'other_rollup',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // JoySpendCard — 3 locales × {value, empty}.
  // -------------------------------------------------------------------------
  group('D-14 / JoySpendCard / forbidden substring sweep', () {
    for (final locale in locales) {
      testWidgets('JoySpendCard / ${locale.languageCode} / value', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _joySpendCard(),
            locale: locale,
            overrides: _joySpendValueOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'JoySpendCard',
          state: 'value',
        );
      });

      testWidgets('JoySpendCard / ${locale.languageCode} / empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _joySpendCard(),
            locale: locale,
            overrides: _joySpendEmptyOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'JoySpendCard',
          state: 'empty',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // JoyCalendarCard — 3 locales × {value, inline_expand, empty}.
  // The inline_expand state taps a day to grow the _InlineDayPanel in place
  // (D-C1) before sweeping, so the day's joy一刻 list copy is swept too.
  // -------------------------------------------------------------------------
  group('D-14 / JoyCalendarCard / forbidden substring sweep', () {
    for (final locale in locales) {
      testWidgets('JoyCalendarCard / ${locale.languageCode} / value', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _joyCalendarCard(),
            locale: locale,
            overrides: _joyCalendarValueOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'JoyCalendarCard',
          state: 'value',
        );
      });

      testWidgets('JoyCalendarCard / ${locale.languageCode} / inline_expand', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _joyCalendarCard(),
            locale: locale,
            overrides: _joyCalendarValueOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        // Tap a day WITH joy to grow the inline panel in place (D-C1).
        await tester.tap(find.byKey(const ValueKey('joy_day_12')));
        await tester.pumpAndSettle();

        // Coverage guard: the inline panel actually expanded before the sweep.
        expect(
          find.byKey(const ValueKey('joy_calendar_inline_panel')),
          findsOneWidget,
          reason: 'D-C1 — the inline day panel must expand so its joy一刻 list '
              'copy is swept.',
        );
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'JoyCalendarCard',
          state: 'inline_expand',
        );
      });

      testWidgets('JoyCalendarCard / ${locale.languageCode} / empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _joyCalendarCard(),
            locale: locale,
            overrides: _joyCalendarEmptyOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'JoyCalendarCard',
          state: 'empty',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // SatisfactionHistogramCard — 3 locales × {value (totalJoyTx>=5), self_hide}.
  // -------------------------------------------------------------------------
  group('D-14 / SatisfactionHistogramCard / forbidden substring sweep', () {
    for (final locale in locales) {
      testWidgets('SatisfactionHistogramCard / ${locale.languageCode} / value',
          (tester) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _satisfactionHistogramCard(),
            locale: locale,
            overrides: _histogramValueOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _expectRenderedText();
        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'SatisfactionHistogramCard',
          state: 'value',
        );
      });

      // totalJoyTx < 5 → the card self-hides (renders nothing). Still swept to
      // confirm the hidden state never leaks a forbidden substring.
      testWidgets(
          'SatisfactionHistogramCard / ${locale.languageCode} / self_hide',
          (tester) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _satisfactionHistogramCard(),
            locale: locale,
            overrides: _histogramEmptyOverrides(locale),
          ),
        );
        await tester.pumpAndSettle();

        _sweepForbiddenSubstrings(
          locale: locale,
          card: 'SatisfactionHistogramCard',
          state: 'self_hide',
        );
      });
    }
  });
}
