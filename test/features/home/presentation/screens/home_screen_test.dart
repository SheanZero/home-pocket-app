import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/shadow_books_provider.dart';
import 'package:home_pocket/features/home/presentation/providers/today_transactions_provider.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';
import 'package:home_pocket/features/home/presentation/widgets/ledger_comparison_section.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';
import 'package:home_pocket/features/home/presentation/widgets/section_divider.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';
import 'package:home_pocket/features/home/presentation/widgets/transaction_list_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

final _shadowBook = Book(
  id: 'shadow-book-1',
  name: 'shadow',
  currency: 'JPY',
  deviceId: 'device-member',
  createdAt: DateTime(2026, 3, 14),
  isShadow: true,
  groupId: 'group-1',
  ownerDeviceId: 'device-member',
  ownerDeviceName: '田中',
);

final _shadowBookInfo = ShadowBookInfo(
  book: _shadowBook,
  memberDisplayName: '田中',
  memberAvatarEmoji: '🌸',
);

final _emptyReport = MonthlyReport(
  year: 2026,
  month: 3,
  totalIncome: 0,
  totalExpenses: 0,
  savings: 0,
  savingsRate: 0,
  survivalTotal: 0,
  soulTotal: 0,
  categoryBreakdowns: [],
  dailyExpenses: [],
);

final _reportWithData = MonthlyReport(
  year: 2026,
  month: 3,
  totalIncome: 300000,
  totalExpenses: 142800,
  savings: 157200,
  savingsRate: 52.4,
  survivalTotal: 102200,
  soulTotal: 40600,
  categoryBreakdowns: [],
  dailyExpenses: [],
);

final _sampleTransaction = Transaction(
  id: 'tx-1',
  bookId: 'book_001',
  deviceId: 'device-abc',
  amount: 3480,
  type: TransactionType.expense,
  categoryId: 'cat_food',
  ledgerType: LedgerType.survival,
  timestamp: DateTime(2026, 3, 15, 12, 0),
  currentHash: 'hash-1',
  createdAt: DateTime(2026, 3, 15, 12, 0),
);

final _soulTransaction = Transaction(
  id: 'tx-2',
  bookId: 'book_001',
  deviceId: 'device-abc',
  amount: 5000,
  type: TransactionType.expense,
  categoryId: 'cat_hobby',
  ledgerType: LedgerType.soul,
  timestamp: DateTime(2026, 3, 15, 14, 0),
  currentHash: 'hash-2',
  createdAt: DateTime(2026, 3, 15, 14, 0),
  soulSatisfaction: 8,
);

