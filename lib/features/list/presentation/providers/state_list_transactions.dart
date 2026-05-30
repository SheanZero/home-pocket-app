import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../application/list/get_list_transactions_use_case.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/tagged_transaction.dart';
import 'repository_providers.dart';
import 'state_list_filter.dart';

part 'state_list_transactions.g.dart';

/// The central behavioral provider for the transaction list feature.
///
/// Returns [List<TaggedTransaction>] applying the full pipeline:
/// 1. Read filter state from [listFilterProvider]
/// 2. Read locale from [currentLocaleProvider] for category name resolution
/// 3. Own-book only — [bookIds] = [[bookId]] (Phase 29 seam: merge shadow books)
/// 4. Call [GetListTransactionsUseCase.execute] for SQL-level filtering
/// 5. Dart-side day filter (year+month+day comparison on [activeDayFilter])
/// 6. Dart-side text search using [CategoryLocalizationService.resolveFromId]
///    to convert categoryId to its locale display name (FILTER-01 / D-04)
/// 7. Wrap surviving [Transaction]s as [TaggedTransaction]
///
/// The text search in step 6 is intentionally NOT delegated to the use case
/// because it requires locale-aware category name resolution and decrypted note
/// access — both belong to the in-memory presentation layer (Phase 25 D-05).
///
/// SECURITY: Transaction.note and .merchant are sensitive financial data.
/// They are used only for in-memory .contains() — never logged (T-26-03-LOG).
@riverpod
Future<List<TaggedTransaction>> listTransactions(
  Ref ref, {
  required String bookId,
}) async {
  // Step 1: read filter state
  final filter = ref.watch(listFilterProvider);

  // Step 2: read locale for category name resolution (D-04)
  final locale =
      ref.watch(currentLocaleProvider).value ?? const Locale('ja');

  // Step 3: own-book only (Phase 29: merge shadow books → bookIds + memberTag)
  final bookIds = [bookId];

  // Step 4: call use case with SQL-able filters
  final useCase = ref.watch(getListTransactionsUseCaseProvider);
  final result = await useCase.execute(
    GetListParams(bookIds: bookIds, filter: filter),
  );

  // Step 5: propagate errors as exceptions so AsyncValue.hasError is set
  if (result.isError) {
    throw Exception(result.error);
  }

  var txs = result.data ?? [];

  // Step 6a: Dart-side day filter
  // activeDayFilter is DateTime? — compare all three components (year+month+day)
  final dayFilter = filter.activeDayFilter;
  if (dayFilter != null) {
    txs = txs
        .where(
          (tx) =>
              tx.timestamp.year == dayFilter.year &&
              tx.timestamp.month == dayFilter.month &&
              tx.timestamp.day == dayFilter.day,
        )
        .toList();
  }

  // Step 6a-bis: Dart-side category filter (D-01 — Set<String> multi-select)
  // categoryId is null in SQL query; multi-select filtering is done here.
  // Empty set = no category filter (pass-all).
  if (filter.categoryIds.isNotEmpty) {
    txs = txs
        .where((tx) => filter.categoryIds.contains(tx.categoryId))
        .toList();
  }

  // Step 6b: Dart-side text search (FILTER-01 / D-04 / D-05)
  // Matches localized category name, merchant, or note (OR within search).
  // AND-composed with the SQL filters applied by the use case (FILTER-04).
  // D-04: MUST use CategoryLocalizationService.resolveFromId — never raw categoryId.
  // D-06: null note/merchant handled via ?? '' — no crash for shadow-book notes.
  final q = filter.searchQuery.toLowerCase().trim();
  if (q.isNotEmpty) {
    txs = txs.where((tx) {
      final localizedCategory =
          CategoryLocalizationService.resolveFromId(tx.categoryId, locale)
              .toLowerCase();
      final merchant = (tx.merchant?.toLowerCase() ?? '');
      final note = (tx.note?.toLowerCase() ?? '');
      return localizedCategory.contains(q) ||
          merchant.contains(q) ||
          note.contains(q);
    }).toList();
  }

  // Step 7: wrap as TaggedTransaction
  // Phase 29: fill memberTag from shadowBooks lookup
  return txs
      .map((tx) => TaggedTransaction(transaction: tx, memberTag: null))
      .toList();
}
