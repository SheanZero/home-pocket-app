---
phase: quick-260609-pmc
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
  - lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
  - lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart
  - lib/l10n/app_zh.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_en.arb
  - test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart
  - test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart
  - test/golden/shopping_filter_bar_golden_test.dart
  - test/golden/shopping_item_tile_golden_test.dart
autonomous: true
requirements:
  - SORT-UX-01
  - SORT-UX-02
  - SORT-UX-03
  - SORT-UX-04

must_haves:
  truths:
    - "In sort mode the filter chip row looks identical to normal mode (no drag-indicator ⠿ prefix on any chip)"
    - "Long-pressing anywhere on an active item row in sort mode initiates drag reorder"
    - "The currently-dragged item has a visually prominent border (darker / elevated) while being held"
    - "In sort mode each active item shows move-to-top and move-to-bottom buttons that jump it instantly"
  artifacts:
    - path: "lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart"
      provides: "reorderPrefix() removed; chip avatars always null"
    - path: "lib/features/shopping_list/presentation/screens/shopping_list_screen.dart"
      provides: "SliverReorderableList with proxyDecorator; ReorderableDelayedDragStartListener on full tile"
    - path: "lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart"
      provides: "move-to-top / move-to-bottom buttons in sort mode; drag handle kept or replaced"
  key_links:
    - from: "ShoppingFilterBar.build"
      to: "shoppingReorderModeProvider"
      via: "ref.watch — no longer changes chip avatar based on reorder state"
      pattern: "reorderPrefix"
    - from: "SliverReorderableList"
      to: "proxyDecorator"
      via: "proxyDecorator: callback in shopping_list_screen.dart"
      pattern: "proxyDecorator"
    - from: "ShoppingItemTile._buildTrailingCluster"
      to: "reorderShoppingItemsUseCaseProvider"
      via: "execute(item.id, 0) and execute(item.id, activeItems.length - 1)"
      pattern: "execute.*item\\.id.*0"
---

<objective>
Four UX improvements to the shopping list sort/reorder mode.

Purpose: Reorder mode currently pollutes the filter row with extra drag-indicator glyphs,
restricts drag to a small handle only, lacks visual feedback for the item being dragged,
and offers no quick jump-to-top/bottom affordance.

Output:
1. Filter row stays layout-identical between normal and sort modes (drop ⠿ chip prefixes).
2. Long-press anywhere on item row initiates drag (not just the handle).
3. Custom proxyDecorator in SliverReorderableList highlights the dragged item with a
   darkened left-border + elevation shadow.
4. Move-to-top and move-to-bottom icon buttons in sort mode per active item tile.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/quick/260609-pmc-shopping-list-sort-ux/260609-pmc-PLAN.md

## Research findings (pre-investigated by planner — do not re-investigate)

### Fix 1 — What currently mutates the filter row in sort mode

`ShoppingFilterBar.build` (line 52–58 of shopping_filter_bar.dart) defines `reorderPrefix()`:
```
Widget? reorderPrefix() => reorderMode
    ? Icon(Icons.drag_indicator, size: 14, color: palette.textTertiary)
    : null;
```
This is passed as `avatar:` to every `ActionChip` (全部, 私有, 分类…) and as an inline child
inside the segmented control when `reorderMode` is true. This is the sole cause of the visual
diff. The ≡ / ✓ trailing button is SEPARATE and must be kept.

Fix: delete the `reorderPrefix()` helper entirely. Set `avatar: null` (or remove the avatar
parameter) on all ActionChip calls. Remove the `if (reorderMode)` block inside the segmented
control that adds the drag_indicator prefix.

Existing widget test at line 246–259 of shopping_filter_bar_test.dart explicitly asserts
`findsWidgets` for `Icons.drag_indicator` in reorder mode — that test assertion must be
inverted to `findsNothing` (the reorder icon button at the RIGHT edge still exists, but it
is an InkWell child, not inside a chip). Update the test description and assertion accordingly.

### Fix 2 — Long-press drag from anywhere

