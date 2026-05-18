import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/state_today_transactions.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_hero_card.dart';
import 'package:home_pocket/features/home/presentation/widgets/transaction_list_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/happiness_test_fixtures.dart';
import '../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

final _mockBook = Book(
  id: 'book_001',
  name: 'Test Book',
  currency: 'JPY',
  deviceId: 'device_local',
  createdAt: DateTime.utc(2026, 1, 1),
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
          ).overrideWith((ref) async => fixtureMonthlyReportRich()),
          happinessReportProvider(
            bookId: 'book_001',
            year: now.year,
            month: now.month,
            currencyCode: 'JPY',
          ).overrideWith((ref) async => fixtureHappinessReportRich()),
          bestJoyMomentProvider(
            bookId: 'book_001',
            year: now.year,
            month: now.month,
          ).overrideWith((ref) async => fixtureBestJoyResultRich()),
          bookByIdProvider(
            bookId: 'book_001',
          ).overrideWith((ref) async => _mockBook),
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

    testWidgets('renders HeroHeader and HomeHeroCard with mock data', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(HeroHeader), findsOneWidget);
      expect(find.byType(HomeHeroCard), findsOneWidget);
    });

    testWidgets('does NOT contain BottomNavigationBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(HomeBottomNavBar), findsNothing);
    });

    testWidgets('renders Japanese localized home section labels', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final l10n = S.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.homeRecentTransactions), findsOneWidget);
    });

    testWidgets('renders English localized home section labels', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final l10n = S.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.homeRecentTransactions), findsOneWidget);
    });

    testWidgets('integrates the legacy month-overview, ledger-comparison, '
        'and soul-fullness cards into a single HomeHeroCard', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // The 3 legacy cards (month-overview / ledger-comparison /
      // soul-fullness) were collapsed into ONE HomeHeroCard composition.
      expect(find.byType(HomeHeroCard), findsOneWidget);
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
