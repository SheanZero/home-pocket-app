# Basic Accounting Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the basic accounting feature (MOD-001) — Use Cases, system categories, and a minimal UI that can add transactions and display the transaction list.

**Architecture:** Clean Architecture with "Thin Feature" pattern. Use Cases in `lib/application/accounting/`, Providers in `lib/features/accounting/presentation/providers/`, Screens/Widgets in `lib/features/accounting/presentation/screens/` and `widgets/`. The main.dart is replaced with a Riverpod-powered app using an in-memory database for development.

**Tech Stack:** Flutter, Riverpod (code-gen), Freezed, Drift (in-memory for dev), ULID, SHA-256 hash chain, Material 3

**Existing Infrastructure (already built):**
- `lib/shared/utils/result.dart` — `Result<T>` type
- `lib/features/accounting/domain/models/` — Transaction, Category, Book (Freezed)
- `lib/features/accounting/domain/repositories/` — TransactionRepository, CategoryRepository, BookRepository (abstract interfaces)
- `lib/data/tables/` — Books, Categories, Transactions (Drift tables)
- `lib/data/daos/` — BookDao, CategoryDao, TransactionDao
- `lib/data/repositories/` — BookRepositoryImpl, CategoryRepositoryImpl, TransactionRepositoryImpl
- `lib/features/accounting/presentation/providers/repository_providers.dart` — Riverpod wiring for all 3 repositories
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — `calculateTransactionHash()`, uses SHA-256
- `lib/infrastructure/crypto/services/field_encryption_service.dart` — `encryptField()`, `decryptField()`
- `lib/infrastructure/crypto/providers.dart` — `hashChainServiceProvider`, `fieldEncryptionServiceProvider`
- `lib/infrastructure/security/providers.dart` — `appDatabaseProvider` (placeholder, must be overridden)
- 188 tests passing, 0 analyzer issues

**Key API surfaces to use:**

```dart
// HashChainService.calculateTransactionHash
String calculateTransactionHash({
  required String transactionId,
  required double amount,      // NOTE: double, not int
  required int timestamp,       // seconds since epoch
  required String previousHash,
});

// TransactionRepository
Future<void> insert(Transaction transaction);
Future<List<Transaction>> findByBookId(String bookId, {LedgerType? ledgerType, ...});
Future<String?> getLatestHash(String bookId);
Future<void> softDelete(String id);

// CategoryRepository
Future<void> insertBatch(List<Category> categories);
Future<List<Category>> findAll();
Future<List<Category>> findByLevel(int level);
Future<List<Category>> findByType(TransactionType type);

// BookRepository
Future<void> insert(Book book);
Future<List<Book>> findAll({bool includeArchived});
```

**Design decisions:**
- Use `int` amount in domain model (cents/yen). HashChainService needs `double`, so convert: `amount.toDouble()`.
- `timestamp` for hash chain uses `DateTime.millisecondsSinceEpoch ~/ 1000` (seconds).
- `currentHash` is computed in the Use Case before inserting.
- `deviceId` defaults to `'dev_local'` until real SecureStorageService is wired.
- `ledgerType` defaults to `LedgerType.survival` (MOD-003 dual-ledger classification engine is out of scope).
- Category `name` for system categories stores localization keys. Since i18n ARB files aren't set up yet, we temporarily use plain Chinese strings for display and will migrate to keys later.
- For development, override `appDatabaseProvider` with an in-memory database in `main.dart`.

---

## Task 1: CreateTransactionUseCase

**Files:**
- Create: `lib/application/accounting/create_transaction_use_case.dart`
- Test: `test/unit/application/accounting/create_transaction_use_case_test.dart`

**Step 1: Write the failing test**

Create `test/unit/application/accounting/create_transaction_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TransactionRepository, CategoryRepository, HashChainService])
import 'create_transaction_use_case_test.mocks.dart';

void main() {
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockHashChainService mockHashChainService;
  late CreateTransactionUseCase useCase;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockHashChainService = MockHashChainService();

    useCase = CreateTransactionUseCase(
      transactionRepository: mockTransactionRepo,
      categoryRepository: mockCategoryRepo,
      hashChainService: mockHashChainService,
    );
  });

  group('CreateTransactionUseCase', () {
    final testCategory = Category(
      id: 'cat_food',
      name: 'Food',
      icon: 'restaurant',
      color: '#FF5722',
      level: 1,
      type: TransactionType.expense,
      isSystem: true,
      sortOrder: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    test('successfully creates a transaction with hash chain', () async {
      when(mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => testCategory);
      when(mockTransactionRepo.getLatestHash('book_001'))
          .thenAnswer((_) async => 'prev_hash_abc');
      when(mockHashChainService.calculateTransactionHash(
        transactionId: anyNamed('transactionId'),
        amount: anyNamed('amount'),
        timestamp: anyNamed('timestamp'),
        previousHash: anyNamed('previousHash'),
      )).thenReturn('computed_hash_xyz');
      when(mockTransactionRepo.insert(any)).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1500,
          type: TransactionType.expense,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.amount, 1500);
      expect(result.data!.categoryId, 'cat_food');
      expect(result.data!.currentHash, 'computed_hash_xyz');
      expect(result.data!.prevHash, 'prev_hash_abc');
      verify(mockTransactionRepo.insert(any)).called(1);
    });

    test('uses genesis hash when no previous transactions', () async {
      when(mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => testCategory);
      when(mockTransactionRepo.getLatestHash('book_001'))
          .thenAnswer((_) async => null);
      when(mockHashChainService.calculateTransactionHash(
        transactionId: anyNamed('transactionId'),
        amount: anyNamed('amount'),
        timestamp: anyNamed('timestamp'),
        previousHash: anyNamed('previousHash'),
      )).thenReturn('genesis_hash');
      when(mockTransactionRepo.insert(any)).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1000,
          type: TransactionType.income,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isSuccess, isTrue);
      verify(mockHashChainService.calculateTransactionHash(
        transactionId: anyNamed('transactionId'),
        amount: anyNamed('amount'),
        timestamp: anyNamed('timestamp'),
        previousHash: '0' * 64,
      )).called(1);
    });

    test('returns error when amount is zero', () async {
      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 0,
          type: TransactionType.expense,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('amount'));
      verifyNever(mockTransactionRepo.insert(any));
    });

    test('returns error when category does not exist', () async {
      when(mockCategoryRepo.findById('invalid_cat'))
          .thenAnswer((_) async => null);

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'invalid_cat',
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('category'));
      verifyNever(mockTransactionRepo.insert(any));
    });

    test('returns error when bookId is empty', () async {
      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: '',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isError, isTrue);
      verifyNever(mockTransactionRepo.insert(any));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/create_transaction_use_case_test.dart`