Currently `ReorderableDragStartListener` wraps only the trailing drag handle widget inside
`_buildTrailingCluster` in shopping_item_tile.dart (lines 378–396).

The whole tile is already inside a `GestureDetector` (with `onLongPress` for batch mode).
In reorder mode `gesturesLocked = true`, so the GestureDetector's `onLongPress` is null.

Strategy: In `shopping_list_screen.dart`, in `_buildBody`, the `itemBuilder` for
`SliverReorderableList` currently returns `ShoppingItemTile(...)` directly. Wrap that widget
with `ReorderableDelayedDragStartListener(index: index, child: ShoppingItemTile(...))`.
`ReorderableDelayedDragStartListener` responds to a long-press anywhere and initiates the
drag — no changes needed in the tile itself for this fix (the tile's `gesturesLocked` guard
already suppresses tap/long-press when `reorderMode` is true, so there is no conflict).

The explicit `ReorderableDragStartListener` wrapper around the drag handle icon in
`_buildTrailingCluster` should be kept — it provides an instant-drag affordance (press without
delay) for users who target the handle directly. The tile-level
`ReorderableDelayedDragStartListener` adds the long-press-anywhere path on top.

Note: `ReorderableDelayedDragStartListener` is in `package:flutter/material.dart` — no new
dependency.

### Fix 3 — Dragged item border (proxyDecorator)

`SliverReorderableList` in `_buildBody` of shopping_list_screen.dart (line 169) has NO
`proxyDecorator:` argument. Flutter's built-in default adds a box-shadow elevation but does
NOT darken or change the left-border.

This is NOT already implemented. Must add `proxyDecorator:` to `SliverReorderableList`.

The proxy child is the tile widget as built by `itemBuilder`. Wrap it in a `Material` with
`elevation: 4` and `color: Colors.transparent`, then wrap that in a `DecoratedBox` that adds
a left `BorderSide` with the `accentPrimary` palette color at full opacity and width 4 — same
width as the tile's existing left accent but using `context.palette.accentPrimary` to read the
theme. Use `context` from the proxyDecorator closure.

```dart
proxyDecorator: (child, index, animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (ctx, _) {
      final double elevation = Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      ).value;
      return Material(
        elevation: elevation,
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: ctx.palette.borderInputActive,
                width: 6,
              ),
            ),
          ),
          child: child,
        ),
      );
    },
  );
},
```
Use `ctx.palette.borderInputActive` (leaf green, `#6FA36F`) as the highlighted border color —
it is the "active/selected" color in the palette and reads well in both light and dark modes.
Do NOT use a hardcoded hex.

### Fix 4 — Move-to-top / move-to-bottom buttons

Sort order persistence: `ShoppingItemDao.reorder(id, newSortOrder)` writes `sort_order` and
`updated_at`. `ReorderShoppingItemsUseCase.execute(itemId, newSortOrder)` delegates to it.
In `shopping_list_screen.dart` the `onReorderItem` callback passes `newIndex` (the target
position, 0-based) directly as `newSortOrder`. This means:
- Move-to-top: `execute(item.id, 0)` — item gets sort_order=0, lands first.
- Move-to-bottom: `execute(item.id, activeItems.length - 1)`.

Note that `newSortOrder` is the list position, not a monotonic integer key. Other items are
NOT re-sequenced; the DB ordering is `sort_order ASC, created_at ASC`. After a move-to-top,
the moved item has sort_order=0 and will be first for any other items also at sort_order=0
only if created_at is also earlier — for a true "always top" guarantee after repeated use,
assigning sort_order = `-1` for move-to-top and `activeItems.length` for move-to-bottom is
safer. Use sort_order = -1 for move-to-top and `activeItems.length` for move-to-bottom.

UI: In `_buildTrailingCluster` in shopping_item_tile.dart, when `reorderMode && isActive`,
add TWO IconButtons BEFORE the existing drag handle:
- `Icons.keyboard_arrow_up` — tap calls use case with `sortOrder = -1` (move to top).
- `Icons.keyboard_arrow_down` — tap calls use case with `sortOrder = activeItems.length`.

