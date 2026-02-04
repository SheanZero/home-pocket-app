# Phase 2 Data Layer - Repository Implementation Design

**Date:** 2026-02-04
**Status:** Approved - Ready for Implementation
**Phase:** MOD-001 Phase 2 (Data Layer)

---

## Overview

Complete Phase 2 (Data Layer) by implementing repository classes that connect domain interfaces to database access, handling encryption and hash chain management transparently.

**Goal:** Provide working repository implementations that use real database access (not mocks), enabling integration with the Application Layer.

---

## Architecture Decisions

### Decision 1: Repository Location (Shared Capability)

**Chosen:** Repositories in `lib/data/repositories/` (shared across features)

**Rationale:**
- Database access is a **shared capability** (multiple features need access)
- Follows capability classification rule: "Will other features need this?" → YES → `lib/`
- Future features (reports, budgets) will need to read transactions/categories/books
- Avoids cross-feature dependencies (no `features/reports` → `features/accounting`)

**Structure:**
```
lib/data/
├── repositories/              ← NEW: Shared repository implementations
│   ├── transaction_repository_impl.dart
│   ├── category_repository_impl.dart
│   └── book_repository_impl.dart
├── daos/                      ← Existing: Data access objects
└── tables/                    ← Existing: Table schemas

lib/features/accounting/
└── domain/repositories/       ← Existing: Interface contracts
    ├── transaction_repository.dart
    ├── category_repository.dart
    └── book_repository.dart
```

### Decision 2: Encryption Responsibility

**Chosen:** Repository handles encryption/decryption

**Rationale:**
- Encryption is a data layer concern (how data is stored)
- Use cases should work with plain domain models
- Single responsibility: encryption logic centralized
- Easier to maintain and test

**Flow:**
```
Use Case (plain data)
    ↓
Repository (encrypts)
    ↓
DAO (stores encrypted)
    ↓
Database (encrypted at rest)
```

### Decision 3: Hash Chain Responsibility

**Chosen:** Repository handles hash chain calculation

**Rationale:**
- Hash chain is a data integrity implementation detail
- Use cases shouldn't know about storage mechanisms
- Repository already has access to previous hash via DAO
- Consistent with encryption approach (data layer handles transformations)

**Flow:**
```
Use Case (provides transaction)
    ↓
Repository (calculates hash)
    ↓
DAO (stores with hash)
```

### Decision 4: Implementation Order

**Chosen:** Transaction → Category → Book

**Rationale:**
- Transaction is most complex (encryption + hash chain)
- Establishes patterns for simpler repositories
- Learn hard parts first, then apply patterns

### Decision 5: Testing Strategy

**Chosen:** In-memory database with mocked crypto services

**Rationale:**
- Fast tests (no file I/O)
- Real database behavior (Drift in-memory)
- Mock encryption service (tested separately)
- Mock hash chain service (tested separately)
- High coverage (≥80%) with confidence

---

## Component Designs

### 1. TransactionRepositoryImpl

**Location:** `lib/data/repositories/transaction_repository_impl.dart`

**Dependencies:**
- `AppDatabase` - Provides DAO access
- `FieldEncryptionService` - Encrypts/decrypts sensitive fields
- `HashChainService` - Calculates transaction hashes

**Key Methods:**

#### insert(Transaction)
```
1. Get previous hash from DAO (or 'GENESIS' if first)
2. Calculate current hash using HashChainService
3. Encrypt sensitive fields (amount, note, merchant)
4. Create transaction with hash and encrypted data
5. Insert via DAO
```

#### update(Transaction)
```
1. Get previous hash (may have changed if reordering)
2. Recalculate current hash
3. Encrypt updated fields
4. Update via DAO
```

#### findById(String)
```
1. Retrieve from DAO
2. Decrypt sensitive fields
3. Return domain model
```

#### findByBook({filters})
```
1. Retrieve list from DAO with filters
2. Decrypt each transaction's sensitive fields
3. Return list of domain models
```

#### verifyHashChain(String bookId)
```
1. Get all transactions for book (ordered by timestamp)
2. Verify each hash links to previous
3. Return true if valid, false if broken
```

**Sensitive Fields to Encrypt:**
- `amount` (stored as int, encrypted separately)
- `note` (optional string)
- `merchant` (optional string)

