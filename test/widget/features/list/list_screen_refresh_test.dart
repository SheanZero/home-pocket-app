// Widget tests for ListScreen pull-to-refresh (LIST-04).
//
// Wave 0 scaffold: tests compile cleanly but fail on behavioral assertions
// because RefreshIndicator is not yet added to list_screen.dart.
// RED is the expected outcome for Phase 29 behavioral assertions.
//
// Run: flutter test test/widget/features/list/list_screen_refresh_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/screens/list_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetListTransactionsUseCase extends Mock
    implements GetListTransactionsUseCase {}

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

/// Fixed filter override — injects a known ListFilterState synchronously.
/// Copied from list_transactions_provider_test.dart lines 67–73.
class _FixedListFilter extends ListFilter {
  _FixedListFilter(this._fixed);
  final ListFilterState _fixed;

  @override
  ListFilterState build() => _fixed;
}

/// Pumps ListScreen inside ProviderScope + MaterialApp with ja locale.
///
/// Provides the minimum overrides needed to render the screen without
/// triggering DB or network calls:
/// - currentLocaleProvider: synchronous ja
/// - listFilterProvider: fixed state for 2026/5
/// - isGroupModeProvider: false (solo mode for basic refresh tests)
/// - shadowBooksProvider: empty (not in group mode)
/// - getListTransactionsUseCaseProvider: mockUseCase returning empty list
/// - analyticsRepositoryProvider: mockRepo returning empty totals
Future<ProviderContainer> _pumpScreen(
  WidgetTester tester,
  _MockGetListTransactionsUseCase mockUseCase,
  _MockAnalyticsRepository mockRepo,
) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        locale_providers.currentLocaleProvider
            .overrideWith((_) async => const Locale('ja')),
        listFilterProvider.overrideWith(
          () => _FixedListFilter(const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
          )),
        ),
        isGroupModeProvider.overrideWithValue(false),
        shadowBooksProvider.overrideWith((_) async => const []),
        getListTransactionsUseCaseProvider.overrideWithValue(mockUseCase),
        analyticsRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(
              body: ListScreen(bookId: 'book1'),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetListParams(
      bookIds: ['book1'],
      filter: ListFilterState(
        selectedYear: 2026,
        selectedMonth: 5,
      ),
    ));
    registerFallbackValue(DateTime(2026));
  });

  group('ListScreen pull-to-refresh (LIST-04)', () {
    setUp(() {});

    testWidgets(
      'LIST-04: RefreshIndicator is present in list screen',
      (tester) async {
        final mockUseCase = _MockGetListTransactionsUseCase();
        final mockRepo = _MockAnalyticsRepository();

        when(() => mockUseCase.execute(any())).thenAnswer(
          (_) async => Result.success(<Transaction>[]),
        );
        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        await _pumpScreen(tester, mockUseCase, mockRepo);

        // RED until RefreshIndicator wraps the list in list_screen.dart (Plan 03)
        expect(find.byType(RefreshIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'LIST-04: pull-to-refresh invalidates listTransactionsProvider (use case called again)',
      (tester) async {
        final mockUseCase = _MockGetListTransactionsUseCase();
        final mockRepo = _MockAnalyticsRepository();

        when(() => mockUseCase.execute(any())).thenAnswer(
          (_) async => Result.success(<Transaction>[]),
        );
        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        await _pumpScreen(tester, mockUseCase, mockRepo);

        // RED: no RefreshIndicator yet; fling will not trigger refresh
        // Perform pull-to-refresh gesture
        await tester.fling(
          find.byType(ListView),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        // After invalidate, provider rebuilds and re-executes use case.
        // Expect called more than once (initial load + refresh).
        verify(() => mockUseCase.execute(any())).called(greaterThan(1));
      },
    );

    testWidgets(
      'LIST-04: pull-to-refresh invalidates calendarDailyTotalsProvider (analytics called again)',
      (tester) async {
        final mockUseCase = _MockGetListTransactionsUseCase();
        final mockRepo = _MockAnalyticsRepository();

        when(() => mockUseCase.execute(any())).thenAnswer(
          (_) async => Result.success(<Transaction>[]),
        );
        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2026, 5, 15), totalAmount: 1000),
          ],
        );

        await _pumpScreen(tester, mockUseCase, mockRepo);

        // RED: no RefreshIndicator yet; fling will not trigger calendar refresh
        await tester.fling(
          find.byType(ListView),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        // After refresh, calendarDailyTotalsProvider is invalidated and
        // getDailyTotals is called at least twice (initial load + refresh).
        verify(() => mockRepo.getDailyTotals(
              bookId: any(named: 'bookId'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).called(greaterThan(1));
      },
    );
  });
}
