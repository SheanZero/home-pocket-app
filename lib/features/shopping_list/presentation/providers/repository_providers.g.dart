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
