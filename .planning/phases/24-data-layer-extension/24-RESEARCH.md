# Phase 24: Data Layer Extension - Research

**Researched:** 2026-05-29
**Domain:** Drift DAO extension (multi-book IN query + `.watch()` stream) + DateBoundaries utility + hash-chain soft-delete contract + shadow-book note decryption
**Confidence:** HIGH — all findings from direct codebase inspection

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `SortField` (timestamp / updatedAt / amount) + `SortDirection` (asc / desc) enums created NOW in `lib/shared/constants/sort_config.dart` (neutral location, no import_guard trip). `findByBookIds` uses them for type-safe ORDER BY.

**D-02:** Month-range queries set NO limit — guarantee all entries in a month are shown. `findByBookId` existing `limit=100` does NOT apply to list month queries. Pagination deferred to v1.5. `findByBookIds` may retain an optional limit parameter for future reuse, but the list caller passes null/unlimited.

**D-03:** ALL filters pushed into the SQL watch: `bookIds` + `dateRange` + `ledgerType?` + `categoryId?` + ORDER BY. Any filter change triggers a new SQL query. Provider layer stays thin (no Dart-side re-filtering of DB results in this phase).

**D-04:** Month/day boundaries use device LOCAL time, consistent with `AnalyticsDao.getDailyTotals` `DATE(timestamp,'unixepoch','localtime')` grouping. Boundaries MUST INCLUDE `00:00:00` and `23:59:59` via `isBiggerOrEqualValue`/`isSmallerOrEqualValue` (closed interval, matching existing `findByBookId` pattern).

### Claude's Discretion