Expected: FAIL (UseCase class not found)

**Step 3: Write minimal implementation**

Create `lib/application/accounting/create_transaction_use_case.dart`:

```dart
import 'package:ulid/ulid.dart';

import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../infrastructure/crypto/services/hash_chain_service.dart';
import '../../shared/utils/result.dart';

/// Parameters for creating a new transaction.
class CreateTransactionParams {
  final String bookId;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final DateTime? timestamp;
  final String? note;

  const CreateTransactionParams({
    required this.bookId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.timestamp,
    this.note,
  });
}

/// Creates a new transaction with hash chain integrity.
///
/// Validates input, verifies category exists, computes hash chain link,
/// and persists the transaction.
class CreateTransactionUseCase {
  CreateTransactionUseCase({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required HashChainService hashChainService,
  })  : _transactionRepo = transactionRepository,
        _categoryRepo = categoryRepository,
        _hashChainService = hashChainService;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final HashChainService _hashChainService;

  /// Genesis hash: 64 zero characters (no previous transaction).
  static const _genesisHash = '0000000000000000000000000000000000000000000000000000000000000000';

  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    // 1. Validate input
    if (params.bookId.isEmpty) {
      return Result.error('bookId must not be empty');
    }
    if (params.amount <= 0) {
      return Result.error('amount must be greater than 0');
    }
    if (params.categoryId.isEmpty) {
      return Result.error('categoryId must not be empty');
    }

    // 2. Verify category exists
    final category = await _categoryRepo.findById(params.categoryId);
    if (category == null) {
      return Result.error('category not found');
    }

    // 3. Get previous hash for chain
    final prevHash = await _transactionRepo.getLatestHash(params.bookId) ?? _genesisHash;

    // 4. Build transaction
    final id = Ulid().toString();
    final now = DateTime.now();
    final timestamp = params.timestamp ?? now;

    // 5. Compute hash chain
    final currentHash = _hashChainService.calculateTransactionHash(
      transactionId: id,
      amount: params.amount.toDouble(),
      timestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
      previousHash: prevHash,
    );

    // 6. Create domain object
    final transaction = Transaction(
      id: id,
      bookId: params.bookId,
      deviceId: 'dev_local',
      amount: params.amount,
      type: params.type,
      categoryId: params.categoryId,
      ledgerType: LedgerType.survival,
      timestamp: timestamp,
      prevHash: prevHash,
      currentHash: currentHash,
      createdAt: now,
      note: params.note,
    );

    // 7. Persist
    await _transactionRepo.insert(transaction);

    return Result.success(transaction);
  }
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/create_transaction_use_case_test.dart`
Expected: PASS (5 tests)

**Step 5: Run ALL tests**

Run: `flutter test`
Expected: ALL pass (188 existing + 5 new = 193)

**Step 6: Commit**

```bash
git add lib/application/accounting/create_transaction_use_case.dart \
        test/unit/application/accounting/create_transaction_use_case_test.dart \
        test/unit/application/accounting/create_transaction_use_case_test.mocks.dart
git commit -m "feat: add CreateTransactionUseCase with hash chain"
```

---

## Task 2: GetTransactionsUseCase

**Files:**
- Create: `lib/application/accounting/get_transactions_use_case.dart`
- Test: `test/unit/application/accounting/get_transactions_use_case_test.dart`

**Step 1: Write the failing test**

