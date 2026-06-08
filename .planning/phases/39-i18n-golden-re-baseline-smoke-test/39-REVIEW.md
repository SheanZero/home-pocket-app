---
phase: 39-i18n-golden-re-baseline-smoke-test
reviewed: 2026-06-09T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - analysis_options.yaml
  - lib/features/accounting/presentation/screens/category_selection_screen.dart
  - lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart
  - test/golden/shopping_batch_chrome_golden_test.dart
  - test/golden/shopping_empty_state_golden_test.dart
  - test/golden/shopping_filter_bar_golden_test.dart
  - test/golden/shopping_item_tile_golden_test.dart
  - test/integration/presentation/shopping_provider_smoke_test.dart
  - test/widget/features/home/presentation/widgets/home_bottom_nav_bar_test.dart
  - test/widget/features/shopping_list/presentation/widgets/home_bottom_nav_bar_shopping_test.dart
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 39: Code Review Report

**Reviewed:** 2026-06-09T00:00:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 39 is an i18n/test-infrastructure phase: it renamed ARB key `homeTabTodo → homeTabShopping`, re-baselined 54 shopping golden PNGs across 4 new golden test files, added a presentation-layer provider smoke test, added a `build/**` analyzer exclude, and migrated a deprecated `onReorder` to `onReorderItem` in `category_selection_screen.dart`.

The three areas of primary concern all check out clean under adversarial scrutiny:

1. **ARB key parity is perfect.** All three locales carry exactly 585 top-level keys with byte-identical key sets (`diff` confirms `EN==JA` and `EN==ZH`). `homeTabTodo` is fully purged from `lib/` and `test/` (zero matches); generated `app_localizations*.dart` are regenerated with the new getter. Values are correct: `Shopping` / `買い物` / `购物`.

2. **The `onReorder → onReorderItem` index adapter is mathematically correct.** Flutter's new `onReorderItem` (SDK > v3.41.0) auto-adjusts `newIndex` for the removed item, whereas the legacy `onReorder` does not. The notifier `CategoryReorderNotifier.reorderL1/reorderL2` still contains `if (newIndex > oldIndex) newIndex -= 1;` — i.e. it expects the **old** convention. The adapter `(o, n) => reorderL1(o, n > o ? n + 1 : n)` inverts the new auto-adjustment (`+1`) so the value the notifier receives matches the legacy contract. Traced through down-move, bottom-drop, up-move, and no-op (`n == o`) cases — all reconstruct the original behavior. Same logic applied symmetrically to the L2 `ReorderableListView.builder`.

3. **No private data leaks into public golden variants.** Every golden fixture uses synthetic data (`"Milk"`, `"Alice"`, `"Secret Gift"`). The `attribution` variant deliberately renders a `listType: 'public'` item — but this is a designed public-attribution scenario with mock data, not real private content. The smoke test's `private` item (`"Secret Gift"`) is asserted **absent** from the public stream, which is the privacy guarantee, not a leak.

`flutter analyze` is clean (0 issues) across all 14 changed files. Remaining findings are quality/maintainability concerns, none blocking.

## Warnings

### WR-01: `onReorderItem` adapter re-introduces the index-fixup it was meant to remove — fragile and undocumented

**File:** `lib/features/accounting/presentation/screens/category_selection_screen.dart:356-358` and `:469`
**Issue:** The Flutter migration guidance for `onReorder → onReorderItem` is explicit: *"remove the manual adjustment of `newIndex` when items are moved downward."* This change does the opposite — it keeps the notifier's internal `newIndex -= 1` and adds a compensating `n > o ? n + 1 : n` at the call site, so the two adjustments cancel. The result is **behaviorally correct today**, but it is the inverse of the intended migration and creates a hidden coupling: anyone who later "cleans up" the notifier by removing its `-= 1` (per the migration guide), or who removes the `+ 1` at the call site, silently breaks downward reordering with no compiler error. The sibling shopping screen (`shopping_list_screen.dart:157-160`) uses `onReorderItem` with the already-adjusted index directly and a comment saying so — this file is now inconsistent with it. There is no comment here explaining why the `+ 1` exists.
**Fix:** Prefer migrating fully: drop `if (newIndex > oldIndex) newIndex -= 1;` from `reorderL1`/`reorderL2` in `state_category_reorder.dart` and pass `onReorderItem`'s index through unchanged (`.reorderL1(o, n)`), matching `shopping_list_screen.dart`. If the compensating form is kept for scope reasons, add a comment at both call sites:
```dart
// onReorderItem gives the already-adjusted newIndex; reorderL1 still uses the
// legacy onReorder convention (subtracts 1 for downward moves), so re-add it here.
onReorderItem: (o, n) => ref
    .read(categoryReorderProvider.notifier)
    .reorderL1(o, n > o ? n + 1 : n),
```

