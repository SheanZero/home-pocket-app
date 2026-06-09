// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_shopping_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the current shopping-list view segment.
///
/// Values: 'all' (全部 — merges private + public) | 'private' (个人 — private only).
/// Default is 'all'. The toggle is only shown in group mode; when solo, the view
/// stays 'all' (which is identical to private since no shared items exist).
///
/// Kept alive across IndexedStack tab switches (D38, SC2) so that the
/// selected segment persists when the user navigates away and returns.
/// On segment switch, [ShoppingFilter.resetForNewSegment] is called to
/// reset filter state (D5/FILT-02 — filter shared across both segments
/// but resets on switch).

@ProviderFor(ListType)
final listTypeProvider = ListTypeProvider._();

/// Holds the current shopping-list view segment.
///
/// Values: 'all' (全部 — merges private + public) | 'private' (个人 — private only).
/// Default is 'all'. The toggle is only shown in group mode; when solo, the view
/// stays 'all' (which is identical to private since no shared items exist).
///
/// Kept alive across IndexedStack tab switches (D38, SC2) so that the
/// selected segment persists when the user navigates away and returns.
/// On segment switch, [ShoppingFilter.resetForNewSegment] is called to
/// reset filter state (D5/FILT-02 — filter shared across both segments
/// but resets on switch).
final class ListTypeProvider extends $NotifierProvider<ListType, String> {
  /// Holds the current shopping-list view segment.
  ///
  /// Values: 'all' (全部 — merges private + public) | 'private' (个人 — private only).
  /// Default is 'all'. The toggle is only shown in group mode; when solo, the view
  /// stays 'all' (which is identical to private since no shared items exist).
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

String _$listTypeHash() => r'068dc3a138ddd6a980a926c8bab16b4f1f1fc1d4';

/// Holds the current shopping-list view segment.
///
/// Values: 'all' (全部 — merges private + public) | 'private' (个人 — private only).
/// Default is 'all'. The toggle is only shown in group mode; when solo, the view
/// stays 'all' (which is identical to private since no shared items exist).
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
/// [setPrivateFilter] toggles the 私有 filter chip (G8Z) — always visible
/// regardless of group membership.

@ProviderFor(ShoppingFilter)
final shoppingFilterProvider = ShoppingFilterProvider._();

/// Holds the filter state for the shopping list view.
///
/// Kept alive across IndexedStack tab switches (SC2) so that filter selections
/// persist when the user navigates away from the shopping tab and returns.
/// [resetForNewSegment] is called automatically when the list type switches (D5).
/// [setPrivateFilter] toggles the 私有 filter chip (G8Z) — always visible
/// regardless of group membership.
final class ShoppingFilterProvider
    extends $NotifierProvider<ShoppingFilter, ShoppingListFilter> {
  /// Holds the filter state for the shopping list view.
  ///
  /// Kept alive across IndexedStack tab switches (SC2) so that filter selections
  /// persist when the user navigates away from the shopping tab and returns.
  /// [resetForNewSegment] is called automatically when the list type switches (D5).
  /// [setPrivateFilter] toggles the 私有 filter chip (G8Z) — always visible
  /// regardless of group membership.
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

String _$shoppingFilterHash() => r'37a9805bd1184fb40f046dd524ecf6de57a7cfb8';

/// Holds the filter state for the shopping list view.
///
/// Kept alive across IndexedStack tab switches (SC2) so that filter selections
/// persist when the user navigates away from the shopping tab and returns.
/// [resetForNewSegment] is called automatically when the list type switches (D5).
/// [setPrivateFilter] toggles the 私有 filter chip (G8Z) — always visible
/// regardless of group membership.

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
