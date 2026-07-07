// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_list_transactions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The list filter with `searchQuery` cleared — the SQL-able projection of the
/// filter (P2-1).
///
/// It rebuilds whenever [listFilterProvider] changes, but because
/// [ListFilterState] is a Freezed value type a search-only edit yields an
/// *equal* value, so Riverpod skips notifying its watchers. This is what keeps
/// [listTransactionsBaseProvider] (SQL query + full-row ChaCha20 decryption)
/// from re-running on every search keystroke. Behaviour is unchanged: the use
/// case never consumed `searchQuery` (D-05).

@ProviderFor(listFilterSansSearch)
final listFilterSansSearchProvider = ListFilterSansSearchProvider._();

/// The list filter with `searchQuery` cleared — the SQL-able projection of the
/// filter (P2-1).
///
/// It rebuilds whenever [listFilterProvider] changes, but because
/// [ListFilterState] is a Freezed value type a search-only edit yields an
/// *equal* value, so Riverpod skips notifying its watchers. This is what keeps
/// [listTransactionsBaseProvider] (SQL query + full-row ChaCha20 decryption)
/// from re-running on every search keystroke. Behaviour is unchanged: the use
/// case never consumed `searchQuery` (D-05).

final class ListFilterSansSearchProvider
    extends
        $FunctionalProvider<ListFilterState, ListFilterState, ListFilterState>
    with $Provider<ListFilterState> {
  /// The list filter with `searchQuery` cleared — the SQL-able projection of the
  /// filter (P2-1).
  ///
  /// It rebuilds whenever [listFilterProvider] changes, but because
  /// [ListFilterState] is a Freezed value type a search-only edit yields an
  /// *equal* value, so Riverpod skips notifying its watchers. This is what keeps
  /// [listTransactionsBaseProvider] (SQL query + full-row ChaCha20 decryption)
  /// from re-running on every search keystroke. Behaviour is unchanged: the use
  /// case never consumed `searchQuery` (D-05).
  ListFilterSansSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listFilterSansSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listFilterSansSearchHash();

  @$internal
  @override
  $ProviderElement<ListFilterState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ListFilterState create(Ref ref) {
    return listFilterSansSearch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListFilterState>(value),
    );
  }
}

String _$listFilterSansSearchHash() =>
    r'bb30b8907b5adaf725b016cb06683a0018b49e07';

/// The active text-search token, isolated so [listTransactions] rebuilds on
/// search edits only. A non-search filter change yields the same token and does
/// not notify through this path (it already rebuilds the base) (P2-1).

@ProviderFor(listSearchQuery)
final listSearchQueryProvider = ListSearchQueryProvider._();

/// The active text-search token, isolated so [listTransactions] rebuilds on
/// search edits only. A non-search filter change yields the same token and does
/// not notify through this path (it already rebuilds the base) (P2-1).

final class ListSearchQueryProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The active text-search token, isolated so [listTransactions] rebuilds on
  /// search edits only. A non-search filter change yields the same token and does
  /// not notify through this path (it already rebuilds the base) (P2-1).
  ListSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listSearchQueryHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return listSearchQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$listSearchQueryHash() => r'08fed1ca3ba3f2a92de522615d08e8e30860eb65';

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
/// 6a. Dart-side category filter (D-01 — Set<String> multi-select)
/// 7. Wrap surviving [Transaction]s as [TaggedTransaction]

@ProviderFor(listTransactionsBase)
final listTransactionsBaseProvider = ListTransactionsBaseFamily._();

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
/// 6a. Dart-side category filter (D-01 — Set<String> multi-select)
/// 7. Wrap surviving [Transaction]s as [TaggedTransaction]

final class ListTransactionsBaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TaggedTransaction>>,
          List<TaggedTransaction>,
          FutureOr<List<TaggedTransaction>>
        >
    with
        $FutureModifier<List<TaggedTransaction>>,
        $FutureProvider<List<TaggedTransaction>> {
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
  /// 6a. Dart-side category filter (D-01 — Set<String> multi-select)
  /// 7. Wrap surviving [Transaction]s as [TaggedTransaction]
  ListTransactionsBaseProvider._({
    required ListTransactionsBaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listTransactionsBaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listTransactionsBaseHash();

  @override
  String toString() {
    return r'listTransactionsBaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TaggedTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TaggedTransaction>> create(Ref ref) {
    final argument = this.argument as String;
    return listTransactionsBase(ref, bookId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListTransactionsBaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listTransactionsBaseHash() =>
    r'696cee2ec618c4e8aa9bcdfb00a5e6a2e4b94c40';

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
/// 6a. Dart-side category filter (D-01 — Set<String> multi-select)
/// 7. Wrap surviving [Transaction]s as [TaggedTransaction]

final class ListTransactionsBaseFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TaggedTransaction>>, String> {
  ListTransactionsBaseFamily._()
    : super(
        retry: null,
        name: r'listTransactionsBaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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
  /// 6a. Dart-side category filter (D-01 — Set<String> multi-select)
  /// 7. Wrap surviving [Transaction]s as [TaggedTransaction]

  ListTransactionsBaseProvider call({required String bookId}) =>
      ListTransactionsBaseProvider._(argument: bookId, from: this);

  @override
  String toString() => r'listTransactionsBaseProvider';
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

@ProviderFor(listTransactions)
final listTransactionsProvider = ListTransactionsFamily._();

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

final class ListTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TaggedTransaction>>,
          List<TaggedTransaction>,
          FutureOr<List<TaggedTransaction>>
        >
    with
        $FutureModifier<List<TaggedTransaction>>,
        $FutureProvider<List<TaggedTransaction>> {
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
  ListTransactionsProvider._({
    required ListTransactionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listTransactionsHash();

  @override
  String toString() {
    return r'listTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TaggedTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TaggedTransaction>> create(Ref ref) {
    final argument = this.argument as String;
    return listTransactions(ref, bookId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listTransactionsHash() => r'b5dd31262812d468818b5912bf0433e9edffbbd1';

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

final class ListTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TaggedTransaction>>, String> {
  ListTransactionsFamily._()
    : super(
        retry: null,
        name: r'listTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  ListTransactionsProvider call({required String bookId}) =>
      ListTransactionsProvider._(argument: bookId, from: this);

  @override
  String toString() => r'listTransactionsProvider';
}
