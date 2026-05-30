---
phase: 28-transaction-tile-sort-filter-bar
verified: 2026-05-30T10:00:00Z
status: passed
human_verified: 2026-05-30T21:25:00Z (user approved all 21 checks — see 28-HUMAN-UAT.md)
score: 11/11 automated must-haves verified
human_checks: 21/21 passed
overrides_applied: 0
human_verification:
  - test: "SC#1 — Transaction tile display fields"
    expected: "Each row shows ledger-color tag badge (blue for 生存, green for 魂), category name in ledger color, formatted amount aligned with tabular figures, and time (HH:mm) on the right of the category row"
    why_human: "Visual rendering, font feature (tabular figures), and color correctness cannot be verified by grep or tests"
  - test: "SC#1 — Day-group headers"
    expected: "Day-group headers appear above each day's rows showing the date (e.g. '2026年5月30日(金)' in ja locale) on a muted background at 32dp"
    why_human: "Layout height, background color rendering, and locale date format require visual inspection"
  - test: "SC#1 — Amount alignment"
    expected: "Digit positions are tabular (not proportional) across rows — amounts align vertically"
    why_human: "Tabular-figures font feature effect requires visual inspection on real device/simulator"
  - test: "SC#2 — Tap-to-edit opens edit screen pre-populated"
    expected: "Tapping a transaction row opens TransactionEditScreen with the transaction's data pre-filled"
    why_human: "Navigation flow and pre-population require running app"
  - test: "SC#2 — Reactive update after edit"
    expected: "After saving a change in TransactionEditScreen, the list updates automatically (no manual refresh required)"
    why_human: "Reactive refresh (ref.invalidate) behavior only verifiable at runtime"
  - test: "SC#3 — Swipe-delete gesture"
    expected: "Swiping a transaction row left reveals a red background with trash icon"
    why_human: "Gesture feel, animation, and visual appearance require running app"
  - test: "SC#3 — Delete confirmation dialog"
    expected: "Releasing swipe triggers AlertDialog with '削除しますか？' title, body text, キャンセル and 削除 buttons"
    why_human: "Dialog rendering and text content require running app"
  - test: "SC#3 — Cancel snaps back, confirm deletes"
    expected: "Tapping キャンセル returns the row; tapping 削除 removes the row and shows '削除しました' SnackBar"
    why_human: "Row animation and SnackBar display require running app"
  - test: "SC#4 — Sort chip active-field label"
    expected: "Sort chip shows the current field name (e.g. '更新日時') NOT a generic 'Sort'"
    why_human: "Confirmed in widget test (SC#4 passes), but visual rendering on full assembled screen needs human check"
  - test: "SC#4 — Sort popup menu"
    expected: "Tapping the sort chip shows a menu with Date / Edit time / Amount options and a checkmark on the active field; selecting a field reorders the list"
    why_human: "Menu positioning and list reorder behavior require running app"
  - test: "SC#4 — Direction arrow toggle"
    expected: "Tapping the direction arrow switches the icon (up/down) and the list reorders accordingly"
    why_human: "Visual toggle and list reorder require running app"
  - test: "SC#5 — Ledger chips filter"
    expected: "Tapping '生存' chip filters the list to Survival entries with active state (blue border/bg); tapping again clears back to All"
    why_human: "Active chip visual state and list filtering require running app"
  - test: "SC#5 — Category filter sheet"
    expected: "Tapping the 'カテゴリ' chip opens CategoryFilterSheet modal showing L1/L2 hierarchy with checkboxes; selecting L2 items and tapping '適用' filters the list and chip shows 'カテゴリ (N)'"
    why_human: "Bottom sheet presentation, category hierarchy display, and filter composition require running app"
  - test: "SC#5 — Search expand"
    expected: "Tapping the search icon expands to a text field; typing filters the list"
    why_human: "AnimatedContainer expand animation and live search filtering require running app"
  - test: "SC#5 — Clear chip"
    expected: "'クリア' chip appears only when any filter is active; tapping it resets all filters"
    why_human: "Conditional visibility and reset behavior require running app"
  - test: "Empty state — no transactions in month"
    expected: "Navigating to a month with no transactions shows receipt icon and placeholder text (not blank screen)"
    why_human: "Empty state rendering requires running app with real or test data"
  - test: "Empty state — filtered empty"
    expected: "Applying a filter that matches no results shows search-off icon and 'フィルターをクリア' button; tapping the button clears filters"
    why_human: "Filtered empty state rendering and button action require running app"
  - test: "No visual regressions on Home screen"
    expected: "Home tab still renders correctly after Phase 28 changes (no HomeTransactionTile layout breakage)"
    why_human: "Cross-tab visual regression requires running app"
  - test: "Calendar header updates after swipe-delete"
    expected: "After confirming swipe-delete, the per-day total in CalendarHeaderWidget decreases to reflect the deleted transaction"
    why_human: "calendarDailyTotalsProvider invalidation effect requires running app with real data"
  - test: "Calendar header updates after tap-to-edit save"
    expected: "After saving an edited transaction amount, CalendarHeaderWidget shows the updated total"
    why_human: "Dual-provider invalidation effect requires running app"
  - test: "Full screen layout on device"
    expected: "ListSortFilterBar is pinned at 44dp height, does not scroll with list content, and the calendar header + bar + list fit correctly within the scaffold"
    why_human: "Layout constraint on physical screen size requires running app"
