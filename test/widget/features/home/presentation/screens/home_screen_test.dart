import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/home/presentation/providers/state_today_transactions.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:home_pocket/features/home/presentation/widgets/ledger_comparison_section.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';
import 'package:home_pocket/features/home/presentation/widgets/section_divider.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';
import 'package:home_pocket/features/home/presentation/widgets/transaction_list_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

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
    late MockGroupRepository groupRepository;
    late DateTime now;

    setUp(() {
      groupRepository = MockGroupRepository();
      now = DateTime.now();
      when(
        () => groupRepository.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(null));
    });

    Widget buildSubject({Locale locale = const Locale('ja')}) {
      return ProviderScope(
        overrides: [
          monthlyReportProvider(
            bookId: 'book_001',
            year: now.year,
            month: now.month,
          ).overrideWith((ref) async => _mockReport),
          todayTransactionsProvider(
            bookId: 'book_001',
          ).overrideWith((ref) async => []),
          groupRepositoryProvider.overrideWithValue(groupRepository),
        ],
        child: testLocalizedApp(
          locale: locale,
          child: const Scaffold(body: HomeScreen(bookId: 'book_001')),
        ),
      );
    }

    testWidgets('renders HeroHeader and MonthOverviewCard with mock data', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(HeroHeader), findsOneWidget);
      expect(find.byType(MonthOverviewCard), findsOneWidget);
    });

    testWidgets('does NOT contain BottomNavigationBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(HomeBottomNavBar), findsNothing);
    });

    testWidgets('renders section dividers', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SectionDivider), findsNWidgets(2));
      expect(
        find.text(
          S.of(tester.element(find.byType(HomeScreen))).homeMonthlyExpense,
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          S.of(tester.element(find.byType(HomeScreen))).homeLedgersSection,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Japanese localized home section labels', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final l10n = S.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.homeMonthlyExpense), findsOneWidget);
      expect(find.text(l10n.homeRecentTransactions), findsOneWidget);
    });

    testWidgets('renders English localized home section labels', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final l10n = S.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.homeMonthlyExpense), findsOneWidget);
      expect(find.text(l10n.homeRecentTransactions), findsOneWidget);
    });

    testWidgets('renders LedgerComparisonSection', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(LedgerComparisonSection), findsOneWidget);
    });

    testWidgets('renders SoulFullnessCard', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SoulFullnessCard), findsOneWidget);
    });

    testWidgets('renders transactions header row', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final l10n = S.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.homeRecentTransactions), findsOneWidget);
      expect(find.text(l10n.homeViewAllTransactions), findsOneWidget);
    });

    testWidgets('shows empty state when no transactions', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final l10n = S.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.noTransactionsYet), findsOneWidget);
      expect(find.byType(TransactionListCard), findsNothing);
    });

    testWidgets(
      'shows invite banner and personal mode when no active group exists',
      (tester) async {
        await tester.pumpWidget(buildSubject(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.byType(FamilyInviteBanner), findsOneWidget);
        expect(find.text('Personal Mode'), findsOneWidget);
      },
    );

    testWidgets(
      'hides invite banner and shows family mode when active group exists',
      (tester) async {
        when(
          () => groupRepository.watchActiveGroup(),
        ).thenAnswer((_) => Stream.value(_buildActiveGroup()));

        await tester.pumpWidget(buildSubject(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.byType(FamilyInviteBanner), findsNothing);
        expect(find.text('Family Mode'), findsOneWidget);
      },
    );

    testWidgets('uses flat layout without hero blue background', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // The old layout had a blue hero container background.
      // Child widgets may still use Stack internally (e.g. avatar overlap),
      // but the hero pattern is removed.
      final blueContainerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFF8AB8DA),
      );
      expect(blueContainerFinder, findsNothing);
    });

    testWidgets('wraps content in SingleChildScrollView', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    });
  });
}

GroupInfo _buildActiveGroup() {
  return GroupInfo(
    groupId: 'group-1',
    groupName: 'Test Family',
    status: GroupStatus.active,
    role: 'owner',
    members: const [],
    createdAt: DateTime(2026, 3, 14),
  );
}
