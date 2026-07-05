// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// BookRepository provider.

@ProviderFor(bookRepository)
final bookRepositoryProvider = BookRepositoryProvider._();

/// BookRepository provider.

final class BookRepositoryProvider
    extends $FunctionalProvider<BookRepository, BookRepository, BookRepository>
    with $Provider<BookRepository> {
  /// BookRepository provider.
  BookRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookRepositoryHash();

  @$internal
  @override
  $ProviderElement<BookRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BookRepository create(Ref ref) {
    return bookRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookRepository>(value),
    );
  }
}

String _$bookRepositoryHash() => r'd010c4f3be9aa4d9eb70242809cef015d87b6b03';

/// Resolves a Book by ID for currency-code lookup (Phase 10 D-12).
///
/// Use case: HomeHeroCard's parent screen needs `Book.currency` to eliminate
/// hardcoded `'JPY'` (CLAUDE.md Pitfall #9). Returns `null` if no Book exists
/// for the given ID — caller falls back to `'JPY'` only in the missing-Book
/// case, never in the widget body.

@ProviderFor(bookById)
final bookByIdProvider = BookByIdFamily._();

/// Resolves a Book by ID for currency-code lookup (Phase 10 D-12).
///
/// Use case: HomeHeroCard's parent screen needs `Book.currency` to eliminate
/// hardcoded `'JPY'` (CLAUDE.md Pitfall #9). Returns `null` if no Book exists
/// for the given ID — caller falls back to `'JPY'` only in the missing-Book
/// case, never in the widget body.