**Implementation Pattern:**
```dart
class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _database;
  final FieldEncryptionService _encryptionService;
  final HashChainService _hashChainService;

  TransactionRepositoryImpl({
    required AppDatabase database,
    required FieldEncryptionService encryptionService,
    required HashChainService hashChainService,
  }) : _database = database,
       _encryptionService = encryptionService,
       _hashChainService = hashChainService;

  @override
  Future<void> insert(Transaction transaction) async {
    // Get previous hash
    final prevHash = await _database.transactionDao
        .getLatestHash(transaction.bookId) ?? 'GENESIS';

    // Calculate current hash
    final currentHash = _hashChainService.calculateTransactionHash(
      transactionId: transaction.id,
      amount: transaction.amount,
      timestamp: transaction.timestamp,
      previousHash: prevHash,
    );

    // Encrypt sensitive fields
    final encryptedNote = transaction.note != null
        ? await _encryptionService.encryptField(transaction.note!)
        : null;
    final encryptedMerchant = transaction.merchant != null
        ? await _encryptionService.encryptField(transaction.merchant!)
        : null;

    // Create transaction with hash and encryption
    final txWithData = transaction.copyWith(
      prevHash: prevHash,
      currentHash: currentHash,
      note: encryptedNote,
      merchant: encryptedMerchant,
    );

    // Insert via DAO
    await _database.transactionDao.insertTransaction(txWithData);
  }

  @override
  Future<Transaction?> findById(String id) async {
    final tx = await _database.transactionDao.getTransactionById(id);
    return tx != null ? await _decryptTransaction(tx) : null;
  }

  Future<Transaction> _decryptTransaction(Transaction tx) async {
    final decryptedNote = tx.note != null
        ? await _encryptionService.decryptField(tx.note!)
        : null;
    final decryptedMerchant = tx.merchant != null
        ? await _encryptionService.decryptField(tx.merchant!)
        : null;

    return tx.copyWith(
      note: decryptedNote,
      merchant: decryptedMerchant,
    );
  }
}
```

---

### 2. CategoryRepositoryImpl

**Location:** `lib/data/repositories/category_repository_impl.dart`

**Dependencies:**
- `AppDatabase` - Provides DAO access

**Simpler Implementation** (no encryption, no hash chain):

**Key Methods:**
- `insert(Category)` - Direct DAO call
- `update(Category)` - Direct DAO call
- `delete(String id)` - Check if system category first
- `findById(String)` - Direct DAO call
- `findByType(TransactionType)` - Filter in memory
- `seedSystemCategories()` - Insert 22 system categories if not exists

**System Category Seeding:**
```dart
@override
Future<void> seedSystemCategories() async {
  for (final category in Category.systemCategories) {
    final existing = await findById(category.id);
    if (existing == null) {
      await insert(category);
    }
  }
}
```

---

### 3. BookRepositoryImpl

**Location:** `lib/data/repositories/book_repository_impl.dart`

**Dependencies:**
- `AppDatabase` - Provides DAO access

**Key Methods:**
- `insert(Book)` - Direct DAO call
- `update(Book)` - Direct DAO call with timestamp update
- `delete(String)` - Hard delete via DAO
- `findById(String)` - Direct DAO call
- `archive(String)` - Set isArchived flag
- `updateStatistics({...})` - Update denormalized counters

**Statistics Management:**
```dart
@override
Future<void> updateStatistics({
  required String bookId,
  required int transactionCount,
  required int survivalBalance,
  required int soulBalance,
}) async {
  final book = await findById(bookId);
  if (book == null) throw Exception('Book not found');

  final updated = book.copyWith(
    transactionCount: transactionCount,
    survivalBalance: survivalBalance,
    soulBalance: soulBalance,
    updatedAt: DateTime.now(),
  );

  await _database.bookDao.updateBook(updated);
}
```

---

## Testing Strategy

### Test Structure

**Location:** `test/data/repositories/`

**Files:**
- `transaction_repository_impl_test.dart`
- `category_repository_impl_test.dart`
- `book_repository_impl_test.dart`

### Test Setup Pattern

```dart
void main() {
  late AppDatabase database;
  late TransactionRepositoryImpl repository;
  late MockFieldEncryptionService mockEncryption;
  late MockHashChainService mockHashChain;

  setUp(() async {
    // Use in-memory database
    database = AppDatabase(NativeDatabase.memory());

    // Mock crypto services
    mockEncryption = MockFieldEncryptionService();
    mockHashChain = MockHashChainService();

    // Setup default mock behavior
    when(mockEncryption.encryptField(any))
        .thenAnswer((inv) async => 'encrypted_${inv.positionalArguments[0]}');
    when(mockEncryption.decryptField(any))
        .thenAnswer((inv) async => (inv.positionalArguments[0] as String)
            .replaceFirst('encrypted_', ''));
    when(mockHashChain.calculateTransactionHash(
      transactionId: anyNamed('transactionId'),
      amount: anyNamed('amount'),
      timestamp: anyNamed('timestamp'),
      previousHash: anyNamed('previousHash'),
    )).thenReturn('mock_hash_123');

    repository = TransactionRepositoryImpl(
      database: database,
      encryptionService: mockEncryption,
      hashChainService: mockHashChain,
    );
  });

  tearDown(() async {
    await database.close();
  });

  // Tests...
}
```

### Test Coverage Requirements