### WR-02: Smoke test assertion 2 depends on a brittle emission-count heuristic that can mask a regression

**File:** `test/integration/presentation/shopping_provider_smoke_test.dart:75-93, 270-281`
**Issue:** `_waitForSettledEmission` resolves on the second-or-later `hasValue` emission (`emissionCount > 1`). The private-item write triggers a re-emission only because the DAO stream uses `readsFrom: {_db.shoppingItems}` (verified) — so an insert of a *filtered-out* private row still re-runs the public query and emits an (unchanged) empty list. The test therefore passes, but the assertion that actually protects the privacy contract (`postWrite.value` does not contain `'private-smoke'`) would *also* pass trivially if the write silently failed and no row was ever inserted. The test never asserts that the private row exists in the DB at all, so a broken `applyOps.execute` for private items would be a false-green here.
**Fix:** After the write, additionally assert the private row landed in the underlying store (e.g. query `shoppingItemRepo.watchByListType('private')` or the DAO once and `expect(...any((i) => i.id == 'private-smoke'), isTrue)`), so the "absent from public stream" assertion is meaningfully distinguished from "write never happened."

### WR-03: Duplicate `home_bottom_nav_bar_test.dart` under two test roots with overlapping assertions

**File:** `test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart` and `test/widget/features/home/presentation/widgets/home_bottom_nav_bar_test.dart`
**Issue:** Two near-identical test files exercise `HomeBottomNavBar` with overlapping cases (4-label render, FAB callback, tab-index callback, inactive `textTertiary` color). Both were touched this phase (the `homeTabTodo → 買い物` label flip), so the duplication was knowingly carried forward. This doubles maintenance cost — the next label/icon change must be made in both, and the third file (`home_bottom_nav_bar_shopping_test.dart`) adds a third place asserting the same `買い物`/`购物`/`Shopping` labels. Divergence risk is real (one file uses `S.localizationsDelegates`, the others use a `testLocalizedApp` helper).
**Fix:** Consolidate into one canonical location (`test/widget/features/home/.../home_bottom_nav_bar_test.dart`), delete the duplicate under `test/features/...`, and keep the NAV-02 shopping-tab cases as the only place asserting the renamed labels. Out of strict scope for an i18n-rename phase, but the duplication was reaffirmed by this change.

## Info

### IN-01: Stale "coral" references in widget doc comment and test names

**File:** `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart:10-11`, `test/widget/features/home/presentation/widgets/home_bottom_nav_bar_test.dart:47`, `test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart:61`
**Issue:** The dartdoc says the active tab is "a coral-coloured pill" and the FAB has "a coral gradient"; test comments/names say "white on coral" / "coral background decoration". Per ADR-019 (桜餅×若葉, live in code), the active pill is leaf-green `accentPrimary` (`#6FA36F`) and the FAB is sakura-pink — coral was the ADR-017/018-era hue. The comments are stale and misdescribe the rendered color. Pre-existing (predates this phase) but present in reviewed files.
**Fix:** Update the dartdoc to "leaf-green pill" / "sakura-pink gradient FAB" and rename the test to `'active tab has accentPrimary background decoration'`. The assertions themselves (`Colors.white` for active text, `textTertiary` for inactive) remain correct and need no change.

### IN-02: Golden baseline count is 54, not the ~72 stated in the task brief

**File:** `test/golden/` (4 files)
**Issue:** Actual shopping golden PNGs: item_tile 18 (3 variants × 3 locales × 2 modes) + empty_state 18 + batch_chrome 12 (2 widgets × 3 × 2) + filter_bar 6 = **54**, not 72. The file-level header comments document their own counts correctly (18 / 18 / 12 / 6); only the orchestration brief's "72" is off. Not a code defect — flagged only so downstream tracking does not assume 18 baselines are missing.
**Fix:** None required in code. Reconcile the phase plan's baseline tally to 54 if it tracks a target.

---

_Reviewed: 2026-06-09T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
