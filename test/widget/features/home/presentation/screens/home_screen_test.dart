import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_edit_screen.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/state_home.dart';
import 'package:home_pocket/features/home/presentation/providers/state_today_transactions.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_hero_card.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';
import 'package:home_pocket/features/home/presentation/widgets/transaction_list_card.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/happiness_test_fixtures.dart';
import '../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class _MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class _FakeUpdateTransactionParams extends Fake
    implements UpdateTransactionParams {}

/// Always returns empty/null — lets TransactionEditScreen build without a real DB.
class _NullCategoryRepository implements CategoryRepository {
  @override
  Future<Category?> findById(String id) async => null;
  @override
  Future<List<Category>> findAll() async => [];
  @override
  Future<List<Category>> findActive() async => [];
  @override
  Future<List<Category>> findByLevel(int level) async => [];
  @override
  Future<List<Category>> findByParent(String parentId) async => [];
  @override
  Future<void> insert(Category category) async {}
  @override
  Future<void> insertBatch(List<Category> categories) async {}
  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}
  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
  @override
  Future<void> deleteAll() async {}
}

class _NullLedgerConfigRepository implements CategoryLedgerConfigRepository {
  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async => null;
  @override
  Future<List<CategoryLedgerConfig>> findAll() async => [];
  @override
  Future<void> upsert(CategoryLedgerConfig config) async {}
  @override
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs) async {}
  @override
  Future<void> delete(String categoryId) async {}
  @override
  Future<void> deleteAll() async {}
}

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
    late DateTime currentMonthStart;
    late DateTime currentMonthEnd;

    setUp(() {
      groupRepository = MockGroupRepository();
      now = DateTime.now();
      currentMonthStart = DateTime(now.year, now.month);
      currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      when(
        () => groupRepository.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(null));
    });

    Widget buildSubject({
      Locale locale = const Locale('ja'),
      List<Transaction> transactions = const [],
    }) {
      return ProviderScope(
        overrides: [
          monthlyReportProvider(
            bookId: 'book_001',
            startDate: currentMonthStart,
            endDate: currentMonthEnd,
          ).overrideWith((ref) async => fixtureMonthlyReportRich()),
          happinessReportProvider(
            bookId: 'book_001',
            startDate: currentMonthStart,
            endDate: currentMonthEnd,
            currencyCode: 'JPY',
          ).overrideWith((ref) async => fixtureHappinessReportRich()),
          bestJoyMomentProvider(
            bookId: 'book_001',
            startDate: currentMonthStart,
            endDate: currentMonthEnd,
          ).overrideWith((ref) async => fixtureBestJoyResultRich()),
          bookByIdProvider(
            bookId: 'book_001',
          ).overrideWith((ref) async => _mockBook),
          todayTransactionsProvider(
            bookId: 'book_001',
          ).overrideWith((ref) async => transactions),
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
        'and joy-fullness cards into a single HomeHeroCard', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // The 3 legacy cards (month-overview / ledger-comparison /
      // joy-fullness) were collapsed into ONE HomeHeroCard composition.
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
        expect(find.text('Personal'), findsOneWidget);
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
        expect(find.text('Family'), findsOneWidget);
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

    testWidgets('renders transaction tiles for daily and joy entries', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(transactions: [_buildTx(daily: true), _buildTx()]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionListCard), findsOneWidget);
      expect(find.byType(HomeTransactionTile), findsNWidgets(2));
      // Merchant text from the fixture is rendered through the tile.
      expect(find.text('Supermarket'), findsOneWidget);
      expect(find.text('Cinema'), findsOneWidget);
    });

    testWidgets('group mode tags tiles with member initial from device id', (
      tester,
    ) async {
      when(
        () => groupRepository.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(_buildActiveGroup()));

      await tester.pumpWidget(
        buildSubject(transactions: [_buildTx(daily: true)]),
      );
      await tester.pumpAndSettle();

      // _memberInitial: first char of deviceId, uppercased.
      expect(find.byType(HomeTransactionTile), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('view-all tap selects list tab and current month filter', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(HomeScreen));
      final container = ProviderScope.containerOf(element, listen: false);
      final l10n = S.of(element);
      final viewAll = find.text(l10n.homeViewAllTransactions);
      await tester.ensureVisible(viewAll);
      await tester.pumpAndSettle();
      await tester.tap(viewAll);
      await tester.pumpAndSettle();

      expect(container.read(selectedTabIndexProvider), 1);
      final filter = container.read(listFilterProvider);
      expect(filter.selectedYear, now.year);
      expect(filter.selectedMonth, now.month);
    });

    // Regression (quick 260613-wjx): tapping a recent tile, editing, and
    // returning with a save/delete (pop result == true) MUST refresh the Home
    // list. Before the fix, home_screen's onTap fired Navigator.push
    // fire-and-forget — the edit persisted to the DB but todayTransactionsProvider
    // kept serving its cached value, so the change looked like it "didn't take
    // effect" (mirrors the contract list_screen already honors).
    testWidgets(
      'recent-item edit returning true re-fetches todayTransactionsProvider',
      (tester) async {
        registerFallbackValue(_FakeUpdateTransactionParams());
        final mockUpdate = _MockUpdateTransactionUseCase();
        when(
          () => mockUpdate.execute(any()),
        ).thenAnswer((_) async => Result.success(_buildTx()));

        var todayFetchCount = 0;
        final tx = _buildTx();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              monthlyReportProvider(
                bookId: 'book_001',
                startDate: currentMonthStart,
                endDate: currentMonthEnd,
              ).overrideWith((ref) async => fixtureMonthlyReportRich()),
              happinessReportProvider(
                bookId: 'book_001',
                startDate: currentMonthStart,
                endDate: currentMonthEnd,
                currencyCode: 'JPY',
              ).overrideWith((ref) async => fixtureHappinessReportRich()),
              bestJoyMomentProvider(
                bookId: 'book_001',
                startDate: currentMonthStart,
                endDate: currentMonthEnd,
              ).overrideWith((ref) async => fixtureBestJoyResultRich()),
              bookByIdProvider(
                bookId: 'book_001',
              ).overrideWith((ref) async => _mockBook),
              // Counting builder: increments once per (re)build. Invalidation
              // after the edit returns true forces a second fetch.
              todayTransactionsProvider(bookId: 'book_001').overrideWith((
                ref,
              ) async {
                todayFetchCount++;
                return [tx];
              }),
              groupRepositoryProvider.overrideWithValue(groupRepository),
              // Edit-screen deps so the pushed TransactionEditScreen builds.
              categoryRepositoryProvider.overrideWithValue(
                _NullCategoryRepository(),
              ),
              categoryServiceProvider.overrideWith(
                (_) => CategoryService(
                  categoryRepository: _NullCategoryRepository(),
                  ledgerConfigRepository: _NullLedgerConfigRepository(),
                ),
              ),
              updateTransactionUseCaseProvider.overrideWith((_) => mockUpdate),
            ],
            child: testLocalizedApp(
              locale: const Locale('ja'),
              child: const Scaffold(body: HomeScreen(bookId: 'book_001')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(todayFetchCount, 1, reason: 'initial fetch');

        // Tap the recent tile → pushes TransactionEditScreen.
        final tile = find.byType(HomeTransactionTile).first;
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(find.byType(TransactionEditScreen), findsOneWidget);

        // Simulate save/delete: the edit screen pops with `true` per its
        // caller-invalidates contract.
        final navigator = Navigator.of(
          tester.element(find.byType(TransactionEditScreen)),
        );
        navigator.pop(true);
        await tester.pumpAndSettle();

        // Home onTap must have invalidated todayTransactionsProvider → re-fetch.
        expect(
          todayFetchCount,
          2,
          reason:
              'Home list must refresh after the edit returns true; '
              'fire-and-forget push (the bug) leaves this at 1.',
        );
      },
    );
  });
}

Transaction _buildTx({bool daily = false}) {
  return Transaction(
    id: daily ? 'tx-daily' : 'tx-joy',
    bookId: 'book_001',
    deviceId: 'device_local',
    amount: daily ? 1200 : 3400,
    type: TransactionType.expense,
    categoryId: daily ? 'cat-food' : 'cat-hobby',
    ledgerType: daily ? LedgerType.daily : LedgerType.joy,
    timestamp: DateTime(2026, 6, 10, 12),
    merchant: daily ? 'Supermarket' : 'Cinema',
    joyFullness: daily ? 2 : 7,
    prevHash: 'prev',
    currentHash: 'curr',
    createdAt: DateTime(2026, 6, 10, 12),
    entrySource: EntrySource.manual,
  );
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
