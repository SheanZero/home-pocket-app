---
phase: 36
plan: "03"
subsystem: shared-widgets, import-guard
tags: [refactor, import-guard, shopping-list, ledger-type-selector]
dependency_graph:
  requires: ["36-01", "36-02"]
  provides: ["lib/shared/widgets/ledger_type_selector.dart", "shopping_list import_guard boundaries"]
  affects: ["lib/features/accounting/presentation/widgets/transaction_details_form.dart", "test files referencing LedgerTypeSelector"]
tech_stack:
  added: []
  patterns: ["import_guard_custom_lint YAML boundary enforcement", "shared widgets pattern"]
key_files:
  created:
    - lib/shared/widgets/ledger_type_selector.dart
    - lib/features/shopping_list/domain/import_guard.yaml
    - lib/features/shopping_list/domain/models/import_guard.yaml
    - lib/features/shopping_list/presentation/import_guard.yaml
  modified:
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - test/widget/features/accounting/presentation/widgets/entry_widgets_dark_mode_test.dart
    - test/widget/features/accounting/presentation/widgets/transaction_details_form_smoke_test.dart
  deleted:
    - lib/features/accounting/presentation/widgets/ledger_type_selector.dart
decisions:
  - "LedgerTypeSelector moved to lib/shared/widgets/ with relative import paths (../../core/theme/, ../../features/accounting/domain/models/)"
  - "Two test files also updated from old accounting-specific package path to shared package path"
  - "shopping_list presentation import_guard.yaml allows CategorySelectionScreen cross-feature dependency (ITEM-03 — cannot move to shared without dragging accounting providers)"
metrics:
  duration: "~10 minutes"
  completed: "2026-06-07"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 3
  files_deleted: 1
---

# Phase 36 Plan 03: LedgerTypeSelector Move + shopping_list Import Guards Summary

**One-liner:** Move LedgerTypeSelector to lib/shared/widgets/ with corrected relative import paths, plus 3 import_guard.yaml files establishing shopping_list feature layer boundary enforcement.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Move LedgerTypeSelector to lib/shared/widgets/ | d4935ebc | lib/shared/widgets/ledger_type_selector.dart (new), lib/features/accounting/presentation/widgets/ledger_type_selector.dart (deleted), transaction_details_form.dart + 2 test files (import updated) |
| 2 | Create import_guard YAML files for shopping_list/ | bad0eff5 | 3 YAML files created |

## What Was Built

### Task 1: LedgerTypeSelector Move

The `LedgerTypeSelector` widget was moved from `lib/features/accounting/presentation/widgets/` to `lib/shared/widgets/`. Import paths within the widget were updated:
- `../../../../core/theme/app_palette.dart` → `../../core/theme/app_palette.dart`
- `../../../../core/theme/app_text_styles.dart` → `../../core/theme/app_text_styles.dart`
- `../../domain/models/transaction.dart` → `../../features/accounting/domain/models/transaction.dart`

All 4 consumer import sites were updated (1 source file + 2 test files + the old location deleted).

### Task 2: shopping_list Import Guard YAML Files

Three `import_guard.yaml` files created to enforce layer boundaries for the `shopping_list` feature tree before any source files exist:

- **domain/import_guard.yaml**: Deny-only parent guard (data, infrastructure, application, presentation, flutter)
- **domain/models/import_guard.yaml**: Per-subdirectory allow-list (dart:core, freezed_annotation, LedgerType from accounting domain)
- **presentation/import_guard.yaml**: Allow CategorySelectionScreen cross-feature dependency + deny infra/daos/tables

## Verification Results

- `lib/shared/widgets/ledger_type_selector.dart` exists
- `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` deleted
- `flutter analyze` on modified files: 0 issues
- `dart run custom_lint --no-fatal-infos`: 0 violations (both after Task 1 and Task 2)
- Full `flutter analyze`: 17 issues — all pre-existing from Plans 36-01/36-02 test scaffold files referencing shopping_item classes not yet created (ShoppingItemDao, ShoppingItemRepositoryImpl, ShoppingItem); none introduced by this plan

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing consumer update] Two test files importing old ledger_type_selector path**
- **Found during:** Task 1 verification (full flutter analyze)
- **Issue:** `test/widget/features/accounting/presentation/widgets/entry_widgets_dark_mode_test.dart` and `transaction_details_form_smoke_test.dart` both imported from the old `package:home_pocket/features/accounting/presentation/widgets/ledger_type_selector.dart` path
- **Fix:** Updated both test files to `package:home_pocket/shared/widgets/ledger_type_selector.dart`
- **Files modified:** 2 test files
- **Commit:** d4935ebc (included in Task 1 commit)

**2. [Rule 1 - Bug] package-absolute import triggered prefer_relative_imports analyzer info**
- **Found during:** Task 1, first analyze run on the new file
- **Issue:** Used `package:home_pocket/features/accounting/domain/models/transaction.dart` in new shared widget; analyzer reported `prefer_relative_imports` info
- **Fix:** Changed to relative import `../../features/accounting/domain/models/transaction.dart`
- **Files modified:** lib/shared/widgets/ledger_type_selector.dart

## Known Stubs

None — this plan creates YAML configuration files and moves/updates an existing widget. No stubs.

## Threat Flags

None — no new network endpoints, auth paths, or trust-boundary-crossing code paths introduced. The `LedgerTypeSelector` widget is a stateless UI component with zero accounting-specific state (T-36-06: accept).

## Self-Check: PASSED

- [x] `lib/shared/widgets/ledger_type_selector.dart` exists
- [x] `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` does NOT exist
- [x] `lib/features/shopping_list/domain/import_guard.yaml` exists
- [x] `lib/features/shopping_list/domain/models/import_guard.yaml` exists
- [x] `lib/features/shopping_list/presentation/import_guard.yaml` exists
- [x] Commits d4935ebc and bad0eff5 exist in git log
- [x] `dart run custom_lint --no-fatal-infos` exits 0 with no violations
