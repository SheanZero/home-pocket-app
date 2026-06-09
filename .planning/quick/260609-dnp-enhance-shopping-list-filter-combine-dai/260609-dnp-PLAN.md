---
phase: quick-260609-dnp
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/shopping_list/presentation/widgets/shopping_category_filter_sheet.dart
  - lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
  - test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart
  - test/golden/goldens/shopping_filter_bar_active_en.png
  - test/golden/goldens/shopping_filter_bar_active_ja.png
  - test/golden/goldens/shopping_filter_bar_active_zh.png
  - test/golden/goldens/shopping_filter_bar_active_dark_en.png
  - test/golden/goldens/shopping_filter_bar_active_dark_ja.png
  - test/golden/goldens/shopping_filter_bar_active_dark_zh.png
autonomous: true
requirements: [FILT-D1, FILT-D2, FILT-D3, FILT-D4, FILT-D5]

must_haves:
  truths:
    - "Shopping filter bar shows 全部 standalone control + a single connected 日常|悦己 segmented control (D-1)"
    - "全部 is highlighted ONLY when filter.ledgerType == null && filter.categoryIds.isEmpty; tapping it calls clearAll() (D-2)"
    - "The conditional clear-all ActionChip is gone from the filter bar (D-2)"
    - "Tapping a ledger segment toggles it; tapping the active segment deselects back to no ledger filter (D-1)"
    - "Category chip opens a NEW shopping-only sheet showing ONLY L1 rows; the shared list-tab sheet is untouched (D-3)"
    - "Selecting an L1 row filters by the union of that L1's L2 leaf child ids (D-4)"
    - "Each L1 row renders a real Icon(resolveCategoryIcon(l1.icon)) leading widget, NOT the raw icon-name string (D-5)"
  artifacts:
    - path: "lib/features/shopping_list/presentation/widgets/shopping_category_filter_sheet.dart"
      provides: "Shopping-only L1-only category filter sheet with real leading Icon (D-3, D-4, D-5)"
      contains: "resolveCategoryIcon"
    - path: "lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart"
      provides: "Reworked filter bar: 全部 reset control + 日常|悦己 segmented control (D-1, D-2)"
  key_links:
    - from: "shopping_filter_bar.dart"
      to: "shoppingFilterProvider.notifier"
      via: "setLedgerFilter / setCategoryIds / clearAll"
      pattern: "clearAll\\(\\)"
    - from: "shopping_filter_bar.dart"
      to: "ShoppingCategoryFilterSheet"
      via: "showModalBottomSheet onApply callback"
      pattern: "ShoppingCategoryFilterSheet"
    - from: "shopping_category_filter_sheet.dart"
      to: "resolveCategoryIcon"
      via: "Icon(resolveCategoryIcon(l1.icon))"
      pattern: "Icon\\(resolveCategoryIcon"
---

<objective>
Enhance the shopping-list (购物 tab) filter bar with three UI changes plus one i18n icon-rendering bug fix, all presentation-layer only.

1. (D-1) Replace the three standalone 全部/日常/悦己 ActionChips with: a standalone 全部 reset control + a single connected SEGMENTED control holding two mutually-exclusive, re-tappable-to-deselect segments 日常 | 悦己.
2. (D-2) Remove the conditional clear-all ActionChip; rework 全部 so it highlights only when nothing is filtered and tapping it calls `clearAll()`.
3. (D-3/D-4) Point the category chip at a NEW shopping-only L1-only category filter sheet (copied from `CategoryFilterSheet`, NOT modifying the shared one). L1 selection filters by the union of that L1's L2 leaf child ids.
4. (D-5) In the new sheet, render a real `Icon(resolveCategoryIcon(l1.icon))` leading widget instead of the bug-causing raw `'${l1.icon} $name'` string.

Purpose: Cleaner, less-cluttered shopping filter UX; fix the "restaurant 食费" icon-name leak.
Output: One new sheet widget, reworked filter bar, updated widget test, re-baselined goldens.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
@lib/features/shopping_list/presentation/providers/state_shopping_filter.dart
@lib/features/list/presentation/widgets/list_category_filter_sheet.dart
@lib/features/accounting/presentation/utils/category_display_utils.dart
@lib/features/accounting/domain/models/category.dart
@test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart
@test/golden/shopping_filter_bar_golden_test.dart

Working-tree note: this runs on the MAIN tree (no worktree). Pre-existing uncommitted edits (status chip already removed from `shopping_filter_bar.dart`, plus shopping_item_form/dao/l10n edits) are the live baseline — build on top of the current working-tree state, not committed HEAD. Atomic commits will naturally include the overlapping pre-existing edits for touched files (same feature iteration; acceptable).

