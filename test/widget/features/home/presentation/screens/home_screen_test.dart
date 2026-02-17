import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/home_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/today_transactions_provider.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';

import '../../helpers/test_localizations.dart';

final _mockReport = MonthlyReport(
  year: 2026,
  month: 2,
  totalIncome: 300000,
  totalExpenses: 142800,
  savings: 157200,
  savingsRate: 52.4,
  survivalTotal: 102200,
  soulTotal: 40600,
  categoryBreakdowns: [],
  dailyExpenses: [],
);

void main() {
  group('HomeScreen', () {
    testWidgets('renders HeroHeader and MonthOverviewCard with mock data', (
      tester,
    ) async {
      final now = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monthlyReportProvider(
              bookId: 'book_001',
              year: now.year,
              month: now.month,
            ).overrideWith((ref) async => _mockReport),
            todayTransactionsProvider(
              bookId: 'book_001',
            ).overrideWith((ref) async => []),
            ohtaniConverterVisibleProvider.overrideWith(
              () => OhtaniConverterVisible(),
            ),
          ],
          child: testLocalizedApp(
            child: const Scaffold(body: HomeScreen(bookId: 'book_001')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HeroHeader), findsOneWidget);
      expect(find.byType(MonthOverviewCard), findsOneWidget);
    });

    testWidgets('does NOT contain BottomNavigationBar', (tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monthlyReportProvider(
              bookId: 'book_001',
              year: now.year,
              month: now.month,
            ).overrideWith((ref) async => _mockReport),
            todayTransactionsProvider(
              bookId: 'book_001',
            ).overrideWith((ref) async => []),
            ohtaniConverterVisibleProvider.overrideWith(
              () => OhtaniConverterVisible(),
            ),
          ],
          child: testLocalizedApp(
            child: const Scaffold(body: HomeScreen(bookId: 'book_001')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(HomeBottomNavBar), findsNothing);
    });
  });
}
