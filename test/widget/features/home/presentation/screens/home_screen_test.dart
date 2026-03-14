import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/home_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/today_transactions_provider.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';
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
          ohtaniConverterVisibleProvider.overrideWith(
            () => OhtaniConverterVisible(),
          ),
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
  });
}

GroupInfo _buildActiveGroup() {
  return GroupInfo(
    groupId: 'group-1',
    status: GroupStatus.active,
    role: 'owner',
    members: const [],
    createdAt: DateTime(2026, 3, 14),
  );
}