---

# Phase 28: Transaction Tile + Sort/Filter Bar — Verification Report

**Phase Goal:** Individual list rows and the sort/filter controls are complete, correctly styled, and safe — the transaction tile shows all required fields with correct colors and formatting, swipe-delete routes exclusively through DeleteTransactionUseCase, and tap-to-edit opens the v1.3 edit screen.

**Verified:** 2026-05-30
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `ListFilterState.categoryIds` is `Set<String>` with `@Default(<String>{})` — old `String? categoryId` removed | VERIFIED | `list_filter_state.dart` line 29: `@Default(<String>{}) Set<String> categoryIds,` |
| 2 | `ListFilter` notifier exposes `setCategories(Set<String>)` and `toggleCategory(String)` — no `setCategoryFilter` | VERIFIED | `state_list_filter.dart` lines 51–63; both mutators use copy-on-write (`Set<String>.from(...)`) |
| 3 | `listTransactionsProvider` applies Dart-side category set filter (`categoryIds.isNotEmpty` / `.contains`) | VERIFIED | `state_list_transactions.dart` lines 77–80 |
| 4 | All 22 Phase 28 ARB keys exist in all 3 locale files (ja/zh/en) | VERIFIED | `grep -c '"list' app_ja.arb` returns 23 (22 keys + 2 parameterized entries); all 22 keys verified present in all 3 files |
| 5 | `ListTransactionTile` is a `ConsumerWidget` with `Dismissible(direction: endToStart)` and `ValueKey(tx.id)` | VERIFIED | `list_transaction_tile.dart` lines 23, 68–69 |
| 6 | `confirmDismiss` calls `showDialog<bool>` returning `AlertDialog` per C-04; `onDismissed` calls SnackBar first then `deleteTransactionUseCaseProvider` then `onDeleted()` | VERIFIED | Lines 77–125; CR-01 fix applied: `onDeleted()` callback from parent supplies `calendarDailyTotalsProvider` invalidation |
| 7 | `deleteTransactionUseCaseProvider` imported with `show` guard — not a direct DAO call | VERIFIED | `list_transaction_tile.dart` lines 8–9: `show deleteTransactionUseCaseProvider` |
| 8 | Tap-to-edit: `onTap` pushes `TransactionEditScreen(transaction: tx.transaction)`; `result == true` triggers both `listTransactionsProvider` and `calendarDailyTotalsProvider` invalidation | VERIFIED | `list_screen.dart` lines 185–202; `invalidateAfterMutation()` at lines 174–183 invalidates both providers; passed as `onTap: onTap, onDeleted: invalidateAfterMutation` |
| 9 | Amount uses `AppTextStyles.amountSmall` (tabular figures); all ledger colors use `AppColors.survival/soul/survivalLight/soulLight` — no hardcoded hex | VERIFIED | `list_transaction_tile.dart` line 197: `AppTextStyles.amountSmall`; no `Color(0xFF...)` in any new Phase 28 widget file |
| 10 | `ListSortFilterBar` sort chip label uses `_sortFieldLabel` (locale-aware, never generic `'Sort'`); `clearAll` wired to conditional clear chip | VERIFIED | `list_sort_filter_bar.dart` lines 48–58; no `'Sort'` string literal found; `clearAll()` at line 439 |
| 11 | SC#3 hash-chain test: soft-delete sets `isDeleted=true` and `verifyChain` returns valid | VERIFIED | `flutter test test/unit/features/list/delete_hash_chain_integrity_test.dart` exits 0; 1 test passes |