final class BookByIdProvider
    extends $FunctionalProvider<AsyncValue<Book?>, Book?, FutureOr<Book?>>
    with $FutureModifier<Book?>, $FutureProvider<Book?> {
  /// Resolves a Book by ID for currency-code lookup (Phase 10 D-12).
  ///
  /// Use case: HomeHeroCard's parent screen needs `Book.currency` to eliminate
  /// hardcoded `'JPY'` (CLAUDE.md Pitfall #9). Returns `null` if no Book exists
  /// for the given ID — caller falls back to `'JPY'` only in the missing-Book
  /// case, never in the widget body.
  BookByIdProvider._({
    required BookByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookByIdHash();

  @override
  String toString() {
    return r'bookByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Book?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Book?> create(Ref ref) {
    final argument = this.argument as String;
    return bookById(ref, bookId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookByIdHash() => r'544dd59914ef0fb28f243b439f1046e87bb972e3';

/// Resolves a Book by ID for currency-code lookup (Phase 10 D-12).
///
/// Use case: HomeHeroCard's parent screen needs `Book.currency` to eliminate
/// hardcoded `'JPY'` (CLAUDE.md Pitfall #9). Returns `null` if no Book exists
/// for the given ID — caller falls back to `'JPY'` only in the missing-Book
/// case, never in the widget body.

final class BookByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Book?>, String> {
  BookByIdFamily._()
    : super(
        retry: null,
        name: r'bookByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves a Book by ID for currency-code lookup (Phase 10 D-12).
  ///
  /// Use case: HomeHeroCard's parent screen needs `Book.currency` to eliminate
  /// hardcoded `'JPY'` (CLAUDE.md Pitfall #9). Returns `null` if no Book exists
  /// for the given ID — caller falls back to `'JPY'` only in the missing-Book
  /// case, never in the widget body.

  BookByIdProvider call({required String bookId}) =>
      BookByIdProvider._(argument: bookId, from: this);

  @override
  String toString() => r'bookByIdProvider';
}

/// CategoryRepository provider.

@ProviderFor(categoryRepository)
final categoryRepositoryProvider = CategoryRepositoryProvider._();

/// CategoryRepository provider.

final class CategoryRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryRepository,
          CategoryRepository,
          CategoryRepository
        >
    with $Provider<CategoryRepository> {
  /// CategoryRepository provider.
  CategoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryRepository create(Ref ref) {
    return categoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryRepository>(value),
    );
  }
}

String _$categoryRepositoryHash() =>
    r'0efc054c1cb685a355e020bea93a3dbb90250e96';

/// MerchantRepository provider.
///
/// Phase 49 wires the interface only — no consumer reads it yet (the
/// recognizer cutover is Phase 50). The seed (Plan 05) is the first user.

@ProviderFor(merchantRepository)
final merchantRepositoryProvider = MerchantRepositoryProvider._();

/// MerchantRepository provider.
///
/// Phase 49 wires the interface only — no consumer reads it yet (the
/// recognizer cutover is Phase 50). The seed (Plan 05) is the first user.

final class MerchantRepositoryProvider
    extends
        $FunctionalProvider<
          MerchantRepository,
          MerchantRepository,
          MerchantRepository
        >
    with $Provider<MerchantRepository> {
  /// MerchantRepository provider.
  ///
  /// Phase 49 wires the interface only — no consumer reads it yet (the
  /// recognizer cutover is Phase 50). The seed (Plan 05) is the first user.
  MerchantRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantRepositoryHash();

  @$internal
  @override
  $ProviderElement<MerchantRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MerchantRepository create(Ref ref) {
    return merchantRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MerchantRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MerchantRepository>(value),
    );
  }
}

String _$merchantRepositoryHash() =>
    r'c5103262477f47f630b714c02af065e589e4145d';

/// CategoryLedgerConfigRepository provider.

@ProviderFor(categoryLedgerConfigRepository)
final categoryLedgerConfigRepositoryProvider =
    CategoryLedgerConfigRepositoryProvider._();

/// CategoryLedgerConfigRepository provider.

final class CategoryLedgerConfigRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryLedgerConfigRepository,
          CategoryLedgerConfigRepository,
          CategoryLedgerConfigRepository
        >
    with $Provider<CategoryLedgerConfigRepository> {
  /// CategoryLedgerConfigRepository provider.
  CategoryLedgerConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryLedgerConfigRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryLedgerConfigRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryLedgerConfigRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryLedgerConfigRepository create(Ref ref) {
    return categoryLedgerConfigRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryLedgerConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryLedgerConfigRepository>(
        value,
      ),
    );
  }
}

String _$categoryLedgerConfigRepositoryHash() =>
    r'a5464185fdbbbdee645ad65d28c378aa477cb47b';

/// TransactionRepository provider.

@ProviderFor(transactionRepository)
final transactionRepositoryProvider = TransactionRepositoryProvider._();

/// TransactionRepository provider.

final class TransactionRepositoryProvider
    extends
        $FunctionalProvider<
          TransactionRepository,
          TransactionRepository,
          TransactionRepository
        >
    with $Provider<TransactionRepository> {
  /// TransactionRepository provider.
  TransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionRepository create(Ref ref) {
    return transactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionRepository>(value),
    );
  }
}

String _$transactionRepositoryHash() =>
    r'c70882ecda67cc3dfa3156ddf91a8b0e0bdd9ead';

/// MerchantCategoryPreferenceRepository provider.

@ProviderFor(merchantCategoryPreferenceRepository)
final merchantCategoryPreferenceRepositoryProvider =
    MerchantCategoryPreferenceRepositoryProvider._();

/// MerchantCategoryPreferenceRepository provider.

final class MerchantCategoryPreferenceRepositoryProvider
    extends
        $FunctionalProvider<
          MerchantCategoryPreferenceRepository,
          MerchantCategoryPreferenceRepository,
          MerchantCategoryPreferenceRepository
        >
    with $Provider<MerchantCategoryPreferenceRepository> {
  /// MerchantCategoryPreferenceRepository provider.
  MerchantCategoryPreferenceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantCategoryPreferenceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$merchantCategoryPreferenceRepositoryHash();

  @$internal
  @override
  $ProviderElement<MerchantCategoryPreferenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MerchantCategoryPreferenceRepository create(Ref ref) {
    return merchantCategoryPreferenceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MerchantCategoryPreferenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<MerchantCategoryPreferenceRepository>(value),
    );
  }
}

String _$merchantCategoryPreferenceRepositoryHash() =>
    r'e973d898b68613759838ca2b7ddb947d77ba7d36';

/// CategoryKeywordPreferenceRepository provider.

@ProviderFor(categoryKeywordPreferenceRepository)
final categoryKeywordPreferenceRepositoryProvider =
    CategoryKeywordPreferenceRepositoryProvider._();

/// CategoryKeywordPreferenceRepository provider.

final class CategoryKeywordPreferenceRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryKeywordPreferenceRepository,
          CategoryKeywordPreferenceRepository,
          CategoryKeywordPreferenceRepository
        >
    with $Provider<CategoryKeywordPreferenceRepository> {
  /// CategoryKeywordPreferenceRepository provider.
  CategoryKeywordPreferenceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryKeywordPreferenceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$categoryKeywordPreferenceRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryKeywordPreferenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryKeywordPreferenceRepository create(Ref ref) {
    return categoryKeywordPreferenceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryKeywordPreferenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryKeywordPreferenceRepository>(
        value,
      ),
    );
  }
}

