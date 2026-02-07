# Database Infrastructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete data layer (Drift tables, DAOs, Freezed domain models, repository interfaces, repository implementations) for the accounting feature, forming the foundation for MOD-001 Basic Accounting.

**Architecture:** Clean Architecture with "Thin Feature" pattern. Domain models and repository interfaces live in `lib/features/accounting/domain/`, Drift tables in `lib/data/tables/`, DAOs in `lib/data/daos/`, repository implementations in `lib/data/repositories/`. Providers wire everything together in `lib/features/accounting/presentation/providers/`.

**Tech Stack:** Flutter, Drift (SQLCipher), Freezed, Riverpod, ULID, SHA-256 hash chain, ChaCha20-Poly1305 field encryption

**Existing Infrastructure:**
- `lib/data/app_database.dart` — minimal AppDatabase with only AuditLogs table
- `lib/data/tables/audit_logs_table.dart` — existing table pattern to follow
- `lib/infrastructure/crypto/` — FieldEncryptionService, HashChainService, providers
- `lib/infrastructure/security/` — AuditLogger, BiometricService, SecureStorageService, providers

---

## Task 1: Result Utility Class

**Files:**
- Create: `lib/shared/utils/result.dart`
- Test: `test/unit/shared/utils/result_test.dart`

**Step 1: Write the failing test**

Create `test/unit/shared/utils/result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/utils/result.dart';

void main() {
  group('Result', () {
    test('success creates a success result with data', () {
      final result = Result.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.data, 42);
      expect(result.error, isNull);
    });

    test('error creates an error result with message', () {
      final result = Result<int>.error('Something failed');

      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.error, 'Something failed');
      expect(result.data, isNull);
    });

    test('success with null data', () {
      final result = Result<void>.success(null);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/shared/utils/result_test.dart`
Expected: FAIL with "Target URI doesn't exist"

**Step 3: Write minimal implementation**

Create `lib/shared/utils/result.dart`:

```dart
/// Simple Result type for use case return values.
///
/// Wraps either a success [data] value or an [error] message.
/// Used by application-layer use cases to communicate outcomes
/// without throwing exceptions.
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T? data) =>
      Result._(data: data, isSuccess: true);

  factory Result.error(String message) =>
      Result._(error: message, isSuccess: false);

  bool get isError => !isSuccess;
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/shared/utils/result_test.dart`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add lib/shared/utils/result.dart test/unit/shared/utils/result_test.dart
git commit -m "feat: add Result utility class for use case return values"
```

---

## Task 2: TransactionType & LedgerType Enums + Transaction Domain Model

**Files:**
- Create: `lib/features/accounting/domain/models/transaction.dart`
- Test: `test/unit/features/accounting/domain/models/transaction_test.dart`

**Step 1: Write the failing test**

Create `test/unit/features/accounting/domain/models/transaction_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('TransactionType', () {
    test('has expense, income, and transfer values', () {
      expect(TransactionType.values.length, 3);
      expect(TransactionType.expense, isNotNull);
      expect(TransactionType.income, isNotNull);
      expect(TransactionType.transfer, isNotNull);
    });
  });

  group('LedgerType', () {
    test('has survival and soul values', () {
      expect(LedgerType.values.length, 2);
      expect(LedgerType.survival, isNotNull);
      expect(LedgerType.soul, isNotNull);
    });
  });

  group('Transaction', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 2, 6, 10, 30);
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'abc123',
        createdAt: now,
      );

      expect(tx.id, 'tx_001');
      expect(tx.amount, 10000);
      expect(tx.type, TransactionType.expense);
      expect(tx.ledgerType, LedgerType.survival);
      expect(tx.isPrivate, false);
      expect(tx.isSynced, false);
      expect(tx.isDeleted, false);
      expect(tx.note, isNull);
      expect(tx.prevHash, isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final now = DateTime(2026, 2, 6);
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'hash1',
        createdAt: now,
      );

      final updated = tx.copyWith(amount: 20000, note: 'lunch');

      expect(updated.amount, 20000);
      expect(updated.note, 'lunch');
      expect(updated.id, 'tx_001'); // unchanged
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 2, 6, 10, 30);
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'hash1',
        createdAt: now,
      );

      final json = tx.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored, tx);
    });

    test('equality works for identical data', () {
      final now = DateTime(2026, 2, 6);
      final tx1 = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'cat_1',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'h1',
        createdAt: now,
      );
      final tx2 = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'cat_1',
        ledgerType: LedgerType.survival,
        timestamp: now,
        currentHash: 'h1',
        createdAt: now,
      );

      expect(tx1, tx2);
      expect(tx1.hashCode, tx2.hashCode);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/features/accounting/domain/models/transaction_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/features/accounting/domain/models/transaction.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  expense,
  income,
  transfer,
}

enum LedgerType {
  survival,
  soul,
}

@freezed
class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    required String id,
    required String bookId,
    required String deviceId,
    required int amount,
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    required DateTime timestamp,

    // Optional fields
    String? note,
    String? photoHash,
    String? merchant,

    // Hash chain
    String? prevHash,
    required String currentHash,

    // Timestamps
    required DateTime createdAt,
    DateTime? updatedAt,

    // Flags
    @Default(false) bool isPrivate,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/features/accounting/domain/models/transaction_test.dart`
Expected: PASS (5 tests)

**Step 5: Commit**

```bash
git add lib/features/accounting/domain/models/transaction.dart \
        lib/features/accounting/domain/models/transaction.freezed.dart \
        lib/features/accounting/domain/models/transaction.g.dart \
        test/unit/features/accounting/domain/models/transaction_test.dart
