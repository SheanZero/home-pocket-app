# Bill Sync (Shadow Book) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable family members to sync bills bidirectionally using the Shadow Book storage model — each remote member's data lives in an isolated "shadow book".

**Architecture:** Extend the existing Books table with shadow-book fields (`isShadow`, `groupId`, `ownerDeviceId`, `ownerDeviceName`). When a pull sync receives operations from `fromDeviceId`, route them to that device's shadow book. On group exit, delete shadow books and their transactions. Fire-and-forget push on local transaction creation.

**Tech Stack:** Flutter, Drift (SQLCipher), Riverpod, Freezed, E2EE (NaCl), Relay Server API

---

## Prerequisites

Before starting, read these files to understand the codebase:
- `CLAUDE.md` — project conventions, architecture layers, Drift index syntax
- `lib/data/tables/books_table.dart` — current Books table (10 columns)
- `lib/data/tables/transactions_table.dart` — Transactions table (20 columns)
- `lib/application/family_sync/pull_sync_use_case.dart` — where `applyOperations` callback is invoked
- `lib/features/family_sync/presentation/providers/sync_providers.dart` — where the TODO stubs live
- `lib/infrastructure/sync/sync_trigger_service.dart` — `onTransactionCreated()` etc.
- `lib/application/accounting/create_transaction_use_case.dart` — current create flow (no sync)

**Commands you'll need:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs  # After Drift/Freezed changes
flutter analyze                                                   # Must be 0 issues
flutter test                                                      # Must pass
flutter test --coverage                                           # ≥80%
```

---

## Task 1: Extend Books Table with Shadow Book Fields

**Files:**
- Modify: `lib/data/tables/books_table.dart`
- Modify: `lib/data/app_database.dart` (schema version 10→11, migration)
- Test: `test/unit/data/tables/books_table_migration_test.dart` (new)

### Step 1: Write the failing migration test

```dart
// test/unit/data/tables/books_table_migration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:home_pocket/data/app_database.dart';

void main() {
  group('Books table shadow book columns', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting();
    });

    tearDown(() => db.close());

    test('books table has isShadow column with default false', () async {
      await db.into(db.books).insert(BooksCompanion.insert(
            id: 'test-book',
            name: 'Test',
            currency: 'JPY',
            deviceId: 'device-1',
            createdAt: DateTime.now(),
          ));

      final row = await (db.select(db.books)
            ..where((t) => t.id.equals('test-book')))
          .getSingle();

      expect(row.isShadow, false);
    });

    test('books table supports shadow book fields', () async {
      await db.into(db.books).insert(BooksCompanion.insert(
            id: 'shadow-book',
            name: 'Partner Records',
            currency: 'JPY',
            deviceId: 'partner-device',
            createdAt: DateTime.now(),
            isShadow: const Value(true),
            groupId: const Value('group-123'),
            ownerDeviceId: const Value('partner-device'),
            ownerDeviceName: const Value('太太の iPhone'),
          ));

      final row = await (db.select(db.books)
            ..where((t) => t.id.equals('shadow-book')))
          .getSingle();

      expect(row.isShadow, true);
      expect(row.groupId, 'group-123');
      expect(row.ownerDeviceId, 'partner-device');
      expect(row.ownerDeviceName, '太太の iPhone');
    });

    test('can query shadow books by groupId', () async {
      await db.into(db.books).insert(BooksCompanion.insert(
            id: 'my-book',
            name: 'My Book',
            currency: 'JPY',
            deviceId: 'my-device',
            createdAt: DateTime.now(),
          ));
      await db.into(db.books).insert(BooksCompanion.insert(
            id: 'shadow-1',
            name: 'Shadow',
            currency: 'JPY',
            deviceId: 'partner',
            createdAt: DateTime.now(),
            isShadow: const Value(true),
            groupId: const Value('group-abc'),
            ownerDeviceId: const Value('partner'),
          ));

      final shadows = await (db.select(db.books)
            ..where((t) => t.isShadow.equals(true))
            ..where((t) => t.groupId.equals('group-abc')))
          .get();

      expect(shadows, hasLength(1));
      expect(shadows.first.id, 'shadow-1');
    });
  });
}
```

### Step 2: Run test to verify it fails

Run: `flutter test test/unit/data/tables/books_table_migration_test.dart`
Expected: FAIL — `isShadow`, `groupId`, `ownerDeviceId`, `ownerDeviceName` don't exist on Books table

### Step 3: Add shadow book columns to Books table

```dart
// lib/data/tables/books_table.dart — add these columns AFTER soulBalance
/// Whether this book is a shadow book created for synced remote data.
BoolColumn get isShadow => boolean().withDefault(const Constant(false))();

/// Group ID this shadow book belongs to (null for local books).
TextColumn get groupId => text().nullable()();

/// Device ID of the remote member who owns the source data.
TextColumn get ownerDeviceId => text().nullable()();

