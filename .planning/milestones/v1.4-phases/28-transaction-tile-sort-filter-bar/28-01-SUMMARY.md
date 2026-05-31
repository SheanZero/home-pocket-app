---
phase: 28-transaction-tile-sort-filter-bar
plan: "01"
subsystem: list-filter-state
tags: [d-01, freezed, arb, i18n, filter, multi-select]
dependency_graph:
  requires:
    - "Phase 26: listFilterProvider (state_list_filter.dart) — mutator shell"
    - "Phase 25: ListFilterState Freezed VO — field to rename"
  provides:
    - "D-01 categoryIds Set<String> field — consumed by Phase 28 widget plans"
    - "22 Phase 28 ARB keys — consumed by Phase 28 widget plans (S.of(context) references)"
    - "setCategories(Set<String>) + toggleCategory(String) mutators"
    - "Dart-side category multi-select filter in listTransactionsProvider"
  affects:
    - "lib/application/list/get_list_transactions_use_case.dart (categoryId: null)"
    - "All existing list filter tests (updated API)"
tech_stack:
  added: []
  patterns:
    - "@Default(<String>{}) Set<String> annotation on Freezed field"
    - "Dart-side Set.contains() filter after SQL fetch (D-01 A3)"
    - "TDD RED/GREEN cycle for domain model field expansion"
key_files:
  created:
    - test/unit/features/list/list_filter_state_category_test.dart
  modified:
    - lib/features/list/domain/models/list_filter_state.dart
    - lib/features/list/domain/models/list_filter_state.freezed.dart
    - lib/features/list/presentation/providers/state_list_filter.dart
    - lib/features/list/presentation/providers/state_list_filter.g.dart
    - lib/features/list/presentation/providers/state_list_transactions.dart
    - lib/features/list/presentation/providers/state_list_transactions.g.dart
    - lib/application/list/get_list_transactions_use_case.dart
    - test/unit/features/list/presentation/providers/list_filter_notifier_test.dart
    - test/unit/features/list/presentation/providers/list_transactions_provider_test.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/generated/app_localizations_en.dart
decisions:
  - "D-01 category filter expanded to Set<String> with Dart-side contains() rather than SQL IN clause (simpler migration path; single-month <500 rows — performance equivalent)"
  - "get_list_transactions_use_case.dart passes categoryId:null to SQL layer; multi-select filtering is purely Dart-side in listTransactionsProvider"
  - "TDD cycle used: RED commit before implementation, GREEN commit after all tests pass"
metrics:
  duration: "~25 minutes"
  completed: "2026-05-30T11:29:00Z"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 16
---

# Phase 28 Plan 01: D-01 State Expansion + Phase 28 ARB Keys Summary

Expanded `ListFilterState.categoryId: String?` to `@Default(<String>{}) Set<String> categoryIds` (D-01), wired Dart-side category multi-select filter in `listTransactionsProvider`, and added all 22 Phase 28 ARB keys across three locale files.

## What Was Built

### Task 1: D-01 Freezed Field Change + Notifier Mutators + Dart-side Filter

**list_filter_state.dart:** Replaced `String? categoryId` with `@Default(<String>{}) Set<String> categoryIds`. Updated docstring to reflect multi-select semantics.

**state_list_filter.dart:** Removed `setCategoryFilter(String? id)`. Added two new mutators:
- `setCategories(Set<String> ids)` — replaces the entire category filter set
- `toggleCategory(String id)` — adds/removes a single leaf ID using `Set<String>.from()` copy-then-mutate pattern (immutability preserved)

**state_list_transactions.dart:** Inserted Dart-side category filter step between the day-filter step and the text-search step:
```dart
if (filter.categoryIds.isNotEmpty) {
  txs = txs.where((tx) => filter.categoryIds.contains(tx.categoryId)).toList();
}
```

**get_list_transactions_use_case.dart:** Changed `categoryId: params.filter.categoryId` to `categoryId: null` in both `execute()` and `watch()` — the SQL layer no longer filters by category; Dart-side handles multi-select.

**build_runner:** Ran with `--delete-conflicting-outputs`; regenerated `list_filter_state.freezed.dart` with `categoryIds` in all `copyWith` signatures.

### Task 2: 22 Phase 28 ARB Keys

Added all 22 keys from the UI-SPEC §Copywriting Contract table to `app_ja.arb`, `app_zh.arb`, and `app_en.arb` simultaneously:

