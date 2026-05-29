# Phase 24: Data Layer Extension - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 9 (4 production + 5 test)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/shared/constants/sort_config.dart` | utility / constants | — (pure enum) | `lib/shared/constants/default_categories.dart` | role-match (same `abstract final class` constants pattern) |
| `lib/shared/utils/date_boundaries.dart` | utility | transform | `lib/features/analytics/domain/models/time_window.dart` | exact (same `({DateTime start, DateTime end})` record return + `DateTime(y,m+1,0,23,59,59)` idiom) |
| `lib/data/daos/transaction_dao.dart` (MODIFY) | DAO | CRUD + streaming | `lib/data/daos/analytics_dao.dart` (multi-book `customSelect`) + `lib/data/daos/group_member_dao.dart` (`.watch()`) | exact (both patterns present in codebase) |
| `lib/data/repositories/transaction_repository_impl.dart` (MODIFY) | repository | CRUD | self (existing `_toModel()` + `findByBookId` pattern) | self-modification |
| `lib/features/accounting/domain/repositories/transaction_repository.dart` (MODIFY) | domain interface | CRUD + streaming | self (existing abstract interface) | self-modification |
| `test/.../transaction_dao_multi_book_test.dart` (NEW) | test | CRUD + streaming | `test/unit/data/daos/transaction_dao_test.dart` | exact (same `AppDatabase.forTesting()` setUp pattern) |
| `test/.../date_boundaries_test.dart` (NEW) | test | transform | `test/unit/data/daos/transaction_dao_test.dart` | role-match (same flutter_test structure) |
| *(SC#4 consolidated into `transaction_dao_multi_book_test.dart` — no standalone `hash_chain_soft_delete_test.dart`; see 24-VALIDATION.md)* | — | — | — | — |
| `test/unit/data/repositories/transaction_repository_note_decrypt_test.dart` (NEW) | test | CRUD | `test/unit/data/daos/transaction_dao_test.dart` | role-match |

---

## Pattern Assignments

### `lib/shared/constants/sort_config.dart` (utility, enum)

**Analog:** `lib/shared/constants/default_categories.dart`

**Constants file structure pattern** (lines 1-6 of `default_categories.dart`):
```dart
import '../../features/accounting/domain/models/category.dart';

abstract final class DefaultCategories {
  // private constructor implied by abstract final
  static final DateTime _epoch = DateTime(2026, 1, 1);
  static List<Category> get all => [...expenseL1, ..._expenseL2];
```

**Applied pattern for `sort_config.dart`:**
```dart
// lib/shared/constants/sort_config.dart
// No imports needed — pure Dart enums

/// Sort field options for multi-book transaction queries.
/// Used by TransactionDao.findByBookIds / watchByBookIds ORDER BY.
/// Placed in lib/shared/constants/ so both data layer (DAO) and
/// domain layer (Phase 25) can import without triggering import_guard.
enum SortField {
  timestamp,
  updatedAt,
  amount,
}

/// Sort direction for multi-book transaction queries.
enum SortDirection {
  asc,
  desc,
}
```

**Key rules:**
- No `@riverpod`, no `@freezed`, no `build_runner` needed — plain Dart enums
- No private constructor trick needed (enums are already sealed)
- `shared/constants/` is import-neutral per D-01 rationale

---

### `lib/shared/utils/date_boundaries.dart` (utility, transform)

**Analog:** `lib/features/analytics/domain/models/time_window.dart`

**Canonical boundary pattern** (`time_window.dart` lines 48-76):
```dart
// Source: lib/features/analytics/domain/models/time_window.dart lines 60-63
MonthWindow(:final year, :final month) => (
  start: DateTime(year, month),                        // 1st day, 00:00:00
  end: DateTime(year, month + 1, 0, 23, 59, 59),       // last day, 23:59:59
),

// Source: time_window.dart lines 49-58 (week pattern — day-level idiom)
WeekWindow(:final mondayStart) => (
  start: DateTime(mondayStart.year, mondayStart.month, mondayStart.day),
  end: DateTime(
    mondayStart.year,
    mondayStart.month,
    mondayStart.day + 6,
    23, 59, 59,
  ),
),
```

**Secondary analog** (`state_today_transactions.dart` lines 21-22):
```dart
// Source: lib/features/home/presentation/providers/state_today_transactions.dart lines 21-22
final todayStart = DateTime(now.year, now.month, now.day);
final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
```

**Applied pattern for `date_boundaries.dart`:**
```dart
// lib/shared/utils/date_boundaries.dart
// No imports needed — pure Dart

/// Shared month/day boundary arithmetic.
///
/// Uses device LOCAL time to align with AnalyticsDao.getDailyTotals
/// DATE(timestamp,'unixepoch','localtime') grouping (D-04).
///
/// All boundaries are INCLUSIVE: start at 00:00:00, end at 23:59:59.
/// Uses DateTime(y, m+1, 0) = last day of month (Dart auto-normalises day=0).
abstract final class DateBoundaries {
  /// Inclusive [start, end] for the given calendar month.
  /// start = first day 00:00:00, end = last day 23:59:59.
  static ({DateTime start, DateTime end}) monthRange(int year, int month) => (
    start: DateTime(year, month, 1),
    end: DateTime(year, month + 1, 0, 23, 59, 59),
  );

  /// Inclusive [start, end] for the given day.
  /// start = 00:00:00, end = 23:59:59.
  static ({DateTime start, DateTime end}) dayRange(DateTime day) => (
    start: DateTime(day.year, day.month, day.day),
    end: DateTime(day.year, day.month, day.day, 23, 59, 59),
  );
}
```

**Key rules:**
- `DateTime(y, m+1, 0)` is the canonical idiom — Dart normalises `day=0` to last day of prior month (same as `time_window.dart` line 62)
- MUST use local-time `DateTime(...)` NOT `DateTime.utc(...)` — matches existing `time_window.dart` and `state_today_transactions.dart` (D-04)
- Use `abstract final class` (not `class` with private constructor) — matches `DefaultCategories` idiom for pure-static utility classes

---

### `lib/data/daos/transaction_dao.dart` — MODIFY: add `findByBookIds` + `watchByBookIds`

**Primary analog for multi-book IN query:** `lib/data/daos/analytics_dao.dart` (lines 511-546 for `getSharedJoyCategoryInsight`, lines 611-646 for `getPerCategorySoulBreakdownAcrossBooks`)

**Primary analog for watch stream:** `lib/data/daos/group_member_dao.dart` (lines 21-23)

**Template for optional filters:** existing `findByBookId` in same file (lines 67-99)

**Multi-book `customSelect` IN pattern** (`analytics_dao.dart` lines 511-536):
```dart
// Source: lib/data/daos/analytics_dao.dart lines 511-536
if (bookIds.isEmpty) return null;  // or const []

final placeholders = List.filled(bookIds.length, '?').join(', ');
final results = await _db
    .customSelect(
      'SELECT ... FROM transactions '
      'WHERE book_id IN ($placeholders) AND ...'
      'AND timestamp >= ? AND timestamp <= ?'
      '... ',
      variables: [
        ...bookIds.map(Variable.withString),
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
    )
    .get();
```

**Multi-book customSelect across-books pattern** (`analytics_dao.dart` lines 606-646):
```dart
// Source: lib/data/daos/analytics_dao.dart lines 606-646
Future<List<PerCategorySoulRowRaw>> getPerCategorySoulBreakdownAcrossBooks({
  required List<String> bookIds,
  ...
}) async {
  if (bookIds.isEmpty) return const [];

  final entrySourceClause = entrySourceFilter != null
      ? ' AND entry_source = ?'
      : '';
  final placeholders = List.filled(bookIds.length, '?').join(', ');
  final results = await _db
      .customSelect(
        'SELECT category_id, AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt '
        'FROM transactions '
        'WHERE book_id IN ($placeholders) AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ?'
        '$entrySourceClause '
        ...
        variables: [
          ...bookIds.map(Variable.withString),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
          if (entrySourceFilter != null) Variable.withString(entrySourceFilter.name),
        ],
      )
      .get();

  return results
      .map((row) => PerCategorySoulRowRaw(
        categoryId: row.read<String>('category_id'),
        ...
      ))
      .toList();
}
```

**Existing `findByBookId` — optional filter pattern** (`transaction_dao.dart` lines 67-99):
```dart
// Source: lib/data/daos/transaction_dao.dart lines 67-99
Future<List<TransactionRow>> findByBookId(
  String bookId, {
  String? ledgerType,
  String? categoryId,
  DateTime? startDate,
  DateTime? endDate,
  int limit = 100,
  int offset = 0,
}) async {
  final query = _db.select(_db.transactions)
    ..where((t) => t.bookId.equals(bookId))
    ..where((t) => t.isDeleted.equals(false))
    ..orderBy([
      (t) => OrderingTerm.desc(t.timestamp),
      (t) => OrderingTerm.desc(t.id),
    ])
    ..limit(limit, offset: offset);

  if (ledgerType != null) {
    query.where((t) => t.ledgerType.equals(ledgerType));
  }
  if (startDate != null) {
    query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
  }
  if (endDate != null) {
    query.where((t) => t.timestamp.isSmallerOrEqualValue(endDate));
  }

  return query.get();
}
```

**Watch stream pattern** (`group_member_dao.dart` lines 21-23):
```dart
// Source: lib/data/daos/group_member_dao.dart lines 21-23
// Typesafe select() — auto-detects table for invalidation
Stream<List<GroupMemberData>> watchByGroupId(String groupId) => (select(
  groupMembers,
)..where((table) => table.groupId.equals(groupId))).watch();
// NOTE: For customSelect, must add readsFrom: {_db.transactions} explicitly
```

**Soft-delete implementation — proof hash fields not touched** (`transaction_dao.dart` lines 167-175):
```dart
// Source: lib/data/daos/transaction_dao.dart lines 167-175
Future<void> softDelete(String id) async {
  await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
    TransactionsCompanion(
      isDeleted: const Value(true),     // ONLY this field
      updatedAt: Value(DateTime.now()), // and this timestamp
      // currentHash and prevHash are NOT touched
    ),
  );
}
```

**Applied pattern for `findByBookIds`:**
```dart
// Import to add at top of transaction_dao.dart
import '../../shared/constants/sort_config.dart';

Future<List<TransactionRow>> findByBookIds(
  List<String> bookIds, {
  required DateTime startDate,
  required DateTime endDate,
  String? ledgerType,
  String? categoryId,
  SortField sortField = SortField.timestamp,
  SortDirection sortDirection = SortDirection.desc,
}) async {
  if (bookIds.isEmpty) return const [];

  final placeholders = List.filled(bookIds.length, '?').join(', ');
  final ledgerClause = ledgerType != null ? ' AND ledger_type = ?' : '';
  final categoryClause = categoryId != null ? ' AND category_id = ?' : '';

  // Enum → column name: compile-time constants prevent SQL injection
  final orderCol = switch (sortField) {
    SortField.timestamp => 'timestamp',
    SortField.updatedAt => 'COALESCE(updated_at, created_at)',  // null-safe
    SortField.amount => 'amount',
  };
  final direction = sortDirection == SortDirection.asc ? 'ASC' : 'DESC';

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

  // mapFromRow converts QueryRow → typed TransactionRow
  // (verify compiles; fallback: read columns individually via row.read<T>('col'))
  return results.map((row) => _db.transactions.mapFromRow(row.data)).toList();
}
```

**Applied pattern for `watchByBookIds`** (same SQL, `.watch()` instead of `.get()`, `readsFrom` required):
```dart
Stream<List<TransactionRow>> watchByBookIds(
  List<String> bookIds, {
  required DateTime startDate,
  required DateTime endDate,
  String? ledgerType,
  String? categoryId,
  SortField sortField = SortField.timestamp,
  SortDirection sortDirection = SortDirection.desc,
}) {
  if (bookIds.isEmpty) return const Stream.empty();

  // ... same placeholder/clause/orderCol logic as findByBookIds ...

  return _db
      .customSelect(
        'SELECT * FROM transactions '
        'WHERE book_id IN ($placeholders) '
        'AND is_deleted = 0 '
        'AND timestamp >= ? AND timestamp <= ?'
        '$ledgerClause'
        '$categoryClause '
        'ORDER BY $orderCol $direction, id DESC',
        variables: [...],
        readsFrom: {_db.transactions},  // CRITICAL — enables watch() reactivity
      )
      .watch()
      .map((rows) => rows
          .map((row) => _db.transactions.mapFromRow(row.data))
          .toList());
}
```

**Key rules:**
- `bookIds.isEmpty` must short-circuit before SQL construction (avoids `IN ()` syntax error)
- `readsFrom: {_db.transactions}` is mandatory on the `watchByBookIds` variant — without it the stream never re-emits after writes (Pitfall 1)
- `COALESCE(updated_at, created_at)` for `SortField.updatedAt` — handles nullable `updatedAt` column (Pitfall 4)
- No `limit` in `findByBookIds` default — D-02 prohibits limit=100 for month-range queries
- `mapFromRow(row.data)` converts `QueryRow` → typed `TransactionRow` (if this API doesn't compile, fall back to `row.read<T>('column')` for each field — see Open Question A1 in RESEARCH.md)
- Import from `lib/data/daos/transaction_dao.dart` (class-level, not mixin-based like `GroupMemberDao`) — keep same plain-class style as existing `TransactionDao`

---

### `lib/data/repositories/transaction_repository_impl.dart` — MODIFY: `findByBookIds` + `_toModel` try/catch

**Analog:** self (`findByBookId` implementation, lines 63-83; `_toModel`, lines 136-167)

**Existing `findByBookId` → template for `findByBookIds`** (lines 63-83):
```dart
// Source: lib/data/repositories/transaction_repository_impl.dart lines 63-83
@override
Future<List<Transaction>> findByBookId(
  String bookId, {
  LedgerType? ledgerType,
  String? categoryId,
  DateTime? startDate,
  DateTime? endDate,
  int limit = 100,
  int offset = 0,
}) async {
  final rows = await _dao.findByBookId(
    bookId,
    ledgerType: ledgerType?.name,
    categoryId: categoryId,
    startDate: startDate,
    endDate: endDate,
    limit: limit,
    offset: offset,
  );

  return Future.wait(rows.map(_toModel));   // ← Future.wait + _toModel pattern
}
```

**Existing `_toModel` note decrypt — current (NO try/catch)** (lines 136-141):
```dart
// Source: lib/data/repositories/transaction_repository_impl.dart lines 136-141
// CURRENT STATE — no try/catch, shadow-book notes will throw
Future<Transaction> _toModel(TransactionRow row) async {
  String? decryptedNote;
  if (row.note != null && row.note!.isNotEmpty) {
    decryptedNote = await _encryptionService.decryptField(row.note!);  // throws on wrong device key
  }
  // ... rest of mapping
```

**Applied fix — wrap ONLY the note decrypt call** (SC#5):
```dart
// MODIFIED: wrap only _encryptionService.decryptField — not the whole _toModel body
Future<Transaction> _toModel(TransactionRow row) async {
  String? decryptedNote;
  if (row.note != null && row.note!.isNotEmpty) {
    try {
      decryptedNote = await _encryptionService.decryptField(row.note!);
    } catch (_) {
      // Shadow-book notes are encrypted with the originating device's key.
      // Decryption fails on any other device. Return note: null.
      // DO NOT log row.note or exception message — may contain ciphertext.
      decryptedNote = null;
    }
  }
  // rest of _toModel UNCHANGED (lines 142-167)
```

**Applied `findByBookIds` method** (mirrors `findByBookId` shape):
```dart
@override
Future<List<Transaction>> findByBookIds(
  List<String> bookIds, {
  LedgerType? ledgerType,
  String? categoryId,
  required DateTime startDate,
  required DateTime endDate,
  SortField sortField = SortField.timestamp,
  SortDirection sortDirection = SortDirection.desc,
}) async {
  final rows = await _dao.findByBookIds(
    bookIds,
    ledgerType: ledgerType?.name,
    categoryId: categoryId,
    startDate: startDate,
    endDate: endDate,
    sortField: sortField,
    sortDirection: sortDirection,
  );
  return Future.wait(rows.map(_toModel));   // same Future.wait pattern
}

@override
Stream<List<Transaction>> watchByBookIds(
  List<String> bookIds, {
  LedgerType? ledgerType,
  String? categoryId,
  required DateTime startDate,
  required DateTime endDate,
  SortField sortField = SortField.timestamp,
  SortDirection sortDirection = SortDirection.desc,
}) {
  return _dao.watchByBookIds(
    bookIds,
    ledgerType: ledgerType?.name,
    categoryId: categoryId,
    startDate: startDate,
    endDate: endDate,
    sortField: sortField,
    sortDirection: sortDirection,
  ).asyncMap((rows) => Future.wait(rows.map(_toModel)));
}
```

**Key rules:**
- `_toModel` try/catch wraps ONLY `decryptField` — NOT the entire method body (Pitfall 3)
- `catch (_)` silently nulls note; MUST NOT log ciphertext (security rule)
- Watch variant needs `.asyncMap` to convert `Stream<List<TransactionRow>>` → `Stream<List<Transaction>>` because `_toModel` is async
- New imports needed: `sort_config.dart` from shared/constants

---

### `lib/features/accounting/domain/repositories/transaction_repository.dart` — MODIFY: abstract interface

**Analog:** self (existing abstract interface, lines 1-26)

**Existing interface pattern** (lines 1-26):
```dart
// Source: lib/features/accounting/domain/repositories/transaction_repository.dart
abstract class TransactionRepository {
  Future<void> insert(Transaction transaction);
  Future<Transaction?> findById(String id);
  Future<List<Transaction>> findByBookId(
    String bookId, {
    LedgerType? ledgerType,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int limit,
    int offset,
  });
  Future<void> update(Transaction transaction);
  Future<void> softDelete(String id);
  ...
}
```

**Applied additions** (mirror `findByBookId` signature style):
```dart
// ADD to TransactionRepository abstract class
// New import needed: sort_config.dart
Future<List<Transaction>> findByBookIds(
  List<String> bookIds, {
  LedgerType? ledgerType,
  String? categoryId,
  required DateTime startDate,
  required DateTime endDate,
  SortField sortField,
  SortDirection sortDirection,
});

Stream<List<Transaction>> watchByBookIds(
  List<String> bookIds, {
  LedgerType? ledgerType,
  String? categoryId,
  required DateTime startDate,
  required DateTime endDate,
  SortField sortField,
  SortDirection sortDirection,
});
```

**Key rules:**
- Domain interface stays in `lib/features/accounting/domain/repositories/` per Thin Feature + layer rules
- Import `SortField`/`SortDirection` from `lib/shared/constants/sort_config.dart` — allowed (shared layer is import-neutral)
- No implementation here — stays abstract (same as existing methods)

---

## Test Pattern Assignments

### `test/unit/data/daos/transaction_dao_multi_book_test.dart` (NEW — SC#1, SC#2, SC#4)

**Analog:** `test/unit/data/daos/transaction_dao_test.dart`

**setUp/tearDown pattern** (lines 1-16):
```dart
// Source: test/unit/data/daos/transaction_dao_test.dart lines 1-16
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';

void main() {
  late AppDatabase db;
  late TransactionDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = TransactionDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionDao', () {
    // tests here
  });
}
```

**insertTransaction call pattern** (lines 22-35):
```dart
// Source: test/unit/data/daos/transaction_dao_test.dart lines 22-35
await dao.insertTransaction(
  id: 'tx_001',
  bookId: 'book_001',
  deviceId: 'dev_001',
  amount: 10000,
  type: 'expense',
  categoryId: 'cat_food',
  ledgerType: 'survival',
  timestamp: now,
  currentHash: 'hash_abc',
  createdAt: now,
  entrySource: 'manual',
);
```

**Watch stream test fixture** (SC#2 pseudocode from RESEARCH.md):
```dart
test('watchByBookIds emits after insert', () async {
  final stream = dao.watchByBookIds(
    ['book_001'],
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 31, 23, 59, 59),
    sortField: SortField.timestamp,
    sortDirection: SortDirection.desc,
  );

  // First emission: empty
  final first = await stream.first;
  expect(first, isEmpty);

  // Insert then collect second emission
  await dao.insertTransaction(id: 'tx_001', bookId: 'book_001', ...);
  final second = await stream.first;
  expect(second.length, 1);
  expect(second.first.id, 'tx_001');
});
```

**SC#4 soft-delete hash field test fixture:**
```dart
test('softDelete sets isDeleted=true, does not touch hash fields', () async {
  // Insert with explicit hashes
  await dao.insertTransaction(
    id: 'tx_002', bookId: 'book_001',
    currentHash: 'hash_tx002', prevHash: 'hash_tx001',
    // ...
  );

  await dao.softDelete('tx_002');

  final row = await dao.findById('tx_002');
  expect(row!.isDeleted, isTrue);
  expect(row.currentHash, 'hash_tx002');   // unchanged
  expect(row.prevHash, 'hash_tx001');       // unchanged
});
```

---

### `test/unit/shared/utils/date_boundaries_test.dart` (NEW — SC#3)

**Analog:** `test/unit/data/daos/transaction_dao_test.dart` (same flutter_test structure, no DB needed)

**Structure:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/utils/date_boundaries.dart';

void main() {
  group('DateBoundaries.monthRange', () {
    test('start = first day 00:00:00', () {
      final range = DateBoundaries.monthRange(2026, 5);
      expect(range.start, DateTime(2026, 5, 1, 0, 0, 0));
    });

    test('end = last day 23:59:59', () {
      final range = DateBoundaries.monthRange(2026, 5);
      expect(range.end, DateTime(2026, 5, 31, 23, 59, 59));
    });

    test('February last day correct (non-leap)', () {
      final range = DateBoundaries.monthRange(2026, 2);
      expect(range.end.day, 28);
    });

    test('excludes tx at 00:00:00 on first day of next month', () {
      final range = DateBoundaries.monthRange(2026, 5);
      final nextMonthStart = DateTime(2026, 6, 1);
      expect(nextMonthStart.isAfter(range.end), isTrue);
    });
  });

  group('DateBoundaries.dayRange', () {
    test('start = 00:00:00', () {
      final range = DateBoundaries.dayRange(DateTime(2026, 5, 15, 14, 30));
      expect(range.start, DateTime(2026, 5, 15, 0, 0, 0));
    });

    test('end = 23:59:59', () {
      final range = DateBoundaries.dayRange(DateTime(2026, 5, 15));
      expect(range.end, DateTime(2026, 5, 15, 23, 59, 59));
    });
  });
}
```

---

### SC#4 hash-chain soft-delete coverage (consolidated into `test/unit/data/daos/transaction_dao_multi_book_test.dart`)

> **Note:** SC#4 is NOT a standalone `hash_chain_soft_delete_test.dart` file — it is folded into the DAO multi-book test (Plan 24-02 Task 1) per 24-VALIDATION.md. The `verifyChain` fixture format below still applies, just within that test file.

**Analog:** `test/unit/data/daos/transaction_dao_test.dart` (DB test) + `test/infrastructure/crypto/services/hash_chain_service_test.dart` (verifyChain fixture format)

**`verifyChain` input format** (from `hash_chain_service.dart` lines 45-85):
```dart
// verifyChain expects List<Map<String, dynamic>> with keys:
// 'transactionId' (String), 'amount' (num), 'timestamp' (int),
// 'previousHash' (String), 'currentHash' (String)
final result = service.verifyChain([
  {
    'transactionId': 'tx_001',
    'amount': 1000.0,
    'timestamp': 1000,
    'previousHash': 'genesis',
    'currentHash': computedHash1,
  },
  // ...
]);
```

**SC#4 revised contract** (from RESEARCH.md Pitfall 2): The test verifies that `softDelete()` does NOT mutate `currentHash`/`prevHash`, and that `verifyChain` on ALL rows (including the soft-deleted row) returns `valid` because hash data was not touched. Do NOT test `verifyChain([non-deleted-rows-only])` — that WILL fail linkage (tx_003.prevHash != tx_001.currentHash).

---

### `test/unit/data/repositories/transaction_repository_note_decrypt_test.dart` (NEW — SC#5)

**Analog:** `test/unit/data/daos/transaction_dao_test.dart` (same `AppDatabase.forTesting()` + DAO setup)

**Mock EncryptionService pattern** (SC#5 fixture from RESEARCH.md):
```dart
class _ThrowingEncryptionService implements FieldEncryptionService {
  @override
  Future<String> decryptField(String ciphertext) =>
      Future.error(Exception('Cannot decrypt — wrong device key'));

  @override
  Future<String> encryptField(String plaintext) =>
      Future.value('encrypted_$plaintext');
}

test('_toModel returns note: null on decrypt failure, all other fields intact', () async {
  final repo = TransactionRepositoryImpl(
    dao: dao,
    encryptionService: _ThrowingEncryptionService(),
  );
  // Insert row with note
  await dao.insertTransaction(id: 'tx_001', note: 'some_ciphertext', amount: 1000, ...);
  // findById triggers _toModel
  final tx = await repo.findById('tx_001');
  expect(tx, isNotNull);
  expect(tx!.note, isNull);       // decrypt threw → null
  expect(tx.amount, 1000);         // other fields intact
});
```

---

## Shared Patterns

### Empty-list short-circuit (multi-book methods)
**Source:** `lib/data/daos/analytics_dao.dart` line 511 (`getSharedJoyCategoryInsight`), line 612 (`getPerCategorySoulBreakdownAcrossBooks`)
**Apply to:** `TransactionDao.findByBookIds`, `TransactionDao.watchByBookIds`
```dart
if (bookIds.isEmpty) return const [];       // findByBookIds
if (bookIds.isEmpty) return const Stream.empty();  // watchByBookIds
```

### `customSelect` variable ordering convention
**Source:** `lib/data/daos/analytics_dao.dart` lines 528-535
**Apply to:** `findByBookIds`, `watchByBookIds`
```dart
variables: [
  ...bookIds.map(Variable.withString),    // positional list first
  Variable.withDateTime(startDate),        // then fixed params
  Variable.withDateTime(endDate),
  if (optional != null) Variable.withString(optional),  // then conditionals
],
```

### `AppDatabase.forTesting()` + setUp/tearDown
**Source:** `test/unit/data/daos/transaction_dao_test.dart` lines 8-16
**Apply to:** All four new test files that touch the DB (dao test, hash chain test, repository test)
```dart
setUp(() {
  db = AppDatabase.forTesting();
  dao = TransactionDao(db);
});
tearDown(() async {
  await db.close();
});
```

### Closed-interval boundary comparison
**Source:** `lib/data/daos/transaction_dao.dart` lines 92-95 (existing `findByBookId`)
**Apply to:** `findByBookIds` WHERE clause (already embedded in raw SQL as `>=` and `<=`)
```dart
// In typesafe DSL (existing findByBookId):
query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
query.where((t) => t.timestamp.isSmallerOrEqualValue(endDate));
// In customSelect SQL (findByBookIds):
'AND timestamp >= ? AND timestamp <= ?'
```

---

## No Analog Found

All files in this phase have close analogs in the codebase. No files require falling back to RESEARCH.md-only patterns.

---

## Metadata

**Analog search scope:** `lib/data/daos/`, `lib/data/repositories/`, `lib/features/*/domain/`, `lib/shared/`, `test/unit/data/daos/`, `lib/features/analytics/domain/models/`, `lib/features/home/presentation/providers/`, `lib/infrastructure/crypto/services/`
**Files scanned:** 12 source files read directly
**Pattern extraction date:** 2026-05-29

**Assumption flags (carry forward to planner):**
- A1: `_db.transactions.mapFromRow(row.data)` assumed valid for Drift 2.25.0 `customSelect` → `TransactionRow` conversion. Planner should include a compile-verify step; fallback is `row.read<T>('column')` for each field.
- A2: SC#4 roadmap wording says "verifyChain on remaining non-deleted rows = valid" — RESEARCH.md proves this is incorrect (linkage fails). Test should verify "softDelete does not mutate hash fields + verifyChain on ALL rows (including soft-deleted) = valid".

---

*Phase: 24-Data Layer Extension*
*Pattern mapping completed: 2026-05-29*
