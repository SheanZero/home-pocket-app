import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';

// Mock secure storage for integration tests
class _MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _storage[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _storage[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _storage.remove(key);

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => Map.from(_storage);

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _storage.clear();

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _storage.containsKey(key);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Integration test for accounting performance
///
/// Tests:
/// - Large transaction lists (1000+ items)
/// - Pagination performance
/// - Hash chain verification performance
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Accounting Performance Tests', () {
    late AppDatabase database;
    late TransactionRepositoryImpl transactionRepo;
    late HashChainService hashChainService;
    late FieldEncryptionService fieldEncryptionService;
    late KeyManager keyManager;

    setUp(() async {
      // Create in-memory database for testing
      database = AppDatabase(NativeDatabase.memory());

      // Setup REAL crypto services
      final secureStorage = _MockSecureStorage();
      final keyRepository = KeyRepositoryImpl(secureStorage: secureStorage);
      final encryptionRepository = EncryptionRepositoryImpl(keyRepository: keyRepository);

      keyManager = KeyManager(repository: keyRepository);
      fieldEncryptionService = FieldEncryptionService(repository: encryptionRepository);
      hashChainService = HashChainService();

      // Generate real device key pair
      await keyManager.generateDeviceKeyPair();

      // Create DAOs
      final transactionDao = TransactionDao(database);

      // Create repositories
      transactionRepo = TransactionRepositoryImpl(
        database: database,
        dao: transactionDao,
        encryptionService: fieldEncryptionService,
        hashChainService: hashChainService,
      );
    });

    tearDown(() async {
      await database.close();
      await keyManager.clearKeys();
    });

    test('Insert and query 1000 transactions', () async {
      const bookId = 'perf_book';
      const transactionCount = 1000;

      // ARRANGE & ACT: Insert 1000 transactions
      final insertStartTime = DateTime.now();

      for (int i = 0; i < transactionCount; i++) {
        final transaction = Transaction.create(
          bookId: bookId,
          deviceId: 'device_001',
          amount: 1000 + i,
          type: i % 2 == 0 ? TransactionType.expense : TransactionType.income,
          categoryId: 'cat_${i % 10}',
          ledgerType: LedgerType.survival,
          note: 'Performance test transaction $i',
        );

        await transactionRepo.insert(transaction);
      }

      final insertDuration = DateTime.now().difference(insertStartTime);
      print('✅ Inserted $transactionCount transactions in ${insertDuration.inMilliseconds}ms');

      // ASSERT: Insertion should be reasonably fast (< 30 seconds for 1000 items)
      expect(insertDuration.inSeconds, lessThan(30));

      // ACT: Query all transactions
      final queryStartTime = DateTime.now();

      final transactions = await transactionRepo.findByBook(
        bookId: bookId,
        limit: transactionCount,
        offset: 0,
      );

      final queryDuration = DateTime.now().difference(queryStartTime);
      print('✅ Queried $transactionCount transactions in ${queryDuration.inMilliseconds}ms');

      // ASSERT: All transactions retrieved
      expect(transactions.length, transactionCount);

      // ASSERT: Query should be fast (< 2 seconds)
      expect(queryDuration.inSeconds, lessThan(2));
    });

    test('Pagination performance with large dataset', () async {
      const bookId = 'pagination_book';
      const totalTransactions = 500;
      const pageSize = 50;

      // ARRANGE: Insert 500 transactions
      for (int i = 0; i < totalTransactions; i++) {
        final transaction = Transaction.create(
          bookId: bookId,
          deviceId: 'device_001',
          amount: 1000 + i,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
        );

        await transactionRepo.insert(transaction);
      }

      // ACT: Query with pagination
      final paginationStartTime = DateTime.now();

      final firstPage = await transactionRepo.findByBook(
        bookId: bookId,
        limit: pageSize,
        offset: 0,
      );

      final secondPage = await transactionRepo.findByBook(
        bookId: bookId,
        limit: pageSize,
        offset: pageSize,
      );

      final lastPage = await transactionRepo.findByBook(
        bookId: bookId,
        limit: pageSize,
        offset: totalTransactions - pageSize,
      );

      final paginationDuration =
          DateTime.now().difference(paginationStartTime);
      print('✅ Paginated queries (3 pages) completed in ${paginationDuration.inMilliseconds}ms');

      // ASSERT: Each page has correct size
      expect(firstPage.length, pageSize);
      expect(secondPage.length, pageSize);
      expect(lastPage.length, pageSize);

      // ASSERT: Pages don't overlap (different transaction IDs)
      final firstPageIds = firstPage.map((t) => t.id).toSet();
      final secondPageIds = secondPage.map((t) => t.id).toSet();
      expect(firstPageIds.intersection(secondPageIds).length, 0);

      // ASSERT: Pagination should be fast (< 1 second for 3 queries)
      expect(paginationDuration.inMilliseconds, lessThan(1000));
    });

    test('Hash chain verification performance', () async {
      const bookId = 'hash_chain_book';
      const chainLength = 200;

      // ARRANGE: Create chain of 200 transactions
      String? prevHash;

      for (int i = 0; i < chainLength; i++) {
        final transaction = Transaction.create(
          bookId: bookId,
          deviceId: 'device_001',
          amount: 1000 + i,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          prevHash: prevHash,
        );

        await transactionRepo.insert(transaction);

        // Get the inserted transaction's hash for next transaction
        final inserted = await transactionRepo.findById(transaction.id);
        prevHash = inserted?.currentHash;
      }

      print('✅ Created hash chain with $chainLength transactions');

      // ACT: Verify hash chain
      final verifyStartTime = DateTime.now();

      final isValid = await transactionRepo.verifyHashChain(bookId);

      final verifyDuration = DateTime.now().difference(verifyStartTime);
      print('✅ Hash chain verification completed in ${verifyDuration.inMilliseconds}ms');

      // ASSERT: Chain is valid
      expect(isValid, isTrue);

      // ASSERT: Verification should be fast (< 2 seconds for 200 items)
      // This tests incremental verification performance
      expect(verifyDuration.inSeconds, lessThan(2));
    });

    test('Hash chain tampering detection', () async {
      const bookId = 'tamper_book';

      // ARRANGE: Create chain of 10 transactions
      final transactions = <Transaction>[];
      String? prevHash;

      for (int i = 0; i < 10; i++) {
        final transaction = Transaction.create(
          bookId: bookId,
          deviceId: 'device_001',
          amount: 1000 + i,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          prevHash: prevHash,
        );

        await transactionRepo.insert(transaction);

        // Get the inserted transaction for next iteration
        final inserted = await transactionRepo.findById(transaction.id);
        transactions.add(inserted!);
        prevHash = inserted.currentHash;
      }

      // ACT: Tamper with middle transaction (modify amount directly in DB)
      final middleTransaction = transactions[5];
      final tamperedTransaction = middleTransaction.copyWith(
        amount: 999999, // Changed amount
        // Keep same currentHash (invalid!)
      );

      await transactionRepo.update(tamperedTransaction);

      // ACT: Verify hash chain
      final isValid = await transactionRepo.verifyHashChain(bookId);

      // ASSERT: Tampering should be detected
      expect(isValid, isFalse);

      print('✅ Hash chain tampering successfully detected');
    });

    test('Query performance with filters', () async {
      const bookId = 'filter_book';
      const totalTransactions = 300;

      // ARRANGE: Insert transactions with various categories and types
      for (int i = 0; i < totalTransactions; i++) {
        final transaction = Transaction.create(
          bookId: bookId,
          deviceId: 'device_001',
          amount: 1000 + i,
          type: i % 3 == 0 ? TransactionType.income : TransactionType.expense,
          categoryId: 'cat_${i % 5}', // 5 different categories
          ledgerType: i % 2 == 0 ? LedgerType.survival : LedgerType.soul,
        );

        await transactionRepo.insert(transaction);
      }

      // ACT: Query with category filter
      final categoryFilterStart = DateTime.now();

      final filteredByCategory = await transactionRepo.findByBook(
        bookId: bookId,
        categoryIds: ['cat_0', 'cat_1'],
        limit: 100,
      );

      final categoryFilterDuration =
          DateTime.now().difference(categoryFilterStart);

      print('✅ Category filter query: ${filteredByCategory.length} results in ${categoryFilterDuration.inMilliseconds}ms');

      // ACT: Query with ledger type filter
      final ledgerFilterStart = DateTime.now();

      final filteredByLedger = await transactionRepo.findByBook(
        bookId: bookId,
        ledgerType: LedgerType.survival,
        limit: 100,
      );

      final ledgerFilterDuration = DateTime.now().difference(ledgerFilterStart);

      print('✅ Ledger type filter query: ${filteredByLedger.length} results in ${ledgerFilterDuration.inMilliseconds}ms');

      // ACT: Query with date range filter
      final dateFilterStart = DateTime.now();

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final filteredByDate = await transactionRepo.findByBook(
        bookId: bookId,
        startDate: yesterday,
        endDate: now,
        limit: 100,
      );

      final dateFilterDuration = DateTime.now().difference(dateFilterStart);

      print('✅ Date range filter query: ${filteredByDate.length} results in ${dateFilterDuration.inMilliseconds}ms');

      // ASSERT: All filter queries should be fast (< 500ms each)
      expect(categoryFilterDuration.inMilliseconds, lessThan(500));
      expect(ledgerFilterDuration.inMilliseconds, lessThan(500));
      expect(dateFilterDuration.inMilliseconds, lessThan(500));

      // ASSERT: Filters work correctly
      expect(filteredByCategory.length, greaterThan(0));
      expect(
        filteredByCategory
            .every((t) => t.categoryId == 'cat_0' || t.categoryId == 'cat_1'),
        isTrue,
      );

      expect(filteredByLedger.length, greaterThan(0));
      expect(
        filteredByLedger.every((t) => t.ledgerType == LedgerType.survival),
        isTrue,
      );
    });

    test('Concurrent read performance', () async {
      const bookId = 'concurrent_book';
      const transactionCount = 100;

      // ARRANGE: Insert 100 transactions
      for (int i = 0; i < transactionCount; i++) {
        final transaction = Transaction.create(
          bookId: bookId,
          deviceId: 'device_001',
          amount: 1000 + i,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
        );

        await transactionRepo.insert(transaction);
      }

      // ACT: Perform 10 concurrent read queries
      final concurrentStartTime = DateTime.now();

      final futures = List.generate(10, (index) {
        return transactionRepo.findByBook(
          bookId: bookId,
          limit: 50,
          offset: index * 5,
        );
      });

      final results = await Future.wait(futures);

      final concurrentDuration = DateTime.now().difference(concurrentStartTime);

      print('✅ 10 concurrent queries completed in ${concurrentDuration.inMilliseconds}ms');

      // ASSERT: All queries returned results
      expect(results.length, 10);
      for (final result in results) {
        expect(result.length, greaterThan(0));
      }

      // ASSERT: Concurrent queries should be fast (< 2 seconds)
      expect(concurrentDuration.inSeconds, lessThan(2));
    });
  });
}
