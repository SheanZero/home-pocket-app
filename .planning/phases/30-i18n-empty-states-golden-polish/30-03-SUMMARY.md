---
phase: 30-i18n-empty-states-golden-polish
plan: "03"
subsystem: list-feature
tags: [golden-tests, i18n, list-tab, png-baselines, locked-decisions]
dependency_graph:
  requires:
    - "30-02 — ListEmptyVariant enum (noData|dayEmpty|filtered) that golden must target"
  provides:
    - "test/golden/list_day_group_header_golden_test.dart — 3-locale golden baselines"
    - "test/golden/list_transaction_tile_golden_test.dart — 3-locale golden baselines"
    - "test/golden/list_sort_filter_bar_golden_test.dart — 3-locale golden baselines"
    - "test/golden/list_empty_state_golden_test.dart — 9-case golden baselines (3 variants × 3 locales)"
    - "test/golden/goldens/list_day_group_header_{ja,zh,en}.png — 3 baselines"
    - "test/golden/goldens/list_transaction_tile_{ja,zh,en}.png — 3 baselines"
    - "test/golden/goldens/list_sort_filter_bar_{ja,zh,en}.png — 3 baselines"
    - "test/golden/goldens/list_empty_state_{noData,dayEmpty,filtered}_{ja,zh,en}.png — 9 baselines"
  affects:
    - "golden CI: hard-fail on pixel diff (D-03)"
    - "D-04 3-state design visually captured in baselines"
tech_stack:
  added: []
  patterns:
    - "no-ProviderScope golden (pure StatelessWidget) — list_day_group_header analog: amount_display"
    - "ProviderScope golden (ConsumerWidget, no overrides needed during build) — list_transaction_tile"
    - "ProviderScope + currentLocaleProvider.overrideWith golden — list_sort_filter_bar (prevents async timer)"
    - "nested for-loop golden structure (3 locales × N variants) — list_empty_state analog: per_category_breakdown_card"
key_files:
  created:
    - test/golden/list_day_group_header_golden_test.dart
    - test/golden/list_transaction_tile_golden_test.dart
    - test/golden/list_sort_filter_bar_golden_test.dart
    - test/golden/list_empty_state_golden_test.dart
    - test/golden/goldens/list_day_group_header_ja.png
    - test/golden/goldens/list_day_group_header_zh.png
    - test/golden/goldens/list_day_group_header_en.png
    - test/golden/goldens/list_transaction_tile_ja.png
    - test/golden/goldens/list_transaction_tile_zh.png
    - test/golden/goldens/list_transaction_tile_en.png
    - test/golden/goldens/list_sort_filter_bar_ja.png
    - test/golden/goldens/list_sort_filter_bar_zh.png
    - test/golden/goldens/list_sort_filter_bar_en.png
    - test/golden/goldens/list_empty_state_noData_ja.png
    - test/golden/goldens/list_empty_state_noData_zh.png
    - test/golden/goldens/list_empty_state_noData_en.png
    - test/golden/goldens/list_empty_state_dayEmpty_ja.png
    - test/golden/goldens/list_empty_state_dayEmpty_zh.png
    - test/golden/goldens/list_empty_state_dayEmpty_en.png
    - test/golden/goldens/list_empty_state_filtered_ja.png
    - test/golden/goldens/list_empty_state_filtered_zh.png
    - test/golden/goldens/list_empty_state_filtered_en.png
  modified: []
decisions:
  - "D-01/D-02/D-03: golden baselines for 4 of 6 list-tab widgets, 3 locales, light theme, no pixel-tolerance threshold"
  - "D-04 3-state design visually captured: noData (no TextButton), dayEmpty (event_busy + TextButton), filtered (search_off + TextButton)"
  - "list_day_group_header uses no ProviderScope (pure StatelessWidget) — same pattern as amount_display golden"
  - "list_sort_filter_bar overrides currentLocaleProvider to prevent async timer from settings-repository chain"
metrics:
  duration: "~10 minutes"
  completed: "2026-05-31"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 0
  files_created: 22
---

# Phase 30 Plan 03: Golden Baselines for 4 List-Tab Widgets Summary

4 golden test files covering list_day_group_header, list_transaction_tile, list_sort_filter_bar, and list_empty_state — 18 PNG baselines across 3 locales (ja/zh/en) in light theme with hard-fail CI and no pixel-tolerance threshold (D-01/D-02/D-03).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Golden tests for list_day_group_header, list_transaction_tile, list_sort_filter_bar | 443420d4 | 3 test files + 9 PNG baselines |
| 2 | list_empty_state golden test (9 cases: 3 variants × 3 locales) | 81e5b332 | 1 test file + 9 PNG baselines |

## Changes Made

### Task 1: 3 golden test files + 9 baselines

**list_day_group_header_golden_test.dart:**
- Pattern: `amount_display_golden_test.dart` analog (no ProviderScope — pure StatelessWidget)
- Fixed `DateTime(2026, 5, 15)` — no `DateTime.now()` dependency
- `_wrap`: `MaterialApp` with `ThemeData.light()`, no ProviderScope, 390×32 SizedBox
- Widget constructor: `ListDayGroupHeader(date: _date, locale: const Locale('ja'))` — locale passed to both `_wrap` and widget
- 3 tests: ja/zh/en → `matchesGoldenFile('goldens/list_day_group_header_{locale}.png')`