`activeItems` is not currently passed to `ShoppingItemTile`. Options:
A. Pass `activeItemCount` as a new `int` parameter to `ShoppingItemTile`.
B. Read it from the provider inside the tile (provider already in scope via `ref.watch`).

Use option B: read `filteredShoppingItemsProvider` inside the tile and derive
`activeItemCount = items.where((i) => !i.isCompleted).length`. This avoids adding a
parameter and is consistent with how other data is accessed in the tile.

New ARB keys needed (3 × 3 locales):
- `shoppingMoveToTop`: zh=置顶, ja=一番上に移動, en=Move to top
- `shoppingMoveToBottom`: zh=置底, ja=一番下に移動, en=Move to bottom

These two buttons render ONLY in reorder mode for active items. Use `Icon` size 20,
`color: palette.textSecondary`, no extra padding beyond the natural button hit target
(use `SizedBox(width: 36, height: 44)` for each). Apply `Semantics(label:, button: true)`
using the new ARB keys.

No new use case needed — reuses `reorderShoppingItemsUseCaseProvider`.
No schema change — `sort_order` column already exists in v20 (integer, default 0).
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Fix 1 — Remove sort-mode chip prefix decorations from ShoppingFilterBar</name>
  <files>
    lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart,
    test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart,
    test/golden/shopping_filter_bar_golden_test.dart
  </files>
  <behavior>
    - Test: In reorder mode, `find.byIcon(Icons.drag_indicator)` finds exactly 1 widget (only the trailing ≡ toggle button), NOT multiple widgets (previously the chips each had one).
    - Test: In normal mode, `find.byIcon(Icons.drag_indicator)` finds 0 widgets (the ≡ button shows `Icons.reorder`, not `Icons.drag_indicator`).
    - Golden: `shopping_filter_bar_active_{ja,zh,en}.png` and dark variants — the active-filter state golden looks identical to the pre-sort-mode layout (no ⠿ prefix visible on any chip).
  </behavior>
  <action>
    In shopping_filter_bar.dart:
    1. Delete the entire `reorderPrefix()` helper function (lines 52–58 approximately).
    2. Remove `avatar: reorderPrefix()` from every `ActionChip` (三 places: 全部, 私有, 分类).
    3. Inside the segmented control's `Row`, remove the `if (reorderMode)` block that adds the inline `Icons.drag_indicator` padding widget (the block at lines ~117–125 approximately). The segmented control Row now only contains the 日常 and 悦己 `_SegmentButton` children plus their divider.
    4. The `reorderMode` watch at line 38 is still needed (the trailing ≡/✓ button still uses it). Keep it.

    In shopping_filter_bar_test.dart: find the test 'EC2 D-2: reorder mode shows drag_indicator chip prefixes' (around line 248). Update:
    - Rename to 'EC2 D-2: reorder mode does NOT add drag_indicator to chip prefixes'
    - Change the assertion that previously expected `findsWidgets` to now expect
      `findsOneWidget` (only the ≡ reorder toggle button icon still uses drag_indicator
      — actually that button shows `Icons.reorder`, not `Icons.drag_indicator`).
      After Fix 1, in reorder mode there should be ZERO `Icons.drag_indicator` icons.
      Change to `findsNothing`.
    - Keep the complementary assertion for normal mode (also `findsNothing`).

    In shopping_filter_bar_golden_test.dart: The existing 6 goldens (active-filter state,
    3 locales × 2 modes) do NOT include a reorder-mode variant. No new golden variant
    needed for this fix (the active-filter golden now reflects the clean layout for all
    modes). Re-baseline the existing 6 goldens if the chip layout changed in reorder-state
    coverage (it did — the ⠿ prefix is gone). Run:
      flutter test test/golden/shopping_filter_bar_golden_test.dart --update-goldens --tags golden
    after the code change and commit the updated PNG masters.
  </action>
  <verify>
    <automated>flutter test test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart --name "drag_indicator"</automated>
  </verify>
  <done>
    Zero `Icons.drag_indicator` icons appear in the filter row during reorder mode;
    the filter bar widget test passes; existing 6 filter bar goldens re-baselined.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Fix 2 — Long-press drag from anywhere; Fix 3 — Dragged item border highlight (proxyDecorator)</name>
  <files>
    lib/features/shopping_list/presentation/screens/shopping_list_screen.dart
  </files>
  <behavior>
    - Fix 2: `ReorderableDelayedDragStartListener` wraps `ShoppingItemTile` in `SliverReorderableList`'s itemBuilder.
    - Fix 3: `SliverReorderableList` has a `proxyDecorator:` callback that animates elevation 0→6 and applies a left BorderSide of width 6 in `palette.borderInputActive`.
  </behavior>
  <action>
    In shopping_list_screen.dart, in `_buildBody`, in the `SliverReorderableList` block:

    1. Add `proxyDecorator:` (Fix 3):
       Place the proxyDecorator as the second named argument after `itemCount:`.
       Use the AnimatedBuilder pattern from the research context (animate elevation
       0→6 with CurvedAnimation+Curves.easeOut, wrap child in Material(elevation,
       color: Colors.transparent) and DecoratedBox with left BorderSide using
       `ctx.palette.borderInputActive` width 6). The `ctx` is the BuildContext
       passed to the AnimatedBuilder's builder closure — `ctx.palette` resolves
       correctly via the ThemeExtension accessor.

    2. Wrap the `ShoppingItemTile(...)` in `itemBuilder` with
       `ReorderableDelayedDragStartListener(index: index, child: ShoppingItemTile(...))`.
       The existing `ReorderableDragStartListener` inside the tile's drag handle is kept
       (instant-drag from handle; long-press-anywhere from the outer listener). Keep the
       `key: ValueKey(activeItems[index].id)` on the outer
       `ReorderableDelayedDragStartListener`.

    IMPORTANT: `ReorderableDelayedDragStartListener` is in `package:flutter/material.dart`
    — already imported. No new import needed.

    IMMUTABILITY: Do not mutate `activeItems` — only read it for length/indexing.

    No test file changes in this task (screen-level reorder gesture behavior is
    exercised by widget tests that already exist; the proxyDecorator rendering is not
    golden-tested because Flutter test rendering does not exercise the drag-lift
    animation — manual verification is the appropriate check here).
  </action>
  <verify>
    <automated>flutter analyze lib/features/shopping_list/presentation/screens/shopping_list_screen.dart</automated>
  </verify>
  <done>
    `SliverReorderableList` in shopping_list_screen.dart has both a `proxyDecorator`
    callback and a `ReorderableDelayedDragStartListener` wrapping each tile.
    `flutter analyze` reports 0 issues on the file.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Fix 4 — Move-to-top and move-to-bottom buttons in sort mode</name>
  <files>
    lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart,
    lib/l10n/app_zh.arb,
    lib/l10n/app_ja.arb,
    lib/l10n/app_en.arb,
    test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart,
    test/golden/shopping_item_tile_golden_test.dart
  </files>
  <behavior>
    - Test: In reorder mode, an active item tile shows `Icons.keyboard_arrow_up` and `Icons.keyboard_arrow_down`.
    - Test: Tapping `Icons.keyboard_arrow_up` calls `reorderShoppingItemsUseCaseProvider.execute(item.id, -1)`.
    - Test: Tapping `Icons.keyboard_arrow_down` calls the use case with `activeItemCount` as the sort order value.
    - Test: In normal mode (reorderMode == false), neither icon is visible on the tile.
    - Golden: Add a new golden variant `shopping_item_tile_reorder_mode_{ja,zh,en}.png` (light + dark, 6 PNGs) showing the tile in reorder mode with the two move buttons and drag handle visible.
  </behavior>
  <action>
    In shopping_item_tile.dart:

    1. In `_buildTrailingCluster`, read `activeItemCount` from the provider. The method
       currently receives `context` and `palette` but not `ref`. Change signature to also
       accept `ref` (pass it from `_buildTileContent` where `ref` is already in scope).

    2. Inside `_buildTrailingCluster`, when `reorderMode && isActive`, before adding the
       existing drag handle, add the two move buttons:

       ```dart
       // Move-to-top button (置顶)
       Semantics(
         label: S.of(context).shoppingMoveToTop,
         button: true,
         child: Tooltip(
           message: S.of(context).shoppingMoveToTop,
           child: InkWell(
             onTap: () => ref
                 .read(reorderShoppingItemsUseCaseProvider)
                 .execute(item.id, -1),
             customBorder: const CircleBorder(),
             child: const SizedBox(
               width: 36,
               height: 44,
               child: Center(
                 child: Icon(Icons.keyboard_arrow_up, size: 20),
               ),
             ),
           ),
         ),
       ),
       // Move-to-bottom button (置底)
       Semantics(
         label: S.of(context).shoppingMoveToBottom,
         button: true,
         child: Tooltip(
           message: S.of(context).shoppingMoveToBottom,
           child: InkWell(
             onTap: () async {
               final items =
                   ref.read(filteredShoppingItemsProvider).value ?? const [];
               final activeCount =
                   items.where((i) => !i.isCompleted).length;
               ref
                   .read(reorderShoppingItemsUseCaseProvider)
                   .execute(item.id, activeCount);
             },
             customBorder: const CircleBorder(),
             child: const SizedBox(
               width: 36,
               height: 44,
               child: Center(
                 child: Icon(Icons.keyboard_arrow_down, size: 20),
               ),
             ),
           ),
         ),
       ),
       ```
       The Icon color comes from the ambient `DefaultTextStyle`/`IconTheme` — use
       `color: palette.textSecondary` explicitly inside the Icon call.

       Keep the existing `ReorderableDragStartListener` drag handle after the two
       move buttons.

    3. Update the call site in `_buildTileContent`: change
       `_buildTrailingCluster(context, palette, reorderMode)` to
       `_buildTrailingCluster(context, ref, palette, reorderMode)`.

    In app_zh.arb — add after the existing `shoppingExitReorderMode` block:
    ```json
    "shoppingMoveToTop": "置顶",
    "@shoppingMoveToTop": {
      "description": "Tooltip/semantics label for the move-item-to-top button in sort mode"
    },
    "shoppingMoveToBottom": "置底",
    "@shoppingMoveToBottom": {
      "description": "Tooltip/semantics label for the move-item-to-bottom button in sort mode"
    }
    ```

    In app_ja.arb — add the same keys:
    ```json
    "shoppingMoveToTop": "一番上に移動",
    "@shoppingMoveToTop": { "description": "..." },
    "shoppingMoveToBottom": "一番下に移動",
    "@shoppingMoveToBottom": { "description": "..." }
    ```

    In app_en.arb — add:
    ```json
    "shoppingMoveToTop": "Move to top",
    "@shoppingMoveToTop": { "description": "..." },
    "shoppingMoveToBottom": "Move to bottom",
    "@shoppingMoveToBottom": { "description": "..." }
    ```

    Run `flutter gen-l10n` after updating all three ARB files.

    In shopping_item_tile_test.dart: add a test group 'reorder mode move buttons' with:
    - A test verifying `Icons.keyboard_arrow_up` and `Icons.keyboard_arrow_down` are found
      when `shoppingReorderModeProvider` is true and `isActive` is true.
    - A test verifying neither icon is found in normal mode.
    - A tap test for move-to-top that verifies the use case `execute` is called with
      `item.id` and `-1` (mock `ReorderShoppingItemsUseCase` via an override).

    In shopping_item_tile_golden_test.dart: add a new variant `reorder_mode` that renders
    the tile with `shoppingReorderModeProvider` overridden to `true`. Baseline 6 new PNGs:
    `shopping_item_tile_reorder_mode_{ja,zh,en}.png` and
    `shopping_item_tile_reorder_mode_dark_{ja,zh,en}.png`.
    Run: flutter test test/golden/shopping_item_tile_golden_test.dart --update-goldens --tags golden

    IMMUTABILITY: read `filteredShoppingItemsProvider.value` for active count; do not
    mutate any list. Use `copyWith` patterns if any model state is involved (none here).
  </action>
  <verify>
    <automated>flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart --name "reorder mode move buttons"</automated>
  </verify>
  <done>
    Move-to-top (sort_order = -1) and move-to-bottom (sort_order = activeCount) buttons
    appear in reorder mode for active items; both ARB keys present in all 3 locales;
    `flutter gen-l10n` succeeds; widget tests pass; 6 reorder-mode tile goldens baselined.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
    All four sort-mode UX fixes:
    1. Filter bar chip layout is identical in sort mode and normal mode (no ⠿ prefix).
    2. Long-pressing anywhere on an item row in sort mode initiates drag reorder.
    3. The dragged item gets a wider left border (borderInputActive) and elevation shadow.
    4. Each active item in sort mode shows ↑ (move-to-top) and ↓ (move-to-bottom) buttons.

    All automated checks:
    - flutter analyze 0 issues
    - Shopping widget tests pass
    - Golden baselines updated (filter bar × 6, tile × 6 new reorder-mode variants)
    - flutter test test/golden/shopping_filter_bar_golden_test.dart --tags golden
    - flutter test test/golden/shopping_item_tile_golden_test.dart --tags golden
    - flutter test test/widget/features/shopping_list/ (all widget tests)
    - architecture tests: flutter test test/unit/arch/ (provider_graph_hygiene + hardcoded_cjk_ui_scan)
  </what-built>
  <how-to-verify>
    1. Run the app: `flutter run`
    2. Navigate to the Shopping tab.
    3. Enter sort mode by tapping the ≡ button at the right of the filter bar.
    4. **Fix 1:** Confirm the filter chips (全部 / 日常·悦己 / 私有 / 分类) look
       exactly the same as before entering sort mode — no drag-indicator ⠿ glyph on
       any chip.
    5. **Fix 2:** Long-press anywhere on an item row (not just on the = handle) and
       confirm the item lifts and can be dragged to a new position.
    6. **Fix 3:** While dragging, confirm the held item has a more prominent left border
       (thicker, in leaf green) compared to its resting state.
    7. **Fix 4:** Confirm each active item shows ↑ and ↓ icon buttons. Tap ↑ on an item
       in the middle of the list — it should jump to the top. Tap ↓ on an item — it
       should jump to the bottom. Exit sort mode (✓) and confirm the order persisted.
  </how-to-verify>
  <resume-signal>Type "approved" or describe any issues found.</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| UI → use case | sortOrder value passed from move-to-top/bottom buttons |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-pmc-01 | Tampering | `execute(item.id, -1)` move-to-top | accept | sort_order is local-per-device (D37-01); no sync pathway; negative integer accepted by INTEGER column (no CHECK constraint); no PII |
