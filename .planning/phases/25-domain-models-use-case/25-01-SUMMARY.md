---
phase: 25-domain-models-use-case
plan: "01"
subsystem: list-domain
tags:
  - freezed
  - domain-models
  - import-guard
  - v1.4
dependency_graph:
  requires:
    - "Phase 24 sort_config.dart (SortField/SortDirection enums)"
    - "Phase 24 transaction.dart (LedgerType enum)"
  provides:
    - "lib/features/list/domain/models/list_sort_config.dart (ListSortConfig Freezed VO)"
    - "lib/features/list/domain/models/list_filter_state.dart (ListFilterState Freezed VO, 7 fields)"
    - "lib/features/list/domain/import_guard.yaml (deny-only parent)"
    - "lib/features/list/domain/models/import_guard.yaml (allow-list child)"
  affects:
    - "Phase 26 listFilterStateProvider (consumes ListFilterState directly)"
    - "Phase 25 Plan 02 GetListTransactionsUseCase (consumes both VOs)"
tech_stack:
  added: []
  patterns:
    - "Freezed no-JSON VO (best_joy_moment_row.dart analog)"
    - "Private constructor const ._() for instance methods (TimeWindow analog)"
    - "@Default on enum fields (@Default(SortField.updatedAt), @Default(SortDirection.desc))"
    - "import_guard deny-parent + allow-child pair for new feature domain directory"
key_files:
  created:
    - lib/features/list/domain/import_guard.yaml
    - lib/features/list/domain/models/import_guard.yaml
    - lib/features/list/domain/models/list_sort_config.dart
    - lib/features/list/domain/models/list_sort_config.freezed.dart
    - lib/features/list/domain/models/list_filter_state.dart
    - lib/features/list/domain/models/list_filter_state.freezed.dart
  modified: []
decisions:
  - "import_guard allow-list uses relative paths (not package: URIs) to match actual Dart import statements — discovered during custom_lint run; package: paths in YAML cause import_guard violations for relative imports in source"
  - "list_sort_config.dart listed explicitly in models/import_guard.yaml allow-list because list_filter_state.dart imports it via relative path 'list_sort_config.dart'"
metrics:
  duration: "~12 minutes"
  completed_date: "2026-05-29"
  tasks_completed: 2
  tasks_total: 2
  files_created: 6
  files_modified: 0
---

# Phase 25 Plan 01: Domain Models (import_guard + ListSortConfig + ListFilterState) Summary

**One-liner:** Two Freezed value objects (`ListSortConfig` wrapping SortField/SortDirection with updatedAt/desc defaults, `ListFilterState` with 7 fields + `clearAll()` + `initial()` factory) plus import_guard configs for the new `lib/features/list/domain/` directory tree, with build_runner generating both `.freezed.dart` files.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create import_guard configs for lib/features/list/domain/ | 3b654a3 | lib/features/list/domain/import_guard.yaml, lib/features/list/domain/models/import_guard.yaml |
| 2 | Create ListSortConfig + ListFilterState Freezed VOs and run build_runner | a8de301 | lib/features/list/domain/models/list_sort_config.dart, list_sort_config.freezed.dart, list_filter_state.dart, list_filter_state.freezed.dart; updated models/import_guard.yaml |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] import_guard.yaml allow-list must use relative paths, not package: URIs**

- **Found during:** Task 2 (custom_lint run after creating Dart files)
- **Issue:** The plan's interface section showed `package:home_pocket/...` paths for the models import_guard.yaml allow list. However, import_guard_custom_lint matches the actual import statements in source files. Since the project enforces `prefer_relative_imports`, the YAML must mirror those relative paths exactly.
- **Fix:** Updated `lib/features/list/domain/models/import_guard.yaml` to use relative paths: `../../../../shared/constants/sort_config.dart`, `../../../accounting/domain/models/transaction.dart`, and `list_sort_config.dart`.
- **Files modified:** lib/features/list/domain/models/import_guard.yaml
- **Commit:** a8de301

**2. [Rule 1 - Bug] prefer_relative_imports linter rule requires relative imports in source files**

- **Found during:** Task 2 (initial `flutter analyze` run, 3 issues found)
- **Issue:** First draft of list_sort_config.dart and list_filter_state.dart used `package:home_pocket/...` imports; analyzer reported `prefer_relative_imports` warnings.
- **Fix:** Changed all intra-lib imports to relative paths in both Dart files to match project convention.
- **Files modified:** list_sort_config.dart, list_filter_state.dart
- **Commit:** a8de301

## Verification

- `flutter pub run build_runner build --delete-conflicting-outputs` — exit 0, wrote 1371 outputs
- Both `.freezed.dart` files generated: `list_sort_config.freezed.dart` (9.0 KB), `list_filter_state.freezed.dart` (16.3 KB)
- `flutter analyze lib/features/list/ --no-pub` — **No issues found!**
- `grep -c "deny:" lib/features/list/domain/import_guard.yaml` → 1
- `grep -c "sort_config.dart" lib/features/list/domain/models/import_guard.yaml` → 2
- `grep -cF "const ListFilterState._()" lib/features/list/domain/models/list_filter_state.dart` → 1
- `grep -c "clearAll" lib/features/list/domain/models/list_filter_state.dart` → 2
- `grep -c "@Default(SortField.updatedAt)" lib/features/list/domain/models/list_sort_config.dart` → 1
- custom_lint: no import_guard violations for lib/features/list/domain/**

## Known Stubs

None. Both Freezed VOs are complete domain value objects with no placeholder values. `searchQuery` defaults to `''` and `memberBookId?` defaults to `null` — intentional design values, not stubs. Downstream consumers (Phase 26 text search, Phase 29 family filter) are deferred by plan decisions D-05/D-01.

## Threat Flags

None. Pure in-memory value objects with no I/O, secrets, user-input parsing, network or persistence operations. No new attack surface introduced.

## Self-Check: PASSED

- lib/features/list/domain/import_guard.yaml: FOUND
- lib/features/list/domain/models/import_guard.yaml: FOUND
- lib/features/list/domain/models/list_sort_config.dart: FOUND
- lib/features/list/domain/models/list_sort_config.freezed.dart: FOUND
- lib/features/list/domain/models/list_filter_state.dart: FOUND
- lib/features/list/domain/models/list_filter_state.freezed.dart: FOUND
- Commit 3b654a3: FOUND (Task 1)
- Commit a8de301: FOUND (Task 2)
