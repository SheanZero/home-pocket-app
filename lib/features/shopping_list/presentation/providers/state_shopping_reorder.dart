import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'state_shopping_reorder.g.dart';

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
@Riverpod(keepAlive: true)
class ShoppingReorderMode extends _$ShoppingReorderMode {
  @override
  bool build() => false;

  /// Flips reorder mode on/off (≡ ⇄ ✓ in the filter bar).
  void toggle() => state = !state;

  /// Force-exits reorder mode (e.g. when leaving the screen).
  void exit() => state = false;
}
