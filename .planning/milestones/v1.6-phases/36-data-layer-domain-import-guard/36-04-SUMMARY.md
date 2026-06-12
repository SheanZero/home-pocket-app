---
phase: 36
plan: "04"
subsystem: shopping-list, domain
tags: [feat, domain, freezed, import-guard, shopping-list]
dependency_graph:
  requires: ["36-01", "36-03"]
  provides:
    - lib/features/shopping_list/domain/models/shopping_item.dart
    - lib/features/shopping_list/domain/models/shopping_list_filter.dart
    - lib/features/shopping_list/domain/models/shopping_item_params.dart
    - lib/features/shopping_list/domain/repositories/shopping_item_repository.dart
    - lib/features/shopping_list/domain/repositories/import_guard.yaml
  affects:
    - lib/data/repositories/shopping_item_repository_impl.dart (Plan 06)
    - lib/application/shopping_list/ (Phase 37 use cases)
    - lib/features/shopping_list/presentation/ (Phase 38 providers)
tech_stack:
  added: []
  patterns:
    - "@freezed abstract class with factory constructor = _ClassName"
    - "import_guard.yaml subdirectory allow-list with inherit: true"
    - "Domain-owned abstract repository interface (no Drift imports)"
key_files:
  created:
    - lib/features/shopping_list/domain/models/shopping_item.dart
    - lib/features/shopping_list/domain/models/shopping_item.freezed.dart
    - lib/features/shopping_list/domain/models/shopping_list_filter.dart
    - lib/features/shopping_list/domain/models/shopping_list_filter.freezed.dart
    - lib/features/shopping_list/domain/models/shopping_item_params.dart
    - lib/features/shopping_list/domain/models/shopping_item_params.freezed.dart
    - lib/features/shopping_list/domain/repositories/shopping_item_repository.dart
    - lib/features/shopping_list/domain/repositories/import_guard.yaml
  modified: []
decisions:
  - "ShoppingItem uses abstract class with private constructor const ShoppingItem._() to allow future custom methods"
  - "ShoppingListFilter.initial() factory returns const ShoppingListFilter() — all defaults (private list, statusFilter=all)"
  - "ShoppingItemRepository uses abstract class (not abstract interface class) — matches TransactionRepository style"
  - "repositories/import_guard.yaml: allow dart:core + ../models/shopping_item.dart; inherit:true pulls parent domain deny rules"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-07"
  tasks_completed: 2
  tasks_total: 2
  files_created: 8
  files_modified: 0
  files_deleted: 0
---

# Phase 36 Plan 04: ShoppingItem Domain Models + Repository Interface Summary

**One-liner:** Three Freezed domain models (ShoppingItem 18-field, ShoppingListFilter, ShoppingItemParams) plus ShoppingItemRepository abstract interface with 8 method signatures — zero Drift imports, import_guard enforced.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create ShoppingItem, ShoppingListFilter, ShoppingItemParams Freezed models | 4a6a195e | 3 source .dart + 3 generated .freezed.dart |
| 2 | Create ShoppingItemRepository abstract interface | 41b9165c | shopping_item_repository.dart + repositories/import_guard.yaml |

## What Was Built

### Task 1: Three Freezed Domain Models

**`ShoppingItem`** — core domain entity with 18 fields matching the v20 table column order:
- `id`, `deviceId`, `listType`, `name` (required)
- `LedgerType? ledgerType`, `String? categoryId`
- `@Default(<String>[]) List<String> tags` (D-01: JSON-encoded at repo boundary)
- `String? note` (decrypted plaintext — encrypted at repo boundary)
- `@Default(1) int quantity` (D-02), `int? estimatedPrice` (ITEM-05)
- `DateTime? completedAt` (D-03 — overrides original D7/no-completedAt)
- `@Default(false) bool isCompleted`, `@Default(0) int sortOrder`
- `@Default(false) bool isSynced`, `@Default(false) bool isDeleted`
- `String? addedByBookId`, `required DateTime createdAt`, `DateTime? updatedAt`
- Uses `const ShoppingItem._()` private constructor to allow future custom methods

**`ShoppingListFilter`** — filter state value object:
- `@Default('private') String listType` — current segment
- `LedgerType? ledgerType` — null means all ledger types
- `@Default('all') String statusFilter` — 'all' | 'active'
- `@Default('') String searchQuery`
- `factory ShoppingListFilter.initial()` → `const ShoppingListFilter()`

**`ShoppingItemParams`** — write-params DTO for use cases:
- `required String name`, `required String listType`
- Optional: `ledgerType`, `categoryId`, `tags`, `note`, `quantity`, `estimatedPrice`, `addedByBookId`
- No `Value<T>` Drift types — pure Dart

All three models import `package:freezed_annotation/freezed_annotation.dart` and `../../../accounting/domain/models/transaction.dart` (for `LedgerType`). Zero Drift imports.

### Task 2: ShoppingItemRepository Interface + repositories import_guard.yaml

**`ShoppingItemRepository`** — abstract class with 8 method signatures:
1. `Future<void> insert(ShoppingItem item)`
2. `Future<void> update(ShoppingItem item)`
3. `Future<void> softDelete(String id)`
4. `Future<void> softDeleteAllCompleted(String listType)`
5. `Future<ShoppingItem?> findById(String id)`
6. `Stream<List<ShoppingItem>> watchByListType(String listType)`
7. `Future<void> upsert(ShoppingItem item)` — for sync apply handler (Phase 37)
8. `Future<void> reorder(String id, int newSortOrder)` — for reorder use case (Phase 37)

Single import: `../models/shopping_item.dart`. No Drift, no Flutter.

**`repositories/import_guard.yaml`**:
- `allow: [dart:core, ../models/shopping_item.dart]`
- `inherit: true` — pulls parent `domain/import_guard.yaml` deny rules (data/**, infrastructure/**, application/**, flutter/**)

## Verification Results

- `grep -r 'package:drift' lib/features/shopping_list/domain/`: 0 matches
- `dart run custom_lint --no-fatal-infos`: No issues found
- `flutter analyze lib/features/shopping_list/domain/`: No issues found (ran in 0.3s)
- All 3 `.freezed.dart` files generated by build_runner
- `ShoppingItemRepository` has exactly 8 method signatures (grep confirms 8 Future/Stream lines)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no stub patterns. These are pure domain type definitions with no data wiring.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. The domain models are pure Dart value objects. The `ShoppingItem.note` field is typed as `String?` (plaintext at domain layer) per T-36-07 accept disposition; encryption is enforced at the repository impl boundary (Plan 06).

## Self-Check: PASSED

- [x] `lib/features/shopping_list/domain/models/shopping_item.dart` exists
- [x] `lib/features/shopping_list/domain/models/shopping_item.freezed.dart` exists
- [x] `lib/features/shopping_list/domain/models/shopping_list_filter.dart` exists
- [x] `lib/features/shopping_list/domain/models/shopping_list_filter.freezed.dart` exists
- [x] `lib/features/shopping_list/domain/models/shopping_item_params.dart` exists
- [x] `lib/features/shopping_list/domain/models/shopping_item_params.freezed.dart` exists
- [x] `lib/features/shopping_list/domain/repositories/shopping_item_repository.dart` exists
- [x] `lib/features/shopping_list/domain/repositories/import_guard.yaml` exists
- [x] Commits 4a6a195e and 41b9165c exist in git log
- [x] Zero Drift imports in domain/
- [x] dart run custom_lint: 0 violations
- [x] flutter analyze: 0 issues