**Score:** 11/11 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Error state i18n — `'[data load error]'` literal in `list_screen.dart:82` | Phase 30 | REQUIREMENTS.md: "LIST-03 — Phase 30 — i18n + Empty States + Golden Polish" |
| 2 | `LIST-03` — clear empty state requirement formally | Phase 30 | REQUIREMENTS.md traceability table |

Note: `ListEmptyState` widget is functionally implemented in Phase 28 and uses real ARB keys (`listEmptyMonth`, `listEmptyFiltered`, `listEmptyFilteredClear`). The deferred item concerns the formal requirement sign-off and the error-state literal string — not the empty-state widget itself.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/list/domain/models/list_filter_state.dart` | Freezed VO with `categoryIds: Set<String>` | VERIFIED | Contains `@Default(<String>{}) Set<String> categoryIds,` |
| `lib/features/list/presentation/providers/state_list_filter.dart` | `setCategories` + `toggleCategory` mutators | VERIFIED | Both mutators present; copy-on-write pattern (`Set<String>.from(...)`) |
| `lib/features/list/presentation/providers/state_list_transactions.dart` | Dart-side category multi-filter | VERIFIED | Lines 77–80: `categoryIds.isNotEmpty` guard + `.contains(tx.categoryId)` |
| `lib/features/list/presentation/widgets/list_transaction_tile.dart` | Dismissible tile with swipe-delete + tap-to-edit | VERIFIED | `ValueKey`, `DismissDirection.endToStart`, `deleteTransactionUseCaseProvider` via `show` guard, `onDeleted` callback |
| `lib/features/list/presentation/widgets/list_day_group_header.dart` | 32dp header + `buildFlatList` helper | VERIFIED | Container height 32, `AppColors.backgroundMuted`, `DateFormatter.formatDate`; `buildFlatList` exports `DayHeaderItem`/`TransactionRowItem` sealed types |
| `lib/features/list/presentation/widgets/list_category_filter_sheet.dart` | L1/L2 multi-select + tristate + Apply wires `setCategories` | VERIFIED | `_L1SelectState` enum, `tristate:` param on `Checkbox`, `setCategories(Set<String>.unmodifiable(...))` on Apply; copy-on-write `{..._localSelected}` pattern |
| `lib/features/list/presentation/widgets/list_empty_state.dart` | Two paths: `receipt_long_outlined` (no filter) / `search_off_outlined` (filter) + clearAll button | VERIFIED | Both icons present in `isFilterActive` branch; `listFilterProvider.notifier.clearAll()` on button |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 44dp `ConsumerStatefulWidget` with all sort/filter controls | VERIFIED | `_sortFieldLabel` never returns `'Sort'`; `AnimatedContainer` search; conditional clear chip; all 3 ledger chips; `CategoryFilterSheet` modal |
| `lib/features/list/presentation/screens/list_screen.dart` | Replaces spinner with `ListSortFilterBar` + grouped `ListView` | VERIFIED | `ListSortFilterBar`, `ListDayGroupHeader`, `ListTransactionTile`, `ListEmptyState`, `buildFlatList`, `calendarDailyTotalsProvider` all present |
| `lib/l10n/app_ja.arb` + `app_zh.arb` + `app_en.arb` | 22 Phase 28 ARB keys in all 3 files | VERIFIED | 23 `"list*"` entries per file (22 keys + 1 placeholder prefix); all 22 specific keys confirmed present |
| `test/unit/features/list/delete_hash_chain_integrity_test.dart` | SC#3 hash-chain integrity test GREEN | VERIFIED | 1 test passes (`flutter test` exit 0) |
| `test/unit/features/list/list_filter_notifier_test.dart` | D-01 notifier tests GREEN | VERIFIED | 5+ tests pass (setCategories, toggleCategory ×2, clearAll, immutability) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `list_filter_state.dart` | `state_list_filter.dart` | `copyWith(categoryIds: ...)` | WIRED | `setCategories` and `toggleCategory` both call `state = state.copyWith(categoryIds: ...)` |
| `state_list_transactions.dart` | `list_filter_state.dart` | `filter.categoryIds.isNotEmpty` | WIRED | Lines 77–80 |
| `list_transaction_tile.dart` | `repository_providers.dart` | `show deleteTransactionUseCaseProvider` | WIRED | Lines 8–9; `ref.read(deleteTransactionUseCaseProvider).execute(...)` at line 121 |
| `list_transaction_tile.dart` | `list_screen.dart` (parent) | `onDeleted` callback | WIRED | `onDeleted()` at line 124; parent supplies `invalidateAfterMutation` closing over `calendarDailyTotalsProvider` |
| `list_screen.dart` | `transaction_edit_screen.dart` | `Navigator.push(TransactionEditScreen(...))` | WIRED | Lines 188–193 |
| `list_screen.dart` | `state_calendar_totals.dart` | `ref.invalidate(calendarDailyTotalsProvider(...))` | WIRED | Lines 177–182; called from both edit (result==true) and delete (`invalidateAfterMutation`) |
| `list_sort_filter_bar.dart` | `list_category_filter_sheet.dart` | `showModalBottomSheet(builder: CategoryFilterSheet(...))` | WIRED | Lines 112–117 |
| `list_sort_filter_bar.dart` | `state_list_filter.dart` | `ref.watch(listFilterProvider)` + all mutators | WIRED | Lines 124–440; all 5 mutators (`setSort`, `setLedgerFilter`, `setCategories` via sheet, `setSearch`, `clearAll`) reachable |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `list_screen.dart` | `txsAsync` (`AsyncValue<List<TaggedTransaction>>`) | `listTransactionsProvider(bookId: bookId)` → `GetListTransactionsUseCase.execute` → DAO query | Yes — delegates to `GetListTransactionsUseCase` which hits `TransactionRepository.findByBookIds` | FLOWING |
| `list_transaction_tile.dart` | `formattedAmount`, `category`, `formattedTime` | Pre-computed by parent `list_screen._buildTile` from real `Transaction` fields | Yes — `NumberFormatter.formatCurrency`, `CategoryLocalizationService.resolveFromId`, `DateFormat('HH:mm')` | FLOWING |
| `list_category_filter_sheet.dart` | `_l1Categories`, `_l2ByParent` | `categoryRepositoryProvider.findActive()` in `_loadCategories()` | Yes — live repository call; `mounted` guard prevents state update after dispose | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 74 Phase 28 list tests pass | `flutter test test/unit/features/list/ test/widget/features/list/` | 74 tests, 0 failures | PASS |
| `flutter analyze lib/features/list/` | `flutter analyze` | `No issues found!` | PASS |
| Hash-chain integrity test (SC#3) | `flutter test test/unit/features/list/delete_hash_chain_integrity_test.dart` | 1 test, exit 0 | PASS |
| D-01 notifier tests | `flutter test test/unit/features/list/list_filter_notifier_test.dart` | 5 tests, exit 0 | PASS |
| ROW-01/ROW-02 widget tests | `flutter test test/widget/features/list/list_transaction_tile_test.dart` | 2 tests, exit 0 | PASS |
| Sort/filter bar tests | `flutter test test/widget/features/list/list_sort_filter_bar_test.dart` | 3 tests (SC#4, FILTER-02, FILTER-04), exit 0 | PASS |
| Category sheet tests | `flutter test test/widget/features/list/list_category_filter_sheet_test.dart` | 5 tests (Apply, L1-cascade, tristate), exit 0 | PASS |

### Probe Execution

Step 7c SKIPPED — no `scripts/*/tests/probe-*.sh` found; phase is a Flutter UI feature, not a CLI/migration phase.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| LIST-01 | 28-01, 28-03, 28-06 | Scrollable list with category emoji, ledger-color tag, date, amount (tabular) | VERIFIED | `list_screen.dart` assembles all display values; `AppTextStyles.amountSmall`; `AppColors.survival/soul` |
| ROW-01 | 28-03, 28-06 | Tap row to open edit screen (reuses `TransactionEditScreen`) | VERIFIED | `list_screen.dart` line 188–193; `TransactionEditScreen(transaction: transaction)` |
| ROW-02 | 28-03, 28-06 | Swipe to delete with confirmation; routes exclusively through `DeleteTransactionUseCase` | VERIFIED | `Dismissible` + `confirmDismiss` dialog + `deleteTransactionUseCaseProvider` via `show` guard; SC#3 hash-chain test GREEN |
| SORT-01 | 28-01, 28-05, 28-06 | Sort by transaction date | VERIFIED | `SortField.timestamp` in `_sortFieldLabel`; sort chip menu; `setSort` mutator |
| SORT-02 | 28-01, 28-05, 28-06 | Sort by edit/created time | VERIFIED | `SortField.updatedAt` in `_sortFieldLabel` |
| SORT-03 | 28-01, 28-05, 28-06 | Sort by amount | VERIFIED | `SortField.amount` in `_sortFieldLabel` |
| SORT-04 | 28-01, 28-05, 28-06 | Toggle asc/desc for active sort | VERIFIED | Direction arrow IconButton toggles `sortDirection`; `setSort(sortConfig.copyWith(sortDirection: toggled))` |
| FILTER-01 | 28-01, 28-05 | Text search by category name, merchant, note | VERIFIED | `state_list_transactions.dart` lines 88–99: `CategoryLocalizationService.resolveFromId` + merchant + note Dart-side search |
| FILTER-02 | 28-01, 28-05 | Filter by ledger (Survival / Soul) | VERIFIED | Three ledger chips in `ListSortFilterBar`; `setLedgerFilter`; FILTER-02 widget test passes |
| FILTER-03 | 28-01, 28-04, 28-05 | Filter by one or more categories (multi-select) | VERIFIED | `CategoryFilterSheet` with tristate L1/L2; `state_list_transactions.dart` Dart-side `categoryIds.contains` filter |
| FILTER-04 | 28-01, 28-05 | Filters compose (AND logic); clear all in one action | VERIFIED | All filters AND-composed in provider pipeline; conditional clear chip calls `clearAll()`; FILTER-04 widget test passes |

**All 11 Phase 28 requirement IDs verified in code.**

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `lib/features/list/presentation/screens/list_screen.dart:82` | `'[data load error]'` literal string (not from ARB) | Info | Cosmetic — error state text not yet localized; deferred to Phase 30 per REQUIREMENTS.md |
| `lib/features/list/presentation/screens/list_screen.dart:39,160` | `const currencyCode = 'JPY'` declared but not used in `NumberFormatter.formatCurrency` call at line 160 (uses independent `'JPY'` literal) | Info (IN-01 from review) | When Phase 29 derives `currencyCode` from `bookByIdProvider`, the formatter call on line 160 will remain JPY unless updated together |

No TBD, FIXME, or XXX markers found in any Phase 28 modified file. Both items are informational only (deferred i18n work) — not blockers.

### Human Verification Required

All 21 checks from Plan 28-07's `checkpoint:human-verify` task are required before Phase 28 can be marked fully complete. Run `flutter run` on the iOS simulator and navigate to the List tab.

#### 1. SC#1 — Tile display fields

**Test:** Confirm transaction rows show: ledger-color tag badge (blue for 生存, green for 魂), category name in ledger color, formatted amount with tabular figures, and time (HH:mm) on the right of the category row.
**Expected:** Each field correctly rendered with color and style matching UI-SPEC C-01.
**Why human:** Visual rendering and font-feature (tabular figures) require running app.

#### 2. SC#1 — Day-group headers

**Test:** Confirm day-group headers appear above each day's rows showing the locale date (e.g. "2026年5月30日(金)") on a 32dp muted-background bar.
**Expected:** Date correctly formatted; background color is `AppColors.backgroundMuted`.
**Why human:** Layout height and date formatting require running app.

#### 3. SC#1 — Amount alignment

**Test:** Confirm digit positions align vertically across rows (tabular figures).
**Expected:** Amounts align — digit columns match across rows of different amounts.
**Why human:** Tabular-figures font feature effect requires visual inspection.

#### 4. SC#2 — Tap-to-edit opens edit screen

**Test:** Tap a transaction row.
**Expected:** `TransactionEditScreen` opens pre-populated with the transaction's data.
**Why human:** Navigation flow and pre-population require running app.

#### 5. SC#2 — Reactive update after edit

**Test:** Make a small change in the edit screen and save.
**Expected:** The list (and calendar header totals) update automatically — no manual refresh.
**Why human:** Dual-provider invalidation effect requires running app.

#### 6. SC#3 — Swipe-delete gesture

**Test:** Swipe a row left.
**Expected:** Red background with trash icon appears.
**Why human:** Gesture animation requires running app.

#### 7. SC#3 — Delete confirmation dialog

**Test:** Release after swiping.
**Expected:** `AlertDialog` with "削除しますか？" title, body text, and キャンセル/削除 buttons.
**Why human:** Dialog rendering requires running app.

#### 8. SC#3 — Cancel snaps back; confirm deletes

**Test:** Tap キャンセル (row should return); swipe again and tap 削除.
**Expected:** Row disappears; "削除しました" SnackBar appears.
**Why human:** Row animation, SnackBar, and swipe-snap behavior require running app.

#### 9. SC#4 — Sort chip active-field label

**Test:** Observe the sort chip label.
**Expected:** Shows current field name (e.g. "更新日時"), never the generic text "Sort".
**Why human:** Widget test confirms this, but visual verification on assembled screen adds confidence.

#### 10. SC#4 — Sort popup menu

**Test:** Tap the sort chip.
**Expected:** Popup menu shows Date / Edit time / Amount with checkmark on active field; selecting an option reorders the list.
**Why human:** Menu positioning and list reorder require running app.

#### 11. SC#4 — Direction arrow toggle

**Test:** Tap the direction arrow.
**Expected:** Icon switches between up/down and the list reorders.
**Why human:** Visual toggle and list order change require running app.

#### 12. SC#5 — Ledger chip filter

**Test:** Tap "生存" chip.
**Expected:** List filters to Survival entries; chip becomes active (blue border/bg). Tapping again clears back to All.
**Why human:** Active chip visual state and list filter result require running app.

#### 13. SC#5 — Category filter sheet

**Test:** Tap the "カテゴリ" chip.
**Expected:** `CategoryFilterSheet` opens showing L1/L2 hierarchy with tristate checkboxes; selecting categories and tapping "適用" filters the list; chip label shows "カテゴリ (N)".
**Why human:** Bottom sheet presentation and category hierarchy require running app.

#### 14. SC#5 — Search expand

**Test:** Tap the search icon.
**Expected:** Expands to a text field (animated); typing a term filters the list.
**Why human:** AnimatedContainer animation and live search require running app.

#### 15. SC#5 — Conditional clear chip

**Test:** Apply any filter, observe bar.
**Expected:** "クリア" chip appears; tapping it resets all filters and collapses search.
**Why human:** Conditional visibility and reset behavior require running app.

#### 16. Empty state — no transactions in month

**Test:** Navigate to a month with no transactions.
**Expected:** Receipt icon and placeholder text appear (not a blank screen).
**Why human:** Empty state rendering requires running app with real or test data.

#### 17. Empty state — filtered empty

**Test:** Apply a filter that matches no results.
**Expected:** Search-off icon and "フィルターをクリア" button appear; tapping clears filters.
**Why human:** Filtered empty state and button action require running app.

#### 18. No visual regressions on Home screen

**Test:** Navigate to the Home tab after using the List tab.
**Expected:** Home screen renders correctly (no `HomeTransactionTile` layout breakage).
**Why human:** Cross-tab visual regression requires running app.

#### 19. Calendar header updates after swipe-delete

**Test:** Delete a transaction via swipe; observe CalendarHeaderWidget.
**Expected:** Per-day total decreases to reflect the deletion.
**Why human:** `calendarDailyTotalsProvider` invalidation on delete requires runtime verification.

#### 20. Calendar header updates after edit

**Test:** Edit a transaction's amount; save; observe CalendarHeaderWidget.
**Expected:** Per-day total reflects the new amount.
**Why human:** Dual-provider invalidation on edit requires runtime verification.

#### 21. Full screen layout on device

**Test:** Observe the complete List tab layout.
**Expected:** `ListSortFilterBar` is pinned (does not scroll with list), calendar header shows above it, all components fit within the scaffold.
**Why human:** Layout constraints require running app.

### Gaps Summary

No automated gaps found. All 11 observable truths are verified in code. All 11 Phase 28 requirement IDs (LIST-01, ROW-01, ROW-02, SORT-01..04, FILTER-01..04) have implementation evidence.

The 21 human verification items from Plan 28-07 are the sole remaining gate. These are behavioral and visual checks that cannot be verified by static analysis or unit/widget tests. The automated sub-gate (flutter analyze + full list test suite, 74 tests) has passed.

Two informational items exist but are not blockers:
- `'[data load error]'` literal in `list_screen.dart` — i18n deferred to Phase 30.
- `currencyCode` constant not passed to `NumberFormatter` call — minor inconsistency, flagged in review (IN-01), does not affect Phase 28 scope.

---

_Verified: 2026-05-30_
_Verifier: Claude (gsd-verifier)_