i18n note: NO new ARB keys required. Reuse existing keys verified present in all 3 ARB files: `shoppingFilterLedgerAll` (全部), `listLedgerDaily` (日常), `listLedgerJoy` (悦己/ときめき), `shoppingFilterCategory` (分类), `listCategorySheetTitle`, `listCategorySheetClear`, `listCategorySheetApply`, `listCategorySheetApplyN`, `listDeleteCancelButton`. Do NOT hardcode any CJK string in widgets (architecture test `hardcoded_cjk_ui_scan` runs in full `flutter test`).
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create shopping-only L1-only category filter sheet (D-3, D-4, D-5)</name>
  <files>lib/features/shopping_list/presentation/widgets/shopping_category_filter_sheet.dart</files>
  <action>
Create `ShoppingCategoryFilterSheet`, a NEW `ConsumerStatefulWidget`, by copying the structure of `CategoryFilterSheet` (`list_category_filter_sheet.dart`) but L1-only. DO NOT modify the shared `CategoryFilterSheet` — the 列表 tab keeps its L1+L2 behavior (D-3).

Constructor: `required Set<String> initialSelected` and `required ValueChanged<Set<String>> onApply` (make onApply non-nullable here — the shopping caller always owns the write target via `shoppingFilterProvider`; do NOT import or write to `listFilterProvider`).

State/data loading: keep `_loadCategories()` exactly as in the source — load `repo.findActive()`, partition into `_l1Categories` (level==1, sorted by sortOrder) and `_l2ByParent` (level==2 grouped by parentId, each child list sorted by sortOrder). `_localSelected` seeded from `initialSelected`.

L1-only rendering (D-4): the `ListView.builder` renders ONLY one row per L1 — NO L2 child rows, no per-L1 Divider-with-children block (a flat divider between L1 rows is fine). Per row use a simple two-state `Checkbox` (drop tristate): `value` = true when ALL of that L1's L2 children are currently in `_localSelected` (i.e. childIds.isNotEmpty && _localSelected.containsAll(childIds)); else false. Preserve the add-all / remove-all data semantics of the source `_toggleL1`: tapping the row (InkWell onTap) or the checkbox toggles — if currently all-selected, removeAll(childIds); else addAll(childIds). Selected set under the hood = union of leaf child ids (shopping items are tagged with leaf ids).

Icon fix (D-5): import `category_display_utils.dart` and render a real leading `Icon(resolveCategoryIcon(l1.icon), size: 20, color: palette.textSecondary)` followed by `SizedBox(width: 12)` then the localized name `Text(CategoryLocalizationService.resolve(l1.name, locale), style: AppTextStyles.titleSmall)`. Do NOT render the raw `'${l1.icon} $name'` string — that is the exact bug (list_category_filter_sheet.dart:219 shows "restaurant 食费").

Header (title `listCategorySheetTitle` + clear button `listCategorySheetClear` resetting `_localSelected = {}`), drag handle, divider, and the Apply bar (Cancel = `listDeleteCancelButton` + Navigator.pop; Apply FilledButton = `listCategorySheetApply` / `listCategorySheetApplyN(_localSelected.length)`) are copied verbatim from the source. On Apply: call `widget.onApply(Set<String>.unmodifiable(_localSelected))` then `Navigator.pop(context)` — no null branch.

Use `context.palette`, `AppTextStyles`, `S.of(context)`, and `currentLocaleProvider` exactly as the source does. Honor light+dark via palette. Reuse existing ARB keys only (no new keys, no hardcoded CJK).
  </action>
  <verify>
    <automated>flutter analyze lib/features/shopping_list/presentation/widgets/shopping_category_filter_sheet.dart 2>&1 | grep -v '^#' | grep -c "error •" | grep -qx 0 && grep -q "Icon(resolveCategoryIcon" lib/features/shopping_list/presentation/widgets/shopping_category_filter_sheet.dart && echo OK</automated>
  </verify>
  <done>New sheet exists, L1-only, real leading Icon via resolveCategoryIcon, onApply non-nullable, shared CategoryFilterSheet untouched, analyze clean for the file.</done>
</task>

<task type="auto">
  <name>Task 2: Rework filter bar — 全部 reset + 日常|悦己 segmented control (D-1, D-2)</name>
  <files>lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart</files>
  <action>