String _$categoryKeywordPreferenceRepositoryHash() =>
    r'e5179f02c7ea66cfa7c354d2bc0c349d1aaf6fdb';

@ProviderFor(createTransactionUseCase)
final createTransactionUseCaseProvider = CreateTransactionUseCaseProvider._();

final class CreateTransactionUseCaseProvider
    extends
        $FunctionalProvider<
          CreateTransactionUseCase,
          CreateTransactionUseCase,
          CreateTransactionUseCase
        >
    with $Provider<CreateTransactionUseCase> {
  CreateTransactionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createTransactionUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createTransactionUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateTransactionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateTransactionUseCase create(Ref ref) {
    return createTransactionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateTransactionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateTransactionUseCase>(value),
    );
  }
}

String _$createTransactionUseCaseHash() =>
    r'7b348e60ef0e21d753786ad4af39e9cf9b2b7442';

@ProviderFor(updateTransactionUseCase)
final updateTransactionUseCaseProvider = UpdateTransactionUseCaseProvider._();

final class UpdateTransactionUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateTransactionUseCase,
          UpdateTransactionUseCase,
          UpdateTransactionUseCase
        >
    with $Provider<UpdateTransactionUseCase> {
  UpdateTransactionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateTransactionUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateTransactionUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateTransactionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateTransactionUseCase create(Ref ref) {
    return updateTransactionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateTransactionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateTransactionUseCase>(value),
    );
  }
}

String _$updateTransactionUseCaseHash() =>
    r'2d93a1870453f403a491cbb6b1e125f621fe76e0';

@ProviderFor(getTransactionsUseCase)
final getTransactionsUseCaseProvider = GetTransactionsUseCaseProvider._();

final class GetTransactionsUseCaseProvider
    extends
        $FunctionalProvider<
          GetTransactionsUseCase,
          GetTransactionsUseCase,
          GetTransactionsUseCase
        >
    with $Provider<GetTransactionsUseCase> {
  GetTransactionsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getTransactionsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getTransactionsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTransactionsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetTransactionsUseCase create(Ref ref) {
    return getTransactionsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTransactionsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTransactionsUseCase>(value),
    );
  }
}

String _$getTransactionsUseCaseHash() =>
    r'664cacb8c958067685e46bd87980a68b66734e50';

@ProviderFor(deleteTransactionUseCase)
final deleteTransactionUseCaseProvider = DeleteTransactionUseCaseProvider._();

final class DeleteTransactionUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteTransactionUseCase,
          DeleteTransactionUseCase,
          DeleteTransactionUseCase
        >
    with $Provider<DeleteTransactionUseCase> {
  DeleteTransactionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteTransactionUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteTransactionUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteTransactionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteTransactionUseCase create(Ref ref) {
    return deleteTransactionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteTransactionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteTransactionUseCase>(value),
    );
  }
}

String _$deleteTransactionUseCaseHash() =>
    r'4a3f0ac07e4bb9b95de0de888aa1f930cefc371c';

@ProviderFor(seedCategoriesUseCase)
final seedCategoriesUseCaseProvider = SeedCategoriesUseCaseProvider._();

final class SeedCategoriesUseCaseProvider
    extends
        $FunctionalProvider<
          SeedCategoriesUseCase,
          SeedCategoriesUseCase,
          SeedCategoriesUseCase
        >
    with $Provider<SeedCategoriesUseCase> {
  SeedCategoriesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seedCategoriesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seedCategoriesUseCaseHash();

  @$internal
  @override
  $ProviderElement<SeedCategoriesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SeedCategoriesUseCase create(Ref ref) {
    return seedCategoriesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeedCategoriesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeedCategoriesUseCase>(value),
    );
  }
}