Create `test/unit/application/accounting/get_transactions_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TransactionRepository])
import 'get_transactions_use_case_test.mocks.dart';

void main() {
  late MockTransactionRepository mockRepo;
  late GetTransactionsUseCase useCase;

  setUp(() {
    mockRepo = MockTransactionRepository();
    useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
  });

  Transaction _makeTransaction(String id, int amount) {
    return Transaction(
      id: id,
      bookId: 'book_001',
      deviceId: 'dev_local',
      amount: amount,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
      timestamp: DateTime(2026, 2, 6),
      currentHash: 'hash_$id',
      createdAt: DateTime(2026, 2, 6),
    );
  }

  group('GetTransactionsUseCase', () {
    test('returns transactions for a book', () async {
      final txList = [_makeTransaction('tx1', 100), _makeTransaction('tx2', 200)];
      when(mockRepo.findByBookId(
        'book_001',
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => txList);

      final result = await useCase.execute(
        GetTransactionsParams(bookId: 'book_001'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 2);
    });

    test('passes filter parameters to repository', () async {
      when(mockRepo.findByBookId(
        'book_001',
        ledgerType: LedgerType.survival,
        categoryId: 'cat_food',
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        limit: 50,
        offset: 10,
      )).thenAnswer((_) async => []);

      await useCase.execute(
        GetTransactionsParams(
          bookId: 'book_001',
          ledgerType: LedgerType.survival,
          categoryId: 'cat_food',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 2, 1),
          limit: 50,
          offset: 10,
        ),
      );

      verify(mockRepo.findByBookId(
        'book_001',
        ledgerType: LedgerType.survival,
        categoryId: 'cat_food',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 1),
        limit: 50,
        offset: 10,
      )).called(1);
    });

    test('returns error when bookId is empty', () async {
      final result = await useCase.execute(
        GetTransactionsParams(bookId: ''),
      );

      expect(result.isError, isTrue);
      verifyNever(mockRepo.findByBookId(any));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/get_transactions_use_case_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/application/accounting/get_transactions_use_case.dart`:

```dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/result.dart';

/// Parameters for querying transactions.
class GetTransactionsParams {
  final String bookId;
  final LedgerType? ledgerType;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const GetTransactionsParams({
    required this.bookId,
    this.ledgerType,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.limit = 100,
    this.offset = 0,
  });
}

/// Fetches transactions for a book with optional filters.
class GetTransactionsUseCase {
  GetTransactionsUseCase({
    required TransactionRepository transactionRepository,
  }) : _transactionRepo = transactionRepository;

  final TransactionRepository _transactionRepo;

  Future<Result<List<Transaction>>> execute(GetTransactionsParams params) async {
    if (params.bookId.isEmpty) {
      return Result.error('bookId must not be empty');
    }

    final transactions = await _transactionRepo.findByBookId(
      params.bookId,
      ledgerType: params.ledgerType,
      categoryId: params.categoryId,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      offset: params.offset,
    );

    return Result.success(transactions);
  }
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/get_transactions_use_case_test.dart`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add lib/application/accounting/get_transactions_use_case.dart \
        test/unit/application/accounting/get_transactions_use_case_test.dart \
        test/unit/application/accounting/get_transactions_use_case_test.mocks.dart
git commit -m "feat: add GetTransactionsUseCase with filters"
```

---

## Task 3: DeleteTransactionUseCase

**Files:**
- Create: `lib/application/accounting/delete_transaction_use_case.dart`
- Test: `test/unit/application/accounting/delete_transaction_use_case_test.dart`

**Step 1: Write the failing test**

Create `test/unit/application/accounting/delete_transaction_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TransactionRepository])
import 'delete_transaction_use_case_test.mocks.dart';

