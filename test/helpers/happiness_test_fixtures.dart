/// Shared test fixtures for Phase 10 (HomeHeroCard) tests.
///
/// Provides factory functions returning instances of Phase 9 contracts
/// (`HappinessReport`, `FamilyHappiness`, `BestJoyMomentRow`, `MetricResult`)
/// plus `MonthlyReport` and `ShadowBookInfo`/`ShadowAggregate` for the
/// home feature. Covers rich / thin-sample / empty / all-neutral states.
///
/// Used by:
///   - test/widget/features/home/presentation/widgets/home_hero_card_test.dart
///   - test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart
///   - test/golden/home_hero_card_golden_test.dart
///
/// Conventions:
///   - All factories are pure (no IO, no DateTime.now()) — fixed timestamps
///     for golden test stability.
///   - Synthetic test data only (no real device IDs, no PII).
///   - `const` constructors used wherever possible.
library;

import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/family_happiness.dart';
import 'package:home_pocket/features/analytics/domain/models/happiness_report.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/month_comparison.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/domain/models/shared_joy_insight.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';

/// Fixed reference timestamp used across MonthlyReport / Book fixtures so
/// repeated runs are deterministic for golden tests.
final DateTime _refCreatedAt = DateTime.utc(2026, 1, 1);

// ---------------------------------------------------------------------------
// MonthlyReport fixtures
// ---------------------------------------------------------------------------

/// Rich monthly report — typical month with totalExpenses=142,800.
MonthlyReport fixtureMonthlyReportRich({String bookId = 'book_001'}) {
  return MonthlyReport(
    year: 2026,
    month: 4,
    totalIncome: 300000,
    totalExpenses: 142800,
    savings: 157200,
    savingsRate: 52.4,
    survivalTotal: 102200,
    soulTotal: 40600,
    categoryBreakdowns: const [],
    dailyExpenses: const [],
    previousMonthComparison: const MonthComparison(
      previousMonth: 3,
      previousYear: 2026,
      previousIncome: 295000,
      previousExpenses: 137000,
      incomeChange: 1.7,
      expenseChange: 4.2,
    ),
  );
}

/// Empty monthly report — all totals zero (first run / blank book).
MonthlyReport fixtureMonthlyReportEmpty({String bookId = 'book_001'}) {
  return const MonthlyReport(
    year: 2026,
    month: 4,
    totalIncome: 0,
    totalExpenses: 0,
    savings: 0,
    savingsRate: 0,
    survivalTotal: 0,
    soulTotal: 0,
    categoryBreakdowns: [],
    dailyExpenses: [],
    previousMonthComparison: MonthComparison(
      previousMonth: 3,
      previousYear: 2026,
      previousIncome: 0,
      previousExpenses: 0,
      incomeChange: 0,
      expenseChange: 0,
    ),
  );
}

// ---------------------------------------------------------------------------
// HappinessReport fixtures
// ---------------------------------------------------------------------------

/// Rich personal happiness report — totalSoulTx=31, all 4 metrics Value.
HappinessReport fixtureHappinessReportRich({String bookId = 'book_001'}) {
  return HappinessReport(
    year: 2026,
    month: 4,
    bookId: bookId,
    totalSoulTx: 31,
    avgSatisfaction: const Value(7.8, 23),
    medianSatisfaction: const Value(8.0, 23),
    joyContribution: const Value(78.4, 23),
    highlightsCount: const Value(12, 23),
    topJoy: Value(fixtureBestJoyMomentRich(), 23),
  );
}

/// Thin-sample happiness report — totalSoulTx=3, sample size 3 across the
/// MetricResult.Value cases. Drives the n<5 coverage caption test.
HappinessReport fixtureHappinessReportThin({String bookId = 'book_001'}) {
  return HappinessReport(
    year: 2026,
    month: 4,
    bookId: bookId,
    totalSoulTx: 3,
    avgSatisfaction: const Value(7.8, 3),
    medianSatisfaction: const Value(8.0, 3),
    joyContribution: const Value(12.0, 3),
    highlightsCount: const Value(1, 3),
    topJoy: Value(fixtureBestJoyMomentRich(), 3),
  );
}

