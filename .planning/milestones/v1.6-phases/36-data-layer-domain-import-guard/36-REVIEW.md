---
phase: 36-data-layer-domain-import-guard
reviewed: 2026-06-07T12:30:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - lib/data/app_database.dart
  - lib/data/tables/shopping_items_table.dart
  - lib/data/daos/shopping_item_dao.dart
  - lib/data/repositories/shopping_item_repository_impl.dart
  - lib/features/shopping_list/domain/models/shopping_item.dart
  - lib/features/shopping_list/domain/models/shopping_list_filter.dart
  - lib/features/shopping_list/domain/models/shopping_item_params.dart
  - lib/features/shopping_list/domain/repositories/shopping_item_repository.dart
  - lib/shared/widgets/ledger_type_selector.dart
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/features/shopping_list/domain/import_guard.yaml
  - lib/features/shopping_list/domain/models/import_guard.yaml
  - lib/features/shopping_list/domain/repositories/import_guard.yaml
  - lib/features/shopping_list/presentation/import_guard.yaml
  - test/unit/data/migrations/shopping_items_v20_contract_test.dart
  - test/unit/data/daos/shopping_item_dao_test.dart
  - test/unit/data/repositories/shopping_item_repository_impl_test.dart
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
---

# Phase 36: Code Review Report

**Reviewed:** 2026-06-07T12:30:00Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

Reviewed the Phase 36 data + domain + import-guard layer for the shopping-list
feature: the `shopping_items` Drift table + v20 migration, the DAO, the
field-encrypting repository, three pure-domain Freezed models, the repository
interface, four `import_guard.yaml` files, the relocated `LedgerTypeSelector`
widget, and three unit-test files.

`flutter analyze` is clean on all source files, the field-encryption boundary is
correctly implemented (note encrypted on write, silently null on decrypt
failure, no ciphertext logging), the reactive `watchByListType` stream correctly
declares `readsFrom:` (v1.4 GAP-2 prevention), SQL is fully parameterized
(`Variable.withString`), and table-level CHECK constraints are confirmed present
in the runtime DDL.

The dominant defect is the **declared-but-never-created indices**: the
`customIndices` getter convention used throughout this codebase is NOT a Drift
API — Drift only reads `@TableIndex` *class annotations*. I proved at runtime
that **all 5 declared `idx_shopping_*` indices are absent** from a freshly
created database, and the migration comment claiming `createTable` "emits ...
customIndices" is factually false. (Confirmed systemic: `idx_tx_*` are also
absent, but for shopping_items this phase relies on the false invariant *instead
of* the explicit `customStatement('CREATE INDEX ...')` pattern every other
migration step actually uses.) Several other comments encode incorrect Drift
mental models and several test/comment hygiene issues remain.

## Critical Issues

### CR-01: Declared `customIndices` are never created — relied-upon invariant is false

**File:** `lib/data/tables/shopping_items_table.dart:65-78`, `lib/data/app_database.dart:426-430`
**Issue:**
The table declares 5 indices via a `List<TableIndex> get customIndices` getter,
and the v20 migration creates the table with:

```dart
if (from < 20) {
  // migrator.createTable emits full DDL including customConstraints and customIndices.
  await migrator.createTable(shoppingItems);
}
```

This comment is **wrong**. In Drift 2.x, `TableIndex` is a *class-level
annotation* (`@Target({TargetKind.classType})`, used as `@TableIndex(...)` on the
table class). Drift's code generator never reads an arbitrarily-named
`customIndices` getter, and `createTable` only emits the table + the (real)
`customConstraints` override — never indices. I verified at runtime against a
fresh `AppDatabase.forTesting()`:

```
SHOPPING_INDICES_FOUND: []      // all 5 idx_shopping_* missing
TX_INDICES_FOUND: []            // pre-existing convention also non-functional
SHOPPING_DDL: CREATE TABLE "shopping_items" (... CHECK(list_type ...) ...)  // constraints OK, no indices
```

So none of `idx_shopping_list_type`, `idx_shopping_list_deleted`,
`idx_shopping_completed`, `idx_shopping_sort_order`, `idx_shopping_added_by_book`
exist. Every other migration step that wants an index issues an explicit
`customStatement('CREATE INDEX IF NOT EXISTS ...')` (see app_database.dart:198-205,
326-331, 378-385) — this step does not, because it trusts the false comment.

