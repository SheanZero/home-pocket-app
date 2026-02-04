import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';

// Mock secure storage for integration tests
class MockSecureStorage implements FlutterSecureStorage {
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
    if (value != null) {
      _storage[key] = value;
    }
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
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TransactionRepository Integration Tests with Real Crypto', () {
    late AppDatabase database;
    late TransactionDao dao;
    late KeyManager keyManager;
    late FieldEncryptionService fieldEncryptionService;
    late HashChainService hashChainService;
    late TransactionRepositoryImpl repository;

    setUp(() async {
      // Setup in-memory database
      database = AppDatabase(NativeDatabase.memory());
      dao = TransactionDao(database);

      // Setup REAL crypto services
      final secureStorage = MockSecureStorage();
      final keyRepository = KeyRepositoryImpl(secureStorage: secureStorage);
      final encryptionRepository = EncryptionRepositoryImpl(keyRepository: keyRepository);

      keyManager = KeyManager(repository: keyRepository);
      fieldEncryptionService = FieldEncryptionService(repository: encryptionRepository);
      hashChainService = HashChainService();

      // Generate real device key pair (CRITICAL: not mocked)
      await keyManager.generateDeviceKeyPair();

      // Create repository with real services
      repository = TransactionRepositoryImpl(
        database: database,
        dao: dao,
        encryptionService: fieldEncryptionService,
        hashChainService: hashChainService,
      );
    });

    tearDown(() async {
      // Cleanup
      await database.close();
      await keyManager.clearKeys();
    });

    test('should encrypt, store, and decrypt transaction', () async {
      // Create transaction with sensitive data
      final transaction = Transaction.create(
        bookId: 'book-001',
        deviceId: 'device-001',
        amount: 12345,
        type: TransactionType.expense,
        categoryId: 'cat-001',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
        note: 'Sensitive note content',
        merchant: 'Secret Merchant Name',
      );

      // Insert transaction (will encrypt note and merchant)
      await repository.insert(transaction);

      // Query database directly to verify encryption
      final storedTransaction = await dao.getTransactionById(transaction.id);
      expect(storedTransaction, isNotNull);

      // CRITICAL: Verify note is encrypted (not plain text)
      expect(storedTransaction!.note, isNotNull);
      expect(storedTransaction.note, isNot(equals('Sensitive note content')));
      expect(storedTransaction.note!.length, greaterThan(20)); // Encrypted data is longer

      // CRITICAL: Verify merchant is encrypted (not plain text)
      expect(storedTransaction.merchant, isNotNull);
      expect(storedTransaction.merchant, isNot(equals('Secret Merchant Name')));
      expect(storedTransaction.merchant!.length, greaterThan(20));

      // Retrieve via repository (should decrypt)
      final retrieved = await repository.findById(transaction.id);
      expect(retrieved, isNotNull);

      // CRITICAL: Verify decryption successful
      expect(retrieved!.note, equals('Sensitive note content'));
      expect(retrieved.merchant, equals('Secret Merchant Name'));
      expect(retrieved.amount, equals(12345));
    });

    test('should maintain hash chain integrity', () async {
      const bookId = 'book-001';
      const deviceId = 'device-001';

      // CRITICAL: Create timestamps with second-level precision (no milliseconds)
      // This is required because SQLite DateTimeColumn truncates to seconds,
      // and hash calculations must use the same precision as stored timestamps
      final baseTimestamp = DateTime.fromMillisecondsSinceEpoch(
        (DateTime.now().millisecondsSinceEpoch / 1000).floor() * 1000,
      );

      // Insert 3 transactions with distinct timestamps (second precision)
      final tx1 = Transaction.create(
        bookId: bookId,
        deviceId: deviceId,
        amount: 1000,
        type: TransactionType.expense,
        categoryId: 'cat-001',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
        note: 'Transaction 1',
        timestamp: baseTimestamp,
      );

      await repository.insert(tx1);

      // CRITICAL: Delay must be > 1 second to ensure different createdAt
      // (SQLite DateTime has second precision)
      await Future.delayed(const Duration(seconds: 1, milliseconds: 100));

      final tx2 = Transaction.create(
        bookId: bookId,
        deviceId: deviceId,
        amount: 2000,
        type: TransactionType.expense,
        categoryId: 'cat-002',
        ledgerType: LedgerType.soul,
        currentHash: 'test_hash',
        note: 'Transaction 2',
        timestamp: baseTimestamp.add(const Duration(seconds: 1)),
      );

      await repository.insert(tx2);

      // CRITICAL: Delay must be > 1 second to ensure different createdAt
      // (SQLite DateTime has second precision)
      await Future.delayed(const Duration(seconds: 1, milliseconds: 100));

      final tx3 = Transaction.create(
        bookId: bookId,
        deviceId: deviceId,
        amount: 3000,
        type: TransactionType.income,
        categoryId: 'cat-003',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
        note: 'Transaction 3',
        timestamp: baseTimestamp.add(const Duration(seconds: 2)),
      );

      await repository.insert(tx3);

      // Verify hash chain integrity via repository
      final isValid = await repository.verifyHashChain(bookId);
      expect(isValid, true, reason: 'Hash chain verification should pass');

      // Get all transactions to verify hash chain structure
      final allTransactions = await dao.getTransactionsByBook(
        bookId,
        limit: 999,
        offset: 0,
      );

      expect(allTransactions.length, equals(3));

      // CRITICAL: Verify first transaction uses GENESIS
      final firstTx = allTransactions.last; // List is newest first, so last = oldest
      expect(firstTx.prevHash, equals('GENESIS'));
      expect(firstTx.currentHash, isNotEmpty);

      // CRITICAL: Verify subsequent transactions have valid prevHash
      // (each tx's prevHash should be non-empty and not equal to its own currentHash)
      for (final tx in allTransactions) {
        expect(tx.currentHash, isNotEmpty);
        if (tx.prevHash != 'GENESIS') {
          expect(tx.prevHash, isNotEmpty);
          expect(tx.currentHash, isNot(equals(tx.prevHash)));
        }
      }
    });
  });
}