/// Empty happiness report — totalSoulTx=0; all 5 MetricResult fields Empty.
HappinessReport fixtureHappinessReportEmpty({String bookId = 'book_001'}) {
  return HappinessReport(
    year: 2026,
    month: 4,
    bookId: bookId,
    totalSoulTx: 0,
    avgSatisfaction: const Empty(),
    medianSatisfaction: const Empty(),
    joyContribution: const Empty(),
    highlightsCount: const Empty(),
    topJoy: const Empty(),
  );
}

// ---------------------------------------------------------------------------
// FamilyHappiness fixtures
// ---------------------------------------------------------------------------

/// Rich family happiness — familyHighlightsSum=27, sharedJoyInsight=Value,
/// medianSatisfaction=Value (all 3 main metrics populated).
FamilyHappiness fixtureFamilyHappinessRich() {
  return FamilyHappiness(
    year: 2026,
    month: 4,
    totalGroupSoulTx: 18,
    familyHighlightsSum: const Value(27, 18),
    sharedJoyInsight: Value(fixtureSharedJoyInsightRich(), 18),
    medianSatisfaction: const Value(8.0, 18),
  );
}

/// Empty family happiness — all 3 main MetricResult fields Empty.
FamilyHappiness fixtureFamilyHappinessEmpty() {
  return const FamilyHappiness(
    year: 2026,
    month: 4,
    totalGroupSoulTx: 0,
    familyHighlightsSum: Empty(),
    sharedJoyInsight: Empty(),
    medianSatisfaction: Empty(),
  );
}

// ---------------------------------------------------------------------------
// BestJoyMomentRow fixtures
// ---------------------------------------------------------------------------

/// Rich best-joy moment — ¥3,000 coffee with joyFullness=10.
BestJoyMomentRow fixtureBestJoyMomentRich() {
  return BestJoyMomentRow(
    transactionId: 'tx_best_001',
    amount: 3000,
    joyFullness: 10,
    categoryId: 'cat_coffee',
    timestamp: DateTime.utc(2026, 4, 15, 14, 30),
  );
}

/// All-neutral best-joy moment — ¥10,000 large purchase with sat=2 (D-09 CTA).
BestJoyMomentRow fixtureBestJoyMomentAllNeutral() {
  return BestJoyMomentRow(
    transactionId: 'tx_neutral_001',
    amount: 10000,
    joyFullness: 2,
    categoryId: 'cat_shopping',
    timestamp: DateTime.utc(2026, 4, 20, 10, 0),
  );
}

// ---------------------------------------------------------------------------
// MetricResult<BestJoyMomentRow> wrappers
// ---------------------------------------------------------------------------

MetricResult<BestJoyMomentRow> fixtureBestJoyResultRich() =>
    Value(fixtureBestJoyMomentRich(), 31);

MetricResult<BestJoyMomentRow> fixtureBestJoyResultThin() =>
    Value(fixtureBestJoyMomentRich(), 3);

MetricResult<BestJoyMomentRow> fixtureBestJoyResultEmpty() => const Empty();

MetricResult<BestJoyMomentRow> fixtureBestJoyResultAllNeutral() =>
    Value(fixtureBestJoyMomentAllNeutral(), 5);

// ---------------------------------------------------------------------------
// SharedJoyInsight fixture
// ---------------------------------------------------------------------------

SharedJoyInsight fixtureSharedJoyInsightRich() {
  return const SharedJoyInsight(
    categoryId: 'cat_coffee',
    avgSatisfaction: 8.5,
    totalCount: 8,
  );
}

// ---------------------------------------------------------------------------
// ShadowBookInfo / ShadowAggregate fixtures
// ---------------------------------------------------------------------------