Classified Critical (not merely a perf concern, which is out of v1 scope)
because: (a) a load-bearing migration invariant is documented as true but is
false, which will mislead every future migration author who copies this pattern,
and (b) the table ships with zero of its intended indices while the code/comments
assert otherwise — a correctness gap between declared and actual schema. The
`watchByListType` query filters on `list_type`/`is_deleted` and orders by
`is_completed`/`sort_order`, all of which the missing indices were meant to back.

**Fix:** Add explicit index creation to the migration step (matching the
established pattern), and convert the dead getter to real `@TableIndex`
annotations so future regeneration also covers fresh installs:

```dart
// lib/data/app_database.dart — v20 step
if (from < 20) {
  await migrator.createTable(shoppingItems);
  await customStatement(
    "CREATE INDEX IF NOT EXISTS idx_shopping_list_type "
    "ON shopping_items (list_type)");
  await customStatement(
    "CREATE INDEX IF NOT EXISTS idx_shopping_list_deleted "
    "ON shopping_items (list_type, is_deleted)");
  await customStatement(
    "CREATE INDEX IF NOT EXISTS idx_shopping_completed "
    "ON shopping_items (is_completed)");
  await customStatement(
    "CREATE INDEX IF NOT EXISTS idx_shopping_sort_order "
    "ON shopping_items (sort_order)");
  await customStatement(
    "CREATE INDEX IF NOT EXISTS idx_shopping_added_by_book "
    "ON shopping_items (added_by_book_id)");
}
```

```dart
// lib/data/tables/shopping_items_table.dart — make indices real for fresh installs
@DataClassName('ShoppingItemRow')
@TableIndex(name: 'idx_shopping_list_type', columns: {#listType})
@TableIndex(name: 'idx_shopping_list_deleted', columns: {#listType, #isDeleted})
@TableIndex(name: 'idx_shopping_completed', columns: {#isCompleted})
@TableIndex(name: 'idx_shopping_sort_order', columns: {#sortOrder})
@TableIndex(name: 'idx_shopping_added_by_book', columns: {#addedByBookId})
class ShoppingItems extends Table { ... }
```

Then re-run `build_runner` and delete the non-functional `customIndices` getter.
(Note: this systemic issue affects every table in the codebase; at minimum, the
shopping_items migration must not depend on the false invariant.)

## Warnings

### WR-01: Migration comment asserts a Drift behavior that does not exist

**File:** `lib/data/app_database.dart:428`
**Issue:** `// migrator.createTable emits full DDL including customConstraints and customIndices.`
`customConstraints` IS emitted, `customIndices` is NOT (see CR-01). A comment
documenting a false runtime guarantee is worse than no comment — it actively
prevents reviewers from catching the missing-index bug.
**Fix:** Replace with an accurate statement, e.g.
`// createTable emits the table + customConstraints CHECKs. Indices are NOT emitted by createTable — see explicit CREATE INDEX below.`

### WR-02: `shopping_items_table.dart` comment cites the wrong reason for omitting `@override`

**File:** `lib/data/tables/shopping_items_table.dart:65`
**Issue:** `// No @override on customIndices — CLAUDE.md pitfall #11`. The real
reason there is no `@override` is that `customIndices` is **not a Drift base-class
member at all** (only `customConstraints` is). The comment frames a dead,
unrecognized getter as an intentional pattern, which masks CR-01.
**Fix:** Remove the getter entirely in favor of `@TableIndex` annotations (CR-01),
or, if kept temporarily, comment honestly: `// NOTE: this getter is NOT read by
Drift; indices are created via explicit CREATE INDEX in the v20 migration.`

### WR-03: v20 contract test validates a hand-written table, not the real Drift schema

**File:** `test/unit/data/migrations/shopping_items_v20_contract_test.dart:86-114`
**Issue:** The "physical schema" group builds its own `CREATE TABLE` via
`_createV20ShoppingItemsTable` on a raw `sqlite3` connection rather than
exercising `AppDatabase`'s actual migration/DDL. As a result it cannot catch
CR-01 (missing indices) or any drift between the hand-written DDL and the real
generated DDL, and it gives false confidence that "the v20 schema is correct".
The hand-written DDL even omits the indices entirely, so the test passing tells
us nothing about the production schema. Additionally, the `name TEXT` column here
has no length enforcement, and neither does the real Drift table at the SQL level
(Drift enforces `withLength(min:1, max:200)` only in Dart `validateIntegrity`) —
so the comment in the table (`withLength`) implies a guarantee raw inserts do not
get.
**Fix:** Assert against the real schema — open `AppDatabase.forTesting()` and
query `sqlite_master` for both the `shopping_items` table DDL and the
`idx_shopping_*` indices, e.g.:

