// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ShoppingItemRepository provider.
///
/// Uses [ShoppingItemRepositoryImpl] wired with the application-layer database
/// and field encryption service.

@ProviderFor(shoppingItemRepository)
final shoppingItemRepositoryProvider = ShoppingItemRepositoryProvider._();

/// ShoppingItemRepository provider.
///
/// Uses [ShoppingItemRepositoryImpl] wired with the application-layer database
/// and field encryption service.

final class ShoppingItemRepositoryProvider
    extends
        $FunctionalProvider<
          ShoppingItemRepository,
          ShoppingItemRepository,
          ShoppingItemRepository
        >
    with $Provider<ShoppingItemRepository> {
  /// ShoppingItemRepository provider.
  ///
  /// Uses [ShoppingItemRepositoryImpl] wired with the application-layer database
  /// and field encryption service.
  ShoppingItemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingItemRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingItemRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShoppingItemRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingItemRepository create(Ref ref) {
    return shoppingItemRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingItemRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingItemRepository>(value),
    );
  }
}

String _$shoppingItemRepositoryHash() =>
    r'8d72a92f4a00eb850078c548bac926c518839491';

@ProviderFor(shoppingUnitUsageRepository)
final shoppingUnitUsageRepositoryProvider =
    ShoppingUnitUsageRepositoryProvider._();

final class ShoppingUnitUsageRepositoryProvider
    extends
        $FunctionalProvider<
          ShoppingUnitUsageRepository,
          ShoppingUnitUsageRepository,
          ShoppingUnitUsageRepository
        >
    with $Provider<ShoppingUnitUsageRepository> {
  ShoppingUnitUsageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingUnitUsageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingUnitUsageRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShoppingUnitUsageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingUnitUsageRepository create(Ref ref) {
    return shoppingUnitUsageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingUnitUsageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingUnitUsageRepository>(value),
    );
  }
}

String _$shoppingUnitUsageRepositoryHash() =>
    r'0223dbc60e9b701a324feea3fdab96db6dd0abdd';

/// Up to three learned unit shortcuts. Hidden for the first ten creations and
/// whenever the history contains only one distinct unit.

@ProviderFor(shoppingUnitSuggestions)
final shoppingUnitSuggestionsProvider = ShoppingUnitSuggestionsProvider._();

/// Up to three learned unit shortcuts. Hidden for the first ten creations and
/// whenever the history contains only one distinct unit.

final class ShoppingUnitSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingUnitSuggestion>>,
          List<ShoppingUnitSuggestion>,
          Stream<List<ShoppingUnitSuggestion>>
        >
    with
        $FutureModifier<List<ShoppingUnitSuggestion>>,
        $StreamProvider<List<ShoppingUnitSuggestion>> {
  /// Up to three learned unit shortcuts. Hidden for the first ten creations and
  /// whenever the history contains only one distinct unit.
  ShoppingUnitSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingUnitSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingUnitSuggestionsHash();

  @$internal
  @override
  $StreamProviderElement<List<ShoppingUnitSuggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ShoppingUnitSuggestion>> create(Ref ref) {
    return shoppingUnitSuggestions(ref);
  }
}

String _$shoppingUnitSuggestionsHash() =>
    r'57f9bb7e6e90c89dc08e7f6dfe10833aa636f95a';

/// [CreateShoppingItemUseCase] provider wired with repo + sync deps.
///
/// Privacy gate (D37-06): only public items enter the sync pipeline;
/// the use case enforces this internally.

@ProviderFor(createShoppingItemUseCase)
final createShoppingItemUseCaseProvider = CreateShoppingItemUseCaseProvider._();

/// [CreateShoppingItemUseCase] provider wired with repo + sync deps.
///
/// Privacy gate (D37-06): only public items enter the sync pipeline;
/// the use case enforces this internally.

final class CreateShoppingItemUseCaseProvider
    extends
        $FunctionalProvider<
          CreateShoppingItemUseCase,
          CreateShoppingItemUseCase,
          CreateShoppingItemUseCase
        >
    with $Provider<CreateShoppingItemUseCase> {
  /// [CreateShoppingItemUseCase] provider wired with repo + sync deps.
  ///
  /// Privacy gate (D37-06): only public items enter the sync pipeline;
  /// the use case enforces this internally.
  CreateShoppingItemUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createShoppingItemUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createShoppingItemUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateShoppingItemUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateShoppingItemUseCase create(Ref ref) {
    return createShoppingItemUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateShoppingItemUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateShoppingItemUseCase>(value),
    );
  }
}