/// Display name of the remote device (e.g. "太太の iPhone").
TextColumn get ownerDeviceName => text().nullable()();
```

Add indices (append to existing `customIndices` list):

```dart
TableIndex(name: 'idx_books_group_id', columns: {#groupId}),
TableIndex(name: 'idx_books_is_shadow', columns: {#isShadow}),
```

### Step 4: Add database migration

In `lib/data/app_database.dart`:
- Change `schemaVersion => 11`
- Add migration block inside `onUpgrade`:

```dart
if (from < 11) {
  await migrator.addColumn(books, books.isShadow);
  await migrator.addColumn(books, books.groupId);
  await migrator.addColumn(books, books.ownerDeviceId);
  await migrator.addColumn(books, books.ownerDeviceName);
}
```

### Step 5: Run code generation

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Regenerates `app_database.g.dart` and books-related generated files

### Step 6: Run test to verify it passes

Run: `flutter test test/unit/data/tables/books_table_migration_test.dart`
Expected: PASS

### Step 7: Run full test suite and analyzer

Run: `flutter analyze && flutter test`
Expected: 0 issues, all tests pass

### Step 8: Commit

```bash
git add lib/data/tables/books_table.dart lib/data/app_database.dart test/unit/data/tables/books_table_migration_test.dart
git add lib/data/app_database.g.dart  # generated
git commit -m "feat(data): add shadow book columns to Books table

Add isShadow, groupId, ownerDeviceId, ownerDeviceName columns.
Schema version 10 → 11 with migration."
```

---

## Task 2: Extend Book Domain Model and Repository

**Files:**
- Modify: `lib/features/accounting/domain/models/book.dart`
- Modify: `lib/features/accounting/domain/repositories/book_repository.dart`
- Modify: `lib/data/daos/book_dao.dart`
- Modify: `lib/data/repositories/book_repository_impl.dart`
- Test: `test/unit/data/daos/book_dao_shadow_test.dart` (new)

### Step 1: Write the failing test

```dart
// test/unit/data/daos/book_dao_shadow_test.dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';

void main() {
  late AppDatabase db;
  late BookDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = BookDao(db);
  });

  tearDown(() => db.close());

  group('Shadow Book DAO', () {
    test('insertShadowBook creates a shadow book', () async {
      await dao.insertShadowBook(
        id: 'shadow-1',
        name: 'Partner Records',
        currency: 'JPY',
        deviceId: 'partner-device',
        createdAt: DateTime.now(),
        groupId: 'group-abc',
        ownerDeviceId: 'partner-device',
        ownerDeviceName: '太太の iPhone',
      );

      final row = await dao.findById('shadow-1');
      expect(row, isNotNull);
      expect(row!.isShadow, true);
      expect(row.groupId, 'group-abc');
      expect(row.ownerDeviceId, 'partner-device');
      expect(row.ownerDeviceName, '太太の iPhone');
    });

    test('findShadowBookByDeviceId returns correct shadow book', () async {
      await dao.insertShadowBook(
        id: 'shadow-1',
        name: 'Partner',
        currency: 'JPY',
        deviceId: 'partner',
        createdAt: DateTime.now(),
        groupId: 'group-1',
        ownerDeviceId: 'partner-device-id',
        ownerDeviceName: 'Partner Phone',
      );

      final result = await dao.findShadowBookByDeviceId('partner-device-id');
      expect(result, isNotNull);
      expect(result!.id, 'shadow-1');
    });

    test('findShadowBookByDeviceId returns null for unknown device', () async {
      final result = await dao.findShadowBookByDeviceId('unknown');
      expect(result, isNull);
    });

    test('findShadowBooksByGroupId returns all shadow books for group', () async {
      // Regular book
      await dao.insertBook(
        id: 'my-book',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'my-device',
        createdAt: DateTime.now(),
      );
      // Shadow book
      await dao.insertShadowBook(
        id: 'shadow-1',
        name: 'Partner 1',
        currency: 'JPY',
        deviceId: 'p1',
        createdAt: DateTime.now(),
        groupId: 'group-1',
        ownerDeviceId: 'p1-device',
        ownerDeviceName: 'Phone 1',
      );

      final shadows = await dao.findShadowBooksByGroupId('group-1');
      expect(shadows, hasLength(1));
      expect(shadows.first.id, 'shadow-1');
    });

    test('deleteShadowBooksByGroupId removes shadow books', () async {
      await dao.insertShadowBook(
        id: 'shadow-1',
        name: 'P',
        currency: 'JPY',
        deviceId: 'p',
        createdAt: DateTime.now(),
        groupId: 'group-1',
        ownerDeviceId: 'p-device',
        ownerDeviceName: 'P',
      );

      await dao.deleteShadowBooksByGroupId('group-1');

      final result = await dao.findById('shadow-1');
      expect(result, isNull);
    });
  });
}
```

### Step 2: Run test to verify it fails

Run: `flutter test test/unit/data/daos/book_dao_shadow_test.dart`
Expected: FAIL — methods `insertShadowBook`, `findShadowBookByDeviceId`, etc. don't exist

### Step 3: Add shadow book methods to BookDao

Add to `lib/data/daos/book_dao.dart`:

```dart
/// Insert a shadow book for a remote member's data.
Future<void> insertShadowBook({
  required String id,
  required String name,
  required String currency,
  required String deviceId,
  required DateTime createdAt,
  required String groupId,
  required String ownerDeviceId,
  required String? ownerDeviceName,
}) async {
  await _db.into(_db.books).insert(
        BooksCompanion.insert(
          id: id,
          name: name,
          currency: currency,
          deviceId: deviceId,
          createdAt: createdAt,
          isShadow: const Value(true),
          groupId: Value(groupId),
          ownerDeviceId: Value(ownerDeviceId),
          ownerDeviceName: Value(ownerDeviceName),
        ),
      );
}

/// Find a shadow book by the remote device ID that owns the data.
Future<BookRow?> findShadowBookByDeviceId(String ownerDeviceId) async {
  return (_db.select(_db.books)
        ..where((t) => t.isShadow.equals(true))
        ..where((t) => t.ownerDeviceId.equals(ownerDeviceId)))
      .getSingleOrNull();
}

/// Find all shadow books for a group.
Future<List<BookRow>> findShadowBooksByGroupId(String groupId) async {
  return (_db.select(_db.books)
        ..where((t) => t.isShadow.equals(true))
        ..where((t) => t.groupId.equals(groupId)))
      .get();
}

/// Delete all shadow books for a group (hard delete).
Future<void> deleteShadowBooksByGroupId(String groupId) async {
  await (_db.delete(_db.books)
        ..where((t) => t.isShadow.equals(true))
        ..where((t) => t.groupId.equals(groupId)))
      .go();
}
```

### Step 4: Update Book domain model

Add to `lib/features/accounting/domain/models/book.dart`:

```dart
// Add inside the Book factory constructor, after soulBalance:
@Default(false) bool isShadow,
String? groupId,
String? ownerDeviceId,
String? ownerDeviceName,
```

### Step 5: Update BookRepository interface

Add to `lib/features/accounting/domain/repositories/book_repository.dart`:

```dart
Future<void> insertShadowBook({
  required String id,
  required String name,
  required String currency,
  required String deviceId,
  required DateTime createdAt,
  required String groupId,
  required String ownerDeviceId,
  required String? ownerDeviceName,
});
Future<Book?> findShadowBookByDeviceId(String ownerDeviceId);
Future<List<Book>> findShadowBooksByGroupId(String groupId);
Future<void> deleteShadowBooksByGroupId(String groupId);
```

### Step 6: Update BookRepositoryImpl

Add methods to `lib/data/repositories/book_repository_impl.dart` that delegate to the DAO.
Update `_toModel` to include the 4 new fields:

```dart
Book _toModel(BookRow row) {
  return Book(
    id: row.id,
    name: row.name,
    currency: row.currency,
    deviceId: row.deviceId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    isArchived: row.isArchived,
    transactionCount: row.transactionCount,
    survivalBalance: row.survivalBalance,
    soulBalance: row.soulBalance,
    isShadow: row.isShadow,
    groupId: row.groupId,
    ownerDeviceId: row.ownerDeviceId,
    ownerDeviceName: row.ownerDeviceName,
  );
}
```

### Step 7: Run code generation + tests

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter test test/unit/data/daos/book_dao_shadow_test.dart`
Expected: PASS

### Step 8: Run full test suite

Run: `flutter analyze && flutter test`
Expected: 0 issues, all tests pass

### Step 9: Commit

```bash
git add lib/features/accounting/domain/models/book.dart lib/features/accounting/domain/repositories/book_repository.dart
git add lib/data/daos/book_dao.dart lib/data/repositories/book_repository_impl.dart
git add test/unit/data/daos/book_dao_shadow_test.dart
git commit -m "feat(data): add shadow book DAO and repository methods

insertShadowBook, findShadowBookByDeviceId, findShadowBooksByGroupId,
deleteShadowBooksByGroupId for managing remote member data isolation."
```

---

## Task 3: Create ShadowBookService

**Files:**
- Create: `lib/application/family_sync/shadow_book_service.dart`
- Test: `test/unit/application/family_sync/shadow_book_service_test.dart` (new)

### Step 1: Write the failing test

```dart
// test/unit/application/family_sync/shadow_book_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ShadowBookService service;
  late BookDao bookDao;
  late TransactionDao txDao;

  setUp(() {
    db = AppDatabase.forTesting();
    bookDao = BookDao(db);
    txDao = TransactionDao(db);
    final bookRepo = BookRepositoryImpl(dao: bookDao);
    service = ShadowBookService(bookRepository: bookRepo);
  });

  tearDown(() => db.close());

  group('ShadowBookService', () {
    test('createShadowBook creates and returns shadow book id', () async {
      final shadowBookId = await service.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner-device',
        memberDeviceName: '太太の iPhone',
        currency: 'JPY',
      );

      expect(shadowBookId, isNotEmpty);

      final row = await bookDao.findById(shadowBookId);
      expect(row, isNotNull);
      expect(row!.isShadow, true);
      expect(row.groupId, 'group-1');
      expect(row.ownerDeviceId, 'partner-device');
    });

    test('findShadowBook returns existing shadow book', () async {
      await service.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner-device',
        memberDeviceName: 'Partner',
        currency: 'JPY',
      );

      final book = await service.findShadowBook('partner-device');
      expect(book, isNotNull);
      expect(book!.ownerDeviceId, 'partner-device');
    });

    test('findShadowBook returns null for unknown device', () async {
      final book = await service.findShadowBook('unknown');
      expect(book, isNull);
    });

    test('cleanSyncData deletes shadow books and their transactions', () async {
      // Create shadow book
      final shadowId = await service.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner',
        memberDeviceName: 'P',
        currency: 'JPY',
      );

      // Add a transaction to the shadow book
      await txDao.insertTransaction(
        id: 'tx-1',
        bookId: shadowId,
        deviceId: 'partner',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat-1',
        ledgerType: 'survival',
        timestamp: DateTime.now(),
        currentHash: 'hash-1',
        createdAt: DateTime.now(),
      );

      // Verify transaction exists
      final txBefore = await txDao.findById('tx-1');
      expect(txBefore, isNotNull);

      // Clean sync data
      await service.cleanSyncData('group-1');

      // Verify shadow book and transaction are deleted
      final bookAfter = await bookDao.findById(shadowId);
      expect(bookAfter, isNull);

      final txAfter = await txDao.findById('tx-1');
      expect(txAfter, isNull);
    });
  });
}
```

### Step 2: Run test to verify it fails

Run: `flutter test test/unit/application/family_sync/shadow_book_service_test.dart`
Expected: FAIL — `ShadowBookService` doesn't exist

### Step 3: Implement ShadowBookService

```dart
// lib/application/family_sync/shadow_book_service.dart
import 'package:ulid/ulid.dart';

import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';

/// Manages shadow books for remote family members' synced data.
///
/// Each remote member gets a dedicated "shadow book" that isolates their
/// transactions from local data. This enables clean bulk deletion on
/// group exit and per-member analytics.
class ShadowBookService {
  ShadowBookService({required BookRepository bookRepository})
      : _bookRepo = bookRepository;

  final BookRepository _bookRepo;

  /// Create a shadow book for a remote member.
  ///
  /// Returns the generated shadow book ID (ULID).
  Future<String> createShadowBook({
    required String groupId,
    required String memberDeviceId,
    required String memberDeviceName,
    required String currency,
  }) async {
    final id = Ulid().toString();
    await _bookRepo.insertShadowBook(
      id: id,
      name: '$memberDeviceName の記録',
      currency: currency,
      deviceId: memberDeviceId,
      createdAt: DateTime.now(),
      groupId: groupId,
      ownerDeviceId: memberDeviceId,
      ownerDeviceName: memberDeviceName,
    );
    return id;
  }

  /// Find the shadow book for a given remote device.
  Future<Book?> findShadowBook(String memberDeviceId) {
    return _bookRepo.findShadowBookByDeviceId(memberDeviceId);
  }

  /// Delete all shadow books and their transactions for a group.
  Future<void> cleanSyncData(String groupId) async {
    final shadowBooks = await _bookRepo.findShadowBooksByGroupId(groupId);
    // Transactions are deleted by cascade or explicit deleteAllByBook
    // But since Drift doesn't have FK cascades with SQLCipher,
    // we rely on the caller to delete transactions first.
    // For safety, the shadow book deletion handles its own cleanup.
    await _bookRepo.deleteShadowBooksByGroupId(groupId);
  }
}
```

**Wait** — the test expects transactions to be deleted too. Update `cleanSyncData` to also delete transactions. But `ShadowBookService` doesn't have `TransactionRepository`. Let's keep it minimal: the `BookRepository.deleteShadowBooksByGroupId` only deletes books. Transaction cleanup needs the caller or a separate step.

Actually, let's update the service to accept `TransactionRepository` too:

```dart
class ShadowBookService {
  ShadowBookService({
    required BookRepository bookRepository,
    required TransactionRepository transactionRepository,
  }) : _bookRepo = bookRepository,
       _transactionRepo = transactionRepository;

  final BookRepository _bookRepo;
  final TransactionRepository _transactionRepo;

  // ... createShadowBook and findShadowBook unchanged ...

  Future<void> cleanSyncData(String groupId) async {
    final shadowBooks = await _bookRepo.findShadowBooksByGroupId(groupId);
    for (final book in shadowBooks) {
      await _transactionRepo.deleteAllByBook(book.id);
    }
    await _bookRepo.deleteShadowBooksByGroupId(groupId);
  }
}
```

Update the test `setUp` to pass `transactionRepository`:

```dart
final txRepo = TransactionRepositoryImpl(dao: txDao, encryptionService: noOpEncryption);
service = ShadowBookService(bookRepository: bookRepo, transactionRepository: txRepo);
```

You'll need a no-op `FieldEncryptionService` for tests — check existing test helpers or create a mock that returns plaintext.

### Step 4: Run test to verify it passes

Run: `flutter test test/unit/application/family_sync/shadow_book_service_test.dart`
Expected: PASS

### Step 5: Commit

```bash
git add lib/application/family_sync/shadow_book_service.dart
git add test/unit/application/family_sync/shadow_book_service_test.dart
git commit -m "feat(sync): add ShadowBookService for remote data isolation

Create, find, and clean shadow books and their transactions."
```

---

## Task 4: Add Transaction Sync Serialization

**Files:**
- Create: `lib/features/accounting/domain/models/transaction_sync_mapper.dart`
- Test: `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart` (new)

### Step 1: Write the failing test

```dart
// test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_sync_mapper.dart';

void main() {
  group('TransactionSyncMapper', () {
    final sampleTransaction = Transaction(
      id: 'tx-123',
      bookId: 'book-1',
      deviceId: 'device-a',
      amount: 1500,
      type: TransactionType.expense,
      categoryId: 'cat-food',
      ledgerType: LedgerType.survival,
      timestamp: DateTime.utc(2026, 3, 15, 10, 30),
      currentHash: 'hash-abc',
      createdAt: DateTime.utc(2026, 3, 15, 10, 30),
      note: 'Lunch',
      merchant: 'Cafe',
      soulSatisfaction: 7,
    );

    test('toSyncMap excludes bookId, hash chain, and deviceId', () {
      final map = TransactionSyncMapper.toSyncMap(sampleTransaction);

      expect(map['id'], 'tx-123');
      expect(map['amount'], 1500);
      expect(map['type'], 'expense');
      expect(map['categoryId'], 'cat-food');
      expect(map['ledgerType'], 'survival');
      expect(map['note'], 'Lunch');
      expect(map['merchant'], 'Cafe');
      expect(map['soulSatisfaction'], 7);
      expect(map['timestamp'], isNotNull);
      expect(map['createdAt'], isNotNull);

      // Must NOT include:
      expect(map.containsKey('bookId'), false);
      expect(map.containsKey('deviceId'), false);
      expect(map.containsKey('currentHash'), false);
      expect(map.containsKey('prevHash'), false);
      expect(map.containsKey('isSynced'), false);
      expect(map.containsKey('isDeleted'), false);
    });

    test('fromSyncMap creates Transaction with correct bookId', () {
      final map = TransactionSyncMapper.toSyncMap(sampleTransaction);

      final restored = TransactionSyncMapper.fromSyncMap(
        map,
        bookId: 'shadow-book-1',
      );

      expect(restored.id, 'tx-123');
      expect(restored.bookId, 'shadow-book-1');
      expect(restored.amount, 1500);
      expect(restored.type, TransactionType.expense);
      expect(restored.ledgerType, LedgerType.survival);
      expect(restored.note, 'Lunch');
      expect(restored.isSynced, true);
      expect(restored.currentHash, ''); // shadow books skip hash chain
    });

    test('fromSyncMap handles missing optional fields', () {
      final map = {
        'id': 'tx-minimal',
        'amount': 500,
        'type': 'income',
        'categoryId': 'cat-salary',
        'ledgerType': 'soul',
        'timestamp': '2026-03-15T10:30:00.000Z',
        'createdAt': '2026-03-15T10:30:00.000Z',
      };

      final tx = TransactionSyncMapper.fromSyncMap(
        map,
        bookId: 'shadow-1',
      );

      expect(tx.note, isNull);
      expect(tx.merchant, isNull);
      expect(tx.soulSatisfaction, 5);
      expect(tx.isPrivate, false);
    });

    test('toSyncOperation wraps in sync protocol format', () {
      final op = TransactionSyncMapper.toCreateOperation(sampleTransaction);

      expect(op['op'], 'create');
      expect(op['entityType'], 'bill');
      expect(op['entityId'], 'tx-123');
      expect(op['data'], isA<Map<String, dynamic>>());
      expect(op['timestamp'], isNotNull);
    });
  });
}
```

### Step 2: Run test to verify it fails

Run: `flutter test test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart`
Expected: FAIL — `TransactionSyncMapper` doesn't exist

### Step 3: Implement TransactionSyncMapper

```dart
// lib/features/accounting/domain/models/transaction_sync_mapper.dart
import 'transaction.dart';

/// Maps [Transaction] to/from sync protocol format.
///
/// Excludes bookId (receiver uses their shadow book), hash chain fields
/// (per-book), and deviceId (from sync message envelope).
class TransactionSyncMapper {
  TransactionSyncMapper._();

  /// Serialize a transaction for sync push.
  static Map<String, dynamic> toSyncMap(Transaction tx) {
    return {
      'id': tx.id,
      'amount': tx.amount,
      'type': tx.type.name,
      'categoryId': tx.categoryId,
      'ledgerType': tx.ledgerType.name,
      'timestamp': tx.timestamp.toUtc().toIso8601String(),
      'createdAt': tx.createdAt.toUtc().toIso8601String(),
      if (tx.note != null) 'note': tx.note,
      if (tx.merchant != null) 'merchant': tx.merchant,
      if (tx.photoHash != null) 'photoHash': tx.photoHash,
      'soulSatisfaction': tx.soulSatisfaction,
      'isPrivate': tx.isPrivate,
    };
  }

  /// Deserialize a transaction from sync pull.
  ///
  /// [bookId] should be the shadow book ID for the remote member.
  static Transaction fromSyncMap(
    Map<String, dynamic> data, {
    required String bookId,
  }) {
    return Transaction(
      id: data['id'] as String,
      bookId: bookId,
      deviceId: '',
      amount: data['amount'] as int,
      type: TransactionType.values.byName(data['type'] as String),
      categoryId: data['categoryId'] as String,
      ledgerType: LedgerType.values.byName(data['ledgerType'] as String),
      timestamp: DateTime.parse(data['timestamp'] as String),
      createdAt: DateTime.parse(
        data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      note: data['note'] as String?,
      merchant: data['merchant'] as String?,
      photoHash: data['photoHash'] as String?,
      soulSatisfaction: data['soulSatisfaction'] as int? ?? 5,
      isPrivate: data['isPrivate'] as bool? ?? false,
      isSynced: true,
      currentHash: '',
    );
  }

  /// Wrap a transaction as a sync protocol create operation.
  static Map<String, dynamic> toCreateOperation(Transaction tx) {
    return {
      'op': 'create',
      'entityType': 'bill',
      'entityId': tx.id,
      'data': toSyncMap(tx),
      'timestamp': tx.createdAt.toUtc().toIso8601String(),
    };
  }

  /// Wrap a transaction as a sync protocol update operation.
  static Map<String, dynamic> toUpdateOperation(Transaction tx) {
    return {
      'op': 'update',
      'entityType': 'bill',
      'entityId': tx.id,
      'data': toSyncMap(tx),
      'timestamp': (tx.updatedAt ?? tx.createdAt).toUtc().toIso8601String(),
    };
  }

  /// Wrap a transaction ID as a sync protocol delete operation.
  static Map<String, dynamic> toDeleteOperation(String transactionId) {
    return {
      'op': 'delete',
      'entityType': 'bill',
      'entityId': transactionId,
    };
  }
}
```

### Step 4: Run test to verify it passes

Run: `flutter test test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart`
Expected: PASS

### Step 5: Commit

```bash
git add lib/features/accounting/domain/models/transaction_sync_mapper.dart
git add test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart
git commit -m "feat(sync): add TransactionSyncMapper for sync serialization

Converts Transaction to/from sync protocol format, excluding bookId
and hash chain fields."
```

---

## Task 5: Implement ApplySyncOperationsUseCase (Pull Side)

**Files:**
- Create: `lib/application/family_sync/apply_sync_operations_use_case.dart`
- Test: `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` (new)

### Step 1: Write the failing test

```dart
// test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
// Import or create a test FieldEncryptionService (no-op / passthrough)

void main() {
  late AppDatabase db;
  late ApplySyncOperationsUseCase useCase;
  late TransactionDao txDao;
  late ShadowBookService shadowBookService;

  setUp(() async {
    db = AppDatabase.forTesting();
    txDao = TransactionDao(db);
    final bookDao = BookDao(db);
    final bookRepo = BookRepositoryImpl(dao: bookDao);
    // Use no-op encryption for tests
    final txRepo = TransactionRepositoryImpl(
      dao: txDao,
      encryptionService: /* no-op mock */,
    );
    shadowBookService = ShadowBookService(
      bookRepository: bookRepo,
      transactionRepository: txRepo,
    );
    useCase = ApplySyncOperationsUseCase(
      transactionRepository: txRepo,
      shadowBookService: shadowBookService,
    );

    // Pre-create a shadow book for partner
    await shadowBookService.createShadowBook(
      groupId: 'group-1',
      memberDeviceId: 'partner-device',
      memberDeviceName: 'Partner',
      currency: 'JPY',
    );
  });

  tearDown(() => db.close());

  test('create operation inserts transaction into shadow book', () async {
    await useCase.execute([
      {
        'op': 'create',
        'entityType': 'bill',
        'entityId': 'tx-remote-1',
        'fromDeviceId': 'partner-device',
        'data': {
          'id': 'tx-remote-1',
          'amount': 2000,
          'type': 'expense',
          'categoryId': 'cat-1',
          'ledgerType': 'survival',
          'timestamp': '2026-03-15T10:00:00.000Z',
          'createdAt': '2026-03-15T10:00:00.000Z',
        },
      },
    ]);

    final tx = await txDao.findById('tx-remote-1');
    expect(tx, isNotNull);
    expect(tx!.amount, 2000);
    // Verify it went into shadow book, not local book
    final shadowBook = await shadowBookService.findShadowBook('partner-device');
    expect(tx.bookId, shadowBook!.id);
  });

  test('create operation is idempotent', () async {
    final op = {
      'op': 'create',
      'entityType': 'bill',
      'entityId': 'tx-dup',
      'fromDeviceId': 'partner-device',
      'data': {
        'id': 'tx-dup',
        'amount': 1000,
        'type': 'expense',
        'categoryId': 'cat-1',
        'ledgerType': 'survival',
        'timestamp': '2026-03-15T10:00:00.000Z',
        'createdAt': '2026-03-15T10:00:00.000Z',
      },
    };

    await useCase.execute([op]);
    await useCase.execute([op]); // duplicate — should not throw

    final tx = await txDao.findById('tx-dup');
    expect(tx, isNotNull);
  });

  test('delete operation soft-deletes the transaction', () async {
    // First create
    await useCase.execute([
      {
        'op': 'create',
        'entityType': 'bill',
        'entityId': 'tx-del',
        'fromDeviceId': 'partner-device',
        'data': {
          'id': 'tx-del',
          'amount': 500,
          'type': 'expense',
          'categoryId': 'cat-1',
          'ledgerType': 'survival',
          'timestamp': '2026-03-15T10:00:00.000Z',
          'createdAt': '2026-03-15T10:00:00.000Z',
        },
      },
    ]);

    // Then delete
    await useCase.execute([
      {
        'op': 'delete',
        'entityType': 'bill',
        'entityId': 'tx-del',
      },
    ]);

    final tx = await txDao.findById('tx-del');
    expect(tx!.isDeleted, true);
  });

  test('skips non-bill entity types', () async {
    await useCase.execute([
      {
        'op': 'create',
        'entityType': 'category',
        'entityId': 'cat-remote',
        'fromDeviceId': 'partner-device',
        'data': {'id': 'cat-remote', 'name': 'Remote Category'},
      },
    ]);

    // No crash, no transaction created
    final tx = await txDao.findById('cat-remote');
    expect(tx, isNull);
  });

  test('skips operation if no shadow book exists for device', () async {
    await useCase.execute([
      {
        'op': 'create',
        'entityType': 'bill',
        'entityId': 'tx-unknown',
        'fromDeviceId': 'unknown-device',
        'data': {
          'id': 'tx-unknown',
          'amount': 100,
          'type': 'expense',
          'categoryId': 'cat-1',
          'ledgerType': 'survival',
          'timestamp': '2026-03-15T10:00:00.000Z',
          'createdAt': '2026-03-15T10:00:00.000Z',
        },
      },
    ]);

    final tx = await txDao.findById('tx-unknown');
    expect(tx, isNull);
  });
}
```

### Step 2: Run test to verify it fails

Run: `flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`
Expected: FAIL — `ApplySyncOperationsUseCase` doesn't exist

### Step 3: Implement ApplySyncOperationsUseCase

```dart
// lib/application/family_sync/apply_sync_operations_use_case.dart
import 'package:flutter/foundation.dart';

import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import 'shadow_book_service.dart';

/// Applies sync operations received from remote devices.
///
/// Routes each operation to the correct shadow book based on `fromDeviceId`.
/// Idempotent: duplicate create operations are skipped.
class ApplySyncOperationsUseCase {
  ApplySyncOperationsUseCase({
    required TransactionRepository transactionRepository,
    required ShadowBookService shadowBookService,
  }) : _transactionRepo = transactionRepository,
       _shadowBookService = shadowBookService;

  final TransactionRepository _transactionRepo;
  final ShadowBookService _shadowBookService;

  Future<void> execute(List<Map<String, dynamic>> operations) async {
    for (final op in operations) {
      final entityType = op['entityType'] as String?;
      if (entityType != 'bill') continue;

      final opType = op['op'] as String;
      final entityId = op['entityId'] as String;

      switch (opType) {
        case 'create':
        case 'insert':
          final data = op['data'] as Map<String, dynamic>?;
          final fromDeviceId = op['fromDeviceId'] as String?;
          if (data == null || fromDeviceId == null) continue;
          await _handleCreate(entityId, data, fromDeviceId);
        case 'update':
          final data = op['data'] as Map<String, dynamic>?;
          final fromDeviceId = op['fromDeviceId'] as String?;
          if (data == null || fromDeviceId == null) continue;
          await _handleUpdate(entityId, data, fromDeviceId);
        case 'delete':
          await _handleDelete(entityId);
      }
    }
  }

  Future<void> _handleCreate(
    String entityId,
    Map<String, dynamic> data,
    String fromDeviceId,
  ) async {
    // Idempotent: skip if already exists
    final existing = await _transactionRepo.findById(entityId);
    if (existing != null) return;

    final shadowBook = await _shadowBookService.findShadowBook(fromDeviceId);
    if (shadowBook == null) {
      if (kDebugMode) {
        debugPrint('ApplySync: no shadow book for device $fromDeviceId');
      }
      return;
    }

    final transaction = TransactionSyncMapper.fromSyncMap(
      data,
      bookId: shadowBook.id,
    );
    await _transactionRepo.insert(transaction);
  }

  Future<void> _handleUpdate(
    String entityId,
    Map<String, dynamic> data,
    String fromDeviceId,
  ) async {
    final existing = await _transactionRepo.findById(entityId);
    if (existing == null) {
      await _handleCreate(entityId, data, fromDeviceId);
      return;
    }

    final updated = TransactionSyncMapper.fromSyncMap(
      data,
      bookId: existing.bookId,
    );
    await _transactionRepo.update(updated);
  }

  Future<void> _handleDelete(String entityId) async {
    await _transactionRepo.softDelete(entityId);
  }
}
```

### Step 4: Run test to verify it passes

Run: `flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`
Expected: PASS

### Step 5: Commit

```bash
git add lib/application/family_sync/apply_sync_operations_use_case.dart
git add test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
git commit -m "feat(sync): add ApplySyncOperationsUseCase for pull-side apply

Routes incoming sync operations to correct shadow book by fromDeviceId.
Idempotent create, LWW update, soft-delete."
```

---

## Task 6: Wire PullSyncUseCase to ApplySyncOperations + Inject fromDeviceId

**Files:**
- Modify: `lib/application/family_sync/pull_sync_use_case.dart:128-138`
- Modify: `lib/features/family_sync/presentation/providers/sync_providers.dart:28-40`

### Step 1: Modify PullSyncUseCase to inject fromDeviceId into operations

In `lib/application/family_sync/pull_sync_use_case.dart`, find the `v2_data` case block (around line 118-141). After parsing operations, inject `fromDeviceId` into each operation:

```dart
// Around line 131-137, replace:
final operations = rawOperations
    .map((operation) =>
        _normalizeOperation(operation as Map<String, dynamic>))
    .toList();
await _applyOperations(operations);

// With:
final operations = rawOperations
    .map((operation) {
      final normalized = _normalizeOperation(
          operation as Map<String, dynamic>);
      // Inject sender identity so applyOperations can route to correct shadow book
      if (fromDeviceId != null) {
        normalized['fromDeviceId'] = fromDeviceId;
      }
      return normalized;
    })
    .toList();
await _applyOperations(operations);
```

### Step 2: Wire the provider

In `lib/features/family_sync/presentation/providers/sync_providers.dart`, replace the `pullSyncUseCase` provider (lines 28-40):

```dart
@riverpod
PullSyncUseCase pullSyncUseCase(Ref ref) {
  final applyOps = ref.watch(applySyncOperationsUseCaseProvider);

  return PullSyncUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    keyManager: ref.watch(keyManagerProvider),
    applyOperations: (operations) => applyOps.execute(operations),
  );
}
```

Add the `ApplySyncOperationsUseCase` provider + imports:

```dart
@riverpod
ApplySyncOperationsUseCase applySyncOperationsUseCase(Ref ref) {
  return ApplySyncOperationsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
}

@riverpod
ShadowBookService shadowBookService(Ref ref) {
  return ShadowBookService(
    bookRepository: ref.watch(bookRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}
```

You need to add the import for `transactionRepositoryProvider` and `bookRepositoryProvider` from the accounting providers. These cross-feature references should use the provider directly since both are `@riverpod` global providers.

### Step 3: Run code generation

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

### Step 4: Run existing pull sync tests + full suite

Run: `flutter analyze && flutter test`
Expected: 0 issues, all tests pass

### Step 5: Commit

```bash
git add lib/application/family_sync/pull_sync_use_case.dart
git add lib/features/family_sync/presentation/providers/sync_providers.dart
git commit -m "feat(sync): wire PullSyncUseCase to ApplySyncOperationsUseCase

Inject fromDeviceId into operations for shadow book routing.
Replace TODO stub with real applyOperations callback."
```

---

## Task 7: Wire FullSyncUseCase to TransactionRepository

**Files:**
- Modify: `lib/features/family_sync/presentation/providers/sync_providers.dart:43-52`

### Step 1: Replace the TODO stub in fullSyncUseCase provider

```dart
@riverpod
FullSyncUseCase fullSyncUseCase(Ref ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final bookRepo = ref.watch(bookRepositoryProvider);

  return FullSyncUseCase(
    pushSync: ref.watch(pushSyncUseCaseProvider),
    fetchAllTransactions: () async {
      // Only push transactions from local books (not shadow books)
      final allBooks = await bookRepo.findAll();
      final localBooks = allBooks.where((b) => !b.isShadow).toList();
      if (localBooks.isEmpty) return [];

      final allOps = <Map<String, dynamic>>[];
      for (final book in localBooks) {
        final transactions = await transactionRepo.findAllByBook(book.id);
        allOps.addAll(
          transactions.map(TransactionSyncMapper.toCreateOperation),
        );
      }
      return allOps;
    },
  );
}
```

### Step 2: Run code generation + tests

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`
Expected: 0 issues, all tests pass

### Step 3: Commit

```bash
git add lib/features/family_sync/presentation/providers/sync_providers.dart
git commit -m "feat(sync): wire FullSyncUseCase to transaction repository

Fetch all local (non-shadow) book transactions for full sync push."
```

---

## Task 8: Add Incremental Sync Trigger to CreateTransactionUseCase

**Files:**
- Modify: `lib/application/accounting/create_transaction_use_case.dart`
- Modify: `lib/features/accounting/presentation/providers/use_case_providers.dart:20-29`
- Test: `test/unit/application/accounting/create_transaction_sync_trigger_test.dart` (new)

### Step 1: Write the failing test

```dart
// test/unit/application/accounting/create_transaction_sync_trigger_test.dart
import 'package:flutter_test/flutter_test.dart';
// ... imports for CreateTransactionUseCase, mocks ...

void main() {
  // Use mocks for SyncTriggerService
  // After successful create, verify onTransactionCreated was called
  // with the correct sync operation format

  test('successful create triggers sync push', () async {
    // Setup mocks for all dependencies
    // Execute CreateTransactionUseCase
    // Verify syncTriggerService.onTransactionCreated was called
    // with a map containing the transaction data
  });

  test('sync failure does not affect create result', () async {
    // Setup: syncTriggerService throws
    // Execute: should still return success
    // Verify: transaction was persisted locally
  });

  test('no sync trigger when no active group', () async {
    // Setup: group check returns noGroup
    // Execute: create succeeds
    // Verify: syncTriggerService was NOT called
  });
}
```

### Step 2: Add optional SyncTriggerService to CreateTransactionUseCase

In `lib/application/accounting/create_transaction_use_case.dart`:

Add to constructor parameters:
```dart
SyncTriggerService? syncTriggerService,
```

Add field:
```dart
final SyncTriggerService? _syncTriggerService;
```

At the end of `execute()`, after line 177 (`await _transactionRepo.insert(transaction);`), add:

```dart
// 10. Fire-and-forget sync trigger (does not affect local result)
_triggerIncrementalSync(transaction);
```

Add helper method:

```dart
void _triggerIncrementalSync(Transaction transaction) {
  final syncService = _syncTriggerService;
  if (syncService == null) return;

  unawaited(
    syncService
        .onTransactionCreated(
          TransactionSyncMapper.toSyncMap(transaction),
        )
        .catchError((Object e) {
      debugPrint('Sync trigger failed (queued for retry): $e');
    }),
  );
}
```

Add imports at the top:
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../infrastructure/sync/sync_trigger_service.dart';
```

### Step 3: Update the provider

In `lib/features/accounting/presentation/providers/use_case_providers.dart`, update the `createTransactionUseCase` provider:

```dart
@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  // SyncTriggerService may not be initialized yet — use tryWatch
  SyncTriggerService? syncService;
  try {
    syncService = ref.watch(syncTriggerServiceProvider);
  } catch (_) {
    // Sync not available (e.g., during tests or early startup)
  }

  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    deviceIdentityRepository: ref.watch(deviceIdentityRepositoryProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
    classificationService: ref.watch(classificationServiceProvider),
    syncTriggerService: syncService,
  );
}
```

### Step 4: Run tests

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`
Expected: 0 issues, all tests pass (existing tests unaffected since syncTriggerService is nullable)

### Step 5: Commit

```bash
git add lib/application/accounting/create_transaction_use_case.dart
git add lib/features/accounting/presentation/providers/use_case_providers.dart
git add test/unit/application/accounting/create_transaction_sync_trigger_test.dart
git commit -m "feat(sync): trigger incremental push on transaction creation

Fire-and-forget sync via SyncTriggerService after local persist.
Sync failure does not affect local create result."
```

---

## Task 9: Implement CheckGroupValidityUseCase

**Files:**
- Create: `lib/application/family_sync/check_group_validity_use_case.dart`
- Test: `test/unit/application/family_sync/check_group_validity_use_case_test.dart` (new)

### Step 1: Write the failing test

```dart
// test/unit/application/family_sync/check_group_validity_use_case_test.dart

void main() {
  group('CheckGroupValidityUseCase', () {
    test('returns noGroup when no active group', () async {
      // groupRepo.getActiveGroup() returns null
      // result should be GroupValidityResult.noGroup()
    });

    test('returns valid when server confirms group exists', () async {
      // groupRepo returns active group
      // apiClient.checkGroup() returns {groupExisted: true}
      // result should be GroupValidityResult.valid()
    });

    test('returns invalid and cleans up when server returns 404', () async {
      // apiClient.checkGroup() throws RelayApiException(404)
      // verify: shadowBookService.cleanSyncData was called
      // verify: groupRepo.deactivateGroup was called
      // result should be GroupValidityResult.invalid('...')
    });

    test('returns valid on network error (offline tolerance)', () async {
      // apiClient.checkGroup() throws SocketException
      // result should be GroupValidityResult.valid()
    });

    test('uses cache for 5 minutes', () async {
      // First call: hits server, returns valid
      // Second call within 5 min: returns cached result, no server call
    });
  });
}
```

### Step 2: Implement

```dart
// lib/application/family_sync/check_group_validity_use_case.dart

import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'shadow_book_service.dart';

sealed class GroupValidityResult {
  const GroupValidityResult();
  const factory GroupValidityResult.valid() = GroupValid;
  const factory GroupValidityResult.noGroup() = GroupNoGroup;
  const factory GroupValidityResult.invalid(String reason) = GroupInvalid;
}

class GroupValid extends GroupValidityResult {
  const GroupValid();
}

class GroupNoGroup extends GroupValidityResult {
  const GroupNoGroup();
}

class GroupInvalid extends GroupValidityResult {
  const GroupInvalid(this.reason);
  final String reason;
}

class CheckGroupValidityUseCase {
  CheckGroupValidityUseCase({
    required GroupRepository groupRepo,
    required RelayApiClient apiClient,
    required ShadowBookService shadowBookService,
  }) : _groupRepo = groupRepo,
       _apiClient = apiClient,
       _shadowBookService = shadowBookService;

  final GroupRepository _groupRepo;
  final RelayApiClient _apiClient;
  final ShadowBookService _shadowBookService;

  // 5-minute cache to avoid hammering server on every transaction
  DateTime? _lastCheckTime;
  GroupValidityResult? _cachedResult;
  static const _cacheDuration = Duration(minutes: 5);

  Future<GroupValidityResult> execute({bool forceCheck = false}) async {
    if (!forceCheck && _cachedResult != null && _lastCheckTime != null) {
      if (DateTime.now().difference(_lastCheckTime!) < _cacheDuration) {
        return _cachedResult!;
      }
    }

    final group = await _groupRepo.getActiveGroup();
    if (group == null) {
      return _cache(const GroupValidityResult.noGroup());
    }

    try {
      await _apiClient.checkGroup();
      return _cache(const GroupValidityResult.valid());
    } on RelayApiException catch (e) {
      if (e.isNotFound || e.isForbidden) {
        await _shadowBookService.cleanSyncData(group.groupId);
        await _groupRepo.deactivateGroup(group.groupId);
        _invalidate();
        return GroupValidityResult.invalid(
          e.isNotFound ? 'Group dissolved' : 'Removed from group',
        );
      }
      return _cache(const GroupValidityResult.valid());
    } catch (_) {
      // Network error → offline tolerance
      return _cache(const GroupValidityResult.valid());
    }
  }

  GroupValidityResult _cache(GroupValidityResult result) {
    _cachedResult = result;
    _lastCheckTime = DateTime.now();
    return result;
  }

  void _invalidate() {
    _cachedResult = null;
    _lastCheckTime = null;
  }
}
```

### Step 3: Run tests

Run: `flutter test test/unit/application/family_sync/check_group_validity_use_case_test.dart`
Expected: PASS

### Step 4: Commit

```bash
git add lib/application/family_sync/check_group_validity_use_case.dart
git add test/unit/application/family_sync/check_group_validity_use_case_test.dart
git commit -m "feat(sync): add CheckGroupValidityUseCase with 5-min cache

Validates group membership with server before sync push.
On invalid: cleans shadow books + deactivates group.
Offline-tolerant: returns valid on network errors."
```

---

## Task 10: Integrate Group Check into CreateTransactionUseCase

**Files:**
- Modify: `lib/application/accounting/create_transaction_use_case.dart`
- Modify: `lib/features/accounting/presentation/providers/use_case_providers.dart`

### Step 1: Add CheckGroupValidityUseCase to constructor

Add optional parameter:
```dart
CheckGroupValidityUseCase? checkGroupValidity,
```

### Step 2: Add group check before sync trigger

At the end of `execute()`, modify the sync trigger section:

```dart
// 10. Check group validity + fire-and-forget sync
if (_checkGroupValidity != null && _syncTriggerService != null) {
  unawaited(_checkAndSync(transaction));
}
```

Add helper:
```dart
Future<void> _checkAndSync(Transaction transaction) async {
  try {
    final validity = await _checkGroupValidity!.execute();
    if (validity is GroupValid) {
      await _syncTriggerService!.onTransactionCreated(
        TransactionSyncMapper.toSyncMap(transaction),
      );
    }
    // GroupInvalid: sync data already cleaned by the use case
    // GroupNoGroup: no sync needed
  } catch (e) {
    debugPrint('Check+sync failed: $e');
  }
}
```

### Step 3: Update provider

```dart
@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  SyncTriggerService? syncService;
  CheckGroupValidityUseCase? groupCheck;
  try {
    syncService = ref.watch(syncTriggerServiceProvider);
    groupCheck = ref.watch(checkGroupValidityUseCaseProvider);
  } catch (_) {}

  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    deviceIdentityRepository: ref.watch(deviceIdentityRepositoryProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
    classificationService: ref.watch(classificationServiceProvider),
    syncTriggerService: syncService,
    checkGroupValidity: groupCheck,
  );
}
```

### Step 4: Run tests

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`
Expected: PASS

### Step 5: Commit

```bash
git add lib/application/accounting/create_transaction_use_case.dart
git add lib/features/accounting/presentation/providers/use_case_providers.dart
git commit -m "feat(sync): integrate group validity check before sync push

Check group membership (with 5-min cache) before triggering push.
Invalid group → clean sync data + deactivate."
```

---

## Task 11: Trigger Initial Full Sync on Group Confirmation

**Files:**
- Modify: `lib/features/family_sync/use_cases/confirm_member_use_case.dart:40-62`
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart:206-234`

### Step 1: Add FullSyncUseCase to ConfirmMemberUseCase

After the key exchange push (line 61), add full sync trigger:

```dart
// After key exchange completes successfully:
// Trigger full sync to send all local transactions to new member
await _fullSync.execute();
```

Add `FullSyncUseCase` as a constructor dependency.

### Step 2: Add initial sync to member_confirmed handler

In `sync_trigger_service.dart`, in `_handleMemberConfirmed()` (line 233), after `_pullSync.execute()`:

```dart
// After pulling (to receive group key + partner data):
// Also push local full sync
if (_fullSync != null) {
  await _fullSync!.execute();
}
```

Add optional `FullSyncUseCase? fullSync` to `SyncTriggerService` constructor.

### Step 3: Update providers to wire full sync

### Step 4: Run tests

Run: `flutter analyze && flutter test`
Expected: PASS

### Step 5: Commit

```bash
git commit -m "feat(sync): trigger full sync on group confirmation

Owner: pushes full data after confirming member.
Member: pushes full data after receiving member_confirmed."
```

---

## Task 12: Create ShadowBook on Group Confirmation

**Files:**
- Modify: `lib/features/family_sync/use_cases/confirm_member_use_case.dart`
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart`

### Step 1: Owner creates shadow book when confirming member

In `ConfirmMemberUseCase.execute()`, after `activateMember()`:

```dart
// Create shadow book for the new member
final defaultBook = await _bookRepo.findAll();
final localBook = defaultBook.firstWhere((b) => !b.isShadow);
await _shadowBookService.createShadowBook(
  groupId: groupId,
  memberDeviceId: deviceId,
  memberDeviceName: member.deviceName,
  currency: localBook.currency,
);
```

### Step 2: Member creates shadow book when receiving member_confirmed

In `SyncTriggerService._handleMemberConfirmed()`, after `_groupRepo.confirmLocalGroup()`:

```dart
// Create shadow book for the owner
final group = await _groupRepo.getActiveGroup();
if (group != null) {
  final defaultBook = /* get default book */;
  for (final member in group.members) {
    if (member.deviceId == localDeviceId) continue;
    final existingShadow = await _shadowBookService.findShadowBook(member.deviceId);
    if (existingShadow == null) {
      await _shadowBookService.createShadowBook(
        groupId: group.groupId,
        memberDeviceId: member.deviceId,
        memberDeviceName: member.deviceName,
        currency: defaultBook.currency,
      );
    }
  }
}
```

### Step 3: Run tests

Run: `flutter analyze && flutter test`
Expected: PASS

### Step 4: Commit

```bash
git commit -m "feat(sync): create shadow books on group confirmation

Owner creates shadow book for new member.
Member creates shadow book for owner after confirmation."
```

---

## Task 13: Integration Test — Full Sync Round Trip

**Files:**
- Create: `test/integration/sync/bill_sync_round_trip_test.dart`

### Step 1: Write integration test

```dart
// test/integration/sync/bill_sync_round_trip_test.dart

void main() {
  group('Bill sync round trip', () {
    test('shadow book created, transactions synced, cleanup on exit', () async {
      final db = AppDatabase.forTesting();
      // Setup: BookDao, TransactionDao, ShadowBookService

      // 1. Create a shadow book
      final shadowId = await shadowBookService.createShadowBook(
        groupId: 'group-1',
        memberDeviceId: 'partner',
        memberDeviceName: 'Partner',
        currency: 'JPY',
      );

      // 2. Apply sync operations (simulating pull)
      await applyOps.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-1',
          'fromDeviceId': 'partner',
          'data': {
            'id': 'tx-1',
            'amount': 1000,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'survival',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      // 3. Verify transaction in shadow book
      final tx = await txDao.findById('tx-1');
      expect(tx!.bookId, shadowId);

      // 4. Clean sync data (simulating group exit)
      await shadowBookService.cleanSyncData('group-1');

      // 5. Verify everything cleaned up
      final txAfter = await txDao.findById('tx-1');
      expect(txAfter, isNull);
      final bookAfter = await bookDao.findById(shadowId);
      expect(bookAfter, isNull);

      await db.close();
    });
  });
}
```

### Step 2: Run integration test

Run: `flutter test test/integration/sync/bill_sync_round_trip_test.dart`
Expected: PASS

### Step 3: Commit

```bash
git add test/integration/sync/bill_sync_round_trip_test.dart
git commit -m "test(sync): add bill sync round trip integration test

Verifies shadow book creation, transaction routing, and cleanup."
```

---

## Task 14: Run Full Verification

### Step 1: Run analyzer

Run: `flutter analyze`
Expected: 0 issues

### Step 2: Run all tests

Run: `flutter test`
Expected: All pass

### Step 3: Run coverage

Run: `flutter test --coverage`
Expected: ≥80% on new code

### Step 4: Final commit (if any fixes needed)

---

## Summary

| Task | What | Files Created/Modified |
|------|------|----------------------|
| 1 | Books table shadow columns + migration | 2 modified, 1 test |
| 2 | Book model + DAO + repo shadow methods | 4 modified, 1 test |
| 3 | ShadowBookService | 1 created, 1 test |
| 4 | TransactionSyncMapper | 1 created, 1 test |
| 5 | ApplySyncOperationsUseCase | 1 created, 1 test |
| 6 | Wire PullSync → ApplyOps + fromDeviceId | 2 modified |
| 7 | Wire FullSync → TransactionRepository | 1 modified |
| 8 | Incremental sync trigger on create | 2 modified, 1 test |
| 9 | CheckGroupValidityUseCase | 1 created, 1 test |
| 10 | Integrate group check into create | 2 modified |
| 11 | Full sync on group confirmation | 2 modified |
| 12 | Shadow book creation on confirmation | 2 modified |
| 13 | Integration test | 1 test |
| 14 | Full verification | — |
