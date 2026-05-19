@TestOn('vm')
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/expense_trend.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../helpers/happiness_test_fixtures.dart';
import '../../../../../helpers/test_localizations.dart';

const _bookId = 'book_001';

final _book = Book(
  id: _bookId,
  name: 'Main Book',
  currency: 'JPY',
  deviceId: 'device_local',
  createdAt: DateTime.utc(2026, 1),
);

const _distribution = [
  SatisfactionScoreBucket(score: 6, count: 2),
  SatisfactionScoreBucket(score: 8, count: 3),
  SatisfactionScoreBucket(score: 10, count: 1),
];

final _largestExpense = LargestMonthlyExpense(
  transactionId: 'tx_largest',
  amount: 18000,
  categoryId: 'cat_food',
  timestamp: DateTime.utc(2026, 5, 10),
);

const _expenseTrend = ExpenseTrendData(
  months: [
    MonthlyTrend(
      year: 2026,
      month: 1,
      totalExpenses: 110000,
      totalIncome: 290000,
    ),
    MonthlyTrend(
      year: 2026,
      month: 2,
      totalExpenses: 118000,
      totalIncome: 290000,
    ),
    MonthlyTrend(
      year: 2026,
      month: 3,
      totalExpenses: 132000,
      totalIncome: 300000,
    ),
    MonthlyTrend(
      year: 2026,
      month: 4,
      totalExpenses: 142800,
      totalIncome: 300000,
    ),
    MonthlyTrend(
      year: 2026,
      month: 5,
      totalExpenses: 150000,
      totalIncome: 300000,
    ),
  ],
);

class _TestSelectedTimeWindow extends SelectedTimeWindow {
  _TestSelectedTimeWindow();

  static TimeWindow fixedWindow = const TimeWindow.month(year: 2026, month: 5);

  @override
  TimeWindow build() => fixedWindow;
}

void main() {
  final variants = <String, TimeWindow>{
    'month': const TimeWindow.month(year: 2026, month: 5),
    'year': const TimeWindow.year(year: 2026),
    'quarter': const TimeWindow.quarter(year: 2026, quarter: 2),
    'week': TimeWindow.week(mondayStart: DateTime(2026, 5, 11)),
    'custom': TimeWindow.custom(
      startDate: DateTime(2026, 3, 15),
      endDate: DateTime(2026, 7, 20),
    ),
  };

  Widget buildSubject(TimeWindow window) {
    _TestSelectedTimeWindow.fixedWindow = window;
    final range = window.range;
    final trendAnchor = DateTime(range.end.year, range.end.month);

    return createLocalizedWidget(
      const AnalyticsScreen(bookId: _bookId),
      locale: const Locale('en'),
      overrides: [
        selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
        locale_providers.currentLocaleProvider.overrideWith(
          (_) async => const Locale('en'),
        ),
        accounting_providers
            .bookByIdProvider(bookId: _bookId)
            .overrideWith((_) async => _book),
        monthlyReportProvider(
          bookId: _bookId,
          startDate: range.start,
          endDate: range.end,
        ).overrideWith((_) async => fixtureMonthlyReportRich()),
        expenseTrendProvider(
          bookId: _bookId,
          anchor: trendAnchor,
        ).overrideWith((_) async => _expenseTrend),
        happinessReportProvider(
          bookId: _bookId,
          startDate: range.start,
          endDate: range.end,
          currencyCode: 'JPY',
        ).overrideWith((_) async => fixtureHappinessReportRich()),
        satisfactionDistributionProvider(
          bookId: _bookId,
          startDate: range.start,
          endDate: range.end,
        ).overrideWith((_) async => _distribution),
        bestJoyMomentProvider(
          bookId: _bookId,
          startDate: range.start,
          endDate: range.end,
        ).overrideWith((_) async => fixtureBestJoyResultRich()),
        largestMonthlyExpenseProvider(
          bookId: _bookId,
          startDate: range.start,
          endDate: range.end,
        ).overrideWith((_) async => _largestExpense),
        familyHappinessProvider(
          startDate: range.start,
          endDate: range.end,
        ).overrideWith((_) async => fixtureFamilyHappinessRich()),
        activeGroupProvider.overrideWith((_) => Stream.value(null)),
        isGroupModeProvider.overrideWith((_) => false),
        shadowBooksProvider.overrideWith((_) async => const []),
        earliestTransactionMonthProvider(
          bookId: _bookId,
        ).overrideWith((_) async => DateTime(2024, 12)),
      ],
    );
  }

  for (final entry in variants.entries) {
    testWidgets('AnalyticsScreen has no delta UI for ${entry.key} window', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(entry.value));
      await tester.pumpAndSettle();

      _expectNoDeltaUi();
    });
  }

  testWidgets(
    'AnalyticsScreen does not depend on retired analyticsKpiTotalDelta ARB keys',
    (tester) async {
      final generated = File(
        'lib/generated/app_localizations.dart',
      ).readAsStringSync();

      expect(generated.contains('analyticsKpiTotalDeltaIncreased'), isFalse);
      expect(generated.contains('analyticsKpiTotalDeltaDecreased'), isFalse);
    },
  );
}

void _expectNoDeltaUi() {
  expect(_textContaining('MoM'), findsNothing);
  expect(find.text('↑'), findsNothing);
  expect(find.text('↓'), findsNothing);
  expect(find.textContaining('vs last'), findsNothing);
  expect(find.textContaining('compared to'), findsNothing);
  expect(find.textContaining('previous'), findsNothing);
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget.runtimeType.toString().contains('Delta') ||
          widget.runtimeType.toString().contains('Comparison'),
    ),
    findsNothing,
  );
}

Finder _textContaining(String needle) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final text = widget.data ?? widget.textSpan?.toPlainText();
    return text?.contains(needle) ?? false;
  });
}
