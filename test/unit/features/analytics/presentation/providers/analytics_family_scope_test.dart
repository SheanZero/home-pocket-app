import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

ShadowBookInfo _shadow(String id) => ShadowBookInfo(
  book: Book(
    id: id,
    name: id,
    currency: 'JPY',
    deviceId: 'device-$id',
    createdAt: DateTime(2026),
    isShadow: true,
    groupId: 'family-1',
  ),
  memberDisplayName: id,
  memberAvatarEmoji: '',
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(SortField.timestamp);
    registerFallbackValue(SortDirection.asc);
  });

  test(
    'joy calendar remains scoped to the personal book in group mode',
    () async {
      final repository = _MockTransactionRepository();
      when(
        () => repository.findByBookIds(
          any(),
          ledgerType: any(named: 'ledgerType'),
          categoryId: any(named: 'categoryId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer((_) async => const []);

      final container = ProviderContainer.test(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
          isGroupModeProvider.overrideWithValue(true),
          shadowBooksProvider.overrideWith(
            (_) async => [_shadow('shadow-a'), _shadow('shadow-b')],
          ),
        ],
      );

      final provider = perDayJoyCountsProvider(
        bookId: 'personal',
        anchor: DateTime(2026, 8),
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      await container.read(provider.future);

      final captured =
          verify(
                () => repository.findByBookIds(
                  captureAny(),
                  ledgerType: LedgerType.joy,
                  categoryId: null,
                  startDate: any(named: 'startDate'),
                  endDate: any(named: 'endDate'),
                  sortField: SortField.timestamp,
                  sortDirection: SortDirection.asc,
                ),
              ).captured.single
              as List<String>;
      expect(captured, ['personal']);
    },
  );

  test('member category totals merge every book in family scope', () async {
    final repository = _MockAnalyticsRepository();
    when(
      () => repository.getMemberCategoryTotals(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        deviceId: any(named: 'deviceId'),
        entrySourceFilter: any(named: 'entrySourceFilter'),
      ),
    ).thenAnswer((invocation) async {
      final bookId = invocation.namedArguments[#bookId]! as String;
      return [
        CategoryTotal(
          categoryId: 'cat_food',
          totalAmount: bookId == 'personal' ? 1000 : 2000,
          transactionCount: 1,
        ),
      ];
    });

    final container = ProviderContainer.test(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(repository),
        isGroupModeProvider.overrideWithValue(true),
        shadowBooksProvider.overrideWith((_) async => [_shadow('shadow-a')]),
      ],
    );
    final provider = memberFilteredCategoryBreakdownProvider(
      bookId: 'personal',
      startDate: DateTime(2026, 8),
      endDate: DateTime(2026, 8, 31),
      deviceId: 'member-device',
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    final result = await container.read(provider.future);

    expect(result.total, 3000);
    expect(result.entryCount, 2);
    expect(result.breakdowns.single.amount, 3000);
    verify(
      () => repository.getMemberCategoryTotals(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        deviceId: 'member-device',
        entrySourceFilter: any(named: 'entrySourceFilter'),
      ),
    ).called(2);
  });
}