String _$seedCategoriesUseCaseHash() =>
    r'a4caa1f0c963fd92d35540d8de28751995f2020f';

/// Phase 21 D-01 — seeds default voice synonyms after categories.

@ProviderFor(seedVoiceSynonymsUseCase)
final seedVoiceSynonymsUseCaseProvider = SeedVoiceSynonymsUseCaseProvider._();

/// Phase 21 D-01 — seeds default voice synonyms after categories.

final class SeedVoiceSynonymsUseCaseProvider
    extends
        $FunctionalProvider<
          SeedVoiceSynonymsUseCase,
          SeedVoiceSynonymsUseCase,
          SeedVoiceSynonymsUseCase
        >
    with $Provider<SeedVoiceSynonymsUseCase> {
  /// Phase 21 D-01 — seeds default voice synonyms after categories.
  SeedVoiceSynonymsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seedVoiceSynonymsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seedVoiceSynonymsUseCaseHash();

  @$internal
  @override
  $ProviderElement<SeedVoiceSynonymsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SeedVoiceSynonymsUseCase create(Ref ref) {
    return seedVoiceSynonymsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeedVoiceSynonymsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeedVoiceSynonymsUseCase>(value),
    );
  }
}

String _$seedVoiceSynonymsUseCaseHash() =>
    r'841f677819587fe04a615c7ce084a6f6f07c457a';

/// Phase 49 D-05 — seeds the curated Japan merchant spine after categories.
///
/// Count-guarded idempotent seed (mirrors [seedCategoriesUseCaseProvider]).
/// Wired as the third leaf of [SeedAllUseCase], NOT the AppInitializer
/// `seedRunner` no-op (Pitfall #1).

@ProviderFor(seedMerchantsUseCase)
final seedMerchantsUseCaseProvider = SeedMerchantsUseCaseProvider._();

/// Phase 49 D-05 — seeds the curated Japan merchant spine after categories.
///
/// Count-guarded idempotent seed (mirrors [seedCategoriesUseCaseProvider]).
/// Wired as the third leaf of [SeedAllUseCase], NOT the AppInitializer
/// `seedRunner` no-op (Pitfall #1).

final class SeedMerchantsUseCaseProvider
    extends
        $FunctionalProvider<
          SeedMerchantsUseCase,
          SeedMerchantsUseCase,
          SeedMerchantsUseCase
        >
    with $Provider<SeedMerchantsUseCase> {
  /// Phase 49 D-05 — seeds the curated Japan merchant spine after categories.
  ///
  /// Count-guarded idempotent seed (mirrors [seedCategoriesUseCaseProvider]).
  /// Wired as the third leaf of [SeedAllUseCase], NOT the AppInitializer
  /// `seedRunner` no-op (Pitfall #1).
  SeedMerchantsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seedMerchantsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seedMerchantsUseCaseHash();

  @$internal
  @override
  $ProviderElement<SeedMerchantsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SeedMerchantsUseCase create(Ref ref) {
    return seedMerchantsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeedMerchantsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeedMerchantsUseCase>(value),
    );
  }
}

String _$seedMerchantsUseCaseHash() =>
    r'a3ff015f974342a5501e1d79582cdfc7cb65da1d';

@ProviderFor(categoryService)
final categoryServiceProvider = CategoryServiceProvider._();

final class CategoryServiceProvider
    extends
        $FunctionalProvider<CategoryService, CategoryService, CategoryService>
    with $Provider<CategoryService> {
  CategoryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryServiceHash();

  @$internal
  @override
  $ProviderElement<CategoryService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CategoryService create(Ref ref) {
    return categoryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryService>(value),
    );
  }
}

String _$categoryServiceHash() => r'0a0159aff6dd29a6c973915fe8a31e02b5d4beb7';

@ProviderFor(ensureDefaultBookUseCase)
final ensureDefaultBookUseCaseProvider = EnsureDefaultBookUseCaseProvider._();