Rework `ShoppingFilterBar.build` left-to-right layout to: [全部 standalone control] [SizedBox 8] [日常|悦己 segmented control] [SizedBox 8] [Category chip]. REMOVE the conditional clear-all `ActionChip` block (the `if (anyFilterActive) ...[ ... ]` Semantics/Icons.clear_all block) entirely and delete the now-unused `anyFilterActive` local (D-2).

全部 control (D-2): keep it as a SEPARATE standalone control to the left (it is the global reset entry, not part of the segmented control). Highlight it ONLY when nothing is filtered: `final noneActive = filter.ledgerType == null && filter.categoryIds.isEmpty;`. When `noneActive` use the active palette styling (e.g. `palette.dailyLight` bg + `palette.borderInputActive` border/text), else inactive (`palette.card` bg + `palette.borderDefault` border + `palette.textSecondary` text). onPressed: `ref.read(shoppingFilterProvider.notifier).clearAll()` (resets BOTH ledgerType and categoryIds — `ShoppingFilter.clearAll()` already resets to `ShoppingListFilter.initial()`; reuse it). Label `l10n.shoppingFilterLedgerAll` with `AppTextStyles.labelMedium`. Note: 全部 is no longer driven by `ledgerType == null` alone — it must also require empty categoryIds.

日常|悦己 segmented control (D-1): render a SINGLE connected segmented widget with two mutually-exclusive, re-tappable-to-deselect segments. Build it as one bordered, rounded `Container`/`ClipRRect` (e.g. `BorderRadius.circular(8)`, 1px `palette.borderDefault`, `palette.card` base) holding a `Row(mainAxisSize: min)` of two tappable segments with a 1px vertical divider between them (so it reads as one connected control, not two chips). Each segment is an `InkWell`/`GestureDetector` over `Padding`:
- 日常 segment: selected when `filter.ledgerType == LedgerType.daily` → bg `palette.dailyLight`, label color `palette.daily`; else label `palette.textSecondary`. onTap toggles: `setLedgerFilter(filter.ledgerType == LedgerType.daily ? null : LedgerType.daily)`.
- 悦己 segment: selected when `filter.ledgerType == LedgerType.joy` → bg `palette.joyLight`, label color `palette.joy`; else `palette.textSecondary`. onTap toggles: `setLedgerFilter(filter.ledgerType == LedgerType.joy ? null : LedgerType.joy)`.
Mutual exclusivity is inherent (single `ledgerType` field). Re-tapping the active segment passes `null` → deselects back to no ledger filter. Labels `l10n.listLedgerDaily` / `l10n.listLedgerJoy` with `AppTextStyles.labelMedium`. Keep the segmented control height aligned to the 44px bar (the existing `Container(height: 44)` wrapper + `SingleChildScrollView` stay). Use `context.palette` for all colors (honor light+dark).

Category chip (D-3): keep the existing category `ActionChip` but swap the sheet from `CategoryFilterSheet` to the new `ShoppingCategoryFilterSheet` (import it; drop the `list_category_filter_sheet.dart` import if now unused). Preserve the `showModalBottomSheet` + `onApply: (ids) => ref.read(shoppingFilterProvider.notifier).setCategoryIds(ids)` pattern and `initialSelected: filter.categoryIds`. Chip active styling stays gated on `filter.categoryIds.isNotEmpty`.

Update the file's header doc comment to reflect the new layout (全部 reset + 日常|悦己 segmented + Category; clear-all removed). No hardcoded CJK; immutable updates only (notifier copyWith already handles state).
  </action>
  <verify>
    <automated>flutter analyze lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart 2>&1 | grep -v '^#' | grep -c "error •" | grep -qx 0 && grep -q "ShoppingCategoryFilterSheet" lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart && ! grep -q "Icons.clear_all" lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart && echo OK</automated>
  </verify>
  <done>全部 standalone reset (highlight only when ledgerType==null && categoryIds.isEmpty, taps clearAll); single 日常|悦己 segmented control with toggle-to-deselect; clear-all ActionChip removed; category chip points at ShoppingCategoryFilterSheet; analyze clean for the file.</done>
</task>

<task type="auto">
  <name>Task 3: Update widget test + re-baseline goldens, full-suite verify (D-1, D-2)</name>
  <files>test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart, test/golden/goldens/shopping_filter_bar_active_en.png, test/golden/goldens/shopping_filter_bar_active_ja.png, test/golden/goldens/shopping_filter_bar_active_zh.png, test/golden/goldens/shopping_filter_bar_active_dark_en.png, test/golden/goldens/shopping_filter_bar_active_dark_ja.png, test/golden/goldens/shopping_filter_bar_active_dark_zh.png</files>
  <action>
