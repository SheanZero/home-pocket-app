// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_shopping_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the current segment ('public' | 'private') for the shopping list.
///
/// Kept alive across IndexedStack tab switches (D38, SC2) so that the
/// selected segment persists when the user navigates away and returns.
/// On segment switch, [ShoppingFilter.resetForNewSegment] is called to
/// reset filter state (D5/FILT-02 — filter shared across both segments
/// but resets on switch).

@ProviderFor(ListType)
final listTypeProvider = ListTypeProvider._();

/// Holds the current segment ('public' | 'private') for the shopping list.
///
/// Kept alive across IndexedStack tab switches (D38, SC2) so that the
/// selected segment persists when the user navigates away and returns.
/// On segment switch, [ShoppingFilter.resetForNewSegment] is called to
/// reset filter state (D5/FILT-02 — filter shared across both segments
/// but resets on switch).
final class ListTypeProvider extends $NotifierProvider<ListType, String> {
  /// Holds the current segment ('public' | 'private') for the shopping list.
  ///
  /// Kept alive across IndexedStack tab switches (D38, SC2) so that the
  /// selected segment persists when the user navigates away and returns.
  /// On segment switch, [ShoppingFilter.resetForNewSegment] is called to
  /// reset filter state (D5/FILT-02 — filter shared across both segments
  /// but resets on switch).
  ListTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listTypeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listTypeHash();

  @$internal
  @override
  ListType create() => ListType();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$listTypeHash() => r'057d9f655956c105ec05d14d32ae36d49c5bd70b';

/// Holds the current segment ('public' | 'private') for the shopping list.
///
/// Kept alive across IndexedStack tab switches (D38, SC2) so that the
/// selected segment persists when the user navigates away and returns.
/// On segment switch, [ShoppingFilter.resetForNewSegment] is called to
/// reset filter state (D5/FILT-02 — filter shared across both segments
/// but resets on switch).

abstract class _$ListType extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Holds the filter state for the shopping list view.
///
/// Kept alive across IndexedStack tab switches (SC2) so that filter selections
/// persist when the user navigates away from the shopping tab and returns.
/// [resetForNewSegment] is called automatically when the list type switches (D5).

@ProviderFor(ShoppingFilter)
final shoppingFilterProvider = ShoppingFilterProvider._();

/// Holds the filter state for the shopping list view.
///
/// Kept alive across IndexedStack tab switches (SC2) so that filter selections
/// persist when the user navigates away from the shopping tab and returns.
/// [resetForNewSegment] is called automatically when the list type switches (D5).
final class ShoppingFilterProvider
    extends $NotifierProvider<ShoppingFilter, ShoppingListFilter> {
  /// Holds the filter state for the shopping list view.
  ///
  /// Kept alive across IndexedStack tab switches (SC2) so that filter selections
  /// persist when the user navigates away from the shopping tab and returns.
  /// [resetForNewSegment] is called automatically when the list type switches (D5).
  ShoppingFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingFilterHash();

  @$internal
  @override
  ShoppingFilter create() => ShoppingFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListFilter>(value),
    );
  }
}

String _$shoppingFilterHash() => r'0220080ab663141f52c2f1ad923bbb6ba7855224';

/// Holds the filter state for the shopping list view.
///
/// Kept alive across IndexedStack tab switches (SC2) so that filter selections
/// persist when the user navigates away from the shopping tab and returns.
/// [resetForNewSegment] is called automatically when the list type switches (D5).

abstract class _$ShoppingFilter extends $Notifier<ShoppingListFilter> {
  ShoppingListFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ShoppingListFilter, ShoppingListFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShoppingListFilter, ShoppingListFilter>,
              ShoppingListFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