final class EnsureDefaultBookUseCaseProvider
    extends
        $FunctionalProvider<
          EnsureDefaultBookUseCase,
          EnsureDefaultBookUseCase,
          EnsureDefaultBookUseCase
        >
    with $Provider<EnsureDefaultBookUseCase> {
  EnsureDefaultBookUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ensureDefaultBookUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ensureDefaultBookUseCaseHash();

  @$internal
  @override
  $ProviderElement<EnsureDefaultBookUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EnsureDefaultBookUseCase create(Ref ref) {
    return ensureDefaultBookUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EnsureDefaultBookUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EnsureDefaultBookUseCase>(value),
    );
  }
}

String _$ensureDefaultBookUseCaseHash() =>
    r'37e41e1327696132edf238d026cdfcb9f86ba297';

@ProviderFor(merchantCategoryLearningService)
final merchantCategoryLearningServiceProvider =
    MerchantCategoryLearningServiceProvider._();

final class MerchantCategoryLearningServiceProvider
    extends
        $FunctionalProvider<
          MerchantCategoryLearningService,
          MerchantCategoryLearningService,
          MerchantCategoryLearningService
        >
    with $Provider<MerchantCategoryLearningService> {
  MerchantCategoryLearningServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantCategoryLearningServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantCategoryLearningServiceHash();

  @$internal
  @override
  $ProviderElement<MerchantCategoryLearningService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MerchantCategoryLearningService create(Ref ref) {
    return merchantCategoryLearningService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MerchantCategoryLearningService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MerchantCategoryLearningService>(
        value,
      ),
    );
  }
}

String _$merchantCategoryLearningServiceHash() =>
    r'17a57f6c50e022072ffd2bdcd44230e7a98b463e';

@ProviderFor(recordCategoryCorrectionUseCase)
final recordCategoryCorrectionUseCaseProvider =
    RecordCategoryCorrectionUseCaseProvider._();

final class RecordCategoryCorrectionUseCaseProvider
    extends
        $FunctionalProvider<
          RecordCategoryCorrectionUseCase,
          RecordCategoryCorrectionUseCase,
          RecordCategoryCorrectionUseCase
        >
    with $Provider<RecordCategoryCorrectionUseCase> {
  RecordCategoryCorrectionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordCategoryCorrectionUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordCategoryCorrectionUseCaseHash();

  @$internal
  @override
  $ProviderElement<RecordCategoryCorrectionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecordCategoryCorrectionUseCase create(Ref ref) {
    return recordCategoryCorrectionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordCategoryCorrectionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordCategoryCorrectionUseCase>(
        value,
      ),
    );
  }
}

String _$recordCategoryCorrectionUseCaseHash() =>
    r'9fc30b2a5e18adff9d18a15ea9f2a05212698750';

/// VoiceTextParser — stateless NLP parser, auto-disposed when not in use.

@ProviderFor(voiceTextParser)
final voiceTextParserProvider = VoiceTextParserProvider._();

/// VoiceTextParser — stateless NLP parser, auto-disposed when not in use.

final class VoiceTextParserProvider
    extends
        $FunctionalProvider<VoiceTextParser, VoiceTextParser, VoiceTextParser>
    with $Provider<VoiceTextParser> {
  /// VoiceTextParser — stateless NLP parser, auto-disposed when not in use.
  VoiceTextParserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceTextParserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceTextParserHash();

  @$internal
  @override
  $ProviderElement<VoiceTextParser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VoiceTextParser create(Ref ref) {
    return voiceTextParser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceTextParser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceTextParser>(value),
    );
  }
}

String _$voiceTextParserHash() => r'3493d74d0200f77486db448b8fc371a0fb3030fd';

/// CategoryRecognizer — Phase 50 keyword-only engine (DECOUP-01/DECOUP-02).
///
/// `VoiceCategoryResolver` minus its step-1 vendor lookup and its
/// vendor-database dependency. Runs unconditionally; always returns an L2
/// categoryId (D-03 always-L2 contract). Constructed from the three
/// keyword-pipeline data sources only — no merchant database.

@ProviderFor(categoryRecognizer)
final categoryRecognizerProvider = CategoryRecognizerProvider._();