**TransactionRepository (≥80% coverage):**
- ✅ Insert with encryption and hash calculation
- ✅ Find by ID with decryption
- ✅ Find by book with filters (date, category, ledger)
- ✅ Update with re-encryption and re-hash
- ✅ Delete (hard and soft)
- ✅ Get latest hash
- ✅ Count transactions
- ✅ Verify hash chain integrity
- ✅ Error cases (not found, duplicate ID)
- ✅ Edge cases (null values, empty results)

**CategoryRepository (≥80% coverage):**
- ✅ Insert category
- ✅ Update category
- ✅ Delete category (prevent system category deletion)
- ✅ Find by ID, type, level, parent
- ✅ Seed system categories (idempotent)
- ✅ Can delete check (has transactions)

**BookRepository (≥80% coverage):**
- ✅ Insert book
- ✅ Update book
- ✅ Delete book
- ✅ Find by ID, device
- ✅ Find active (not archived)
- ✅ Archive book
- ✅ Update statistics

### Mocking Strategy

**Mock These:**
- `FieldEncryptionService` - Encryption tested separately
- `HashChainService` - Hashing tested separately

**Use Real:**
- `AppDatabase` with in-memory SQLite
- DAOs (test integration with database)

---

## Riverpod Provider Updates

### Current State (Mock Providers)

```dart
// lib/features/accounting/presentation/providers/repository_providers.dart

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return MockTransactionRepository(); // TODO: Replace with real
}
```

### New State (Real Providers)

```dart
@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  final executor = await createEncryptedExecutor(keyManager);
  return AppDatabase(executor);
}

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return TransactionRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    encryptionService: ref.watch(fieldEncryptionServiceProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
  );
}

@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  return CategoryRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
  );
}

@riverpod
BookRepository bookRepository(BookRepositoryRef ref) {
  return BookRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
  );
}
```

**Remove all mock repository classes** once real implementations are complete.

---

## Implementation Tasks

### Task 2.3.1: TransactionRepositoryImpl
- **Estimated Time:** 3 hours
- **Complexity:** High (encryption + hash chain)
- **Dependencies:** FieldEncryptionService, HashChainService
- **Test Coverage:** ≥80%

**Steps:**
1. Create implementation file
2. Implement insert with encryption + hash
3. Implement findById with decryption
4. Implement findByBook with filters
5. Implement update with re-encryption
6. Implement delete methods
7. Implement verifyHashChain
8. Write comprehensive tests
9. Verify coverage ≥80%

### Task 2.3.2: CategoryRepositoryImpl
- **Estimated Time:** 1 hour
- **Complexity:** Low (simple CRUD)
- **Dependencies:** None (just DAO)
- **Test Coverage:** ≥80%

**Steps:**
1. Create implementation file
2. Implement all CRUD methods
3. Implement seedSystemCategories
4. Write tests
5. Verify coverage ≥80%

### Task 2.3.3: BookRepositoryImpl
- **Estimated Time:** 1 hour
- **Complexity:** Low (CRUD + statistics)
- **Dependencies:** None (just DAO)
- **Test Coverage:** ≥80%

**Steps:**
1. Create implementation file
2. Implement all CRUD methods
3. Implement updateStatistics
4. Write tests
5. Verify coverage ≥80%

### Task 2.4: Provider Integration
- **Estimated Time:** 1 hour
- **Complexity:** Medium (update providers + use cases)

**Steps:**
1. Update repository providers (remove mocks)
2. Update appDatabase provider
3. Run all Application Layer tests
4. Verify use cases work with real repositories
5. Remove mock repository classes

### Task 2.5: Integration Testing
- **Estimated Time:** 1 hour
- **Complexity:** Medium (end-to-end verification)

**Steps:**
1. Create integration test suite
2. Test full flow: Use Case → Repository → DAO → Database
3. Test with real encryption service
4. Verify hash chain integrity
5. Test concurrent operations

---

## Total Estimated Time: 7 hours

**Breakdown:**
- TransactionRepositoryImpl: 3 hours
- CategoryRepositoryImpl: 1 hour
- BookRepositoryImpl: 1 hour
- Provider Integration: 1 hour
- Integration Testing: 1 hour

---

## Success Criteria

Phase 2 is complete when:

1. ✅ All repository implementations exist in `lib/data/repositories/`
2. ✅ All repositories pass ≥80% test coverage
3. ✅ TransactionRepository handles encryption transparently
4. ✅ TransactionRepository calculates hash chains correctly
5. ✅ CategoryRepository seeds system categories on first use
6. ✅ BookRepository updates statistics correctly
7. ✅ Riverpod providers use real repositories (no mocks)
8. ✅ Application Layer tests pass with real repositories
9. ✅ Integration tests verify end-to-end flows
10. ✅ `flutter test` shows all tests passing

---

## Next Phase

After Phase 2 completion:
- **Phase 4 Presentation Layer** can be completed (currently using mock data)
- **Phase 5 Integration Tests** can be written
- Application is ready for UI testing with real data persistence

---

**Design Approved:** 2026-02-04
**Author:** Claude Sonnet 4.5 (with user collaboration)
**Status:** Ready for Implementation Plan