**list_transaction_tile_golden_test.dart:**
- Pattern: `soul_vs_survival_card_golden_test.dart` analog (ProviderScope + fixed fixture)
- `_makeTx()` fixture: fixed `DateTime(2026, 5, 1, 10, 30)`, amount=1234, survival ledger
- ProviderScope with no overrides (deleteTransactionUseCaseProvider only called on dismiss, not build)
- Fixed display values: `tagText: 'Survival'`, `formattedAmount: '¥1,234'`, `formattedTime: '10:30'`
- 390×80 SizedBox — matches tile height constraint

**list_sort_filter_bar_golden_test.dart:**
- Pattern: `soul_vs_survival_card_golden_test.dart` + `list_sort_filter_bar_test.dart` override set
- ProviderScope with `currentLocaleProvider.overrideWith((_) async => locale)` to prevent async timer
- `isGroupMode` defaults to false (no Mine-only chip visible)
- 390×56 SizedBox

### Task 2: list_empty_state golden test + 9 baselines

**list_empty_state_golden_test.dart:**
- Pattern: `per_category_breakdown_card_golden_test.dart` analog (ProviderScope + nested loop)
- ProviderScope required (ConsumerWidget — ref.read in onPressed callbacks)
- No provider overrides needed (button callbacks not triggered during pumpAndSettle)
- Nested loops: `for locale in [ja, zh, en]` × `for variant in ListEmptyVariant.values`
- Golden naming: `list_empty_state_${variant.name}_${locale.languageCode}.png`
- 390×300 SizedBox

**9 baselines visually confirm D-04:**
- `noData` → `Icons.receipt_long_outlined`, no TextButton
- `dayEmpty` → `Icons.event_busy_outlined` + TextButton (listEmptyDayClear)
- `filtered` → `Icons.search_off_outlined` + TextButton (listEmptyFilteredClear)

## Verification Results

| Check | Result |
|-------|--------|
| `flutter test list_day_group_header_golden_test.dart` | PASS (3/3) |
| `flutter test list_transaction_tile_golden_test.dart` | PASS (3/3) |
| `flutter test list_sort_filter_bar_golden_test.dart` | PASS (3/3) |
| `flutter test list_empty_state_golden_test.dart` | PASS (9/9) |
| All 4 files without `--update-goldens` | PASS (18/18) |
| `ls test/golden/goldens/list_*.png \| wc -l` | 18 (3+3+3+9) |
| `flutter analyze --no-fatal-infos` (new files only) | 0 new issues |

**Note on `flutter analyze` output:** Global analysis shows 4 issues — all pre-existing:
- 1 `build/ios/SourcePackages/firebase_messaging` warning
- 2 `category_selection_screen.dart:386,502` deprecated `onReorder` API
These match the 4 pre-existing issues documented in 30-02-SUMMARY.md. The new golden test files introduce 0 issues.

**Note on PNG count:** PLAN.md stated 15 baselines but the correct count is 3+3+3+9=18. The discrepancy is a typo in the plan's success criteria comment `(3+3+3+9 — from this plan; 6 more from Plan 04)`. We have 18 baselines from this plan, which is correct.

## Deviations from Plan

### Auto-fix: `const DateTime` → `final DateTime` (Rule 1 — Bug)

**Found during:** Task 1, `flutter analyze` pre-commit
**Issue:** `const _date = DateTime(2026, 5, 15)` — `DateTime` constructor is not const-eligible (`const_initialized_with_non_constant_value` and `const_with_non_const` errors)
**Fix:** Changed to `final _date = DateTime(2026, 5, 15)` in `list_day_group_header_golden_test.dart`; also changed `const now = ...` to `final now = ...` in `list_transaction_tile_golden_test.dart`
**Files modified:** 2 test files (fixed before commit)
**Commit:** 443420d4

## Known Stubs

None — golden test files capture production widget rendering with real ARB strings. All 3 locales render actual translated text. No placeholder data.

## Threat Flags

None — PNG files contain rendered UI layout only, no PII, no credentials, no sensitive data (T-30-03 accepted per plan threat model).

## Self-Check: PASSED

- [x] `test/golden/list_day_group_header_golden_test.dart` exists — FOUND
- [x] `test/golden/list_transaction_tile_golden_test.dart` exists — FOUND
- [x] `test/golden/list_sort_filter_bar_golden_test.dart` exists — FOUND
- [x] `test/golden/list_empty_state_golden_test.dart` exists — FOUND
- [x] `test/golden/goldens/list_empty_state_noData_ja.png` exists — FOUND
- [x] `test/golden/goldens/list_empty_state_dayEmpty_ja.png` exists — FOUND
- [x] `test/golden/goldens/list_empty_state_filtered_ja.png` exists — FOUND
- [x] Total list_*.png count == 18 (3+3+3+9) — VERIFIED
- [x] All 4 golden test files pass without --update-goldens (18/18) — VERIFIED
- [x] Commit 443420d4 exists — VERIFIED
- [x] Commit 81e5b332 exists — VERIFIED