Widget _buildLocalizedApp({
  required Widget child,
  Locale locale = const Locale('ja'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: child,
  );
}

void main() {
  late MockGroupRepository groupRepository;
  late DateTime now;

  setUp(() {
    groupRepository = MockGroupRepository();
    now = DateTime.now();
    when(
      () => groupRepository.watchActiveGroup(),
    ).thenAnswer((_) => Stream.value(null));
  });

  Widget buildSubject({
    MonthlyReport? report,
    List<Transaction>? transactions,
    bool groupMode = false,
    Locale locale = const Locale('ja'),
    List<ShadowBookInfo>? shadowBooks,
    ShadowAggregate? shadowAgg,
  }) {
    if (groupMode) {
      when(() => groupRepository.watchActiveGroup()).thenAnswer(
        (_) => Stream.value(
          GroupInfo(
            groupId: 'group-1',
            groupName: 'Test Family',
            status: GroupStatus.active,
            role: 'owner',
            members: const [],
            createdAt: DateTime(2026, 3, 14),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        monthlyReportProvider(
          bookId: 'book_001',
          year: now.year,
          month: now.month,
        ).overrideWith((ref) async => report ?? _emptyReport),
        todayTransactionsProvider(
          bookId: 'book_001',
        ).overrideWith((ref) async => transactions ?? []),
        groupRepositoryProvider.overrideWithValue(groupRepository),
        shadowBooksProvider.overrideWith(
          (ref) async => shadowBooks ?? const [],
        ),
        shadowAggregateProvider(year: now.year, month: now.month).overrideWith(
          (ref) async => shadowAgg ?? const ShadowAggregate.empty(),
        ),
      ],
      child: _buildLocalizedApp(
        locale: locale,
        child: const Scaffold(body: HomeScreen(bookId: 'book_001')),
      ),
    );
  }

  group('HomeScreen layout structure', () {
    testWidgets('uses flat SingleChildScrollView layout', (tester) async {
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

    testWidgets('does not use hero Stack pattern with blue background', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // The old layout had a Stack as a direct child of the Column in
      // HomeScreen build. The new flat layout uses SingleChildScrollView >
      // SafeArea > Padding > Column. Child widgets may still use Stack
      // internally (e.g. FamilyInviteBanner avatar overlap), but the
      // top-level hero stack pattern is gone.
      // Verify no blue hero container exists:
      final blueContainerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFF8AB8DA),
      );
      expect(blueContainerFinder, findsNothing);
    });

    testWidgets('renders HeroHeader', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(HeroHeader), findsOneWidget);
    });

    testWidgets('renders two SectionDividers', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SectionDivider), findsNWidgets(2));
      expect(find.text('今月の支出'), findsOneWidget);
      expect(find.text('帳 本'), findsOneWidget);
    });

    testWidgets('renders MonthOverviewCard', (tester) async {
      await tester.pumpWidget(buildSubject(report: _reportWithData));
      await tester.pumpAndSettle();

      expect(find.byType(MonthOverviewCard), findsOneWidget);
    });

    testWidgets('renders LedgerComparisonSection', (tester) async {
      await tester.pumpWidget(buildSubject(report: _reportWithData));
      await tester.pumpAndSettle();

      expect(find.byType(LedgerComparisonSection), findsOneWidget);
    });

    testWidgets('renders SoulFullnessCard', (tester) async {
      await tester.pumpWidget(buildSubject(report: _reportWithData));
      await tester.pumpAndSettle();

      expect(find.byType(SoulFullnessCard), findsOneWidget);
    });

    testWidgets('renders transactions header row', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('最近の取引'), findsOneWidget);
      expect(find.text('すべて見る'), findsOneWidget);
    });
  });

  group('HomeScreen data wiring', () {
    testWidgets('shows empty state when no transactions', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('取引がまだありません'), findsOneWidget);
      expect(find.byType(TransactionListCard), findsNothing);
    });

    testWidgets('shows transactions inside TransactionListCard', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          report: _reportWithData,
          transactions: [_sampleTransaction],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionListCard), findsOneWidget);
      expect(find.byType(HomeTransactionTile), findsOneWidget);
    });

    testWidgets('survival transaction shows 生 tag in tile', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          report: _reportWithData,
          transactions: [_sampleTransaction],
        ),
      );
      await tester.pumpAndSettle();

      // '生' appears in both LedgerComparisonSection tag and transaction tile tag
      // Verify it appears in the HomeTransactionTile specifically
      final tileFinder = find.descendant(
        of: find.byType(HomeTransactionTile),
        matching: find.text('\u751f'),
      );
      expect(tileFinder, findsOneWidget);
    });

    testWidgets('soul transaction shows 魂 tag', (tester) async {
      await tester.pumpWidget(
        buildSubject(report: _reportWithData, transactions: [_soulTransaction]),
      );
      await tester.pumpAndSettle();

      // '\u9b42' is '魂'
      expect(find.text('\u9b42'), findsOneWidget);
    });

    testWidgets('displays formatted expense amount with minus sign', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          report: _reportWithData,
          transactions: [_sampleTransaction],
        ),
      );
      await tester.pumpAndSettle();

      // Amount 3480 -> "-\u00a53,480"
      expect(find.text('-\u00a53,480'), findsOneWidget);
    });
  });

  group('HomeScreen solo vs group mode', () {
    testWidgets('solo mode shows FamilyInviteBanner', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(FamilyInviteBanner), findsOneWidget);
    });

    testWidgets('group mode hides FamilyInviteBanner', (tester) async {
      await tester.pumpWidget(buildSubject(groupMode: true));
      await tester.pumpAndSettle();

      expect(find.byType(FamilyInviteBanner), findsNothing);
    });

    testWidgets('solo mode shows personal mode badge', (tester) async {
      await tester.pumpWidget(buildSubject(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Personal Mode'), findsOneWidget);
    });

    testWidgets('group mode shows family mode badge', (tester) async {
      await tester.pumpWidget(
        buildSubject(groupMode: true, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Family Mode'), findsOneWidget);
    });

    testWidgets('group mode shows member initial in transaction tag', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          groupMode: true,
          report: _reportWithData,
          transactions: [_sampleTransaction],
        ),
      );
      await tester.pumpAndSettle();

      // deviceId is 'device-abc', first char uppercased => 'D'
      expect(find.text('D'), findsOneWidget);
    });
  });

  group('HomeScreen ledger rows', () {
    testWidgets('solo mode shows 2 ledger rows (survival + soul)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(report: _reportWithData));
      await tester.pumpAndSettle();

      expect(find.text('生存帳本'), findsOneWidget);
      expect(find.text('灵魂帳本'), findsOneWidget);
      expect(find.text('共有帳本'), findsNothing);
    });

    testWidgets('group mode shows shadow book ledger row named after member', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          report: _reportWithData,
          groupMode: true,
          shadowBooks: [_shadowBookInfo],
          shadowAgg: ShadowAggregate(
            totalExpenses: 12000,
            prevTotalExpenses: 9000,
            perBookReports: {
              _shadowBook.id: MonthlyReport(
                year: now.year,
                month: now.month,
                totalIncome: 0,
                totalExpenses: 12000,
                savings: 0,
                savingsRate: 0,
                survivalTotal: 12000,
                soulTotal: 0,
                categoryBreakdowns: [],
                dailyExpenses: [],
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('生存帳本'), findsOneWidget);
      expect(find.text('灵魂帳本'), findsOneWidget);
      expect(find.text('田中の帳本'), findsOneWidget);
      expect(find.text('共有帳本'), findsNothing);
    });
  });
}