/// CategoryRecognizer — Phase 50 keyword-only engine (DECOUP-01/DECOUP-02).
///
/// `VoiceCategoryResolver` minus its step-1 vendor lookup and its
/// vendor-database dependency. Runs unconditionally; always returns an L2
/// categoryId (D-03 always-L2 contract). Constructed from the three
/// keyword-pipeline data sources only — no merchant database.

final class CategoryRecognizerProvider
    extends
        $FunctionalProvider<
          CategoryRecognizer,
          CategoryRecognizer,
          CategoryRecognizer
        >
    with $Provider<CategoryRecognizer> {
  /// CategoryRecognizer — Phase 50 keyword-only engine (DECOUP-01/DECOUP-02).
  ///
  /// `VoiceCategoryResolver` minus its step-1 vendor lookup and its
  /// vendor-database dependency. Runs unconditionally; always returns an L2
  /// categoryId (D-03 always-L2 contract). Constructed from the three
  /// keyword-pipeline data sources only — no merchant database.
  CategoryRecognizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryRecognizerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryRecognizerHash();

  @$internal
  @override
  $ProviderElement<CategoryRecognizer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryRecognizer create(Ref ref) {
    return categoryRecognizer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryRecognizer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryRecognizer>(value),
    );
  }
}

String _$categoryRecognizerHash() =>
    r'0f40c85d8948aa871440620a39816eb4cf46db06';

/// MerchantRecognizer — Phase 50 anchored scorer (DECOUP-03).
///
/// Recall-first ranker over Phase-49's `merchant_match_keys`. Takes only a
/// [MerchantRepository]; never references the keyword/category recognizer
/// (construction independence, DECOUP-01). `keepAlive` because it warms an
/// in-memory cache of every match-key surface once per app session.

@ProviderFor(merchantRecognizer)
final merchantRecognizerProvider = MerchantRecognizerProvider._();

/// MerchantRecognizer — Phase 50 anchored scorer (DECOUP-03).
///
/// Recall-first ranker over Phase-49's `merchant_match_keys`. Takes only a
/// [MerchantRepository]; never references the keyword/category recognizer
/// (construction independence, DECOUP-01). `keepAlive` because it warms an
/// in-memory cache of every match-key surface once per app session.

final class MerchantRecognizerProvider
    extends
        $FunctionalProvider<
          MerchantRecognizer,
          MerchantRecognizer,
          MerchantRecognizer
        >
    with $Provider<MerchantRecognizer> {
  /// MerchantRecognizer — Phase 50 anchored scorer (DECOUP-03).
  ///
  /// Recall-first ranker over Phase-49's `merchant_match_keys`. Takes only a
  /// [MerchantRepository]; never references the keyword/category recognizer
  /// (construction independence, DECOUP-01). `keepAlive` because it warms an
  /// in-memory cache of every match-key surface once per app session.
  MerchantRecognizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantRecognizerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantRecognizerHash();

  @$internal
  @override
  $ProviderElement<MerchantRecognizer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MerchantRecognizer create(Ref ref) {
    return merchantRecognizer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MerchantRecognizer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MerchantRecognizer>(value),
    );
  }
}

String _$merchantRecognizerHash() =>
    r'c90c7072dfb13e69c23b99662f744e3a51e1fbee';

/// ParseVoiceInputUseCase — wired to both decoupled voice engines.
///
/// The orchestrator runs [CategoryRecognizer] and [MerchantRecognizer]
/// independently and applies the thin keyword-priority merge with the 0.85
/// auto-fill floor (D-02 / D-03). Ledger is derived from the final category
/// via `resolveLedgerType` — never the merchant's ledger hint.

@ProviderFor(parseVoiceInputUseCase)
final parseVoiceInputUseCaseProvider = ParseVoiceInputUseCaseProvider._();

/// ParseVoiceInputUseCase — wired to both decoupled voice engines.
///
/// The orchestrator runs [CategoryRecognizer] and [MerchantRecognizer]
/// independently and applies the thin keyword-priority merge with the 0.85
/// auto-fill floor (D-02 / D-03). Ledger is derived from the final category
/// via `resolveLedgerType` — never the merchant's ledger hint.

