// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_list_transactions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(listTransactions)
final listTransactionsProvider = ListTransactionsFamily._();

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

String _$listTransactionsHash() => r'b3986f6c4904f67742c780fb3e345b2f78c78a6c';

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

  ListTransactionsProvider call({required String bookId}) =>
      ListTransactionsProvider._(argument: bookId, from: this);

  @override
  String toString() => r'listTransactionsProvider';
}