| Key | ja | zh | en |
|-----|----|----|-----|
| listSortDate | 日付 | 日期 | Date |
| listSortEditTime | 更新日時 | 更新时间 | Edit time |
| listSortAmount | 金額 | 金额 | Amount |
| listLedgerAll | すべて | 全部 | All |
| listLedgerSurvival | 生存 | 生存 | Survival |
| listLedgerSoul | 魂 | 灵魂 | Soul |
| listCategoryChip | カテゴリ | 分类 | Categories |
| listCategoryChipN (param) | カテゴリ ({n}) | 分类 ({n}) | Categories ({n}) |
| listSearchHint | 検索... | 搜索... | Search... |
| listClearAll | クリア | 清除 | Clear |
| listDeleteConfirmTitle | 削除しますか？ | 确认删除？ | Delete entry? |
| listDeleteConfirmBody | この記録を削除します。元に戻せません。 | 此记录将被删除，无法恢复。 | This entry will be deleted and cannot be undone. |
| listDeleteCancelButton | キャンセル | 取消 | Cancel |
| listDeleteConfirmButton | 削除 | 删除 | Delete |
| listDeletedSnackBar | 削除しました | 已删除 | Deleted |
| listCategorySheetTitle | カテゴリで絞り込む | 按分类筛选 | Filter by category |
| listCategorySheetClear | クリア | 清除 | Clear |
| listCategorySheetApply | 適用 | 应用 | Apply |
| listCategorySheetApplyN (param) | 適用 ({n}) | 应用 ({n}) | Apply ({n}) |
| listEmptyMonth | この月の記録はありません | 本月暂无记录 | No entries this month |
| listEmptyFiltered | 条件に合う記録が見つかりません | 没有符合条件的记录 | No entries match your filters |
| listEmptyFilteredClear | フィルターをクリア | 清除筛选 | Clear filters |

Ran `flutter gen-l10n`; regenerated `lib/generated/app_localizations*.dart`.

## Commits

| Hash | Type | Description |
|------|------|-------------|
| 7f84a67 | test | RED — failing tests for D-01 categoryIds Set<String> + mutators |
| 9b5ed16 | feat | GREEN — D-01 field change + mutators + Dart-side filter |
| a704170 | feat | 22 Phase 28 ARB keys + gen-l10n |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Cascading categoryId references after D-01 field rename**
- **Found during:** Task 1 (flutter analyze after build_runner)
- **Issue:** `get_list_transactions_use_case.dart` still referenced `filter.categoryId` (old field name) at lines 54 and 78; `list_filter_notifier_test.dart` still used `setCategoryFilter`/`categoryId` API (8 references); `list_transactions_provider_test.dart` constructed `ListFilterState(categoryId: ...)` and asserted `filter.categoryId`.
- **Fix:** Updated `get_list_transactions_use_case.dart` to pass `categoryId: null` (with comment explaining Dart-side replaces SQL filter); updated both test files to use new `setCategories`/`categoryIds` API; updated `list_transactions_provider_test.dart` test to verify Dart-side filtering behavior instead of SQL forwarding.
- **Files modified:** `lib/application/list/get_list_transactions_use_case.dart`, `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart`, `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart`
- **Commits:** included in `9b5ed16`

## Verification

### flutter analyze
- 0 errors in `lib/`
- 4 `info`-level issues: 1 `warning` in `build/ios/SourcePackages/` (third-party dep), 2 `info` in `category_selection_screen.dart` (pre-existing `onReorder` deprecation, out of scope)

### Tests
- All 53 list unit tests pass (`flutter test test/unit/features/list/`)
- 11 new D-01-specific tests pass (`list_filter_state_category_test.dart`)
- Dart-side filter test in `list_transactions_provider_test.dart` passes

### Done Criteria
- [x] `list_filter_state.dart` contains "categoryIds" (not "categoryId")
- [x] `state_list_filter.dart` contains "setCategories" and "toggleCategory" (not "setCategoryFilter")
- [x] `state_list_transactions.dart` contains "categoryIds.isNotEmpty"
- [x] `list_filter_state.freezed.dart` contains "categoryIds" in copyWith signature (31 occurrences)
- [x] `listDeleteConfirmTitle` present in all three ARB files (1 each)
- [x] All three ARB files have identical 22 Phase 28 keys
- [x] `flutter gen-l10n` exits 0 with no warnings
- [x] `flutter analyze` 0 errors in `lib/`

## Known Stubs

None — this plan is purely model/state/ARB layer. No UI rendering with placeholder data.

## Threat Flags

No new trust boundaries introduced. D-01 is purely in-memory domain model and Dart-side filter; no new data source access. ARB keys contain only UI copy strings (no PII or financial values).

## Self-Check: PASSED

- `lib/features/list/domain/models/list_filter_state.dart` — FOUND
- `lib/features/list/presentation/providers/state_list_filter.dart` — FOUND
- `lib/features/list/presentation/providers/state_list_transactions.dart` — FOUND
- `lib/l10n/app_ja.arb` — FOUND (listDeleteConfirmTitle present: 1)
- `lib/l10n/app_zh.arb` — FOUND (listDeleteConfirmTitle present: 1)
- `lib/l10n/app_en.arb` — FOUND (listDeleteConfirmTitle present: 1)
- Commit 7f84a67 — FOUND (test RED)
- Commit 9b5ed16 — FOUND (feat GREEN)
- Commit a704170 — FOUND (feat ARB)
