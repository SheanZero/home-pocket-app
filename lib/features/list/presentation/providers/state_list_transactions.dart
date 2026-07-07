import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../application/list/get_list_transactions_use_case.dart';
import '../../../family_sync/presentation/providers/state_active_group.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/list_filter_state.dart';
import '../../domain/models/tagged_transaction.dart';
import 'repository_providers.dart';
import 'state_list_filter.dart';

part 'state_list_transactions.g.dart';

/// The list filter with `searchQuery` cleared — the SQL-able projection of the
/// filter (P2-1).
///
/// It rebuilds whenever [listFilterProvider] changes, but because
/// [ListFilterState] is a Freezed value type a search-only edit yields an
/// *equal* value, so Riverpod skips notifying its watchers. This is what keeps
/// [listTransactionsBaseProvider] (SQL query + full-row ChaCha20 decryption)
/// from re-running on every search keystroke. Behaviour is unchanged: the use
/// case never consumed `searchQuery` (D-05).
@riverpod
ListFilterState listFilterSansSearch(Ref ref) =>
    ref.watch(listFilterProvider).copyWith(searchQuery: '');

/// The active text-search token, isolated so [listTransactions] rebuilds on
/// search edits only. A non-search filter change yields the same token and does
/// not notify through this path (it already rebuilds the base) (P2-1).
@riverpod
String listSearchQuery(Ref ref) =>
    ref.watch(listFilterProvider).searchQuery;

/// SQL + structural pipeline for the transaction list, WITHOUT the in-memory
/// text search (P2-1).
///
/// Watches [listFilterSansSearchProvider], so the expensive
/// `GetListTransactionsUseCase.execute` SQL query and its full-row decryption
/// run only when a SQL-able filter changes (month/day/ledger/category/member) —
/// never on a search keystroke.
///
/// Pipeline:
/// 1. Read filter state (searchQuery stripped) from [listFilterSansSearchProvider]
/// 3. Own-book + shadow books in group mode (FAM-01)
/// 4. Call [GetListTransactionsUseCase.execute] for SQL-level filtering
/// 5. Dart-side day filter (year+month+day comparison on [activeDayFilter])
/// 6a. Dart-side category filter (D-01 — `Set<String>` multi-select)
/// 7. Wrap surviving [Transaction]s as [TaggedTransaction]
@riverpod
Future<List<TaggedTransaction>> listTransactionsBase(
  Ref ref, {
  required String bookId,
}) async {
  // Step 1: read filter WITHOUT searchQuery (see listFilterSansSearchProvider).
  final filter = ref.watch(listFilterSansSearchProvider);

  // Step 3: own-book + shadow books in group mode (FAM-01)
  final isGroup = ref.watch(isGroupModeProvider);
  final shadowBookList = isGroup
      ? (await ref.watch(shadowBooksProvider.future))
      : const <ShadowBookInfo>[];

  final bookIds = [bookId, ...shadowBookList.map((s) => s.book.id)];
  // Build lookup table once: shadowBookId → ShadowBookInfo (for memberTag fill, D-01)
  final bookIdToShadow = {for (final s in shadowBookList) s.book.id: s};

  // Member filter narrowing — SQL-level (D-02 preference)
  // Reduces bookIds to one book when a member chip is selected.
  // A stale memberBookId (member removed, or returned to solo mode while the
  // keepAlive filter still holds a shadow id) is treated as "no member filter"
  // and falls back to the full book set — never an empty list, which the use
  // case rejects and would strand the user on an error screen (CR-01).
  final memberBookId = filter.memberBookId;
  final effectiveBookIds =
      (memberBookId != null && bookIds.contains(memberBookId))
      ? [memberBookId]
      : bookIds;

  // Step 4: call use case with SQL-able filters
  final useCase = ref.watch(getListTransactionsUseCaseProvider);
  final result = await useCase.execute(
    GetListParams(bookIds: effectiveBookIds, filter: filter),
  );

  // Propagate errors as exceptions so AsyncValue.hasError is set
  if (result.isError) {
    throw Exception(result.error);
  }

  var txs = result.data ?? [];

  // Step 5: Dart-side day filter
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

  // Step 6a: Dart-side category filter (D-01 — Set<String> multi-select)
  // categoryId is null in SQL query; multi-select filtering is done here.
  // Empty set = no category filter (pass-all).
  if (filter.categoryIds.isNotEmpty) {
    txs = txs
        .where((tx) => filter.categoryIds.contains(tx.categoryId))
        .toList();
  }

  // Step 7: wrap as TaggedTransaction; own-book rows → memberTag null (D-01/SC#3)
  return txs.map((tx) {
    final shadow = bookIdToShadow[tx.bookId];
    return TaggedTransaction(
      transaction: tx,
      memberTag: shadow == null
          ? null
          : MemberTag(
              emoji: shadow.memberAvatarEmoji,
              name: shadow.memberDisplayName,
            ),
    );
  }).toList();
}

/// The central behavioral provider for the transaction list feature.
///
/// Returns [List<TaggedTransaction>] by layering the locale-aware in-memory
/// text search (step 6b) on top of [listTransactionsBaseProvider], which owns
/// the SQL + structural pipeline. Because the base is immune to `searchQuery`
/// (see [listFilterSansSearchProvider]), each keystroke re-runs ONLY this cheap
/// `.contains` scan — no SQL query, no decryption (P2-1).
///
/// The text search is intentionally NOT delegated to the use case because it
/// requires locale-aware category name resolution and decrypted note access —
/// both belong to the in-memory presentation layer (Phase 25 D-05).
///
/// SECURITY: Transaction.note and .merchant are sensitive financial data.
/// They are used only for in-memory .contains() — never logged (T-26-03-LOG).
@riverpod
Future<List<TaggedTransaction>> listTransactions(
  Ref ref, {
  required String bookId,
}) async {
  // Structural pipeline (SQL + day/category + wrap), immune to search keystrokes.
  final base = await ref.watch(
    listTransactionsBaseProvider(bookId: bookId).future,
  );

  // Locale for category name resolution (D-04). Read in this provider, not the
  // base, because it is consumed only by the in-memory text search below.
  final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

  // Step 6b: Dart-side text search (FILTER-01 / D-04 / D-05). Watch the isolated
  // search token so unrelated filter changes don't run this twice (they already
  // rebuilt the base). Matches localized category name, merchant, or note.
  // D-06: null note/merchant handled via ?? '' — no crash for shadow-book notes.
  final q = ref.watch(listSearchQueryProvider).toLowerCase().trim();
  if (q.isEmpty) return base;

  return base.where((tagged) {
    final tx = tagged.transaction;
    final localizedCategory =
        CategoryLocalizationService.resolveFromId(
          tx.categoryId,
          locale,
        ).toLowerCase();
    final merchant = (tx.merchant?.toLowerCase() ?? '');
    final note = (tx.note?.toLowerCase() ?? '');
    return localizedCategory.contains(q) ||
        merchant.contains(q) ||
        note.contains(q);
  }).toList();
}