String _$createShoppingItemUseCaseHash() =>
    r'be8d5d79044a7fa62e27b005a1baf831bb71535a';

/// [ToggleItemCompletedUseCase] provider wired with repo + sync deps.

@ProviderFor(toggleItemCompletedUseCase)
final toggleItemCompletedUseCaseProvider =
    ToggleItemCompletedUseCaseProvider._();

/// [ToggleItemCompletedUseCase] provider wired with repo + sync deps.

final class ToggleItemCompletedUseCaseProvider
    extends
        $FunctionalProvider<
          ToggleItemCompletedUseCase,
          ToggleItemCompletedUseCase,
          ToggleItemCompletedUseCase
        >
    with $Provider<ToggleItemCompletedUseCase> {
  /// [ToggleItemCompletedUseCase] provider wired with repo + sync deps.
  ToggleItemCompletedUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toggleItemCompletedUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toggleItemCompletedUseCaseHash();

  @$internal
  @override
  $ProviderElement<ToggleItemCompletedUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ToggleItemCompletedUseCase create(Ref ref) {
    return toggleItemCompletedUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToggleItemCompletedUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToggleItemCompletedUseCase>(value),
    );
  }
}

String _$toggleItemCompletedUseCaseHash() =>
    r'6833b8a4b128b416533c93bb954b669da4a7b9fe';

/// [DeleteShoppingItemUseCase] provider wired with repo + sync deps.

@ProviderFor(deleteShoppingItemUseCase)
final deleteShoppingItemUseCaseProvider = DeleteShoppingItemUseCaseProvider._();

/// [DeleteShoppingItemUseCase] provider wired with repo + sync deps.

final class DeleteShoppingItemUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteShoppingItemUseCase,
          DeleteShoppingItemUseCase,
          DeleteShoppingItemUseCase
        >
    with $Provider<DeleteShoppingItemUseCase> {
  /// [DeleteShoppingItemUseCase] provider wired with repo + sync deps.
  DeleteShoppingItemUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteShoppingItemUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteShoppingItemUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteShoppingItemUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteShoppingItemUseCase create(Ref ref) {
    return deleteShoppingItemUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteShoppingItemUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteShoppingItemUseCase>(value),
    );
  }
}

String _$deleteShoppingItemUseCaseHash() =>
    r'2bfd83076822b59b2dc38c6bbee1e2ee5609217e';

/// [UpdateShoppingItemUseCase] provider wired with repo + sync deps.

@ProviderFor(updateShoppingItemUseCase)
final updateShoppingItemUseCaseProvider = UpdateShoppingItemUseCaseProvider._();

/// [UpdateShoppingItemUseCase] provider wired with repo + sync deps.

final class UpdateShoppingItemUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateShoppingItemUseCase,
          UpdateShoppingItemUseCase,
          UpdateShoppingItemUseCase
        >
    with $Provider<UpdateShoppingItemUseCase> {
  /// [UpdateShoppingItemUseCase] provider wired with repo + sync deps.
  UpdateShoppingItemUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateShoppingItemUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateShoppingItemUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateShoppingItemUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateShoppingItemUseCase create(Ref ref) {
    return updateShoppingItemUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateShoppingItemUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateShoppingItemUseCase>(value),
    );
  }
}

String _$updateShoppingItemUseCaseHash() =>
    r'c4e40d9a158ac092841dd28ec6aa37316c649a6f';

/// [ReorderShoppingItemsUseCase] provider — repo only, no sync deps.
///
/// D37-01: sortOrder is local-per-device — NOT synced. This use case
/// intentionally has no changeTracker and no syncEngine.

@ProviderFor(reorderShoppingItemsUseCase)
final reorderShoppingItemsUseCaseProvider =
    ReorderShoppingItemsUseCaseProvider._();

/// [ReorderShoppingItemsUseCase] provider — repo only, no sync deps.
///
/// D37-01: sortOrder is local-per-device — NOT synced. This use case
/// intentionally has no changeTracker and no syncEngine.

final class ReorderShoppingItemsUseCaseProvider
    extends
        $FunctionalProvider<
          ReorderShoppingItemsUseCase,
          ReorderShoppingItemsUseCase,
          ReorderShoppingItemsUseCase
        >
    with $Provider<ReorderShoppingItemsUseCase> {
  /// [ReorderShoppingItemsUseCase] provider — repo only, no sync deps.
  ///
  /// D37-01: sortOrder is local-per-device — NOT synced. This use case
  /// intentionally has no changeTracker and no syncEngine.
  ReorderShoppingItemsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reorderShoppingItemsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reorderShoppingItemsUseCaseHash();

  @$internal
  @override
  $ProviderElement<ReorderShoppingItemsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReorderShoppingItemsUseCase create(Ref ref) {
    return reorderShoppingItemsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReorderShoppingItemsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReorderShoppingItemsUseCase>(value),
    );
  }
}