final class ParseVoiceInputUseCaseProvider
    extends
        $FunctionalProvider<
          ParseVoiceInputUseCase,
          ParseVoiceInputUseCase,
          ParseVoiceInputUseCase
        >
    with $Provider<ParseVoiceInputUseCase> {
  /// ParseVoiceInputUseCase — wired to both decoupled voice engines.
  ///
  /// The orchestrator runs [CategoryRecognizer] and [MerchantRecognizer]
  /// independently and applies the thin keyword-priority merge with the 0.85
  /// auto-fill floor (D-02 / D-03). Ledger is derived from the final category
  /// via `resolveLedgerType` — never the merchant's ledger hint.
  ParseVoiceInputUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'parseVoiceInputUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$parseVoiceInputUseCaseHash();

  @$internal
  @override
  $ProviderElement<ParseVoiceInputUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ParseVoiceInputUseCase create(Ref ref) {
    return parseVoiceInputUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ParseVoiceInputUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ParseVoiceInputUseCase>(value),
    );
  }
}

String _$parseVoiceInputUseCaseHash() =>
    r'15dacf0e6edc1b57902d91698d6b925a46e2f975';

/// VoiceSatisfactionEstimator — pure stateless class.

@ProviderFor(voiceSatisfactionEstimator)
final voiceSatisfactionEstimatorProvider =
    VoiceSatisfactionEstimatorProvider._();

/// VoiceSatisfactionEstimator — pure stateless class.

final class VoiceSatisfactionEstimatorProvider
    extends
        $FunctionalProvider<
          VoiceSatisfactionEstimator,
          VoiceSatisfactionEstimator,
          VoiceSatisfactionEstimator
        >
    with $Provider<VoiceSatisfactionEstimator> {
  /// VoiceSatisfactionEstimator — pure stateless class.
  VoiceSatisfactionEstimatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceSatisfactionEstimatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceSatisfactionEstimatorHash();

  @$internal
  @override
  $ProviderElement<VoiceSatisfactionEstimator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoiceSatisfactionEstimator create(Ref ref) {
    return voiceSatisfactionEstimator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceSatisfactionEstimator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceSatisfactionEstimator>(value),
    );
  }
}

String _$voiceSatisfactionEstimatorHash() =>
    r'633b00ee3ba24d00f0bf477ac217841dbcb2db4c';

/// Phase 23 D-14: composition of the three seed use cases (quality report
/// P1-2: moved here from application/seed/seed_providers.dart — wiring
/// providers belong in a feature composition root, and an application-layer
/// provider watching presentation providers was a reverse layer dependency).
///
/// Composes the three leaf providers via [ref.watch] so the ordering
/// contract is owned by [SeedAllUseCase.execute()], not by call-site comments.

@ProviderFor(seedAllUseCase)
final seedAllUseCaseProvider = SeedAllUseCaseProvider._();

/// Phase 23 D-14: composition of the three seed use cases (quality report
/// P1-2: moved here from application/seed/seed_providers.dart — wiring
/// providers belong in a feature composition root, and an application-layer
/// provider watching presentation providers was a reverse layer dependency).
///
/// Composes the three leaf providers via [ref.watch] so the ordering
/// contract is owned by [SeedAllUseCase.execute()], not by call-site comments.

final class SeedAllUseCaseProvider
    extends $FunctionalProvider<SeedAllUseCase, SeedAllUseCase, SeedAllUseCase>
    with $Provider<SeedAllUseCase> {
  /// Phase 23 D-14: composition of the three seed use cases (quality report
  /// P1-2: moved here from application/seed/seed_providers.dart — wiring
  /// providers belong in a feature composition root, and an application-layer
  /// provider watching presentation providers was a reverse layer dependency).
  ///
  /// Composes the three leaf providers via [ref.watch] so the ordering
  /// contract is owned by [SeedAllUseCase.execute()], not by call-site comments.
  SeedAllUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seedAllUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seedAllUseCaseHash();

  @$internal
  @override
  $ProviderElement<SeedAllUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SeedAllUseCase create(Ref ref) {
    return seedAllUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeedAllUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeedAllUseCase>(value),
    );
  }
}

String _$seedAllUseCaseHash() => r'2b82c286309cea3e0ee0e058d6824c39014c2137';
