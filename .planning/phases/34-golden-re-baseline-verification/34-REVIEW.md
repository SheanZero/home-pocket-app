---
phase: 34-golden-re-baseline-verification
reviewed: 2026-06-01T14:08:06Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - test/golden/amount_display_golden_test.dart
  - test/golden/list_calendar_header_golden_test.dart
  - test/golden/list_category_filter_sheet_golden_test.dart
  - test/golden/list_day_group_header_golden_test.dart
  - test/golden/list_empty_state_golden_test.dart
  - test/golden/list_sort_filter_bar_golden_test.dart
  - test/golden/list_transaction_tile_golden_test.dart
  - test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart
  - test/widget/features/list/list_transaction_tile_test.dart
  - test/features/home/presentation/widgets/home_transaction_tile_test.dart
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues
---

# Phase 34: Code Review Report

**Reviewed:** 2026-06-01T14:08:06Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 34 delivered two categories of changes: (1) ThemeMode parameterization of 7 golden test `_wrap()` functions with 27 new dark variant test stubs, and (2) replacement of stale `Color(0xFF5A9CC8)` / `Color(0xFF47B88A)` / `Color(0xFFE85A4F)` literals with `AppPalette.light.*` tokens in 3 widget test files.

**Architecture soundness:** All 7 golden test wrappers correctly use `ThemeData.dark()` paired with `themeMode: ThemeMode.dark` to exercise dark rendering. The `context.palette` fallback in `AppPaletteContext` (brightness-based, lines 612–616 of `app_palette.dart`) correctly resolves `AppPalette.dark` when `ThemeData.dark()` is present but `AppPalette` is not registered as a `ThemeExtension`, so all widgets using `context.palette` (AmountDisplay, ListSortFilterBar, ListDayGroupHeader, ListEmptyState, CategoryFilterSheet, CalendarHeaderWidget, ListTransactionTile's internal palette reads) receive the correct dark tokens. No critical correctness defects found.

**Token replacement correctness:** All three AppPalette token substitutions are semantically correct — `Color(0xFF5A9CC8)` → `.daily` (teal-navy), `Color(0xFF47B88A)` → `.joy` (gold), `Color(0xFFE85A4F)` → `.error` (error red). The `const` → non-const downgrade for `MaterialApp` and local color variables (required because `AppPalette.light.*` are `final`, not `const`) is correctly applied.

**One Warning was found:** `list_transaction_tile_golden_test.dart` hardcodes `locale: const Locale('ja')` for the `ListTransactionTile` widget parameter regardless of the `_wrap(locale:)` argument. This defect was pre-existing in the light variants but was propagated unchanged into all 3 dark variant test cases added by this phase — meaning the zh and en dark goldens are capturing tile-internal date/time formatting in Japanese, not the locale indicated by the test name.

---

## Warnings

### WR-01: Dark golden locale parameter not passed through to ListTransactionTile widget

**File:** `test/golden/list_transaction_tile_golden_test.dart:94`
**Issue:** `ListTransactionTile` receives `locale: const Locale('ja')` hardcoded at line 94, regardless of the `locale` parameter passed to `_wrap()`. All 6 variants (ja/zh/en × light/dark) forward the `locale` correctly to `MaterialApp`, but the tile itself always gets `Locale('ja')`. This means the `zh` and `en` golden captures — including the 3 new dark variants added in this phase — are rendering tile-internal locale-sensitive content (date, time formatting) in Japanese rather than the claimed locale. The zh/en test names and golden PNG filenames imply locale-faithful rendering, but the tile is rendering ja. This was a pre-existing defect in the light variants, but phase 34 copied the same incorrect pattern into 3 new dark variants (`list_transaction_tile_dark_zh.png`, `list_transaction_tile_dark_en.png`) without correction.

**Fix:** Pass `locale` through to the tile parameter:
```dart
child: ListTransactionTile(
  taggedTx: _makeTx(),
  bookId: 'book_golden',
  onTap: () {},
  onDeleted: () {},
  tagText: 'Daily',
  tagBgColor: effectiveTagBgColor,
  tagTextColor: effectiveTagTextColor,
  category: 'Food',
  categoryColor: effectiveCategoryColor,
  formattedAmount: '¥1,234',
  l1Icon: Icons.restaurant,
  locale: locale,   // ← was: const Locale('ja')
  merchant: null,
  satisfactionIcon: null,
),
```
After fixing, re-run `--update-goldens` for all 6 variants (both zh/en may produce new renders). Light goldens for zh/en would also need re-baselining.

---

## Info

### IN-01: Golden fixture uses stale ADR-017 terminology ("Survival")

**File:** `test/golden/list_transaction_tile_golden_test.dart:87`
**Issue:** `tagText: 'Survival'` uses the old pre-ADR-017 English label. ADR-017 unified Survival → Daily across all identifiers and ARB values. This fixture string is rendered in the PNG golden and is not subject to the ROADMAP SC2-a grep (which only checks `lib/l10n/*.arb`), so it does not block any success criteria. It is pre-existing (present before this phase) and was not corrected when the dark variants were added.
**Fix:** Change `tagText: 'Survival'` to `tagText: 'Daily'` and re-run `--update-goldens` for all 6 variants.

### IN-02: Remaining hardcoded Color(0xFFE8F0F8) literals in widget test fixtures

**File:** `test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart:16,43,66` and `test/features/home/presentation/widgets/home_transaction_tile_test.dart:14,43`
**Issue:** `tagBgColor: const Color(0xFFE8F0F8)` remains as a hardcoded hex in several test cases after the D-03a audit pass. This value is not a retired palette color (it is not coral `#E85A4F`, old-daily-blue `#5A9CC8`, or old-joy-green `#47B88A`) and was explicitly left unchanged by Plan 34-03. However, `0xFFE8F0F8` is not an ADR-018 token and has no corresponding `AppPalette` entry. In widget tests this color is only passed in as a fixture value and is never asserted on, so it does not affect test correctness. It is out-of-scope for the D-03a audit as specified.
**Fix:** No action required for this phase. If full fixture token alignment is desired in a future pass, replace with `AppPalette.light.accentPrimaryLight` (`0xFFE0F4F5`) or `AppPalette.light.dailyLight` (`0xFFE0F0F2`) as appropriate.

### IN-03: Stale "Survival" / "霊魂" category label strings in widget test fixture display strings

**File:** `test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart:19,46`
**Issue:** `category: '食費 · 生存'` (line 19) and `category: 'Food · Survival'` (line 46) use old terminology; `category: '趣味 · 霊魂'` (line 93) uses pre-Phase-31 terminology. These are arbitrary display strings in widget test fixtures used as test props — not ARB keys — so they don't affect ARB compliance or any ROADMAP success criteria. They are pre-existing. The associated `expect(find.text('食費 · 生存'), ...)` will pass regardless of terminology, as the widget renders what it is given.
**Fix:** No immediate action required. Update to `'食費 · 日常'` / `'Food · Daily'` / `'趣味 · ときめき'` in a future terminology sweep for fixture consistency.

---

_Reviewed: 2026-06-01T14:08:06Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