- `findByBookIds` multi-value `book_id` SQL implementation (Drift `isIn()` DSL vs `customSelect` with `IN (?)` expansion) — choose by readability and type-safety, must be a single SQL (SC#1), no N+1.
- Soft-delete / hash chain test fixture construction (SC#4: soft-delete mid-chain, `verifyChain()` still valid on remaining non-deleted rows).
- Shadow-book decrypt failure fixture (SC#5: explicit test simulating decrypt failure).
- Watch stream deduplication / distinct handling (avoid unnecessary rebuilds from unrelated writes).

### Deferred Ideas (OUT OF SCOPE)

- Pagination / infinite scroll — v1.5 explicitly.
- Family calendar daily totals (combined) — v1.4 own-book only; cross-book analytics variant deferred to v1.5.
- Undo-delete SnackBar / loading skeleton — post-v1.4.
- Any UI, provider, domain model, use case — Phase 25+.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIST-02 | The list updates reactively after add / edit / delete / family-sync — no manual refresh required (new `TransactionDao.watchByBookId(s)` stream) | Drift `.watch()` DSL verified; `GroupMemberDao.watchByGroupId` is the in-project reference; `customSelect` + `readsFrom` required for multi-book watch |
</phase_requirements>

---

## Summary

Phase 24 delivers the pure-Dart data foundation for the v1.4 list feature: three new artifacts (`SortField`/`SortDirection` enums, `findByBookIds` DAO method + watch variant, `DateBoundaries` utility) plus two contract verifications (hash chain safety after soft-delete, shadow-book note decryption failure → `note: null`). No Drift schema migration is needed — the `transactions` table (schema v17) already has all required columns including `updatedAt`, `ledgerType`, `categoryId`, and `isDeleted`.

The key implementation insight is that the existing `AnalyticsDao` already uses `customSelect` with `IN (?)` expansion for multi-book queries (see `getSharedJoyCategoryInsight`, `getPerCategorySoulBreakdownAcrossBooks`, `getLedgerSnapshotAcrossBooks`). The `findByBookIds` DAO method should follow this exact pattern — a `customSelect` with manually expanded placeholders — rather than the Drift typesafe DSL, which does not support `IN` lists natively. For the reactive watch variant, `customSelect(...).watch()` is available but requires explicit `readsFrom` to tell Drift which tables to monitor.

The hash-chain soft-delete contract is already well-designed: `verifyChain()` accepts only the non-deleted rows as input (the caller filters out `isDeleted=true` rows before calling it), so a mid-chain soft-delete does NOT invalidate the chain — each surviving row's `prevHash`/`currentHash` pair is still internally consistent. The chain simply has a logical gap, which is acceptable and intentional per ADR architecture.

The `_toModel()` decrypt path in `TransactionRepositoryImpl` currently calls `_encryptionService.decryptField(row.note!)` without try/catch. Shadow-book notes are encrypted with the originating device's key and will throw on any local decrypt attempt. A try/catch wrapping this single call — returning `note: null` on any exception, with all other fields intact — is the correct fix.

**Primary recommendation:** Follow the `AnalyticsDao` multi-book `customSelect` pattern for `findByBookIds`; add try/catch to `_toModel()` note decrypt; use `DateBoundaries` following the `TimeWindow.range` canonical idiom; all tests use `AppDatabase.forTesting()` with `TransactionDao` directly (no Riverpod needed for DAO/service-layer tests).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Multi-book SQL query (`findByBookIds`) | Data (DAO) | — | Single SQL, no N+1; filter logic belongs in DB, not Dart |
| Reactive watch stream | Data (DAO) | — | Drift `.watch()` is DAO-level; provider subscribes but does not poll |
| Month/day boundary arithmetic | Shared utils (`lib/shared/utils/`) | — | Reused by DAO callers; neutral to all layers |
| `SortField`/`SortDirection` enums | Shared constants (`lib/shared/constants/`) | — | Imported by both data layer (DAO ORDER BY) and domain layer (Phase 25); neutral placement avoids import_guard |
| Note decryption fail-safe | Data (Repository impl) | — | `_toModel()` owns the decrypt-to-domain conversion; the fix belongs there |
| Hash chain integrity contract | Infrastructure (HashChainService) + Application (DeleteTransactionUseCase) | — | `DeleteTransactionUseCase` is the ONLY safe delete entry point; chain verified on non-deleted rows only |

---

## Standard Stack

Phase 24 introduces NO new packages. It extends existing code only.

### Core (existing, all verified against live `lib/`)

| Library | Version (from pubspec.lock) | Purpose in this phase | Provenance |
|---------|----|-----------------------|------------|
| `drift` | 2.25.0 | DAO query extension + `.watch()` stream | [VERIFIED: pubspec.lock] |
| `drift/extensions/native.dart` | same | In-memory `AppDatabase.forTesting()` for unit tests | [VERIFIED: pubspec.lock] |
| `crypto` | 3.0.6 | SHA-256 in `HashChainService` (no change) | [VERIFIED: pubspec.lock] |
| `freezed_annotation` | 2.4.4 | `ChainVerificationResult` (no change) | [VERIFIED: pubspec.lock] |
| `flutter_test` | SDK | DAO and service unit tests | [VERIFIED: pubspec.yaml] |

### No new packages required

All capabilities (multi-book IN query, reactive watch, boundary math, hash chain verify) are achievable with existing dependencies. No `pub add` step needed in this phase.

---

## Package Legitimacy Audit

> No external packages added in this phase. All work extends existing code.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Phase 24 deliverables (data layer only — no UI, no Riverpod)

  CALLER (Phase 25+ providers/use-cases)
          |
          | calls
          v
  lib/shared/constants/sort_config.dart    ← NEW: SortField + SortDirection enums
          |
          | used by
          v
  lib/data/daos/transaction_dao.dart       ← MODIFIED: + findByBookIds() + watchByBookIds()
    [customSelect with IN(?) expansion]
    [.watch() via readsFrom: {db.transactions}]
          |
          | DAO rows
          v
  lib/data/repositories/transaction_repository_impl.dart  ← MODIFIED: + findByBookIds() impl
    [Future.wait(rows.map(_toModel))]
    [_toModel: try/catch around decryptField for note — SC#5]
          |
          | domain Transaction objects
          v
  lib/features/accounting/domain/repositories/transaction_repository.dart  ← MODIFIED: + findByBookIds abstract

  SIDE CONTRACTS verified in this phase (no code change, tests added):

  lib/application/accounting/delete_transaction_use_case.dart
    [calls softDelete() only — NEVER direct DAO delete]
    [test: insert 3-tx chain → soft-delete tx_002 → verifyChain([tx_001, tx_003]) = valid]

  lib/shared/utils/date_boundaries.dart   ← NEW utility
    [monthRange(year, month) → (start: DateTime(y,m,1), end: DateTime(y,m+1,0,23,59,59))]
    [dayRange(day: DateTime) → (start: DateTime(y,m,d), end: DateTime(y,m,d,23,59,59))]
```

### Recommended Project Structure (Phase 24 additions)

```
lib/
├── shared/
│   ├── constants/
│   │   └── sort_config.dart          ← NEW: SortField enum + SortDirection enum
│   └── utils/
│       └── date_boundaries.dart      ← NEW: monthRange + dayRange
├── data/
│   ├── daos/
│   │   └── transaction_dao.dart      ← MODIFIED: + findByBookIds + watchByBookIds
│   └── repositories/
│       └── transaction_repository_impl.dart  ← MODIFIED: + findByBookIds impl + _toModel try/catch
└── features/
    └── accounting/
        └── domain/
            └── repositories/
                └── transaction_repository.dart  ← MODIFIED: + findByBookIds abstract

test/
├── unit/
│   ├── data/
│   │   └── daos/
│   │       └── transaction_dao_multi_book_test.dart   ← NEW (SC#1, SC#2)
│   ├── shared/
│   │   └── utils/
│   │       └── date_boundaries_test.dart              ← NEW (SC#3)
│   └── infrastructure/
│       └── crypto/
│           └── hash_chain_soft_delete_test.dart       ← NEW (SC#4)
└── data/
    └── repositories/
        └── transaction_repository_note_decrypt_test.dart  ← NEW (SC#5)
```

### Pattern 1: Multi-Book IN Query via `customSelect`

**What:** Use `customSelect` with manually-expanded `?` placeholders (same as `AnalyticsDao.getSharedJoyCategoryInsight`). This is the established codebase pattern for multi-book queries.

**When to use:** Any time `bookId IN (...)` with a dynamic list is required.

**Why NOT Drift typesafe DSL `isIn()`:** Drift's typesafe `select()` builder does support `isIn()` for text columns, but the codebase precedent for multi-book queries (set by AnalyticsDao in multiple methods) uses `customSelect` with `IN (?)` expansion. This is more readable for complex ORDER BY + optional filter combinations, and is already proven in the project.

**Example (from `AnalyticsDao.getSharedJoyCategoryInsight` — VERIFIED in codebase):**

```dart
// Source: lib/data/daos/analytics_dao.dart (lines 516-529)
final placeholders = List.filled(bookIds.length, '?').join(', ');
final results = await _db
    .customSelect(
      'SELECT ... FROM transactions '
      'WHERE book_id IN ($placeholders) AND ...',
      variables: [
        ...bookIds.map(Variable.withString),
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
    )
    .get();
```

**Applied to `findByBookIds`:**

```dart
// Source pattern: analytics_dao.dart multi-book methods
Future<List<TransactionRow>> findByBookIds(
  List<String> bookIds, {
  required DateTime startDate,
  required DateTime endDate,
  String? ledgerType,
  String? categoryId,
  SortField sortField = SortField.timestamp,
  bool sortAscending = false,
  // No limit by default — D-02: month-range queries show all entries
}) async {
  if (bookIds.isEmpty) return const [];

  final placeholders = List.filled(bookIds.length, '?').join(', ');

  // Build optional WHERE clauses
  final ledgerClause = ledgerType != null ? ' AND ledger_type = ?' : '';
  final categoryClause = categoryId != null ? ' AND category_id = ?' : '';

  // Translate SortField enum to column name
  final orderCol = switch (sortField) {
    SortField.timestamp => 'timestamp',
    SortField.updatedAt => 'updated_at',
    SortField.amount => 'amount',
  };
  final direction = sortAscending ? 'ASC' : 'DESC';

  final results = await _db
      .customSelect(
        'SELECT * FROM transactions '
        'WHERE book_id IN ($placeholders) '
        'AND is_deleted = 0 '
        'AND timestamp >= ? AND timestamp <= ?'
        '$ledgerClause'
        '$categoryClause '
        'ORDER BY $orderCol $direction, id DESC',
        variables: [
          ...bookIds.map(Variable.withString),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
          if (ledgerType != null) Variable.withString(ledgerType),
          if (categoryId != null) Variable.withString(categoryId),
        ],
      )
      .get();

  return results.map((row) => _db.transactions.mapFromRow(row.data)).toList();
}
```

**IMPORTANT — `mapFromRow`:** `customSelect` returns `QueryRow` objects, not typed `TransactionRow` data classes. To get `TransactionRow`, use `_db.transactions.mapFromRow(row.data)`. This is the same approach used in existing codebase DAO custom queries that need typed results (vs. the analytics DAOs which read named columns directly). Verify this compiles — alternative is to manually construct `TransactionRow` from `row.read<T>('column')` calls.

### Pattern 2: Drift `.watch()` Stream on `customSelect`

**What:** `customSelect(...).watch()` returns a `Stream<List<QueryRow>>` that emits whenever any write touches the `transactions` table. The stream is hot and Drift re-executes the SQL automatically.

**Critical requirement:** `customSelect` queries require `readsFrom` to be declared if `.watch()` is used, otherwise Drift cannot determine which table writes should trigger re-execution.

**Example (from `GroupMemberDao.watchByGroupId` — in-project reference for `.watch()`):**

```dart
// Source: lib/data/daos/group_member_dao.dart (line 21-23)
Stream<List<GroupMemberData>> watchByGroupId(String groupId) => (select(
  groupMembers,
)..where((table) => table.groupId.equals(groupId))).watch();
```

The typesafe `select().watch()` auto-detects the table. For `customSelect`, you must add `readsFrom`:

```dart
// Pattern for watch on customSelect — required for reactive LIST-02 behavior
Stream<List<TransactionRow>> watchByBookIds(
  List<String> bookIds, {
  required DateTime startDate,
  required DateTime endDate,
  String? ledgerType,
  String? categoryId,
  SortField sortField = SortField.timestamp,
  bool sortAscending = false,
}) {
  if (bookIds.isEmpty) return const Stream.empty();

  final placeholders = List.filled(bookIds.length, '?').join(', ');
  final ledgerClause = ledgerType != null ? ' AND ledger_type = ?' : '';
  final categoryClause = categoryId != null ? ' AND category_id = ?' : '';
  final orderCol = switch (sortField) {
    SortField.timestamp => 'timestamp',
    SortField.updatedAt => 'updated_at',
    SortField.amount => 'amount',
  };
  final direction = sortAscending ? 'ASC' : 'DESC';

  return _db
      .customSelect(
        'SELECT * FROM transactions '
        'WHERE book_id IN ($placeholders) '
        'AND is_deleted = 0 '
        'AND timestamp >= ? AND timestamp <= ?'
        '$ledgerClause'
        '$categoryClause '
        'ORDER BY $orderCol $direction, id DESC',
        variables: [
          ...bookIds.map(Variable.withString),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
          if (ledgerType != null) Variable.withString(ledgerType),
          if (categoryId != null) Variable.withString(categoryId),
        ],
        readsFrom: {_db.transactions},   // ← CRITICAL: enables watch() reactivity
      )
      .watch()
      .map(
        (rows) => rows
            .map((row) => _db.transactions.mapFromRow(row.data))
            .toList(),
      );
}
```

**Reactivity guarantee:** Any write to `_db.transactions` (insert, update, soft-delete, sync-applied upsert) causes Drift to re-execute the query and push the new result to the stream. The subscriber (Riverpod `StreamProvider` in Phase 26) will receive the new list in the next event loop tick — within one rebuild cycle, satisfying SC#2.

**Note on `Stream.empty()`:** When `bookIds` is empty, return `const Stream.empty()` rather than `Stream.value([])` to avoid a spurious emission. The Phase 26 provider guards against empty bookIds upstream.

### Pattern 3: `DateBoundaries` Utility

**What:** A pure static utility class codifying the existing codebase idiom for inclusive date-range boundaries.

**Canonical idiom (VERIFIED in codebase):**

```dart
// Source: lib/features/analytics/domain/models/time_window.dart (line 62-63)
MonthWindow(:final year, :final month) => (
  start: DateTime(year, month),                        // 1st day, 00:00:00
  end: DateTime(year, month + 1, 0, 23, 59, 59),       // last day, 23:59:59
),

// Source: lib/features/home/presentation/providers/state_today_transactions.dart (line 22)
final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
```

**`DateBoundaries` implementation:**

```dart
// lib/shared/utils/date_boundaries.dart
// Source pattern: time_window.dart + state_today_transactions.dart

/// Shared month/day boundary arithmetic.
///
/// Uses device LOCAL time (aligns with AnalyticsDao.getDailyTotals
/// `DATE(timestamp,'unixepoch','localtime')` — D-04).
///
/// All boundaries are INCLUSIVE: start at 00:00:00, end at 23:59:59.
/// Uses `DateTime(y, m+1, 0)` = last day of month (Dart auto-normalizes).
class DateBoundaries {
  const DateBoundaries._();

  /// Returns the inclusive start and end of the given calendar month.
  /// `start` = first day at 00:00:00, `end` = last day at 23:59:59.
  static ({DateTime start, DateTime end}) monthRange(int year, int month) => (
    start: DateTime(year, month, 1),
    end: DateTime(year, month + 1, 0, 23, 59, 59),
  );

  /// Returns the inclusive start and end of the given day.
  /// `start` = 00:00:00, `end` = 23:59:59.
  static ({DateTime start, DateTime end}) dayRange(DateTime day) => (
    start: DateTime(day.year, day.month, day.day),
    end: DateTime(day.year, day.month, day.day, 23, 59, 59),
  );
}
```

**Dart `DateTime` normalisation guarantee:** `DateTime(2026, 3, 0)` = February 28, 2026 (Dart normalises month overflow and day=0 to the last day of the prior month). This is safe and is the documented codebase idiom.

### Pattern 4: `_toModel()` Note Decrypt Try/Catch (SC#5)

**Current code (VERIFIED in `transaction_repository_impl.dart` line 136-140):**

```dart
Future<Transaction> _toModel(TransactionRow row) async {
  String? decryptedNote;
  if (row.note != null && row.note!.isNotEmpty) {
    decryptedNote = await _encryptionService.decryptField(row.note!);  // NO try/catch
  }
  // ...
}
```

**Fix — wrap note decrypt in try/catch:**

```dart
Future<Transaction> _toModel(TransactionRow row) async {
  String? decryptedNote;
  if (row.note != null && row.note!.isNotEmpty) {
    try {
      decryptedNote = await _encryptionService.decryptField(row.note!);
    } catch (_) {
      // Shadow-book notes are encrypted with the originating device's key.
      // Decryption will fail on any other device. Return note: null.
      decryptedNote = null;
    }
  }
  // rest of _toModel unchanged — all other fields intact
}
```

**Scope of change:** Only the note decrypt call. All other fields (`amount`, `timestamp`, `categoryId`, `ledgerType`, etc.) are NOT encrypted and remain intact regardless of note decrypt failure.

### Pattern 5: Hash Chain Soft-Delete Contract (SC#4)

**Key insight (from `hash_chain_service.dart` line 45):**

`verifyChain()` takes `List<Map<String, dynamic>> transactions` — it operates on WHATEVER list the caller provides. The caller (backup/integrity-check path) is responsible for filtering out soft-deleted rows BEFORE calling `verifyChain()`. This is already how `findAllByBook` works: it filters `isDeleted.equals(false)` (line 179-183 of `transaction_dao.dart`), so backup/verify paths only see non-deleted rows.

**Why mid-chain soft-delete does NOT break the chain:**

Given chain: `tx_001 → tx_002 → tx_003` (linked by `prevHash`/`currentHash`)

After `softDelete('tx_002')`:
- `tx_002` row has `isDeleted=true`, `updatedAt=now`
- `currentHash` and `prevHash` on `tx_002` are UNCHANGED (soft-delete only sets `isDeleted` + `updatedAt`)
- `tx_003.prevHash` still equals `tx_002.currentHash` — linkage is intact

When `verifyChain` is called with only non-deleted rows `[tx_001, tx_003]`:
- `tx_001` validates (hash matches its own data)
- `tx_003` validates (hash matches its own data)
- BUT: chain linkage check at i=0 → `nextTx['previousHash'] != tx['currentHash']` compares `tx_003.prevHash` with `tx_001.currentHash` — these ARE DIFFERENT because `tx_003.prevHash = tx_002.currentHash`, not `tx_001.currentHash`
- **This WOULD fail the linkage check**

**Corrected understanding:** The `verifyChain` design verifies individual row integrity AND sequence linkage between adjacent elements in the supplied list. After soft-deleting `tx_002`, calling `verifyChain([tx_001, tx_003])` will flag `tx_003` as tampered because `tx_003.prevHash != tx_001.currentHash`.

**What the SC#4 test actually verifies:** The contract is NOT that `verifyChain` on the filtered list returns valid after a mid-chain delete. The contract is that `DeleteTransactionUseCase` performs SOFT-delete only (sets `isDeleted=true`, does NOT relink hashes or physically remove rows). SC#4 should be stated as: "after soft-deleting tx_002, the `isDeleted` flag is `true` on that row, and `verifyChain` on ALL rows (including the soft-deleted one) returns `valid` because the full chain is intact — only when the soft-deleted row is excluded does the linkage check fail."

**Test fixture for SC#4:**

```dart
// test/unit/infrastructure/crypto/hash_chain_soft_delete_test.dart
// Verifies the soft-delete-only contract:
// 1. Insert 3-tx chain with valid prevHash/currentHash linkage
// 2. Soft-delete tx_002 via DeleteTransactionUseCase
// 3. Assert tx_002 row has isDeleted=true (soft delete occurred)
// 4. Call verifyChain on ALL 3 rows (including soft-deleted) → valid
//    (because no hash data was modified by softDelete())
// 5. Separately verify: deleteAllByBook is NOT called from DeleteTransactionUseCase

// The key assertion: softDelete() does not touch currentHash or prevHash columns.
// The softDelete implementation: only writes isDeleted=true + updatedAt.
// (verified in transaction_dao.dart line 168-175)
```

**Correction for ROADMAP SC#4 wording:** The roadmap states "verifyChain on the remaining non-deleted rows returns valid." This is architecturally incorrect — if tx_002 is soft-deleted and excluded, `tx_003.prevHash` will not match `tx_001.currentHash`. The actual invariant to verify is: `softDelete()` does not mutate the hash fields, so the FULL chain (all rows including soft-deleted) remains cryptographically valid. The correct test verifies that `isDeleted=true` was set and that neither `currentHash` nor `prevHash` was modified on the soft-deleted row.

**Planner note:** Discuss this SC#4 restatement with the architect before writing the plan task. The test target should be: "softDelete preserves hash integrity of all rows (the chain is intact when all rows including soft-deleted are verified)."

### Anti-Patterns to Avoid

- **N+1 book queries:** Do NOT call `findByBookId` in a loop per book. The entire purpose of `findByBookIds` is a single SQL.
- **Typesafe DSL `isIn()` for the watch variant:** Confirmed `isIn()` would work for the one-shot query, but the `customSelect` pattern is more readable for dynamic ORDER BY + optional filters and matches existing multi-book precedents in `AnalyticsDao`.
- **Missing `readsFrom`:** A `customSelect(...).watch()` without `readsFrom: {_db.transactions}` will never emit after initial load — Drift won't know to re-execute the query on table writes.
- **Direct row access from `QueryRow` without `mapFromRow`:** `customSelect` returns `QueryRow`, not `TransactionRow`. Always use `_db.transactions.mapFromRow(row.data)` to get a typed result.
- **`limit=100` in `findByBookIds`:** D-02 prohibits a default limit for month-range queries. The parameter may exist for future reuse but the list caller must not pass a limit.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-book IN query | N+1 `findByBookId` loop | `customSelect` with `IN (?)` expansion | Single SQL, scales to family; loop is O(N) round-trips |
| Reactive table watch | Polling / `Timer.periodic` | Drift `.watch()` with `readsFrom` | Drift's write-invalidation is table-level, zero-cost |
| Month-end boundary | Bespoke calendar math | `DateTime(y, m+1, 0, 23, 59, 59)` idiom | Dart normalises day=0 correctly; 6 existing call sites already use this |
| Note decryption fail-safe | Custom encryption error types | `try/catch (_)` on single decrypt call | `EncryptionRepository.decryptField` may throw any exception type; catch-all is correct |
| Hash chain link verification | Custom hash comparator | `HashChainService.verifyChain()` | Already implemented, tested, and authoritative |

---

## Runtime State Inventory

> Phase 24 is greenfield extension (new methods on existing DAOs; new shared utility). No rename, refactor, or migration. Skip this section.

---

## Common Pitfalls

### Pitfall 1: Missing `readsFrom` on `customSelect(...).watch()`
**What goes wrong:** The watch stream emits the initial query result but never emits again after inserts/soft-deletes/sync writes. LIST-02 silently fails.
**Why it happens:** Drift's query invalidation for `customSelect` is opt-in; it cannot infer which tables are read from a raw SQL string.
**How to avoid:** Always add `readsFrom: {_db.transactions}` to the `customSelect` call used for `.watch()`.
**Warning signs:** Test that inserts a new row after subscribing to the stream sees no second emission.

### Pitfall 2: `verifyChain` Contract Misunderstood (SC#4)
**What goes wrong:** Test passes the wrong input list to `verifyChain` — filtering out soft-deleted rows before calling it. On a mid-chain delete, this causes a linkage failure (`tx_003.prevHash != tx_001.currentHash`) and the test asserts incorrectly.
**Why it happens:** SC#4 wording in the roadmap implies "remaining non-deleted rows" but that input set fails the chain linkage check.
**How to avoid:** The SC#4 test should verify: (a) `softDelete()` sets `isDeleted=true` only, does NOT change `currentHash`/`prevHash`; (b) `verifyChain` on ALL rows (including `isDeleted=true` ones) returns valid because the full chain is cryptographically intact.
**Warning signs:** Test fails with `tamperedTransactionIds` containing the row AFTER the soft-deleted one.

### Pitfall 3: `_toModel()` try/catch Too Broad (SC#5)
**What goes wrong:** Wrapping the entire `_toModel()` body in try/catch — if an unrelated field mapping throws (e.g., unknown `ledgerType` enum value), the exception is silently swallowed and the transaction is returned with all fields null or wrong.
**Why it happens:** Developer wraps the wrong scope.
**How to avoid:** Wrap ONLY the `_encryptionService.decryptField(row.note!)` call. Let all other exceptions from `_toModel()` propagate normally.
**Warning signs:** A malformed `ledgerType` string causes a silent null transaction to appear in the list instead of an error.

### Pitfall 4: `SortField.updatedAt` Ordering When `updatedAt` Is Null
**What goes wrong:** `ORDER BY updated_at DESC` — rows where `updatedAt IS NULL` (never edited) sort before or after edited rows inconsistently across SQLite versions.
**Why it happens:** `updatedAt` is nullable in the schema (`DateTimeColumn get updatedAt => dateTime().nullable()()`).
**How to avoid:** When `sortField == SortField.updatedAt`, use `COALESCE(updated_at, created_at) DESC` as the ORDER BY expression. Alternatively, use `ORDER BY updated_at IS NULL ASC, updated_at DESC` to put null-updated rows last.
**Warning signs:** Newly created transactions (no edits) appear at wrong sort position when sorting by edit time.

### Pitfall 5: `DateBoundaries` Using UTC Instead of Local Time
**What goes wrong:** `DateTime.utc(y, m, 1)` produces midnight UTC, not midnight local. The DAO comparison `timestamp >= startDate` works in SQLite's stored representation (which may be UTC epoch), but `getDailyTotals` groups by `DATE(timestamp, 'unixepoch', 'localtime')` — a UTC-midnight boundary misaligns with localtime-grouped day totals.
**Why it happens:** Developer reaches for `DateTime.utc()` for "correctness."
**How to avoid:** `DateBoundaries` must use `DateTime(y, m, d)` (local time, no `.utc()`). Matches existing codebase idiom in `time_window.dart` and `state_today_transactions.dart`.
**Warning signs:** A transaction at 23:30 local time on Dec 31 appears in the Jan 1 day total in the calendar.

---

## Code Examples

### Verified: `AnalyticsDao` multi-book `customSelect` with IN (reference pattern)

```dart
// Source: lib/data/daos/analytics_dao.dart lines 514-545
// getSharedJoyCategoryInsight — THE reference for multi-book customSelect
final placeholders = List.filled(bookIds.length, '?').join(', ');
final results = await _db
    .customSelect(
      'SELECT ... FROM transactions '
      'WHERE book_id IN ($placeholders) AND ...'
      '...',
      variables: [
        ...bookIds.map(Variable.withString),
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
    )
    .get();
```

### Verified: `findByBookId` typesafe DSL filter pattern (template for optional filters)

```dart
// Source: lib/data/daos/transaction_dao.dart lines 76-98
// findByBookId — shows optional WHERE clauses pattern and isBiggerOrEqualValue usage
final query = _db.select(_db.transactions)
  ..where((t) => t.bookId.equals(bookId))
  ..where((t) => t.isDeleted.equals(false))
  ..orderBy([...])
  ..limit(limit, offset: offset);

if (ledgerType != null) {
  query.where((t) => t.ledgerType.equals(ledgerType));
}
if (startDate != null) {
  query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
}
```

### Verified: Month-end boundary idiom

```dart
// Source: lib/features/analytics/domain/models/time_window.dart line 62-63
// MonthWindow boundary — THE canonical idiom in the codebase
end: DateTime(year, month + 1, 0, 23, 59, 59),  // day=0 = last day of `month`
```

### Verified: `AppDatabase.forTesting()` + DAO pattern for unit tests

```dart
// Source: test/unit/data/daos/transaction_dao_test.dart lines 8-16
late AppDatabase db;
late TransactionDao dao;

setUp(() {
  db = AppDatabase.forTesting();
  dao = TransactionDao(db);
});

tearDown(() async {
  await db.close();
});
```

### Verified: `GroupMemberDao.watchByGroupId` — in-project `.watch()` reference

```dart
// Source: lib/data/daos/group_member_dao.dart lines 21-23
Stream<List<GroupMemberData>> watchByGroupId(String groupId) => (select(
  groupMembers,
)..where((table) => table.groupId.equals(groupId))).watch();
// Note: typesafe select() auto-detects table for invalidation.
// For customSelect, must add readsFrom: {_db.transactions}.
```

### Verified: `softDelete()` implementation — proof it does NOT touch hash fields

```dart
// Source: lib/data/daos/transaction_dao.dart lines 167-175
Future<void> softDelete(String id) async {
  await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
    TransactionsCompanion(
      isDeleted: const Value(true),   // ← ONLY this field
      updatedAt: Value(DateTime.now()), // ← and this timestamp
      // currentHash, prevHash NOT touched
    ),
  );
}
```

### Verified: `HashChainService.verifyChain` input format

```dart
// Source: lib/infrastructure/crypto/services/hash_chain_service.dart line 45
// Input: List<Map<String, dynamic>> with keys:
// 'transactionId', 'amount' (num), 'timestamp' (int), 'previousHash', 'currentHash'
ChainVerificationResult verifyChain(List<Map<String, dynamic>> transactions)

// From test (line 163-185), a valid chain entry looks like:
{
  'transactionId': 'tx_001',
  'amount': 100.0,
  'timestamp': 1000,          // int (not DateTime)
  'previousHash': 'genesis',
  'currentHash': hash1,
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Riverpod 2 `StateNotifierProvider` for list state | Riverpod 3 `@riverpod` code-gen `Notifier` | v1.1 migration | Provider names strip `Notifier` suffix; `AsyncValue.value` is now nullable |
| Manual `ref.invalidate` after every mutation | Drift `.watch()` stream auto-pushes on any write | Phase 24 (this phase) | LIST-02 satisfied; no `ref.invalidate` needed in list provider |
| Single-book queries only | Multi-book `IN (?)` queries for family support | Phase 24 (this phase) | Shadow books included in single SQL pass |

**Deprecated/outdated:**
- `limit=100` in `findByBookId` context: This limit was appropriate for the home-screen quick transaction list. It is NOT appropriate for the month-range list query. D-02 explicitly removes this limit from `findByBookIds`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `_db.transactions.mapFromRow(row.data)` is the correct API to get a typed `TransactionRow` from a `QueryRow` returned by `customSelect` | Pattern 1 | If API differs, `findByBookIds` will fail to compile; fallback is to read columns individually via `row.read<T>('column')` |
| A2 | `const Stream.empty()` is an appropriate return for `watchByBookIds` when `bookIds` is empty | Pattern 2 | If Phase 26 expects a non-empty stream for zero bookIds, a `StreamController.broadcast()` emitting `[]` may be needed instead |

**Most claims are VERIFIED against live source files. Only these two minor API surface details are [ASSUMED].**

---

## Open Questions

1. **`mapFromRow` vs manual column reads for `customSelect` returning `TransactionRow`**
   - What we know: `analytics_dao.dart` reads named columns via `row.read<T>('column')` directly. `TransactionDao` uses the typesafe builder which returns typed rows automatically.
   - What's unclear: Whether `_db.transactions.mapFromRow(row.data)` actually compiles for a `customSelect` result on the `transactions` table in this Drift version (2.25.0).
   - Recommendation: The planner should include a compile-verify step in the first plan task after writing `findByBookIds`. Fallback: manually read all columns from `QueryRow`.

2. **SC#4 verifyChain contract restatement**
   - What we know: `verifyChain([tx_001, tx_003])` (excluding soft-deleted `tx_002`) WILL fail the linkage check because `tx_003.prevHash != tx_001.currentHash`.
   - What's unclear: Whether the roadmap's SC#4 wording is intentional (testing a known invariant differently) or is an error in the success criterion.
   - Recommendation: The planner should note this discrepancy and write the SC#4 test to verify "soft-delete does not mutate hash fields" rather than "verifyChain on remaining rows = valid."

---

## Environment Availability

> All dependencies for Phase 24 are in-project existing code. No new tools or services needed.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Dart SDK | All | ✓ | Flutter SDK | — |
| Drift | DAO watch query | ✓ | 2.25.0 | — |
| `AppDatabase.forTesting()` | DAO unit tests | ✓ | In-project | — |
| `flutter test` | Test runner | ✓ | Flutter SDK | — |
| `build_runner` | Code gen (only if Freezed/Riverpod annotations used) | ✓ | In pubspec.yaml | — |

**Note:** Phase 24 adds NO new Riverpod `@riverpod` annotations, NO new Freezed `@freezed` annotations, and NO new Drift table definitions. `build_runner` is NOT required for this phase unless `sort_config.dart` enums need code gen (they do not — plain Dart enums). The first `build_runner` run for v1.4 will happen in Phase 25 when Freezed domain models are added.

---

## Validation Architecture

> `workflow.nyquist_validation: true` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) |
| Config file | `pubspec.yaml` `dev_dependencies: flutter_test:` |
| Quick run command | `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIST-02 | Watch stream emits after insert | Integration (in-memory DB) | `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart` | ❌ Wave 0 |
| LIST-02 | Watch stream emits after soft-delete | Integration (in-memory DB) | same | ❌ Wave 0 |
| LIST-02 | Watch stream emits after sync-applied write (simulated update) | Integration (in-memory DB) | same | ❌ Wave 0 |
| SC#1 | `findByBookIds` executes single query, multi-book, excludes deleted, respects ledgerType/categoryId, ordered by SortField | Unit (in-memory DB) | `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart` | ❌ Wave 0 |
| SC#3 | `DateBoundaries.monthRange` includes tx at 00:00:00 on day 1 | Unit (pure Dart) | `flutter test test/unit/shared/utils/date_boundaries_test.dart` | ❌ Wave 0 |
| SC#3 | `DateBoundaries.monthRange` includes tx at 23:59:59 on last day | Unit (pure Dart) | same | ❌ Wave 0 |
| SC#3 | `DateBoundaries.dayRange` includes tx at 00:00:00 and 23:59:59 | Unit (pure Dart) | same | ❌ Wave 0 |
| SC#3 | `DateBoundaries.monthRange` excludes tx at 00:00:00 on day 1 of NEXT month | Unit (pure Dart) | same | ❌ Wave 0 |
| SC#4 | `softDelete()` sets `isDeleted=true`, does NOT change `currentHash`/`prevHash` | Unit (in-memory DB) | `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart` | ❌ Wave 0 |
| SC#4 | `verifyChain` on all 3 rows (including soft-deleted) = valid | Unit (pure Dart, no DB) | `flutter test test/unit/infrastructure/crypto/hash_chain_soft_delete_test.dart` | ❌ Wave 0 |
| SC#5 | `_toModel()` with simulated decrypt failure → `note: null`, all other fields intact | Unit (mock EncryptionService) | `flutter test test/data/repositories/transaction_repository_note_decrypt_test.dart` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/data/daos/transaction_dao_multi_book_test.dart test/unit/shared/utils/date_boundaries_test.dart`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps (all new files, no existing test infrastructure to reuse)

- [ ] `test/unit/data/daos/transaction_dao_multi_book_test.dart` — covers SC#1, SC#2, SC#4 (soft-delete flag verification)
- [ ] `test/unit/shared/utils/date_boundaries_test.dart` — covers SC#3 (6 boundary cases)
- [ ] `test/unit/infrastructure/crypto/hash_chain_soft_delete_test.dart` — covers SC#4 (chain integrity)
- [ ] `test/data/repositories/transaction_repository_note_decrypt_test.dart` — covers SC#5

*(No new framework install needed — `flutter_test` and `AppDatabase.forTesting()` already available.)*

### SC#2 Test Fixture Design (watch stream)

SC#2 requires testing that the watch stream emits within one rebuild cycle after three types of writes. The pattern:

```dart
// Pseudocode for watch stream test
test('watchByBookIds emits after insert', () async {
  final db = AppDatabase.forTesting();
  final dao = TransactionDao(db);
  final stream = dao.watchByBookIds(
    ['book_001'],
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 31, 23, 59, 59),
    sortField: SortField.timestamp,
  );

  // Collect first emission (empty list)
  final first = await stream.first;
  expect(first, isEmpty);

  // Insert a new transaction
  await dao.insertTransaction(id: 'tx_001', bookId: 'book_001', ...);

  // Collect second emission (should contain tx_001)
  final second = await stream.first;
  expect(second.length, 1);
  expect(second.first.id, 'tx_001');
});
```

Note: `stream.first` waits for ONE emission and cancels. For soft-delete and sync-applied-write tests, same pattern: subscribe → write → assert next emission.

### SC#5 Test Fixture Design (note decrypt failure)

```dart
// Pseudocode — mock EncryptionService that throws on decrypt
class _ThrowingEncryptionService implements FieldEncryptionService {
  @override
  Future<String> decryptField(String ciphertext) =>
      Future.error(Exception('Cannot decrypt — wrong device key'));
  // ... other methods return normally
}

test('_toModel returns note: null on decrypt failure, other fields intact', () async {
  final repo = TransactionRepositoryImpl(
    dao: dao,
    encryptionService: _ThrowingEncryptionService(),
  );
  // Insert a row with a note
  await dao.insertTransaction(id: 'tx_001', note: 'some_encrypted_blob', ...);
  // findById triggers _toModel
  final tx = await repo.findById('tx_001');
  expect(tx, isNotNull);
  expect(tx!.note, isNull);         // note is null because decrypt threw
  expect(tx.amount, 1000);          // other fields intact
  expect(tx.categoryId, 'cat_001'); // other fields intact
});
```

---

## Security Domain

> `security_enforcement` not explicitly set to `false` in config.json — included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 24 is data-layer only, no auth surface |
| V3 Session Management | No | No session changes |
| V4 Access Control | No | No new access control surface |
| V5 Input Validation | Yes | `bookIds.isEmpty` check before SQL construction; `SortField` enum prevents SQL injection in ORDER BY (enum values are compile-time constants, not user strings) |
| V6 Cryptography | Yes | `_toModel()` try/catch preserves non-note fields; no custom crypto; `HashChainService.verifyChain` is read-only |

### Known Threat Patterns for Dart/Drift/SQLite

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via ORDER BY | Tampering | `SortField` enum translates to compile-time constant column name strings — user input never reaches ORDER BY clause |
| SQL injection via IN clause | Tampering | `Variable.withString(bookId)` parameterizes all values — SQLite treats them as literals |
| Sensitive note data in logs | Information Disclosure | `_toModel()` catch block must NOT log `row.note` or the exception message (which may contain ciphertext) — silent catch only |
| Shadow-book note ciphertext exposure | Information Disclosure | `try/catch` returning `null` prevents ciphertext from reaching UI as a string |

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)

- `lib/data/daos/transaction_dao.dart` — `findByBookId` template; `softDelete` implementation; `isBiggerOrEqualValue`/`isSmallerOrEqualValue` usage
- `lib/data/daos/analytics_dao.dart` — `customSelect` + `IN (?)` multi-book pattern (lines 514-545, 606-643, 699-744); `getDailyTotals` localtime alignment (lines 226-264)
- `lib/data/daos/group_member_dao.dart` — `.watch()` on typesafe select (lines 21-23); `readsFrom` requirement note
- `lib/data/repositories/transaction_repository_impl.dart` — `_toModel()` decrypt path (lines 136-167); absence of try/catch confirmed
- `lib/data/tables/transactions_table.dart` — schema v17 confirmed; all columns Phase 24 needs (`updatedAt`, `ledgerType`, `categoryId`, `isDeleted`) present; existing composite indices (`idx_tx_book_timestamp`, `idx_tx_book_deleted`)
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — `verifyChain` signature and chain linkage logic (lines 45-85)
- `lib/infrastructure/crypto/services/field_encryption_service.dart` — `decryptField` API (may throw any exception)
- `lib/infrastructure/crypto/models/chain_verification_result.dart` — `ChainVerificationResult` factory constructors
- `lib/features/analytics/domain/models/time_window.dart` — canonical `DateTime(y, m+1, 0, 23, 59, 59)` month-end idiom (line 63)
- `lib/features/home/presentation/providers/state_today_transactions.dart` — canonical `DateTime(y, m, d, 23, 59, 59)` day-end idiom (line 22)
- `lib/features/home/presentation/screens/main_shell_screen.dart` — `IndexedStack` at line 97; List tab placeholder at line 111; sync invalidation pattern at lines 34-91
- `lib/application/accounting/delete_transaction_use_case.dart` — soft-delete-only path confirmed (line 30); no direct DAO delete
- `lib/shared/utils/result.dart` — `Result<T>` type for use case return
- `test/helpers/test_provider_scope.dart` — `createTestProviderScope`, `waitForFirstValue<T>` helper
- `test/unit/data/daos/transaction_dao_test.dart` — established test pattern (`AppDatabase.forTesting()`, setUp/tearDown)
- `test/infrastructure/crypto/services/hash_chain_service_test.dart` — `verifyChain` fixture format confirmed

### Secondary (MEDIUM confidence — upstream research documents)

- `.planning/research/ARCHITECTURE.md` — `findByBookIds` signature draft; shadow-book note handling; provider dependency graph
- `.planning/research/PITFALLS.md` — hash chain soft-delete contract; date-range boundary errors; ProviderException wrapping
- `.planning/research/SUMMARY.md` — Cross-file divergence resolutions; `AnalyticsDao.getDailyTotals` reuse confirmed

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all existing dependencies verified
- Architecture: HIGH — all patterns from direct source inspection with line references
- Pitfalls: HIGH — SC#4 verifyChain contract restatement is a new finding from reading the actual `verifyChain` implementation; pitfalls 1-5 verified against source

**Research date:** 2026-05-29
**Valid until:** 2026-06-28 (stable Drift/Riverpod; 30-day window)

---

*Phase: 24-Data Layer Extension*
*Research completed: 2026-05-29*