```dart
final idx = await db.customSelect(
  "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_shopping%'",
).get();
expect(idx.map((r) => r.data['name']), containsAll([
  'idx_shopping_list_type', 'idx_shopping_list_deleted',
  'idx_shopping_completed', 'idx_shopping_sort_order',
  'idx_shopping_added_by_book',
]));
```

This test would have failed and surfaced CR-01.

### WR-04: No migration test exercises the v19→v20 upgrade path

**File:** `lib/data/app_database.dart:426-430` (no covering test)
**Issue:** CLAUDE.md flags "schemaVersion=20 migration correctness (if from < 20)"
as a focus area, but the only schema-version test asserts `schemaVersion == 20`
and the contract test uses a hand-rolled table (WR-03). There is no test that
opens a v19 database and runs `onUpgrade` to v20 to confirm `createTable` +
indices succeed and existing data survives. The DAO/repo tests all start from a
fresh v20 DB via `AppDatabase.forTesting()` (default `onCreate`), so the
`onUpgrade` branch for shopping_items is entirely uncovered.
**Fix:** Add a Drift migration test (using a v19 schema snapshot or
`SchemaVerifier`/`step-by-step` migration helper) that runs from < 20 to 20 and
asserts the table + indices exist afterward.

### WR-05: Stale "RED state / does not exist yet" scaffold comments in shipped tests

**File:** `test/unit/data/daos/shopping_item_dao_test.dart:1-10`, `test/unit/data/repositories/shopping_item_repository_impl_test.dart:1-9`
**Issue:** Both test files retain header comments asserting the production code
"does not exist yet" and the file "will fail to analyze/compile until Plans
02/04/05/06 are complete", plus inline `// RED — does not exist yet` on imports.
All referenced files now exist and the tests are GREEN. These comments are now
false and will confuse maintainers into thinking the suite is in a broken
intermediate state.
**Fix:** Delete the Wave-0 scaffold preamble and the `// RED` import annotations
now that the implementation has landed.

## Info

### IN-01: `transaction_details_form.dart` exceeds the 800-line file guideline

**File:** `lib/features/accounting/presentation/widgets/transaction_details_form.dart:1-831`
**Issue:** 831 lines, over the project's 800-line max (CLAUDE.md / coding-style).
Phase 36 only relocated the `LedgerTypeSelector` import (line 36), so this is
pre-existing, but it crosses the threshold. The `submit()` method (425-548) also
exceeds the <50-line function guideline.
**Fix:** Extract the `.new` / `.edit` submit branches into private helper methods
and consider splitting the build helpers (`_buildMerchantRow`, `_buildNoteSection`)
into a sub-widget file.

### IN-02: `_toModel` uses non-final local with reassignment

**File:** `lib/data/repositories/shopping_item_repository_impl.dart:179-186`
**Issue:** `List<String> tags = [];` is declared mutable and reassigned in the
try block. Minor deviation from the project's prefer-immutable/`final` guidance;
not a correctness bug.
**Fix:** Use a `final` with a single assignment, e.g.
`final tags = row.tags == null ? <String>[] : _decodeTagsSafely(row.tags!);`

### IN-03: DAO `update` reads `item.id.value` without an `present` guard

**File:** `lib/data/daos/shopping_item_dao.dart:22-26`
**Issue:** `update` does `item.id.value` to build the `where`; if a caller ever
passes a companion with `id: Value.absent()`, this throws an opaque error. All
current repository call sites always set `id`, so this is defensive-only.
**Fix:** Optionally `assert(item.id.present, 'update requires id');` or accept an
explicit `String id` parameter to make the contract unambiguous.

### IN-04: `presentation/import_guard.yaml` ships ahead of any presentation source

**File:** `lib/features/shopping_list/presentation/import_guard.yaml:1-13`
**Issue:** The presentation directory currently contains only this guard file —
no presentation source exists in Phase 36 (data+domain scope). The pre-declared
allow-list for `category_selection_screen.dart` is harmless but unverifiable
until Phase 37 adds screens; nothing enforces it today.
**Fix:** No action required; noted for traceability. Confirm the allow/deny rules
are re-validated when presentation files land.

---

_Reviewed: 2026-06-07T12:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
