// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_shopping_reorder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pure-UI flag for the shopping list manual-reorder mode (EC2 / D-2).
///
/// `false` (default) — normal mode: tile body opens the edit form, the left
/// circle toggles completion, swipe-to-delete is enabled, and NO drag handle
/// is rendered (items are not reorderable).
/// `true` — reorder mode: the filter bar shows a ✓ exit affordance, each filter
/// chip gains a ≡ prefix, and every active tile renders a drag handle. Toggle,
/// tile-body edit and swipe-to-delete are all suppressed so the only available
/// gesture is dragging.
///
/// This state is NEVER persisted — it is a transient view mode. It is
/// [keepAlive] (matching [ShoppingFilter] / [ListType]) so the mode survives
/// IndexedStack tab switches while the shopping tab stays mounted.
///
/// Riverpod 3 suffix-stripping: `class ShoppingReorderMode` →
/// `shoppingReorderModeProvider`.

@ProviderFor(ShoppingReorderMode)
final shoppingReorderModeProvider = ShoppingReorderModeProvider._();

/// Pure-UI flag for the shopping list manual-reorder mode (EC2 / D-2).
///
/// `false` (default) — normal mode: tile body opens the edit form, the left
/// circle toggles completion, swipe-to-delete is enabled, and NO drag handle
/// is rendered (items are not reorderable).
/// `true` — reorder mode: the filter bar shows a ✓ exit affordance, each filter
/// chip gains a ≡ prefix, and every active tile renders a drag handle. Toggle,
/// tile-body edit and swipe-to-delete are all suppressed so the only available
/// gesture is dragging.
///
/// This state is NEVER persisted — it is a transient view mode. It is
/// [keepAlive] (matching [ShoppingFilter] / [ListType]) so the mode survives
/// IndexedStack tab switches while the shopping tab stays mounted.
///
/// Riverpod 3 suffix-stripping: `class ShoppingReorderMode` →
/// `shoppingReorderModeProvider`.
final class ShoppingReorderModeProvider
    extends $NotifierProvider<ShoppingReorderMode, bool> {
  /// Pure-UI flag for the shopping list manual-reorder mode (EC2 / D-2).
  ///
  /// `false` (default) — normal mode: tile body opens the edit form, the left
  /// circle toggles completion, swipe-to-delete is enabled, and NO drag handle
  /// is rendered (items are not reorderable).
  /// `true` — reorder mode: the filter bar shows a ✓ exit affordance, each filter
  /// chip gains a ≡ prefix, and every active tile renders a drag handle. Toggle,
  /// tile-body edit and swipe-to-delete are all suppressed so the only available
  /// gesture is dragging.
  ///
  /// This state is NEVER persisted — it is a transient view mode. It is
  /// [keepAlive] (matching [ShoppingFilter] / [ListType]) so the mode survives
  /// IndexedStack tab switches while the shopping tab stays mounted.
  ///
  /// Riverpod 3 suffix-stripping: `class ShoppingReorderMode` →
  /// `shoppingReorderModeProvider`.
  ShoppingReorderModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingReorderModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingReorderModeHash();

  @$internal
  @override
  ShoppingReorderMode create() => ShoppingReorderMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shoppingReorderModeHash() =>
    r'c587d7143c4ed894a271528ba40b86a6a70f441d';

/// Pure-UI flag for the shopping list manual-reorder mode (EC2 / D-2).
///
/// `false` (default) — normal mode: tile body opens the edit form, the left
/// circle toggles completion, swipe-to-delete is enabled, and NO drag handle
/// is rendered (items are not reorderable).
/// `true` — reorder mode: the filter bar shows a ✓ exit affordance, each filter
/// chip gains a ≡ prefix, and every active tile renders a drag handle. Toggle,
/// tile-body edit and swipe-to-delete are all suppressed so the only available
/// gesture is dragging.
///
/// This state is NEVER persisted — it is a transient view mode. It is
/// [keepAlive] (matching [ShoppingFilter] / [ListType]) so the mode survives
/// IndexedStack tab switches while the shopping tab stays mounted.
///
/// Riverpod 3 suffix-stripping: `class ShoppingReorderMode` →
/// `shoppingReorderModeProvider`.

abstract class _$ShoppingReorderMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
