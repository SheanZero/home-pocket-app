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
    r'ba9abda10af0bd2a4ad8d5e1f2bc3f20f9deb0a9';

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
    r'3dcb5ae0a44bcb4677d4eaa3b3673c3464826407';

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
    r'1af571467047be7810f518919f2fe36af85b4917';

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
    r'c0d100c9d2a03b8f332929c1dd11580e9243377a';

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
    r'2c9c325560e5e577f42ccc1462742afe722a026b';

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