git commit -m "feat: add Transaction domain model with Freezed"
```

---

## Task 3: Category Domain Model

**Files:**
- Create: `lib/features/accounting/domain/models/category.dart`
- Test: `test/unit/features/accounting/domain/models/category_test.dart`

**Step 1: Write the failing test**

Create `test/unit/features/accounting/domain/models/category_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('Category', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 2, 6);
      final cat = Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        createdAt: now,
      );

      expect(cat.id, 'cat_food');
      expect(cat.name, 'Food');
      expect(cat.level, 1);
      expect(cat.isSystem, false);
      expect(cat.sortOrder, 0);
      expect(cat.parentId, isNull);
    });

    test('system category cannot be user-deleted conceptually', () {
      final now = DateTime(2026, 2, 6);
      final cat = Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      );

      expect(cat.isSystem, true);
    });

    test('supports parent-child hierarchy via parentId', () {
      final now = DateTime(2026, 2, 6);
      final child = Category(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: TransactionType.expense,
        createdAt: now,
      );

      expect(child.parentId, 'cat_food');
      expect(child.level, 2);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 2, 6, 10, 30);
      final cat = Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: now,
      );

      final json = cat.toJson();
      final restored = Category.fromJson(json);

      expect(restored, cat);
    });

    test('copyWith creates new instance', () {
      final now = DateTime(2026, 2, 6);
      final cat = Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        createdAt: now,
      );

      final updated = cat.copyWith(name: 'Dining');
      expect(updated.name, 'Dining');
      expect(updated.id, 'cat_food'); // unchanged
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/features/accounting/domain/models/category_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/features/accounting/domain/models/category.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'transaction.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const Category._();

  const factory Category({
    required String id,
    required String name,
    required String icon,
    required String color,
    String? parentId,
    required int level,
    required TransactionType type,
    @Default(false) bool isSystem,
    @Default(0) int sortOrder,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/features/accounting/domain/models/category_test.dart`
Expected: PASS (5 tests)

**Step 5: Commit**

```bash
git add lib/features/accounting/domain/models/category.dart \
        lib/features/accounting/domain/models/category.freezed.dart \
        lib/features/accounting/domain/models/category.g.dart \
        test/unit/features/accounting/domain/models/category_test.dart
git commit -m "feat: add Category domain model with Freezed"
```

---

## Task 4: Book Domain Model

**Files:**
- Create: `lib/features/accounting/domain/models/book.dart`
- Test: `test/unit/features/accounting/domain/models/book_test.dart`

**Step 1: Write the failing test**

Create `test/unit/features/accounting/domain/models/book_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';

void main() {
  group('Book', () {
    test('creates with required fields and defaults', () {
      final now = DateTime(2026, 2, 6);
      final book = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      expect(book.id, 'book_001');
      expect(book.name, 'My Book');
      expect(book.currency, 'JPY');
      expect(book.isArchived, false);
      expect(book.transactionCount, 0);
      expect(book.survivalBalance, 0);
      expect(book.soulBalance, 0);
      expect(book.updatedAt, isNull);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2026, 2, 6, 10, 30);
      final book = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
        transactionCount: 5,
        survivalBalance: 50000,
        soulBalance: 20000,
      );

      final json = book.toJson();
      final restored = Book.fromJson(json);

      expect(restored, book);
    });

    test('copyWith creates new instance', () {
      final now = DateTime(2026, 2, 6);
      final book = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      final updated = book.copyWith(
        name: 'Family Book',
        isArchived: true,
      );

      expect(updated.name, 'Family Book');
      expect(updated.isArchived, true);
      expect(updated.id, 'book_001'); // unchanged
    });

    test('equality works for identical data', () {
      final now = DateTime(2026, 2, 6);
      final b1 = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );
      final b2 = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      expect(b1, b2);
      expect(b1.hashCode, b2.hashCode);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/features/accounting/domain/models/book_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/features/accounting/domain/models/book.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,
    required String name,
    required String currency,
    required String deviceId,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isArchived,

    // Denormalized stats for performance
    @Default(0) int transactionCount,
    @Default(0) int survivalBalance,
    @Default(0) int soulBalance,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) =>
      _$BookFromJson(json);
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/features/accounting/domain/models/book_test.dart`
Expected: PASS (4 tests)

**Step 5: Commit**

```bash
git add lib/features/accounting/domain/models/book.dart \
        lib/features/accounting/domain/models/book.freezed.dart \
        lib/features/accounting/domain/models/book.g.dart \
        test/unit/features/accounting/domain/models/book_test.dart
git commit -m "feat: add Book domain model with Freezed"
```

---

## Task 5: Books Drift Table

**Files:**
- Create: `lib/data/tables/books_table.dart`
- Modify: `lib/data/app_database.dart` (add Books table)
- Test: `test/unit/data/tables/books_table_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/tables/books_table_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('Books table', () {
    test('inserts and retrieves a book', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

      await db.into(db.books).insert(
        BooksCompanion.insert(
          id: 'book_001',
          name: 'My Book',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: now,
        ),
      );

      final rows = await db.select(db.books).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'book_001');
      expect(rows.first.name, 'My Book');
      expect(rows.first.currency, 'JPY');
      expect(rows.first.isArchived, false);
      expect(rows.first.transactionCount, 0);
    });

    test('updates a book', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

      await db.into(db.books).insert(
        BooksCompanion.insert(
          id: 'book_001',
          name: 'My Book',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: now,
        ),
      );

      await (db.update(db.books)
            ..where((t) => t.id.equals('book_001')))
          .write(
        const BooksCompanion(
          name: Value('Updated Book'),
          isArchived: Value(true),
        ),
      );

      final rows = await db.select(db.books).get();
      expect(rows.first.name, 'Updated Book');
      expect(rows.first.isArchived, true);
    });

    test('enforces primary key uniqueness', () async {
      final now = DateTime(2026, 2, 6);

      await db.into(db.books).insert(
        BooksCompanion.insert(
          id: 'book_001',
          name: 'Book 1',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: now,
        ),
      );

      expect(
        () => db.into(db.books).insert(
          BooksCompanion.insert(
            id: 'book_001',
            name: 'Book 2',
            currency: 'USD',
            deviceId: 'dev_002',
            createdAt: now,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/tables/books_table_test.dart`
Expected: FAIL (no `db.books` accessor)

**Step 3: Write minimal implementation**

Create `lib/data/tables/books_table.dart`:

```dart
import 'package:drift/drift.dart';

/// Books table — represents accounting ledger books.
///
/// Each book belongs to a device and tracks aggregated balances
/// for survival and soul ledger types.
@DataClassName('BookRow')
class Books extends Table {
  /// ULID primary key.
  TextColumn get id => text()();

  /// Display name (1-100 chars).
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// ISO 4217 currency code (e.g. "JPY", "USD").
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Device that created this book.
  TextColumn get deviceId => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Soft archive flag. Archived books are hidden from main view.
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();

  // Denormalized stats for fast dashboard rendering
  IntColumn get transactionCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get survivalBalance =>
      integer().withDefault(const Constant(0))();
  IntColumn get soulBalance =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_books_device_id', columns: {#deviceId}),
    TableIndex(name: 'idx_books_archived', columns: {#isArchived}),
  ];
}
```

Modify `lib/data/app_database.dart` — add Books to the database:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables/audit_logs_table.dart';
import 'tables/books_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [AuditLogs, Books])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/data/tables/books_table_test.dart`
Expected: PASS (3 tests)

**Step 5: Run ALL existing tests to check nothing broke**

Run: `flutter test --concurrency=1`
Expected: ALL tests pass (existing security + crypto tests + new tests)

**Step 6: Commit**

```bash
git add lib/data/tables/books_table.dart lib/data/app_database.dart \
        test/unit/data/tables/books_table_test.dart
git commit -m "feat: add Books Drift table with indexes"
```

---

## Task 6: Categories Drift Table

**Files:**
- Create: `lib/data/tables/categories_table.dart`
- Modify: `lib/data/app_database.dart` (add Categories table)
- Test: `test/unit/data/tables/categories_table_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/tables/categories_table_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('Categories table', () {
    test('inserts and retrieves a category', () async {
      final now = DateTime(2026, 2, 6);

      await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: 'expense',
          createdAt: now,
        ),
      );

      final rows = await db.select(db.categories).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'cat_food');
      expect(rows.first.name, 'Food');
      expect(rows.first.level, 1);
      expect(rows.first.isSystem, false);
      expect(rows.first.parentId, isNull);
    });

    test('supports parent-child hierarchy', () async {
      final now = DateTime(2026, 2, 6);

      // Insert parent
      await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: 'expense',
          createdAt: now,
        ),
      );

      // Insert child
      await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: 'cat_food_breakfast',
          name: 'Breakfast',
          icon: 'free_breakfast',
          color: '#FF5722',
          parentId: const Value('cat_food'),
          level: 2,
          type: 'expense',
          createdAt: now,
        ),
      );

      final children = await (db.select(db.categories)
            ..where((t) => t.parentId.equals('cat_food')))
          .get();

      expect(children.length, 1);
      expect(children.first.name, 'Breakfast');
      expect(children.first.level, 2);
    });

    test('queries by level', () async {
      final now = DateTime(2026, 2, 6);

      await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: 'expense',
          createdAt: now,
        ),
      );

      await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: 'cat_food_breakfast',
          name: 'Breakfast',
          icon: 'free_breakfast',
          color: '#FF5722',
          parentId: const Value('cat_food'),
          level: 2,
          type: 'expense',
          createdAt: now,
        ),
      );

      final level1 = await (db.select(db.categories)
            ..where((t) => t.level.equals(1)))
          .get();

      expect(level1.length, 1);
      expect(level1.first.id, 'cat_food');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/tables/categories_table_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/data/tables/categories_table.dart`:

```dart
import 'package:drift/drift.dart';

/// Categories table — hierarchical transaction categories (3 levels).
///
/// Supports system-preset categories (isSystem=true) which cannot
/// be deleted by the user. Custom categories are user-created.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get color => text()();

  /// Parent category ID for hierarchy. NULL for top-level (level 1).
  TextColumn get parentId => text().nullable()();

  /// Hierarchy depth: 1, 2, or 3.
  IntColumn get level => integer()();

  /// 'expense' or 'income'.
  TextColumn get type => text()();

  /// System categories cannot be deleted.
  BoolColumn get isSystem =>
      boolean().withDefault(const Constant(false))();

  /// Display order within same level/parent.
  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_categories_parent_id', columns: {#parentId}),
    TableIndex(name: 'idx_categories_level', columns: {#level}),
    TableIndex(name: 'idx_categories_type', columns: {#type}),
  ];
}
```

Modify `lib/data/app_database.dart` — add Categories:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables/audit_logs_table.dart';
import 'tables/books_table.dart';
import 'tables/categories_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [AuditLogs, Books, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/data/tables/categories_table_test.dart`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add lib/data/tables/categories_table.dart lib/data/app_database.dart \
        test/unit/data/tables/categories_table_test.dart
git commit -m "feat: add Categories Drift table with hierarchy indexes"
```

---

## Task 7: Transactions Drift Table

**Files:**
- Create: `lib/data/tables/transactions_table.dart`
- Modify: `lib/data/app_database.dart` (add Transactions table)
- Test: `test/unit/data/tables/transactions_table_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/tables/transactions_table_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('Transactions table', () {
    test('inserts and retrieves a transaction', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

      // Must insert book first (conceptual FK)
      await db.into(db.books).insert(
        BooksCompanion.insert(
          id: 'book_001',
          name: 'My Book',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: now,
        ),
      );

      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
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
        ),
      );

      final rows = await db.select(db.transactions).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'tx_001');
      expect(rows.first.amount, 10000);
      expect(rows.first.type, 'expense');
      expect(rows.first.ledgerType, 'survival');
      expect(rows.first.isPrivate, false);
      expect(rows.first.isSynced, false);
      expect(rows.first.isDeleted, false);
    });

    test('queries by bookId and orders by timestamp desc', () async {
      final t1 = DateTime(2026, 2, 5);
      final t2 = DateTime(2026, 2, 6);

      await db.into(db.books).insert(
        BooksCompanion.insert(
          id: 'book_001',
          name: 'Book',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: t1,
        ),
      );

      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 1000,
          type: 'expense',
          categoryId: 'cat_food',
          ledgerType: 'survival',
          timestamp: t1,
          currentHash: 'h1',
          createdAt: t1,
        ),
      );

      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          id: 'tx_002',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 2000,
          type: 'income',
          categoryId: 'cat_salary',
          ledgerType: 'survival',
          timestamp: t2,
          currentHash: 'h2',
          createdAt: t2,
        ),
      );

      final results = await (db.select(db.transactions)
            ..where((t) => t.bookId.equals('book_001'))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();

      expect(results.length, 2);
      expect(results.first.id, 'tx_002'); // newer first
    });

    test('supports soft delete flag', () async {
      final now = DateTime(2026, 2, 6);

      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 1000,
          type: 'expense',
          categoryId: 'cat_food',
          ledgerType: 'survival',
          timestamp: now,
          currentHash: 'h1',
          createdAt: now,
        ),
      );

      // Soft delete
      await (db.update(db.transactions)
            ..where((t) => t.id.equals('tx_001')))
          .write(const TransactionsCompanion(isDeleted: Value(true)));

      // Query non-deleted
      final active = await (db.select(db.transactions)
            ..where((t) => t.isDeleted.equals(false)))
          .get();

      expect(active.length, 0);
    });

    test('stores nullable fields correctly', () async {
      final now = DateTime(2026, 2, 6);

      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 500,
          type: 'expense',
          categoryId: 'cat_food',
          ledgerType: 'survival',
          timestamp: now,
          currentHash: 'h1',
          createdAt: now,
          note: const Value('Lunch at cafe'),
          merchant: const Value('Starbucks'),
          prevHash: const Value('prev_hash_abc'),
        ),
      );

      final row = await (db.select(db.transactions)
            ..where((t) => t.id.equals('tx_001')))
          .getSingle();

      expect(row.note, 'Lunch at cafe');
      expect(row.merchant, 'Starbucks');
      expect(row.prevHash, 'prev_hash_abc');
      expect(row.photoHash, isNull);
      expect(row.metadata, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/tables/transactions_table_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/data/tables/transactions_table.dart`:

```dart
import 'package:drift/drift.dart';

/// Transactions table — core financial records.
///
/// Each transaction belongs to a book, has a category,
/// and participates in a SHA-256 hash chain for integrity.
/// The `note` field stores encrypted ciphertext (ChaCha20-Poly1305).
@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get deviceId => text()();

  /// Amount in minor units (e.g. cents/yen).
  IntColumn get amount => integer()();

  /// 'expense', 'income', or 'transfer'.
  TextColumn get type => text()();

  TextColumn get categoryId => text()();

  /// 'survival' or 'soul'.
  TextColumn get ledgerType => text()();

  /// When the transaction occurred (user-facing timestamp).
  DateTimeColumn get timestamp => dateTime()();

  // Optional fields
  /// Encrypted note (ChaCha20-Poly1305 ciphertext, base64).
  TextColumn get note => text().nullable()();
  TextColumn get photoHash => text().nullable()();
  TextColumn get merchant => text().nullable()();

  /// Extra JSON metadata.
  TextColumn get metadata => text().nullable()();

  // Hash chain
  TextColumn get prevHash => text().nullable()();
  TextColumn get currentHash => text()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // Flags
  BoolColumn get isPrivate =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_tx_book_id', columns: {#bookId}),
    TableIndex(name: 'idx_tx_category_id', columns: {#categoryId}),
    TableIndex(name: 'idx_tx_timestamp', columns: {#timestamp}),
    TableIndex(name: 'idx_tx_ledger_type', columns: {#ledgerType}),
    TableIndex(
      name: 'idx_tx_book_timestamp',
      columns: {#bookId, #timestamp},
    ),
    TableIndex(
      name: 'idx_tx_book_deleted',
      columns: {#bookId, #isDeleted},
    ),
  ];
}
```

Modify `lib/data/app_database.dart` — add Transactions:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables/audit_logs_table.dart';
import 'tables/books_table.dart';
import 'tables/categories_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [AuditLogs, Books, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/data/tables/transactions_table_test.dart`
Expected: PASS (4 tests)

**Step 5: Run ALL tests**

Run: `flutter test --concurrency=1`
Expected: ALL tests pass

**Step 6: Commit**

```bash
git add lib/data/tables/transactions_table.dart lib/data/app_database.dart \
        test/unit/data/tables/transactions_table_test.dart
git commit -m "feat: add Transactions Drift table with compound indexes"
```

---

## Task 8: BookDao

**Files:**
- Create: `lib/data/daos/book_dao.dart`
- Test: `test/unit/data/daos/book_dao_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/daos/book_dao_test.dart`:

```dart
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

  tearDown(() async {
    await db.close();
  });

  group('BookDao', () {
    test('insertBook and findById', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      final book = await dao.findById('book_001');
      expect(book, isNotNull);
      expect(book!.name, 'My Book');
      expect(book.currency, 'JPY');
    });

    test('findById returns null for non-existent', () async {
      final book = await dao.findById('no_such_book');
      expect(book, isNull);
    });

    test('findAll returns all non-archived books', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'Active Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      await dao.insertBook(
        id: 'book_002',
        name: 'Archived Book',
        currency: 'USD',
        deviceId: 'dev_001',
        createdAt: now,
        isArchived: true,
      );

      final active = await dao.findAll(includeArchived: false);
      expect(active.length, 1);
      expect(active.first.name, 'Active Book');

      final all = await dao.findAll(includeArchived: true);
      expect(all.length, 2);
    });

    test('updateBook modifies fields', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'Old Name',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      await dao.updateBook(
        id: 'book_001',
        name: 'New Name',
        updatedAt: DateTime(2026, 2, 7),
      );

      final book = await dao.findById('book_001');
      expect(book!.name, 'New Name');
      expect(book.updatedAt, isNotNull);
    });

    test('archiveBook sets isArchived flag', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      await dao.archiveBook('book_001');

      final book = await dao.findById('book_001');
      expect(book!.isArchived, true);
    });

    test('updateBalances modifies stats', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBook(
        id: 'book_001',
        name: 'Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: now,
      );

      await dao.updateBalances(
        bookId: 'book_001',
        transactionCount: 10,
        survivalBalance: 50000,
        soulBalance: 20000,
      );

      final book = await dao.findById('book_001');
      expect(book!.transactionCount, 10);
      expect(book.survivalBalance, 50000);
      expect(book.soulBalance, 20000);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/daos/book_dao_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/data/daos/book_dao.dart`:

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/books_table.dart';

/// Data access object for the [Books] table.
///
/// Provides typed CRUD operations for book records.
/// Does NOT handle encryption or domain model conversion —
/// that responsibility belongs to the repository layer.
class BookDao {
  BookDao(this._db);

  final AppDatabase _db;

  Future<void> insertBook({
    required String id,
    required String name,
    required String currency,
    required String deviceId,
    required DateTime createdAt,
    bool isArchived = false,
  }) async {
    await _db.into(_db.books).insert(
      BooksCompanion.insert(
        id: id,
        name: name,
        currency: currency,
        deviceId: deviceId,
        createdAt: createdAt,
        isArchived: Value(isArchived),
      ),
    );
  }

  Future<BookRow?> findById(String id) async {
    return (
      _db.select(_db.books)..where((t) => t.id.equals(id))
    ).getSingleOrNull();
  }

  Future<List<BookRow>> findAll({bool includeArchived = false}) async {
    final query = _db.select(_db.books);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  Future<void> updateBook({
    required String id,
    String? name,
    String? currency,
    bool? isArchived,
    DateTime? updatedAt,
  }) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        currency:
            currency != null ? Value(currency) : const Value.absent(),
        isArchived:
            isArchived != null ? Value(isArchived) : const Value.absent(),
        updatedAt:
            updatedAt != null ? Value(updatedAt) : const Value.absent(),
      ),
    );
  }

  Future<void> archiveBook(String id) async {
    await updateBook(
      id: id,
      isArchived: true,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> updateBalances({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  }) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(bookId)))
        .write(
      BooksCompanion(
        transactionCount: Value(transactionCount),
        survivalBalance: Value(survivalBalance),
        soulBalance: Value(soulBalance),
      ),
    );
  }
}
```

**Step 4: Run test**

Run: `flutter test test/unit/data/daos/book_dao_test.dart`
Expected: PASS (6 tests)

**Step 5: Commit**

```bash
git add lib/data/daos/book_dao.dart test/unit/data/daos/book_dao_test.dart
git commit -m "feat: add BookDao with CRUD operations"
```

---

## Task 9: CategoryDao

**Files:**
- Create: `lib/data/daos/category_dao.dart`
- Test: `test/unit/data/daos/category_dao_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/daos/category_dao_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao', () {
    test('insertCategory and findById', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        isSystem: true,
        sortOrder: 1,
        createdAt: now,
      );

      final cat = await dao.findById('cat_food');
      expect(cat, isNotNull);
      expect(cat!.name, 'Food');
      expect(cat.isSystem, true);
    });

    test('findByLevel returns categories at specific depth', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: 'expense',
        createdAt: now,
      );

      final level1 = await dao.findByLevel(1);
      expect(level1.length, 1);
      expect(level1.first.name, 'Food');
    });

    test('findByParent returns child categories', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: 'expense',
        sortOrder: 1,
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food_lunch',
        name: 'Lunch',
        icon: 'lunch_dining',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: 'expense',
        sortOrder: 2,
        createdAt: now,
      );

      final children = await dao.findByParent('cat_food');
      expect(children.length, 2);
      expect(children.first.name, 'Breakfast'); // sortOrder 1
    });

    test('findAll returns all categories ordered by sortOrder', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_transport',
        name: 'Transport',
        icon: 'car',
        color: '#2196F3',
        level: 1,
        type: 'expense',
        sortOrder: 2,
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        sortOrder: 1,
        createdAt: now,
      );

      final all = await dao.findAll();
      expect(all.length, 2);
      expect(all.first.name, 'Food'); // sortOrder 1
    });

    test('findByType returns only expense or income categories', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertCategory(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: 'expense',
        createdAt: now,
      );

      await dao.insertCategory(
        id: 'cat_salary',
        name: 'Salary',
        icon: 'payments',
        color: '#4CAF50',
        level: 1,
        type: 'income',
        createdAt: now,
      );

      final expense = await dao.findByType('expense');
      expect(expense.length, 1);
      expect(expense.first.name, 'Food');
    });

    test('insertBatch inserts multiple categories', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertBatch([
        CategoryInsertData(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: 'expense',
          isSystem: true,
          sortOrder: 1,
          createdAt: now,
        ),
        CategoryInsertData(
          id: 'cat_transport',
          name: 'Transport',
          icon: 'car',
          color: '#2196F3',
          level: 1,
          type: 'expense',
          isSystem: true,
          sortOrder: 2,
          createdAt: now,
        ),
      ]);

      final all = await dao.findAll();
      expect(all.length, 2);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/daos/category_dao_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/data/daos/category_dao.dart`:

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

/// Parameter object for batch category insertion.
class CategoryInsertData {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? parentId;
  final int level;
  final String type;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;

  const CategoryInsertData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.parentId,
    required this.level,
    required this.type,
    this.isSystem = false,
    this.sortOrder = 0,
    required this.createdAt,
  });
}

/// Data access object for the [Categories] table.
class CategoryDao {
  CategoryDao(this._db);

  final AppDatabase _db;

  Future<void> insertCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
    String? parentId,
    required int level,
    required String type,
    bool isSystem = false,
    int sortOrder = 0,
    required DateTime createdAt,
  }) async {
    await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        id: id,
        name: name,
        icon: icon,
        color: color,
        parentId: Value(parentId),
        level: level,
        type: type,
        isSystem: Value(isSystem),
        sortOrder: Value(sortOrder),
        createdAt: createdAt,
      ),
    );
  }

  Future<CategoryRow?> findById(String id) async {
    return (_db.select(_db.categories)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<CategoryRow>> findAll() async {
    return (_db.select(_db.categories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<CategoryRow>> findByLevel(int level) async {
    return (_db.select(_db.categories)
          ..where((t) => t.level.equals(level))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<CategoryRow>> findByParent(String parentId) async {
    return (_db.select(_db.categories)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<CategoryRow>> findByType(String type) async {
    return (_db.select(_db.categories)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<void> insertBatch(List<CategoryInsertData> categories) async {
    await _db.batch((batch) {
      for (final cat in categories) {
        batch.insert(
          _db.categories,
          CategoriesCompanion.insert(
            id: cat.id,
            name: cat.name,
            icon: cat.icon,
            color: cat.color,
            parentId: Value(cat.parentId),
            level: cat.level,
            type: cat.type,
            isSystem: Value(cat.isSystem),
            sortOrder: Value(cat.sortOrder),
            createdAt: cat.createdAt,
          ),
        );
      }
    });
  }
}
```

**Step 4: Run test**

Run: `flutter test test/unit/data/daos/category_dao_test.dart`
Expected: PASS (6 tests)

**Step 5: Commit**

```bash
git add lib/data/daos/category_dao.dart test/unit/data/daos/category_dao_test.dart
git commit -m "feat: add CategoryDao with hierarchy and batch operations"
```

---

## Task 10: TransactionDao

**Files:**
- Create: `lib/data/daos/transaction_dao.dart`
- Test: `test/unit/data/daos/transaction_dao_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/daos/transaction_dao_test.dart`:

```dart
import 'package:drift/drift.dart';
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
    test('insertTransaction and findById', () async {
      final now = DateTime(2026, 2, 6, 10, 0);

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
      );

      final tx = await dao.findById('tx_001');
      expect(tx, isNotNull);
      expect(tx!.amount, 10000);
      expect(tx.type, 'expense');
    });

    test('findByBookId returns transactions ordered by timestamp desc', () async {
      final t1 = DateTime(2026, 2, 5, 10, 0);
      final t2 = DateTime(2026, 2, 6, 10, 0);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: t1,
        currentHash: 'h1',
        createdAt: t1,
      );

      await dao.insertTransaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: 'income',
        categoryId: 'cat_salary',
        ledgerType: 'survival',
        timestamp: t2,
        currentHash: 'h2',
        createdAt: t2,
      );

      final results = await dao.findByBookId('book_001');
      expect(results.length, 2);
      expect(results.first.id, 'tx_002'); // newer first
    });

    test('findByBookId excludes soft-deleted', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: now,
        currentHash: 'h1',
        createdAt: now,
      );

      await dao.softDelete('tx_001');

      final results = await dao.findByBookId('book_001');
      expect(results.length, 0);
    });

    test('findByBookId with filters', () async {
      final t1 = DateTime(2026, 2, 1);
      final t2 = DateTime(2026, 2, 15);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: t1,
        currentHash: 'h1',
        createdAt: t1,
      );

      await dao.insertTransaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: 'expense',
        categoryId: 'cat_transport',
        ledgerType: 'soul',
        timestamp: t2,
        currentHash: 'h2',
        createdAt: t2,
      );

      // Filter by ledger type
      final soul = await dao.findByBookId(
        'book_001',
        ledgerType: 'soul',
      );
      expect(soul.length, 1);
      expect(soul.first.id, 'tx_002');

      // Filter by date range
      final feb = await dao.findByBookId(
        'book_001',
        startDate: DateTime(2026, 2, 10),
        endDate: DateTime(2026, 2, 20),
      );
      expect(feb.length, 1);
      expect(feb.first.id, 'tx_002');
    });

    test('findByBookId supports pagination', () async {
      final now = DateTime(2026, 2, 6);

      for (int i = 0; i < 5; i++) {
        await dao.insertTransaction(
          id: 'tx_00$i',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: (i + 1) * 1000,
          type: 'expense',
          categoryId: 'cat_food',
          ledgerType: 'survival',
          timestamp: now.add(Duration(hours: i)),
          currentHash: 'h$i',
          createdAt: now,
        );
      }

      final page1 = await dao.findByBookId('book_001', limit: 2, offset: 0);
      expect(page1.length, 2);

      final page2 = await dao.findByBookId('book_001', limit: 2, offset: 2);
      expect(page2.length, 2);

      final page3 = await dao.findByBookId('book_001', limit: 2, offset: 4);
      expect(page3.length, 1);
    });

    test('getLatestHash returns most recent transaction hash', () async {
      final t1 = DateTime(2026, 2, 5);
      final t2 = DateTime(2026, 2, 6);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: t1,
        currentHash: 'first_hash',
        createdAt: t1,
      );

      await dao.insertTransaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: t2,
        currentHash: 'latest_hash',
        createdAt: t2,
        prevHash: 'first_hash',
      );

      final hash = await dao.getLatestHash('book_001');
      expect(hash, 'latest_hash');
    });

    test('getLatestHash returns null for empty book', () async {
      final hash = await dao.getLatestHash('no_book');
      expect(hash, isNull);
    });

    test('countByBookId counts non-deleted transactions', () async {
      final now = DateTime(2026, 2, 6);

      await dao.insertTransaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: now,
        currentHash: 'h1',
        createdAt: now,
      );

      await dao.insertTransaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: 'expense',
        categoryId: 'cat_food',
        ledgerType: 'survival',
        timestamp: now,
        currentHash: 'h2',
        createdAt: now,
      );

      await dao.softDelete('tx_002');

      final count = await dao.countByBookId('book_001');
      expect(count, 1);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/daos/transaction_dao_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/data/daos/transaction_dao.dart`:

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transactions_table.dart';

/// Data access object for the [Transactions] table.
///
/// Provides raw CRUD and query operations.
/// Does NOT handle encryption/decryption or domain model
/// conversion — that belongs in the repository layer.
class TransactionDao {
  TransactionDao(this._db);

  final AppDatabase _db;

  Future<void> insertTransaction({
    required String id,
    required String bookId,
    required String deviceId,
    required int amount,
    required String type,
    required String categoryId,
    required String ledgerType,
    required DateTime timestamp,
    required String currentHash,
    required DateTime createdAt,
    String? note,
    String? photoHash,
    String? merchant,
    String? metadata,
    String? prevHash,
    bool isPrivate = false,
  }) async {
    await _db.into(_db.transactions).insert(
      TransactionsCompanion.insert(
        id: id,
        bookId: bookId,
        deviceId: deviceId,
        amount: amount,
        type: type,
        categoryId: categoryId,
        ledgerType: ledgerType,
        timestamp: timestamp,
        currentHash: currentHash,
        createdAt: createdAt,
        note: Value(note),
        photoHash: Value(photoHash),
        merchant: Value(merchant),
        metadata: Value(metadata),
        prevHash: Value(prevHash),
        isPrivate: Value(isPrivate),
      ),
    );
  }

  Future<TransactionRow?> findById(String id) async {
    return (_db.select(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Query transactions for a book with optional filters.
  ///
  /// Results are ordered newest-first by timestamp, then by id (ULID tiebreaker).
  /// Soft-deleted transactions are excluded by default.
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
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    if (startDate != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.timestamp.isSmallerOrEqualValue(endDate));
    }

    return query.get();
  }

  /// Get the hash of the most recent transaction in a book.
  ///
  /// Returns null if the book has no transactions.
  /// Used to build the hash chain when inserting new transactions.
  Future<String?> getLatestHash(String bookId) async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.bookId.equals(bookId))
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([
        (t) => OrderingTerm.desc(t.timestamp),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.currentHash;
  }

  /// Soft-delete a transaction.
  Future<void> softDelete(String id) async {
    await (_db.update(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Count non-deleted transactions in a book.
  Future<int> countByBookId(String bookId) async {
    final countExp = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([countExp])
      ..where(_db.transactions.bookId.equals(bookId))
      ..where(_db.transactions.isDeleted.equals(false));

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
```

**Step 4: Run test**

Run: `flutter test test/unit/data/daos/transaction_dao_test.dart`
Expected: PASS (9 tests)

**Step 5: Run ALL tests**

Run: `flutter test --concurrency=1`
Expected: ALL pass

**Step 6: Commit**

```bash
git add lib/data/daos/transaction_dao.dart test/unit/data/daos/transaction_dao_test.dart
git commit -m "feat: add TransactionDao with filtering, pagination, hash chain"
```

---

## Task 11: Repository Interfaces

**Files:**
- Create: `lib/features/accounting/domain/repositories/transaction_repository.dart`
- Create: `lib/features/accounting/domain/repositories/category_repository.dart`
- Create: `lib/features/accounting/domain/repositories/book_repository.dart`

These are abstract interfaces — no tests needed for interfaces themselves.

**Step 1: Create TransactionRepository interface**

Create `lib/features/accounting/domain/repositories/transaction_repository.dart`:

```dart
import '../models/transaction.dart';

/// Abstract repository interface for transaction data access.
///
/// Implementations handle encryption, hash chain computation,
/// and database operations. Defined in domain layer so application
/// layer can depend on this interface without knowing the data layer.
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
  Future<String?> getLatestHash(String bookId);
  Future<int> countByBookId(String bookId);
}
```

**Step 2: Create CategoryRepository interface**

Create `lib/features/accounting/domain/repositories/category_repository.dart`:

```dart
import '../models/category.dart';
import '../models/transaction.dart';

/// Abstract repository interface for category data access.
abstract class CategoryRepository {
  Future<void> insert(Category category);
  Future<Category?> findById(String id);
  Future<List<Category>> findAll();
  Future<List<Category>> findByLevel(int level);
  Future<List<Category>> findByParent(String parentId);
  Future<List<Category>> findByType(TransactionType type);
  Future<void> insertBatch(List<Category> categories);
}
```

**Step 3: Create BookRepository interface**

Create `lib/features/accounting/domain/repositories/book_repository.dart`:

```dart
import '../models/book.dart';

/// Abstract repository interface for book data access.
abstract class BookRepository {
  Future<void> insert(Book book);
  Future<Book?> findById(String id);
  Future<List<Book>> findAll({bool includeArchived});
  Future<void> update(Book book);
  Future<void> archive(String id);
  Future<void> updateBalances({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  });
}
```

**Step 4: Run analyzer**

Run: `flutter analyze`
Expected: No issues

**Step 5: Commit**

```bash
git add lib/features/accounting/domain/repositories/
git commit -m "feat: add repository interfaces for Transaction, Category, Book"
```

---

## Task 12: BookRepositoryImpl

**Files:**
- Create: `lib/data/repositories/book_repository_impl.dart`
- Test: `test/unit/data/repositories/book_repository_impl_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/repositories/book_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';

void main() {
  late AppDatabase db;
  late BookDao dao;
  late BookRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = BookDao(db);
    repo = BookRepositoryImpl(dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('BookRepositoryImpl', () {
    test('insert and findById', () async {
      final book = Book(
        id: 'book_001',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: DateTime(2026, 2, 6),
      );

      await repo.insert(book);

      final found = await repo.findById('book_001');
      expect(found, isNotNull);
      expect(found!.name, 'My Book');
      expect(found.currency, 'JPY');
      expect(found.deviceId, 'dev_001');
    });

    test('findAll excludes archived by default', () async {
      await repo.insert(Book(
        id: 'book_001',
        name: 'Active',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.insert(Book(
        id: 'book_002',
        name: 'Archived',
        currency: 'USD',
        deviceId: 'dev_001',
        createdAt: DateTime(2026, 2, 6),
        isArchived: true,
      ));

      final active = await repo.findAll();
      expect(active.length, 1);
      expect(active.first.name, 'Active');

      final all = await repo.findAll(includeArchived: true);
      expect(all.length, 2);
    });

    test('update modifies book fields', () async {
      await repo.insert(Book(
        id: 'book_001',
        name: 'Old Name',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: DateTime(2026, 2, 6),
      ));

      final book = (await repo.findById('book_001'))!;
      final updated = book.copyWith(name: 'New Name');
      await repo.update(updated);

      final found = await repo.findById('book_001');
      expect(found!.name, 'New Name');
    });

    test('archive sets isArchived flag', () async {
      await repo.insert(Book(
        id: 'book_001',
        name: 'Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.archive('book_001');

      final book = await repo.findById('book_001');
      expect(book!.isArchived, true);
    });

    test('updateBalances modifies stats', () async {
      await repo.insert(Book(
        id: 'book_001',
        name: 'Book',
        currency: 'JPY',
        deviceId: 'dev_001',
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.updateBalances(
        bookId: 'book_001',
        transactionCount: 42,
        survivalBalance: 100000,
        soulBalance: 50000,
      );

      final book = await repo.findById('book_001');
      expect(book!.transactionCount, 42);
      expect(book.survivalBalance, 100000);
      expect(book.soulBalance, 50000);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/repositories/book_repository_impl_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/data/repositories/book_repository_impl.dart`:

```dart
import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../daos/book_dao.dart';
import '../app_database.dart';

/// Concrete implementation of [BookRepository].
///
/// Converts between domain [Book] model and Drift [BookRow] entities.
/// No encryption needed for book data.
class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl({required BookDao dao}) : _dao = dao;

  final BookDao _dao;

  @override
  Future<void> insert(Book book) async {
    await _dao.insertBook(
      id: book.id,
      name: book.name,
      currency: book.currency,
      deviceId: book.deviceId,
      createdAt: book.createdAt,
      isArchived: book.isArchived,
    );
  }

  @override
  Future<Book?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<Book>> findAll({bool includeArchived = false}) async {
    final rows = await _dao.findAll(includeArchived: includeArchived);
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> update(Book book) async {
    await _dao.updateBook(
      id: book.id,
      name: book.name,
      currency: book.currency,
      isArchived: book.isArchived,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> archive(String id) async {
    await _dao.archiveBook(id);
  }

  @override
  Future<void> updateBalances({
    required String bookId,
    required int transactionCount,
    required int survivalBalance,
    required int soulBalance,
  }) async {
    await _dao.updateBalances(
      bookId: bookId,
      transactionCount: transactionCount,
      survivalBalance: survivalBalance,
      soulBalance: soulBalance,
    );
  }

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
    );
  }
}
```

**Step 4: Run test**

Run: `flutter test test/unit/data/repositories/book_repository_impl_test.dart`
Expected: PASS (5 tests)

**Step 5: Commit**

```bash
git add lib/data/repositories/book_repository_impl.dart \
        test/unit/data/repositories/book_repository_impl_test.dart
git commit -m "feat: add BookRepositoryImpl with domain model conversion"
```

---

## Task 13: CategoryRepositoryImpl

**Files:**
- Create: `lib/data/repositories/category_repository_impl.dart`
- Test: `test/unit/data/repositories/category_repository_impl_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/repositories/category_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;
  late CategoryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = CategoryDao(db);
    repo = CategoryRepositoryImpl(dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepositoryImpl', () {
    test('insert and findById', () async {
      final cat = Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime(2026, 2, 6),
      );

      await repo.insert(cat);

      final found = await repo.findById('cat_food');
      expect(found, isNotNull);
      expect(found!.name, 'Food');
      expect(found.isSystem, true);
      expect(found.type, TransactionType.expense);
    });

    test('findByLevel returns level-1 categories', () async {
      await repo.insert(Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.insert(Category(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: TransactionType.expense,
        createdAt: DateTime(2026, 2, 6),
      ));

      final level1 = await repo.findByLevel(1);
      expect(level1.length, 1);
      expect(level1.first.name, 'Food');
    });

    test('findByParent returns child categories', () async {
      await repo.insert(Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.insert(Category(
        id: 'cat_food_breakfast',
        name: 'Breakfast',
        icon: 'free_breakfast',
        color: '#FF5722',
        parentId: 'cat_food',
        level: 2,
        type: TransactionType.expense,
        createdAt: DateTime(2026, 2, 6),
      ));

      final children = await repo.findByParent('cat_food');
      expect(children.length, 1);
      expect(children.first.name, 'Breakfast');
    });

    test('findByType returns expense-only categories', () async {
      await repo.insert(Category(
        id: 'cat_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.insert(Category(
        id: 'cat_salary',
        name: 'Salary',
        icon: 'payments',
        color: '#4CAF50',
        level: 1,
        type: TransactionType.income,
        createdAt: DateTime(2026, 2, 6),
      ));

      final expense = await repo.findByType(TransactionType.expense);
      expect(expense.length, 1);
      expect(expense.first.name, 'Food');
    });

    test('insertBatch inserts multiple categories', () async {
      final cats = [
        Category(
          id: 'cat_food',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          createdAt: DateTime(2026, 2, 6),
        ),
        Category(
          id: 'cat_transport',
          name: 'Transport',
          icon: 'car',
          color: '#2196F3',
          level: 1,
          type: TransactionType.expense,
          isSystem: true,
          createdAt: DateTime(2026, 2, 6),
        ),
      ];

      await repo.insertBatch(cats);

      final all = await repo.findAll();
      expect(all.length, 2);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/repositories/category_repository_impl_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/data/repositories/category_repository_impl.dart`:

```dart
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../daos/category_dao.dart';
import '../app_database.dart';

/// Concrete implementation of [CategoryRepository].
///
/// Converts between domain [Category] model and Drift [CategoryRow].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required CategoryDao dao}) : _dao = dao;

  final CategoryDao _dao;

  @override
  Future<void> insert(Category category) async {
    await _dao.insertCategory(
      id: category.id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      parentId: category.parentId,
      level: category.level,
      type: category.type.name,
      isSystem: category.isSystem,
      sortOrder: category.sortOrder,
      createdAt: category.createdAt,
    );
  }

  @override
  Future<Category?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toModel(row);
  }

  @override
  Future<List<Category>> findAll() async {
    final rows = await _dao.findAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findByLevel(int level) async {
    final rows = await _dao.findByLevel(level);
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findByParent(String parentId) async {
    final rows = await _dao.findByParent(parentId);
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<Category>> findByType(TransactionType type) async {
    final rows = await _dao.findByType(type.name);
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> insertBatch(List<Category> categories) async {
    await _dao.insertBatch(
      categories
          .map(
            (c) => CategoryInsertData(
              id: c.id,
              name: c.name,
              icon: c.icon,
              color: c.color,
              parentId: c.parentId,
              level: c.level,
              type: c.type.name,
              isSystem: c.isSystem,
              sortOrder: c.sortOrder,
              createdAt: c.createdAt,
            ),
          )
          .toList(),
    );
  }

  Category _toModel(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      parentId: row.parentId,
      level: row.level,
      type: TransactionType.values.firstWhere(
        (e) => e.name == row.type,
      ),
      isSystem: row.isSystem,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
    );
  }
}
```

**Step 4: Run test**

Run: `flutter test test/unit/data/repositories/category_repository_impl_test.dart`
Expected: PASS (5 tests)

**Step 5: Commit**

```bash
git add lib/data/repositories/category_repository_impl.dart \
        test/unit/data/repositories/category_repository_impl_test.dart
git commit -m "feat: add CategoryRepositoryImpl with hierarchy support"
```

---

## Task 14: TransactionRepositoryImpl

This is the most complex repository — it integrates field encryption and hash chain.

**Files:**
- Create: `lib/data/repositories/transaction_repository_impl.dart`
- Test: `test/unit/data/repositories/transaction_repository_impl_test.dart`

**Step 1: Write the failing test**

Create `test/unit/data/repositories/transaction_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FieldEncryptionService])
import 'transaction_repository_impl_test.mocks.dart';

void main() {
  late AppDatabase db;
  late TransactionDao dao;
  late MockFieldEncryptionService mockEncryption;
  late HashChainService hashChainService;
  late TransactionRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = TransactionDao(db);
    mockEncryption = MockFieldEncryptionService();
    hashChainService = HashChainService();
    repo = TransactionRepositoryImpl(
      dao: dao,
      encryptionService: mockEncryption,
      hashChainService: hashChainService,
    );

    // Default: encryption passthrough
    when(mockEncryption.encryptField(any))
        .thenAnswer((inv) async => 'enc_${inv.positionalArguments[0]}');
    when(mockEncryption.decryptField(any))
        .thenAnswer((inv) async {
          final cipher = inv.positionalArguments[0] as String;
          return cipher.replaceFirst('enc_', '');
        });
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionRepositoryImpl', () {
    test('insert stores transaction with encrypted note', () async {
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6, 10, 0),
        note: 'Lunch at cafe',
        currentHash: 'hash_abc',
        createdAt: DateTime(2026, 2, 6, 10, 0),
      );

      await repo.insert(tx);

      // Verify encryption was called
      verify(mockEncryption.encryptField('Lunch at cafe')).called(1);

      // Verify data was stored
      final row = await dao.findById('tx_001');
      expect(row, isNotNull);
      expect(row!.note, 'enc_Lunch at cafe');
    });

    test('insert stores transaction without note (no encryption call)', () async {
      final tx = Transaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 5000,
        type: TransactionType.income,
        categoryId: 'cat_salary',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6),
        currentHash: 'hash_xyz',
        createdAt: DateTime(2026, 2, 6),
      );

      await repo.insert(tx);

      verifyNever(mockEncryption.encryptField(any));

      final row = await dao.findById('tx_002');
      expect(row!.note, isNull);
    });

    test('findById decrypts note', () async {
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6, 10, 0),
        note: 'Lunch at cafe',
        currentHash: 'hash_abc',
        createdAt: DateTime(2026, 2, 6, 10, 0),
      );

      await repo.insert(tx);

      final found = await repo.findById('tx_001');
      expect(found, isNotNull);
      expect(found!.note, 'Lunch at cafe'); // decrypted
      verify(mockEncryption.decryptField('enc_Lunch at cafe')).called(1);
    });

    test('findByBookId returns sorted, decrypted transactions', () async {
      final t1 = DateTime(2026, 2, 5, 10, 0);
      final t2 = DateTime(2026, 2, 6, 10, 0);

      await repo.insert(Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: t1,
        currentHash: 'h1',
        createdAt: t1,
      ));

      await repo.insert(Transaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: TransactionType.income,
        categoryId: 'cat_salary',
        ledgerType: LedgerType.survival,
        timestamp: t2,
        note: 'Salary',
        currentHash: 'h2',
        createdAt: t2,
      ));

      final results = await repo.findByBookId('book_001');
      expect(results.length, 2);
      expect(results.first.id, 'tx_002'); // newer first
      expect(results.first.note, 'Salary'); // decrypted
    });

    test('softDelete marks transaction as deleted', () async {
      await repo.insert(Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6),
        currentHash: 'h1',
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.softDelete('tx_001');

      final results = await repo.findByBookId('book_001');
      expect(results.length, 0);
    });

    test('getLatestHash delegates to dao', () async {
      await repo.insert(Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6),
        currentHash: 'latest_hash_value',
        createdAt: DateTime(2026, 2, 6),
      ));

      final hash = await repo.getLatestHash('book_001');
      expect(hash, 'latest_hash_value');
    });

    test('countByBookId returns count of non-deleted', () async {
      await repo.insert(Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 1000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6),
        currentHash: 'h1',
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.insert(Transaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 2000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6),
        currentHash: 'h2',
        createdAt: DateTime(2026, 2, 6),
      ));

      await repo.softDelete('tx_002');

      final count = await repo.countByBookId('book_001');
      expect(count, 1);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/data/repositories/transaction_repository_impl_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/data/repositories/transaction_repository_impl.dart`:

```dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../infrastructure/crypto/services/field_encryption_service.dart';
import '../../infrastructure/crypto/services/hash_chain_service.dart';
import '../daos/transaction_dao.dart';
import '../app_database.dart';

/// Concrete implementation of [TransactionRepository].
///
/// Handles:
/// - Encrypting/decrypting the `note` field via [FieldEncryptionService]
/// - Converting between domain [Transaction] and Drift [TransactionRow]
/// - Delegating to [TransactionDao] for raw database operations
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required TransactionDao dao,
    required FieldEncryptionService encryptionService,
    required HashChainService hashChainService,
  })  : _dao = dao,
        _encryptionService = encryptionService,
        _hashChainService = hashChainService;

  final TransactionDao _dao;
  final FieldEncryptionService _encryptionService;
  final HashChainService _hashChainService;

  @override
  Future<void> insert(Transaction transaction) async {
    String? encryptedNote;
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      encryptedNote = await _encryptionService.encryptField(transaction.note!);
    }

    await _dao.insertTransaction(
      id: transaction.id,
      bookId: transaction.bookId,
      deviceId: transaction.deviceId,
      amount: transaction.amount,
      type: transaction.type.name,
      categoryId: transaction.categoryId,
      ledgerType: transaction.ledgerType.name,
      timestamp: transaction.timestamp,
      currentHash: transaction.currentHash,
      createdAt: transaction.createdAt,
      note: encryptedNote,
      photoHash: transaction.photoHash,
      merchant: transaction.merchant,
      prevHash: transaction.prevHash,
      isPrivate: transaction.isPrivate,
    );
  }

  @override
  Future<Transaction?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toModel(row);
  }

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

    return Future.wait(rows.map(_toModel));
  }

  @override
  Future<void> update(Transaction transaction) async {
    // For update, we soft-delete the old and insert a new version
    // This preserves hash chain integrity.
    // In MVP, we use a simpler approach: just update the row.
    String? encryptedNote;
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      encryptedNote = await _encryptionService.encryptField(transaction.note!);
    }

    // Re-insert with updated data (actual update logic can be refined later)
    await _dao.softDelete(transaction.id);
    await _dao.insertTransaction(
      id: transaction.id,
      bookId: transaction.bookId,
      deviceId: transaction.deviceId,
      amount: transaction.amount,
      type: transaction.type.name,
      categoryId: transaction.categoryId,
      ledgerType: transaction.ledgerType.name,
      timestamp: transaction.timestamp,
      currentHash: transaction.currentHash,
      createdAt: transaction.createdAt,
      note: encryptedNote,
      photoHash: transaction.photoHash,
      merchant: transaction.merchant,
      prevHash: transaction.prevHash,
      isPrivate: transaction.isPrivate,
    );
  }

  @override
  Future<void> softDelete(String id) => _dao.softDelete(id);

  @override
  Future<String?> getLatestHash(String bookId) => _dao.getLatestHash(bookId);

  @override
  Future<int> countByBookId(String bookId) => _dao.countByBookId(bookId);

  Future<Transaction> _toModel(TransactionRow row) async {
    String? decryptedNote;
    if (row.note != null && row.note!.isNotEmpty) {
      decryptedNote = await _encryptionService.decryptField(row.note!);
    }

    return Transaction(
      id: row.id,
      bookId: row.bookId,
      deviceId: row.deviceId,
      amount: row.amount,
      type: TransactionType.values.firstWhere((e) => e.name == row.type),
      categoryId: row.categoryId,
      ledgerType: LedgerType.values.firstWhere((e) => e.name == row.ledgerType),
      timestamp: row.timestamp,
      note: decryptedNote,
      photoHash: row.photoHash,
      merchant: row.merchant,
      prevHash: row.prevHash,
      currentHash: row.currentHash,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isPrivate: row.isPrivate,
      isSynced: row.isSynced,
      isDeleted: row.isDeleted,
    );
  }
}
```

**Step 4: Run code generation (for mocks) then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/data/repositories/transaction_repository_impl_test.dart`
Expected: PASS (7 tests)

**Step 5: Run ALL tests**

Run: `flutter test --concurrency=1`
Expected: ALL pass

**Step 6: Commit**

```bash
git add lib/data/repositories/transaction_repository_impl.dart \
        test/unit/data/repositories/transaction_repository_impl_test.dart \
        test/unit/data/repositories/transaction_repository_impl_test.mocks.dart
git commit -m "feat: add TransactionRepositoryImpl with encryption integration"
```

---

## Task 15: Repository Providers

**Files:**
- Create: `lib/features/accounting/presentation/providers/repository_providers.dart`
- Test: Static analysis only (providers require platform channels for runtime test)

**Step 1: Write the providers**

Create `lib/features/accounting/presentation/providers/repository_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/daos/book_dao.dart';
import '../../../../data/daos/category_dao.dart';
import '../../../../data/daos/transaction_dao.dart';
import '../../../../data/repositories/book_repository_impl.dart';
import '../../../../data/repositories/category_repository_impl.dart';
import '../../../../data/repositories/transaction_repository_impl.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../infrastructure/security/providers.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

part 'repository_providers.g.dart';

/// BookRepository provider.
@riverpod
BookRepository bookRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = BookDao(database);
  return BookRepositoryImpl(dao: dao);
}

/// CategoryRepository provider.
@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = CategoryDao(database);
  return CategoryRepositoryImpl(dao: dao);
}

/// TransactionRepository provider.
@riverpod
TransactionRepository transactionRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = TransactionDao(database);
  final encryptionService = ref.watch(fieldEncryptionServiceProvider);
  final hashChainService = ref.watch(hashChainServiceProvider);

  return TransactionRepositoryImpl(
    dao: dao,
    encryptionService: encryptionService,
    hashChainService: hashChainService,
  );
}
```

**Step 2: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates `repository_providers.g.dart`

**Step 3: Run analyzer**

Run: `flutter analyze`
Expected: No issues

**Step 4: Run ALL tests to verify nothing broke**

Run: `flutter test --concurrency=1`
Expected: ALL pass

**Step 5: Commit**

```bash
git add lib/features/accounting/presentation/providers/repository_providers.dart \
        lib/features/accounting/presentation/providers/repository_providers.g.dart
git commit -m "feat: add Riverpod providers for accounting repositories"
```

---

## Task 16: Final Verification & Cleanup

**Step 1: Run full test suite**

Run: `flutter test --concurrency=1`
Expected: ALL tests pass (security 57 + crypto 65 + data infrastructure ~55 = ~177 total)

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found

**Step 3: Format code**

Run: `dart format lib/shared/ lib/features/accounting/ lib/data/ test/unit/shared/ test/unit/features/ test/unit/data/`

**Step 4: Verify directory structure**

Verify the "Thin Feature" pattern:
```
lib/features/accounting/
  domain/
    models/
      transaction.dart
      category.dart
      book.dart
    repositories/
      transaction_repository.dart   # abstract interface
      category_repository.dart      # abstract interface
      book_repository.dart          # abstract interface
  presentation/
    providers/
      repository_providers.dart     # Single source of truth

lib/data/
  tables/
    audit_logs_table.dart           # existing
    books_table.dart                # NEW
    categories_table.dart           # NEW
    transactions_table.dart         # NEW
  daos/
    book_dao.dart                   # NEW
    category_dao.dart               # NEW
    transaction_dao.dart            # NEW
  repositories/
    book_repository_impl.dart       # NEW
    category_repository_impl.dart   # NEW
    transaction_repository_impl.dart # NEW
  app_database.dart                 # MODIFIED (added 3 tables)

lib/shared/
  utils/
    result.dart                     # NEW
```

**Step 5: Commit final verification**

```bash
git add -A
git commit -m "chore: format and verify database infrastructure"
```

---

## Summary

| Task | Component | Tests | Files |
|------|-----------|-------|-------|
| 1 | Result utility | 3 | 2 |
| 2 | Transaction model | 5 | 2 (+gen) |
| 3 | Category model | 5 | 2 (+gen) |
| 4 | Book model | 4 | 2 (+gen) |
| 5 | Books table | 3 | 3 |
| 6 | Categories table | 3 | 3 |
| 7 | Transactions table | 4 | 3 |
| 8 | BookDao | 6 | 2 |
| 9 | CategoryDao | 6 | 2 |
| 10 | TransactionDao | 9 | 2 |
| 11 | Repository interfaces | 0 | 3 |
| 12 | BookRepositoryImpl | 5 | 2 |
| 13 | CategoryRepositoryImpl | 5 | 2 |
| 14 | TransactionRepositoryImpl | 7 | 2 (+mocks) |
| 15 | Repository providers | 0 | 2 (+gen) |
| 16 | Final verification | 0 | 0 |
| **Total** | | **~65** | **~35** |

**Dependencies on existing infrastructure:**
- `FieldEncryptionService` from `lib/infrastructure/crypto/services/`
- `HashChainService` from `lib/infrastructure/crypto/services/`
- `appDatabaseProvider` from `lib/infrastructure/security/providers.dart`
- `fieldEncryptionServiceProvider` from `lib/infrastructure/crypto/providers.dart`
- `hashChainServiceProvider` from `lib/infrastructure/crypto/providers.dart`
