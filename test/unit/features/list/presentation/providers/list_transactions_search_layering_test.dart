import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_transactions.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetListTransactionsUseCase extends Mock
    implements GetListTransactionsUseCase {}

Transaction _makeTransaction({
  String id = 'tx-1',
  String categoryId = 'cat_food',
  String? merchant,
  String? note,
}) {
  return Transaction(
    id: id,
    bookId: 'book1',
    deviceId: 'device1',
    amount: 1000,
    type: TransactionType.expense,
    categoryId: categoryId,
    ledgerType: LedgerType.daily,
    timestamp: DateTime(2026, 5, 15, 12, 0),
    currentHash: 'hash-$id',
    createdAt: DateTime(2026, 5, 15),
    note: note,
    merchant: merchant,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const GetListParams(
        bookIds: ['book1'],
        filter: ListFilterState(selectedYear: 2026, selectedMonth: 5),
      ),
    );
  });

  // P2-1: the expensive SQL query + full-row ChaCha20 decryption must run only
  // when a SQL-able filter changes (month/day/ledger/category/member), NEVER on
  // a search keystroke. Search is a locale-aware in-memory scan layered on top.
  group('P2-1 search layering (SQL base immune to searchQuery)', () {
    test(
      'changing searchQuery does NOT re-run the SQL use case, but still filters',
      () async {
        final mock = _MockGetListTransactionsUseCase();
        var executeCount = 0;
        final tx = _makeTransaction(
          categoryId: 'cat_food',
          merchant: 'Starbucks',
        );
        when(() => mock.execute(any())).thenAnswer((_) async {
          executeCount++;
          return Result.success([tx]);
        });

        final container = ProviderContainer.test(
          overrides: [
            getListTransactionsUseCaseProvider.overrideWithValue(mock),
            currentLocaleProvider.overrideWith(
              (ref) async => const Locale('ja'),
            ),
            isGroupModeProvider.overrideWithValue(false),
            shadowBooksProvider.overrideWith(
              (_) async => const <ShadowBookInfo>[],
            ),
          ],
        );

        // Hold a subscription so the provider is not disposed between reads —
        // Riverpod 3 disposes orphan reads mid-build (see test_provider_scope).
        final sub = container.listen(
          listTransactionsProvider(bookId: 'book1'),
          (_, _) {},
        );
        addTearDown(sub.close);

        // Initial build → SQL runs exactly once.
        final initial = await container.read(
          listTransactionsProvider(bookId: 'book1').future,
        );
        expect(initial, hasLength(1));
        expect(executeCount, 1);

        // Type a matching query: the SQL base must NOT re-run …
        container.read(listFilterProvider.notifier).setSearch('starbucks');
        final afterSearch = await container.read(
          listTransactionsProvider(bookId: 'book1').future,
        );
        expect(
          executeCount,
          1,
          reason:
              'P2-1: a searchQuery change must not re-run SQL + full-row decrypt',
        );
        // … yet the in-memory search still filters (merchant match survives).
        expect(afterSearch, hasLength(1));

        // A non-matching query: still no SQL, and the row is filtered out.
        container.read(listFilterProvider.notifier).setSearch('zzz-no-match');
        final afterNoMatch = await container.read(
          listTransactionsProvider(bookId: 'book1').future,
        );
        expect(executeCount, 1);
        expect(afterNoMatch, isEmpty);

        // Sanity: a SQL-able filter change DOES re-run the use case. (The stale
        // 'zzz-no-match' query is irrelevant to the execute count assertion.)
        container
            .read(listFilterProvider.notifier)
            .setLedgerFilter(LedgerType.joy);
        await container.read(
          listTransactionsProvider(bookId: 'book1').future,
        );
        expect(
          executeCount,
          2,
          reason: 'a non-search (SQL-able) filter change must re-run SQL',
        );
      },
    );
  });
}