| T-pmc-02 | Denial of Service | move-to-bottom reads `filteredShoppingItemsProvider` inside onTap | accept | provider is already in scope and cached; reading `.value` inside onTap is synchronous; no additional DB call |
</threat_model>

<verification>
Run the full scoped suite before committing:

```bash
flutter analyze
flutter test test/widget/features/shopping_list/
flutter test test/unit/arch/
flutter test test/golden/shopping_filter_bar_golden_test.dart --tags golden
flutter test test/golden/shopping_item_tile_golden_test.dart --tags golden
```

All must pass (0 analyze issues, all widget tests green, goldens match updated baselines).
</verification>

<success_criteria>
- flutter analyze: 0 issues
- Filter bar: no drag_indicator icons in chip avatars in any mode
- Drag from anywhere: ReorderableDelayedDragStartListener wraps each active tile
- proxyDecorator: SliverReorderableList has a custom proxyDecorator with animated elevation and wider left border
- Move buttons: ↑ and ↓ in reorder mode, calling execute(item.id, -1) and execute(item.id, activeCount)
- ARB keys shoppingMoveToTop and shoppingMoveToBottom in zh/ja/en + gen-l10n succeeds
- All shopping widget tests pass; 6 new reorder-mode tile goldens baselined; 6 filter bar goldens updated
</success_criteria>

<output>
Create `.planning/quick/260609-pmc-shopping-list-sort-ux/260609-pmc-SUMMARY.md` when done.
</output>