void main() {
  late MockTransactionRepository mockRepo;
  late DeleteTransactionUseCase useCase;

  setUp(() {
    mockRepo = MockTransactionRepository();
    useCase = DeleteTransactionUseCase(transactionRepository: mockRepo);
  });

  group('DeleteTransactionUseCase', () {
    test('soft-deletes an existing transaction', () async {
      when(mockRepo.findById('tx_001')).thenAnswer((_) async => Transaction(
            id: 'tx_001',
            bookId: 'book_001',
            deviceId: 'dev_local',
            amount: 1000,
            type: TransactionType.expense,
            categoryId: 'cat_food',
            ledgerType: LedgerType.survival,
            timestamp: DateTime(2026, 2, 6),
            currentHash: 'hash_001',
            createdAt: DateTime(2026, 2, 6),
          ));
      when(mockRepo.softDelete('tx_001')).thenAnswer((_) async {});

      final result = await useCase.execute('tx_001');

      expect(result.isSuccess, isTrue);
      verify(mockRepo.softDelete('tx_001')).called(1);
    });

    test('returns error when transaction not found', () async {
      when(mockRepo.findById('nonexistent')).thenAnswer((_) async => null);

      final result = await useCase.execute('nonexistent');

      expect(result.isError, isTrue);
      expect(result.error, contains('not found'));
      verifyNever(mockRepo.softDelete(any));
    });

    test('returns error when id is empty', () async {
      final result = await useCase.execute('');

      expect(result.isError, isTrue);
      verifyNever(mockRepo.findById(any));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/delete_transaction_use_case_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/application/accounting/delete_transaction_use_case.dart`:

```dart
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/result.dart';

/// Soft-deletes a transaction by ID.
class DeleteTransactionUseCase {
  DeleteTransactionUseCase({
    required TransactionRepository transactionRepository,
  }) : _transactionRepo = transactionRepository;

  final TransactionRepository _transactionRepo;

  Future<Result<void>> execute(String transactionId) async {
    if (transactionId.isEmpty) {
      return Result.error('transactionId must not be empty');
    }

    final existing = await _transactionRepo.findById(transactionId);
    if (existing == null) {
      return Result.error('Transaction not found');
    }

    await _transactionRepo.softDelete(transactionId);
    return Result.success(null);
  }
}
```

**Step 4: Run code generation then test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/delete_transaction_use_case_test.dart`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add lib/application/accounting/delete_transaction_use_case.dart \
        test/unit/application/accounting/delete_transaction_use_case_test.dart \
        test/unit/application/accounting/delete_transaction_use_case_test.mocks.dart
git commit -m "feat: add DeleteTransactionUseCase with soft-delete"
```

---

## Task 4: System Default Categories

**Files:**
- Create: `lib/shared/constants/default_categories.dart`
- Test: `test/unit/shared/constants/default_categories_test.dart`

**Step 1: Write the failing test**

Create `test/unit/shared/constants/default_categories_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

void main() {
  group('DefaultCategories', () {
    test('all categories have unique IDs', () {
      final ids = DefaultCategories.all.map((c) => c.id).toSet();
      expect(ids.length, DefaultCategories.all.length);
    });

    test('all categories are marked as system', () {
      for (final cat in DefaultCategories.all) {
        expect(cat.isSystem, isTrue, reason: '${cat.id} should be isSystem');
      }
    });

    test('level 1 categories have no parentId', () {
      final level1 = DefaultCategories.all.where((c) => c.level == 1);
      expect(level1.length, greaterThanOrEqualTo(7));
      for (final cat in level1) {
        expect(cat.parentId, isNull, reason: '${cat.id} level-1 should have no parent');
      }
    });

    test('level 2 categories reference valid level 1 parents', () {
      final level1Ids = DefaultCategories.all
          .where((c) => c.level == 1)
          .map((c) => c.id)
          .toSet();
      final level2 = DefaultCategories.all.where((c) => c.level == 2);
      for (final cat in level2) {
        expect(level1Ids.contains(cat.parentId), isTrue,
            reason: '${cat.id} parent ${cat.parentId} not found in level 1');
      }
    });

    test('contains both expense and income categories', () {
      final types = DefaultCategories.all.map((c) => c.type).toSet();
      expect(types, contains(TransactionType.expense));
      expect(types, contains(TransactionType.income));
    });

    test('expense categories getter returns only expense', () {
      for (final cat in DefaultCategories.expense) {
        expect(cat.type, TransactionType.expense);
      }
    });

    test('income categories getter returns only income', () {
      for (final cat in DefaultCategories.income) {
        expect(cat.type, TransactionType.income);
      }
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/shared/constants/default_categories_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/shared/constants/default_categories.dart`:

```dart
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/transaction.dart';

/// System default categories.
///
/// All system categories use `isSystem: true`.
/// The `name` field stores a plain display string for now;
/// will be migrated to localization keys in a future i18n task.
abstract final class DefaultCategories {
  static final DateTime _epoch = DateTime(2026, 1, 1);

  /// All default categories (expense + income, all levels).
  static List<Category> get all => [...expense, ...income];

  /// Expense categories only.
  static List<Category> get expense => [
        ..._expenseLevel1,
        ..._expenseLevel2,
      ];

  /// Income categories only.
  static List<Category> get income => _incomeLevel1;

  // ── Expense Level 1 ──

  static final List<Category> _expenseLevel1 = [
    Category(id: 'cat_food', name: '餐饮', icon: 'restaurant', color: '#FF5722', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 1, createdAt: _epoch),
    Category(id: 'cat_transport', name: '交通', icon: 'directions_car', color: '#2196F3', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 2, createdAt: _epoch),
    Category(id: 'cat_shopping', name: '购物', icon: 'shopping_cart', color: '#E91E63', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 3, createdAt: _epoch),
    Category(id: 'cat_entertainment', name: '娱乐', icon: 'movie', color: '#9C27B0', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 4, createdAt: _epoch),
    Category(id: 'cat_housing', name: '住房', icon: 'home', color: '#795548', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 5, createdAt: _epoch),
    Category(id: 'cat_medical', name: '医疗', icon: 'local_hospital', color: '#F44336', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 6, createdAt: _epoch),
    Category(id: 'cat_education', name: '教育', icon: 'school', color: '#3F51B5', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 7, createdAt: _epoch),
    Category(id: 'cat_daily', name: '日用', icon: 'local_mall', color: '#00BCD4', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 8, createdAt: _epoch),
    Category(id: 'cat_social', name: '社交', icon: 'people', color: '#FF9800', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 9, createdAt: _epoch),
    Category(id: 'cat_other_expense', name: '其他', icon: 'more_horiz', color: '#607D8B', level: 1, type: TransactionType.expense, isSystem: true, sortOrder: 99, createdAt: _epoch),
  ];

  // ── Expense Level 2 (Food sub-categories) ──

  static final List<Category> _expenseLevel2 = [
    Category(id: 'cat_food_breakfast', name: '早餐', icon: 'free_breakfast', color: '#FF5722', parentId: 'cat_food', level: 2, type: TransactionType.expense, isSystem: true, sortOrder: 1, createdAt: _epoch),
    Category(id: 'cat_food_lunch', name: '午餐', icon: 'lunch_dining', color: '#FF5722', parentId: 'cat_food', level: 2, type: TransactionType.expense, isSystem: true, sortOrder: 2, createdAt: _epoch),
    Category(id: 'cat_food_dinner', name: '晚餐', icon: 'dinner_dining', color: '#FF5722', parentId: 'cat_food', level: 2, type: TransactionType.expense, isSystem: true, sortOrder: 3, createdAt: _epoch),
    Category(id: 'cat_food_snack', name: '零食', icon: 'icecream', color: '#FF5722', parentId: 'cat_food', level: 2, type: TransactionType.expense, isSystem: true, sortOrder: 4, createdAt: _epoch),
    Category(id: 'cat_transport_public', name: '公共交通', icon: 'directions_bus', color: '#2196F3', parentId: 'cat_transport', level: 2, type: TransactionType.expense, isSystem: true, sortOrder: 1, createdAt: _epoch),
    Category(id: 'cat_transport_taxi', name: '打车', icon: 'local_taxi', color: '#2196F3', parentId: 'cat_transport', level: 2, type: TransactionType.expense, isSystem: true, sortOrder: 2, createdAt: _epoch),
  ];

  // ── Income Level 1 ──

  static final List<Category> _incomeLevel1 = [
    Category(id: 'cat_salary', name: '工资', icon: 'account_balance', color: '#4CAF50', level: 1, type: TransactionType.income, isSystem: true, sortOrder: 1, createdAt: _epoch),
    Category(id: 'cat_bonus', name: '奖金', icon: 'stars', color: '#FFC107', level: 1, type: TransactionType.income, isSystem: true, sortOrder: 2, createdAt: _epoch),
    Category(id: 'cat_investment', name: '投资收益', icon: 'trending_up', color: '#009688', level: 1, type: TransactionType.income, isSystem: true, sortOrder: 3, createdAt: _epoch),
    Category(id: 'cat_other_income', name: '其他收入', icon: 'attach_money', color: '#8BC34A', level: 1, type: TransactionType.income, isSystem: true, sortOrder: 99, createdAt: _epoch),
  ];
}
```

**Step 4: Run test**

Run: `flutter test test/unit/shared/constants/default_categories_test.dart`
Expected: PASS (7 tests)

**Step 5: Commit**

```bash
git add lib/shared/constants/default_categories.dart \
        test/unit/shared/constants/default_categories_test.dart
git commit -m "feat: add system default categories (10 expense + 4 income)"
```

---

## Task 5: SeedCategoriesUseCase

**Files:**
- Create: `lib/application/accounting/seed_categories_use_case.dart`
- Test: `test/unit/application/accounting/seed_categories_use_case_test.dart`

**Step 1: Write the failing test**

Create `test/unit/application/accounting/seed_categories_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository])
import 'seed_categories_use_case_test.mocks.dart';

void main() {
  late MockCategoryRepository mockRepo;
  late SeedCategoriesUseCase useCase;

  setUp(() {
    mockRepo = MockCategoryRepository();
    useCase = SeedCategoriesUseCase(categoryRepository: mockRepo);
  });

  group('SeedCategoriesUseCase', () {
    test('inserts all default categories when db is empty', () async {
      when(mockRepo.findAll()).thenAnswer((_) async => []);
      when(mockRepo.insertBatch(any)).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      verify(mockRepo.insertBatch(DefaultCategories.all)).called(1);
    });

    test('skips seeding when categories already exist', () async {
      when(mockRepo.findAll()).thenAnswer((_) async => DefaultCategories.all);

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      verifyNever(mockRepo.insertBatch(any));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/seed_categories_use_case_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/application/accounting/seed_categories_use_case.dart`:

```dart
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../shared/constants/default_categories.dart';
import '../../shared/utils/result.dart';

/// Seeds default system categories if none exist.
///
/// Called during app initialization. Idempotent — does nothing
/// if categories are already present.
class SeedCategoriesUseCase {
  SeedCategoriesUseCase({
    required CategoryRepository categoryRepository,
  }) : _categoryRepo = categoryRepository;

  final CategoryRepository _categoryRepo;

  Future<Result<void>> execute() async {
    final existing = await _categoryRepo.findAll();
    if (existing.isNotEmpty) {
      return Result.success(null);
    }

    await _categoryRepo.insertBatch(DefaultCategories.all);
    return Result.success(null);
  }
}
```

**Step 4: Run test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/seed_categories_use_case_test.dart`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/application/accounting/seed_categories_use_case.dart \
        test/unit/application/accounting/seed_categories_use_case_test.dart \
        test/unit/application/accounting/seed_categories_use_case_test.mocks.dart
git commit -m "feat: add SeedCategoriesUseCase for default categories"
```

---

## Task 6: EnsureDefaultBookUseCase

**Files:**
- Create: `lib/application/accounting/ensure_default_book_use_case.dart`
- Test: `test/unit/application/accounting/ensure_default_book_use_case_test.dart`

**Step 1: Write the failing test**

Create `test/unit/application/accounting/ensure_default_book_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/ensure_default_book_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([BookRepository])
import 'ensure_default_book_use_case_test.mocks.dart';

void main() {
  late MockBookRepository mockRepo;
  late EnsureDefaultBookUseCase useCase;

  setUp(() {
    mockRepo = MockBookRepository();
    useCase = EnsureDefaultBookUseCase(bookRepository: mockRepo);
  });

  group('EnsureDefaultBookUseCase', () {
    test('creates default book when none exist', () async {
      when(mockRepo.findAll()).thenAnswer((_) async => []);
      when(mockRepo.insert(any)).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.currency, 'JPY');
      verify(mockRepo.insert(any)).called(1);
    });

    test('returns existing book when one already exists', () async {
      final existing = Book(
        id: 'book_existing',
        name: 'My Book',
        currency: 'JPY',
        deviceId: 'dev_local',
        createdAt: DateTime(2026, 1, 1),
      );
      when(mockRepo.findAll()).thenAnswer((_) async => [existing]);

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect(result.data!.id, 'book_existing');
      verifyNever(mockRepo.insert(any));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/ensure_default_book_use_case_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `lib/application/accounting/ensure_default_book_use_case.dart`:

```dart
import 'package:ulid/ulid.dart';

import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../shared/utils/result.dart';

/// Ensures a default book exists.
///
/// Returns the existing book if one is found, otherwise creates
/// a default "My Book" with JPY currency.
class EnsureDefaultBookUseCase {
  EnsureDefaultBookUseCase({
    required BookRepository bookRepository,
  }) : _bookRepo = bookRepository;

  final BookRepository _bookRepo;

  Future<Result<Book>> execute() async {
    final books = await _bookRepo.findAll();
    if (books.isNotEmpty) {
      return Result.success(books.first);
    }

    final book = Book(
      id: Ulid().toString(),
      name: 'My Book',
      currency: 'JPY',
      deviceId: 'dev_local',
      createdAt: DateTime.now(),
    );

    await _bookRepo.insert(book);
    return Result.success(book);
  }
}
```

**Step 4: Run test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/unit/application/accounting/ensure_default_book_use_case_test.dart`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/application/accounting/ensure_default_book_use_case.dart \
        test/unit/application/accounting/ensure_default_book_use_case_test.dart \
        test/unit/application/accounting/ensure_default_book_use_case_test.mocks.dart
git commit -m "feat: add EnsureDefaultBookUseCase"
```

---

## Task 7: Use Case Providers

**Files:**
- Create: `lib/features/accounting/presentation/providers/use_case_providers.dart`
- No test: Providers are wiring-only; verified by analyzer + existing tests.

**Step 1: Write the providers**

Create `lib/features/accounting/presentation/providers/use_case_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../application/accounting/delete_transaction_use_case.dart';
import '../../../../application/accounting/ensure_default_book_use_case.dart';
import '../../../../application/accounting/get_transactions_use_case.dart';
import '../../../../application/accounting/seed_categories_use_case.dart';
import '../../../../infrastructure/crypto/providers.dart';
import 'repository_providers.dart';

part 'use_case_providers.g.dart';

@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
  );
}

@riverpod
GetTransactionsUseCase getTransactionsUseCase(Ref ref) {
  return GetTransactionsUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}

@riverpod
DeleteTransactionUseCase deleteTransactionUseCase(Ref ref) {
  return DeleteTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}

@riverpod
SeedCategoriesUseCase seedCategoriesUseCase(Ref ref) {
  return SeedCategoriesUseCase(
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}

@riverpod
EnsureDefaultBookUseCase ensureDefaultBookUseCase(Ref ref) {
  return EnsureDefaultBookUseCase(
    bookRepository: ref.watch(bookRepositoryProvider),
  );
}
```

**Step 2: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 3: Run analyzer**

Run: `flutter analyze`
Expected: No issues

**Step 4: Commit**

```bash
git add lib/features/accounting/presentation/providers/use_case_providers.dart \
        lib/features/accounting/presentation/providers/use_case_providers.g.dart
git commit -m "feat: add Use Case providers for accounting"
```

---

## Task 8: Transaction List Screen

**Files:**
- Create: `lib/features/accounting/presentation/screens/transaction_list_screen.dart`
- Create: `lib/features/accounting/presentation/widgets/transaction_list_tile.dart`
- No unit test — Widget tested via manual + widget tests in Task 11.

**Step 1: Write TransactionListTile widget**

Create `lib/features/accounting/presentation/widgets/transaction_list_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/models/transaction.dart';

/// Displays a single transaction as a list tile.
///
/// Shows category icon, amount (red for expense, green for income),
/// optional note, and relative timestamp.
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.transaction,
    this.categoryName,
    this.onTap,
    this.onDelete,
  });

  final Transaction transaction;
  final String? categoryName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isExpense ? Icons.remove : Icons.add,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(categoryName ?? transaction.categoryId),
        subtitle: transaction.note != null && transaction.note!.isNotEmpty
            ? Text(
                transaction.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? "-" : "+"}${transaction.amount}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            Text(
              _formatTime(transaction.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${dt.month}/${dt.day}';
  }
}
```

**Step 2: Write TransactionListScreen**

Create `lib/features/accounting/presentation/screens/transaction_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../providers/repository_providers.dart';
import '../providers/use_case_providers.dart';
import '../widgets/transaction_list_tile.dart';
import 'transaction_form_screen.dart';

/// Main transaction list screen.
///
/// Displays all transactions for the current book, with a FAB
/// to add new transactions. Supports swipe-to-delete.
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  List<Transaction> _transactions = [];
  Map<String, Category> _categoryMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final getTransactions = ref.read(getTransactionsUseCaseProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);

    final result = await getTransactions.execute(
      GetTransactionsParams(bookId: widget.bookId),
    );

    final categories = await categoryRepo.findAll();
    final catMap = <String, Category>{};
    for (final cat in categories) {
      catMap[cat.id] = cat;
    }

    if (mounted) {
      setState(() {
        _transactions = result.isSuccess ? result.data! : [];
        _categoryMap = catMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTransaction(String id) async {
    final deleteUseCase = ref.read(deleteTransactionUseCaseProvider);
    await deleteUseCase.execute(id);
    await _loadData();
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(bookId: widget.bookId),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap + to add your first transaction'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final cat = _categoryMap[tx.categoryId];
                      return TransactionListTile(
                        transaction: tx,
                        categoryName: cat?.name,
                        onDelete: () => _deleteTransaction(tx.id),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

NOTE: This import `GetTransactionsParams` — make sure it's exported from the use case file.

**Step 3: Run analyzer**

Run: `flutter analyze`
Expected: No issues

**Step 4: Commit**

```bash
git add lib/features/accounting/presentation/screens/transaction_list_screen.dart \
        lib/features/accounting/presentation/widgets/transaction_list_tile.dart
git commit -m "feat: add TransactionListScreen with swipe-to-delete"
```

---

## Task 9: Transaction Form Screen

**Files:**
- Create: `lib/features/accounting/presentation/screens/transaction_form_screen.dart`

**Step 1: Write the form screen**

Create `lib/features/accounting/presentation/screens/transaction_form_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../providers/repository_providers.dart';
import '../providers/use_case_providers.dart';

/// Transaction entry form.
///
/// Provides amount input, transaction type toggle (expense/income),
/// category selection, optional note, and save button.
/// Returns `true` via Navigator.pop on successful save.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isSubmitting = false;
  String? _amountError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final repo = ref.read(categoryRepositoryProvider);
    final cats = await repo.findByType(_type);
    if (mounted) {
      setState(() {
        _categories = cats.where((c) => c.level == 1).toList();
        // Reset selection if type changed
        if (_selectedCategoryId != null &&
            !_categories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
      });
    }
  }

  bool _validate() {
    bool valid = true;

    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);
    if (amountText.isEmpty || amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid amount > 0');
      valid = false;
    } else {
      setState(() => _amountError = null);
    }

    if (_selectedCategoryId == null) {
      setState(() => _categoryError = 'Select a category');
      valid = false;
    } else {
      setState(() => _categoryError = null);
    }

    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    final createUseCase = ref.read(createTransactionUseCaseProvider);
    final result = await createUseCase.execute(
      CreateTransactionParams(
        bookId: widget.bookId,
        amount: int.parse(_amountController.text.trim()),
        type: _type,
        categoryId: _selectedCategoryId!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to save')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Transaction')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount input
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: const OutlineInputBorder(),
                        errorText: _amountError,
                      ),
                      autofocus: true,
                    ),

                    const SizedBox(height: 16),

                    // Type toggle
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Income'),
                          icon: Icon(Icons.add_circle_outline),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (selected) {
                        setState(() => _type = selected.first);
                        _loadCategories();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Category selector
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_categoryError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _categoryError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _selectedCategoryId == cat.id;
                        return ChoiceChip(
                          label: Text(cat.name),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = cat.id;
                              _categoryError = null;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Note input
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
```

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/features/accounting/presentation/screens/transaction_form_screen.dart
git commit -m "feat: add TransactionFormScreen with amount, type, category, note"
```

---

## Task 10: Wire main.dart with Riverpod + In-Memory DB

**Files:**
- Modify: `lib/main.dart`

**Step 1: Rewrite main.dart**

Replace the default Flutter counter app with the accounting app:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/accounting/ensure_default_book_use_case.dart';
import 'application/accounting/seed_categories_use_case.dart';
import 'data/app_database.dart';
import 'features/accounting/presentation/providers/repository_providers.dart';
import 'features/accounting/presentation/providers/use_case_providers.dart';
import 'features/accounting/presentation/screens/transaction_list_screen.dart';
import 'infrastructure/security/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In-memory database for development.
  // Production will use encrypted SQLCipher executor.
  final database = AppDatabase(NativeDatabase.memory());

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const HomePocketApp(),
    ),
  );
}

class HomePocketApp extends ConsumerStatefulWidget {
  const HomePocketApp({super.key});

  @override
  ConsumerState<HomePocketApp> createState() => _HomePocketAppState();
}

class _HomePocketAppState extends ConsumerState<HomePocketApp> {
  String? _bookId;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Seed categories
      final seedCategories = ref.read(seedCategoriesUseCaseProvider);
      await seedCategories.execute();

      // Ensure default book
      final ensureBook = ref.read(ensureDefaultBookUseCaseProvider);
      final bookResult = await ensureBook.execute();

      if (bookResult.isSuccess && bookResult.data != null) {
        setState(() {
          _bookId = bookResult.data!.id;
          _initialized = true;
        });
      } else {
        setState(() => _error = bookResult.error ?? 'Failed to initialize');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Pocket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_error!)),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return TransactionListScreen(bookId: _bookId!);
  }
}
```

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues

**Step 3: Run ALL tests**

Run: `flutter test`
Expected: ALL pass (existing widget_test.dart will fail because it tests the old counter app)

NOTE: The default `test/widget_test.dart` tests the old counter app. It needs to be updated or removed.

**Step 4: Update widget_test.dart**

Replace `test/widget_test.dart` with a minimal smoke test:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder smoke test', () {
    // The old counter app widget test is no longer valid.
    // Real widget tests will be added as the UI stabilizes.
    expect(1 + 1, 2);
  });
}
```

**Step 5: Run ALL tests again**

Run: `flutter test`
Expected: ALL pass

**Step 6: Commit**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "feat: wire main.dart with Riverpod, in-memory DB, and accounting UI"
```

---

## Task 11: Widget Tests for Core UI

**Files:**
- Create: `test/widget/features/accounting/presentation/widgets/transaction_list_tile_test.dart`
- Create: `test/widget/features/accounting/presentation/screens/transaction_form_screen_test.dart`

**Step 1: Write TransactionListTile widget test**

Create `test/widget/features/accounting/presentation/widgets/transaction_list_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_list_tile.dart';

void main() {
  final testTransaction = Transaction(
    id: 'tx_001',
    bookId: 'book_001',
    deviceId: 'dev_local',
    amount: 1500,
    type: TransactionType.expense,
    categoryId: 'cat_food',
    ledgerType: LedgerType.survival,
    timestamp: DateTime.now(),
    currentHash: 'hash_001',
    createdAt: DateTime.now(),
    note: 'Lunch at cafe',
  );

  group('TransactionListTile', () {
    testWidgets('displays amount with minus sign for expense', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(
              transaction: testTransaction,
              categoryName: 'Food',
            ),
          ),
        ),
      );

      expect(find.text('-1500'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Lunch at cafe'), findsOneWidget);
    });

    testWidgets('displays amount with plus sign for income', (tester) async {
      final incomeTx = Transaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_local',
        amount: 50000,
        type: TransactionType.income,
        categoryId: 'cat_salary',
        ledgerType: LedgerType.survival,
        timestamp: DateTime.now(),
        currentHash: 'hash_002',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(
              transaction: incomeTx,
              categoryName: 'Salary',
            ),
          ),
        ),
      );

      expect(find.text('+50000'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('shows category ID when categoryName is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListTile(transaction: testTransaction),
          ),
        ),
      );

      expect(find.text('cat_food'), findsOneWidget);
    });
  });
}
```

**Step 2: Run widget tests**

Run: `flutter test test/widget/`
Expected: PASS (3 tests)

**Step 3: Commit**

```bash
git add test/widget/
git commit -m "test: add widget tests for TransactionListTile"
```

---

## Task 12: Final Verification & Cleanup

**Step 1: Run full test suite**

Run: `flutter test`
Expected: ALL tests pass

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found

**Step 3: Format code**

Run: `dart format lib/application/ lib/features/accounting/ lib/shared/ test/`

**Step 4: Verify directory structure**

```
lib/application/accounting/
  create_transaction_use_case.dart
  delete_transaction_use_case.dart
  ensure_default_book_use_case.dart
  get_transactions_use_case.dart
  seed_categories_use_case.dart

lib/features/accounting/
  domain/
    models/
      transaction.dart          # existing
      category.dart             # existing
      book.dart                 # existing
    repositories/
      transaction_repository.dart  # existing
      category_repository.dart     # existing
      book_repository.dart         # existing
  presentation/
    providers/
      repository_providers.dart    # existing
      use_case_providers.dart      # NEW
    screens/
      transaction_list_screen.dart # NEW
      transaction_form_screen.dart # NEW
    widgets/
      transaction_list_tile.dart   # NEW

lib/shared/
  constants/
    default_categories.dart     # NEW
  utils/
    result.dart                 # existing
```

**Step 5: Commit final verification**

```bash
git add -A
git commit -m "chore: format and verify basic accounting feature"
```

---

## Summary

| Task | Description | Tests | Files |
|------|-------------|-------|-------|
| 1 | CreateTransactionUseCase | 5 | 1 src + 1 test |
| 2 | GetTransactionsUseCase | 3 | 1 src + 1 test |
| 3 | DeleteTransactionUseCase | 3 | 1 src + 1 test |
| 4 | System Default Categories | 7 | 1 src + 1 test |
| 5 | SeedCategoriesUseCase | 2 | 1 src + 1 test |
| 6 | EnsureDefaultBookUseCase | 2 | 1 src + 1 test |
| 7 | Use Case Providers | 0 (analyzer) | 1 src |
| 8 | TransactionListScreen + Tile | 0 (manual) | 2 src |
| 9 | TransactionFormScreen | 0 (manual) | 1 src |
| 10 | Wire main.dart | 0 (manual) | 1 modified |
| 11 | Widget Tests | 3 | 1 test |
| 12 | Final Verification | 0 | cleanup |

**Total new tests:** ~25
**Total tests after completion:** ~213 (188 existing + 25 new)
**New source files:** 12
**Modified files:** 2 (main.dart, widget_test.dart)
