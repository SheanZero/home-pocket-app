---
phase: quick-260609-dnp
plan: 01
subsystem: shopping_list/presentation
tags: [ui, i18n, filter, shopping-list, goldens]
requires:
  - shoppingFilterProvider (setLedgerFilter / setCategoryIds / clearAll)
  - resolveCategoryIcon (category_display_utils)
  - categoryRepositoryProvider.findActive()
provides:
  - ShoppingCategoryFilterSheet (shopping-only L1-only category filter sheet)
  - Reworked ShoppingFilterBar (全部 reset + 日常|悦己 segmented control)
affects:
  - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
  - shopping tab (购物) filter UX
tech-stack:
  added: []
  patterns:
    - "Connected segmented control = bordered ClipRRect Container holding a Row of InkWell segments split by a 1px vertical divider"
    - "L1-only category filter selects the union of an L1's L2 leaf child ids"
key-files:
  created:
    - lib/features/shopping_list/presentation/widgets/shopping_category_filter_sheet.dart
  modified:
    - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
    - test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart
    - test/golden/goldens/shopping_filter_bar_active_{en,ja,zh}.png
    - test/golden/goldens/shopping_filter_bar_active_dark_{en,ja,zh}.png
decisions:
  - "全部 kept as a SEPARATE standalone reset control (not part of the segmented control) — it is the global clear entry, highlighted only when ledgerType==null && categoryIds.isEmpty, tapping calls clearAll()"
  - "L1-only sheet uses a simple two-state Checkbox (no tristate): value = all-children-selected; toggle add/removeAll the L2 leaf child ids"
  - "Segment label rendered as a plain Text widget so find.text keeps working in widget tests"
metrics:
  duration: ~10 min
  tasks: 3
  files: 9
  completed: 2026-06-09
---

# Quick 260609-dnp: Enhance Shopping List Filter Bar Summary

Reworked the 购物-tab filter bar into a standalone 全部 reset control plus a single connected 日常|悦己 segmented control, pointed the category chip at a new shopping-only L1-only category sheet, and fixed the raw icon-name leak by rendering a real `Icon(resolveCategoryIcon(l1.icon))` leading widget.

## What Was Built

**Task 1 — `ShoppingCategoryFilterSheet` (D-3, D-4, D-5)** — `7bb2a44c`
- New `ConsumerStatefulWidget` copied structurally from `CategoryFilterSheet` but **L1-only**: the `ListView.builder` renders exactly one row per L1, no L2 child rows.
- Two-state `Checkbox` (tristate dropped): `value` = `childIds.isNotEmpty && _localSelected.containsAll(childIds)`. Tapping the row or checkbox `addAll`/`removeAll`s the L1's L2 leaf child ids (D-4 — selected set under the hood is the union of leaf ids).
- D-5 fix: leading `Icon(resolveCategoryIcon(l1.icon), size: 20, color: palette.textSecondary)` + `SizedBox(width: 12)` + localized name `Text`. No more raw `'${l1.icon} $name'` ("restaurant 食费") leak.
- `onApply` is **non-nullable**; the sheet never imports or writes to `listFilterProvider`. Header / drag handle / Apply bar copied verbatim, reusing existing ARB keys.

**Task 2 — Reworked `ShoppingFilterBar` (D-1, D-2)** — `6d32c14e`
- New layout: `[全部 reset] [日常|悦己 segmented] [Category chip]`.
- 全部 is a standalone `ActionChip` reset, highlighted only when `ledgerType == null && categoryIds.isEmpty`; `onPressed` calls `clearAll()`.
- Single connected segmented control: a `ClipRRect`/`Container` (8px radius, 1px `borderDefault`, `card` base) holding a `Row` of two `_SegmentButton` InkWells split by a 1px vertical divider. Each segment toggles to-deselect (passes `null` when already active). Mutual exclusivity is inherent in the single `ledgerType` field.
- Removed the conditional clear-all `ActionChip` and the unused `anyFilterActive` local. Category chip now opens `ShoppingCategoryFilterSheet`; dropped the `list_category_filter_sheet.dart` import.

**Task 3 — Widget test + goldens (D-1, D-2)** — `3f96e9be`
- Rewrote `shopping_filter_bar_test.dart` (7 tests): 全部/日常/ときめき/カテゴリ render; clear-all `findsNothing` is now a **permanent** guarantee (asserted even with an active filter); 全部 taps `clearAll()` and resets all fields; 日常 segment sets daily; active 日常 toggles to null; 悦己-after-日常 switches (mutual exclusivity); 全部 active-state tracks "nothing filtered".
- Re-baselined 6 goldens (3 locales × light/dark) for the new bar layout.

## Deviations from Plan

None — plan executed exactly as written. The widget-test `_pumpFilterBar` override was simplified to `ShoppingFilter.new` (tear-off) to satisfy the analyzer's `unnecessary_lambdas`; behaviorally identical.

## Verification

- `flutter analyze` → **No issues found** (0 issues, project hard rule).
- Scoped widget test → 7/7 pass.
- Scoped golden test → 6/6 pass against re-baselined masters.
- `test/architecture` (47 tests incl. `hardcoded_cjk_ui_scan`, `presentation_layer_rules`/import_guard, `provider_graph_hygiene`) → all pass.
- Full `flutter test` → reached +2502; one failure: `test/scripts/merge_findings_test.dart` "idempotency" — **passes in isolation (8/8)**, a known parallelism-sensitive subprocess flake in `test/scripts/`, unrelated to the shopping presentation layer. Logged in `deferred-items.md` (out-of-scope per scope boundary).
- Shared `CategoryFilterSheet` (列表 tab) confirmed untouched (no diff; last touched in Phase 38).

## Deferred Issues

| Item | Reason |
|------|--------|
| `test/scripts/merge_findings_test.dart` idempotency flake under full parallel run | Pre-existing, passes in isolation, unrelated to this change. Out-of-scope. |

## Self-Check: PASSED

- FOUND: lib/features/shopping_list/presentation/widgets/shopping_category_filter_sheet.dart
- FOUND: lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart (reworked)
- FOUND commits: 7bb2a44c, 6d32c14e, 3f96e9be