String _$reorderShoppingItemsUseCaseHash() =>
    r'54f8061d59bb97f4a70b1aff88277fcda7cf10e9';

/// [ClearCompletedItemsUseCase] provider wired with repo + sync deps.

@ProviderFor(clearCompletedItemsUseCase)
final clearCompletedItemsUseCaseProvider =
    ClearCompletedItemsUseCaseProvider._();

/// [ClearCompletedItemsUseCase] provider wired with repo + sync deps.

final class ClearCompletedItemsUseCaseProvider
    extends
        $FunctionalProvider<
          ClearCompletedItemsUseCase,
          ClearCompletedItemsUseCase,
          ClearCompletedItemsUseCase
        >
    with $Provider<ClearCompletedItemsUseCase> {
  /// [ClearCompletedItemsUseCase] provider wired with repo + sync deps.
  ClearCompletedItemsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clearCompletedItemsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clearCompletedItemsUseCaseHash();

  @$internal
  @override
  $ProviderElement<ClearCompletedItemsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClearCompletedItemsUseCase create(Ref ref) {
    return clearCompletedItemsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClearCompletedItemsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClearCompletedItemsUseCase>(value),
    );
  }
}

String _$clearCompletedItemsUseCaseHash() =>
    r'5b5f42eee206bfd8bd890e9d9e8ab36845698f88';

/// Derived stream of filtered shopping items for the current segment.
///
/// Watches both [listTypeProvider] and [shoppingFilterProvider] so any
/// filter chip change triggers a re-emission.
///
/// Implementation note (D38-04 / Pitfall 5): the DAO returns ALL non-deleted
/// items for a given listType. Ledger, category, and status filtering is done
/// client-side here — NOT in SQL — to keep the reactive stream simple and avoid
/// extra DAO variants. The privacy gate (public/private separation) is enforced
/// at the DAO level via [watchByListType]; the client-side filter is cosmetic.
///
/// NEVER call ref.invalidate on this provider — reactivity comes from the
/// Drift stream emitting on DB writes (SC-5, reactive delivery).

@ProviderFor(filteredShoppingItems)
final filteredShoppingItemsProvider = FilteredShoppingItemsProvider._();

/// Derived stream of filtered shopping items for the current segment.
///
/// Watches both [listTypeProvider] and [shoppingFilterProvider] so any
/// filter chip change triggers a re-emission.
///
/// Implementation note (D38-04 / Pitfall 5): the DAO returns ALL non-deleted
/// items for a given listType. Ledger, category, and status filtering is done
/// client-side here — NOT in SQL — to keep the reactive stream simple and avoid
/// extra DAO variants. The privacy gate (public/private separation) is enforced
/// at the DAO level via [watchByListType]; the client-side filter is cosmetic.
///
/// NEVER call ref.invalidate on this provider — reactivity comes from the
/// Drift stream emitting on DB writes (SC-5, reactive delivery).

final class FilteredShoppingItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingItem>>,
          List<ShoppingItem>,
          Stream<List<ShoppingItem>>
        >
    with
        $FutureModifier<List<ShoppingItem>>,
        $StreamProvider<List<ShoppingItem>> {
  /// Derived stream of filtered shopping items for the current segment.
  ///
  /// Watches both [listTypeProvider] and [shoppingFilterProvider] so any
  /// filter chip change triggers a re-emission.
  ///
  /// Implementation note (D38-04 / Pitfall 5): the DAO returns ALL non-deleted
  /// items for a given listType. Ledger, category, and status filtering is done
  /// client-side here — NOT in SQL — to keep the reactive stream simple and avoid
  /// extra DAO variants. The privacy gate (public/private separation) is enforced
  /// at the DAO level via [watchByListType]; the client-side filter is cosmetic.
  ///
  /// NEVER call ref.invalidate on this provider — reactivity comes from the
  /// Drift stream emitting on DB writes (SC-5, reactive delivery).
  FilteredShoppingItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredShoppingItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredShoppingItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<ShoppingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ShoppingItem>> create(Ref ref) {
    return filteredShoppingItems(ref);
  }
}

String _$filteredShoppingItemsHash() =>
    r'96fe30639903a779119cf895e3ad4cd658796991';