Update the widget test `shopping_filter_bar_test.dart` to match the reworked bar (D-1, D-2):
- FILT-01 test: ledger labels 全部 (`すべて`? — note ja `shoppingFilterLedgerAll` = `全部`/`すべて`; assert via the same key the widget uses), 日常, 悦己 (ja `ときめき`) and カテゴリ still render. The status-chip-absent assertions stay. The `Icons.clear_all` "findsNothing" assertion stays valid (clear-all removed permanently) — keep it as a permanent guarantee, not state-conditional.
- REMOVE/replace the FILT-03 "clear-all chip visible when ledger filter active" test: there is no longer a clear-all chip. Replace it with a test asserting that the 全部 control taps to `clearAll()` — set a non-default filter (e.g. `ledgerType: LedgerType.daily`), tap the 全部 label (`find.text` on `shoppingFilterLedgerAll`'s ja value), pumpAndSettle, then assert `ledgerType == null && categoryIds.isEmpty && statusFilter == 'all'`.
- Keep/adjust the "tapping 日常 sets daily" and "tapping active 日常 toggles to null" tests — they tap `find.text('日常')` which still works on the segment label. Verify the segment label Text is findable (segmented control uses Text widgets).
- Add a test asserting 全部 is highlighted/active only when nothing filtered: with default filter the 全部 control reads as active; with `ledgerType: daily` it is NOT active (assert indirectly via state if styling is hard to assert — acceptable to assert behavior via tapping).

Then re-baseline the 6 affected goldens (the bar UI changed):
`flutter test --update-goldens test/golden/shopping_filter_bar_golden_test.dart`

Run the FULL suite to catch architecture tests (`hardcoded_cjk_ui_scan`, import_guard, provider_graph_hygiene) plus the updated widget + golden tests. No `@riverpod`/`@freezed`/Drift/ARB changes were made, so build_runner is NOT required.
  </action>
  <verify>
    <automated>flutter analyze 2>&1 | grep -v '^#' | grep -c "error •" | grep -qx 0 && flutter test test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart test/golden/shopping_filter_bar_golden_test.dart 2>&1 | tail -5 | grep -q "All tests passed" && echo SCOPED_OK</automated>
    <human-check>Full `flutter test` (entire suite incl. hardcoded_cjk_ui_scan + import_guard) passes green; `flutter analyze` reports 0 issues.</human-check>
  </verify>
  <done>Widget test updated to reflect segmented control + 全部-as-reset (no clear-all chip); 6 goldens re-baselined; scoped tests green; full `flutter test` green and `flutter analyze` 0 issues.</done>
</task>

</tasks>

<verification>
- `flutter analyze` → 0 issues (project hard rule).
- Full `flutter test` → green, including architecture tests (`hardcoded_cjk_ui_scan` confirms no hardcoded CJK in the new sheet / reworked bar; `import_guard` confirms shopping presentation layering; `provider_graph_hygiene` unaffected).
- Manual/visual (optional): 购物 tab filter bar shows 全部 + a connected 日常|悦己 segmented control + Category; tapping 全部 clears everything; category sheet shows L1-only rows each with a real leading icon (no "restaurant 食费" text leak).
- Shared `CategoryFilterSheet` (列表 tab) untouched → L1+L2 behavior preserved.
</verification>

<success_criteria>
- D-1: single connected 日常|悦己 segmented control (re-tappable-to-deselect) + standalone 全部 control to its left.
- D-2: clear-all ActionChip removed; 全部 highlighted only when `ledgerType == null && categoryIds.isEmpty`; tapping 全部 calls `clearAll()`.
- D-3: new `ShoppingCategoryFilterSheet` created; shared `CategoryFilterSheet` unmodified; shopping category chip points at the new sheet.
- D-4: sheet is L1-only; selecting an L1 filters by the union of its L2 leaf child ids.
- D-5: each L1 row renders `Icon(resolveCategoryIcon(l1.icon))`, not the raw icon-name string.
- 0 analyzer issues; full test suite + 6 re-baselined goldens green.
</success_criteria>

<output>
Create `.planning/quick/260609-dnp-enhance-shopping-list-filter-combine-dai/260609-dnp-SUMMARY.md` when done.
Per project worklog rule, also create a `docs/worklog/{YYYYMMDD_HHMM}_enhance_shopping_filter_bar.md` entry.
</output>