/// 3 shadow books for group-mode rendering — alphabetical by display name
/// (stable ordering for golden tests; honors RESEARCH Pitfall 8).
List<ShadowBookInfo> fixtureShadowBooksThree() {
  return [
    ShadowBookInfo(
      book: Book(
        id: 'shadow_001',
        name: 'TestMember1 Book',
        currency: 'JPY',
        deviceId: 'device_local',
        createdAt: _refCreatedAt,
        isShadow: true,
        groupId: 'group_test',
        ownerDeviceId: 'device_member1',
        ownerDeviceName: 'TestMember1 Device',
      ),
      memberDisplayName: 'TestMember1',
      memberAvatarEmoji: '🦊',
    ),
    ShadowBookInfo(
      book: Book(
        id: 'shadow_002',
        name: 'TestMember2 Book',
        currency: 'JPY',
        deviceId: 'device_local',
        createdAt: _refCreatedAt,
        isShadow: true,
        groupId: 'group_test',
        ownerDeviceId: 'device_member2',
        ownerDeviceName: 'TestMember2 Device',
      ),
      memberDisplayName: 'TestMember2',
      memberAvatarEmoji: '🐻',
    ),
    ShadowBookInfo(
      book: Book(
        id: 'shadow_003',
        name: 'TestMember3 Book',
        currency: 'JPY',
        deviceId: 'device_local',
        createdAt: _refCreatedAt,
        isShadow: true,
        groupId: 'group_test',
        ownerDeviceId: 'device_member3',
        ownerDeviceName: 'TestMember3 Device',
      ),
      memberDisplayName: 'TestMember3',
      memberAvatarEmoji: '🐼',
    ),
  ];
}

/// Aggregate matching `fixtureShadowBooksThree` — totalExpenses=72,500.
ShadowAggregate fixtureShadowAggregateThree() {
  return ShadowAggregate(
    totalExpenses: 72500,
    prevTotalExpenses: 68000,
    perBookReports: {
      'shadow_001': MonthlyReport(
        year: 2026,
        month: 4,
        totalIncome: 0,
        totalExpenses: 25000,
        savings: 0,
        savingsRate: 0,
        survivalTotal: 18000,
        soulTotal: 7000,
        categoryBreakdowns: const [],
        dailyExpenses: const [],
        previousMonthComparison: const MonthComparison(
          previousMonth: 3,
          previousYear: 2026,
          previousIncome: 0,
          previousExpenses: 23000,
          incomeChange: 0,
          expenseChange: 8.7,
        ),
      ),
      'shadow_002': MonthlyReport(
        year: 2026,
        month: 4,
        totalIncome: 0,
        totalExpenses: 20500,
        savings: 0,
        savingsRate: 0,
        survivalTotal: 15500,
        soulTotal: 5000,
        categoryBreakdowns: const [],
        dailyExpenses: const [],
        previousMonthComparison: const MonthComparison(
          previousMonth: 3,
          previousYear: 2026,
          previousIncome: 0,
          previousExpenses: 19000,
          incomeChange: 0,
          expenseChange: 7.9,
        ),
      ),
      'shadow_003': MonthlyReport(
        year: 2026,
        month: 4,
        totalIncome: 0,
        totalExpenses: 27000,
        savings: 0,
        savingsRate: 0,
        survivalTotal: 20000,
        soulTotal: 7000,
        categoryBreakdowns: const [],
        dailyExpenses: const [],
        previousMonthComparison: const MonthComparison(
          previousMonth: 3,
          previousYear: 2026,
          previousIncome: 0,
          previousExpenses: 26000,
          incomeChange: 0,
          expenseChange: 3.8,
        ),
      ),
    },
  );
}

/// Empty list — for "group mode + 0 shadow books" minimum-gate D-08 case.
List<ShadowBookInfo> fixtureShadowBooksEmpty() => const [];
