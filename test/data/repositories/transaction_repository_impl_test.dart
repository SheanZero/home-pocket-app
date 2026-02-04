import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'transaction_repository_impl_test.mocks.dart';

@GenerateMocks([FieldEncryptionService, HashChainService])
void main() {
  late AppDatabase database;
  late TransactionDao dao;
  late FieldEncryptionService mockEncryptionService;
  late HashChainService mockHashChainService;
  late TransactionRepositoryImpl repository;

  setUp(() {
    // Create in-memory database
    database = AppDatabase(NativeDatabase.memory());
    dao = TransactionDao(database);

    // Create mocks for crypto services
    mockEncryptionService = MockFieldEncryptionService();
    mockHashChainService = MockHashChainService();

    // Create repository with real DAO and mocked crypto services
    repository = TransactionRepositoryImpl(
      database: database,
      dao: dao,
      encryptionService: mockEncryptionService,
      hashChainService: mockHashChainService,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('TransactionRepositoryImpl - insert', () {
    test('should insert transaction with encryption and hash', () async {
      // Arrange
      final transaction = Transaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'device1',
        amount: 100000, // 1000.00 in cents
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 4),
        note: 'Test note',
        merchant: 'Test merchant',
        currentHash: '',
        createdAt: DateTime(2026, 2, 4),
        updatedAt: DateTime(2026, 2, 4),
      );

      // Mock hash calculation
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx1',
        amount: 100000.0, // Convert int to double for hash
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash123');

      // Mock encryption
      when(mockEncryptionService.encryptField('Test note'))
          .thenAnswer((_) async => 'encrypted_note');
      when(mockEncryptionService.encryptField('Test merchant'))
          .thenAnswer((_) async => 'encrypted_merchant');

      // Act
      await repository.insert(transaction);

      // Assert: Verify encryption was called
      verify(mockEncryptionService.encryptField('Test note')).called(1);
      verify(mockEncryptionService.encryptField('Test merchant')).called(1);

      // Assert: Verify hash calculation was called with correct parameters
      verify(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx1',
        amount: 100000.0, // Convert int to double for hash
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).called(1);

      // Assert: Verify transaction stored in database with encrypted data and hash
      final storedTx = await dao.getTransactionById('tx1');
      expect(storedTx, isNotNull);
      expect(storedTx!.id, 'tx1');
      expect(storedTx.note, 'encrypted_note');
      expect(storedTx.merchant, 'encrypted_merchant');
      expect(storedTx.currentHash, 'hash123');
      expect(storedTx.prevHash, 'GENESIS');
    });
  });

  group('TransactionRepositoryImpl - findById', () {
    test('should find by ID and decrypt fields', () async {
      // Arrange: First insert a transaction
      final transaction = Transaction(
        id: 'tx1',
        bookId: 'book1',
        deviceId: 'device1',
        amount: 100000, // 1000.00 in cents
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 4),
        note: 'Test note',
        merchant: 'Test merchant',
        currentHash: '',
        createdAt: DateTime(2026, 2, 4),
        updatedAt: DateTime(2026, 2, 4),
      );

      // Mock hash calculation for insert
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx1',
        amount: 100000.0,
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash123');

      // Mock encryption for insert
      when(mockEncryptionService.encryptField('Test note'))
          .thenAnswer((_) async => 'encrypted_note');
      when(mockEncryptionService.encryptField('Test merchant'))
          .thenAnswer((_) async => 'encrypted_merchant');

      // Insert transaction
      await repository.insert(transaction);

      // Mock decryption for findById
      when(mockEncryptionService.decryptField('encrypted_note'))
          .thenAnswer((_) async => 'Test note');
      when(mockEncryptionService.decryptField('encrypted_merchant'))
          .thenAnswer((_) async => 'Test merchant');

      // Act
      final result = await repository.findById('tx1');

      // Assert: Transaction found and decrypted
      expect(result, isNotNull);
      expect(result!.id, 'tx1');
      expect(result.note, 'Test note'); // Decrypted
      expect(result.merchant, 'Test merchant'); // Decrypted
      expect(result.amount, 100000);

      // Verify decryption was called with encrypted values
      verify(mockEncryptionService.decryptField('encrypted_note')).called(1);
      verify(mockEncryptionService.decryptField('encrypted_merchant')).called(1);
    });

    test('should return null for non-existent transaction', () async {
      // Act
      final result = await repository.findById('non_existent_id');

      // Assert
      expect(result, isNull);
    });
  });

  group('TransactionRepositoryImpl - findByBook', () {
    test('should find transactions by book and decrypt all', () async {
      // Arrange: Insert 3 transactions for same book
      final tx1 = Transaction(
        id: 'tx_find_1',
        bookId: 'book_filter',
        deviceId: 'device1',
        amount: 50000, // 500.00 in cents
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 1),
        note: 'Note 1',
        merchant: 'Merchant 1',
        currentHash: '',
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final tx2 = Transaction(
        id: 'tx_find_2',
        bookId: 'book_filter',
        deviceId: 'device1',
        amount: 60000, // 600.00 in cents
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 2),
        note: 'Note 2',
        merchant: 'Merchant 2',
        currentHash: '',
        createdAt: DateTime(2026, 2, 2),
        updatedAt: DateTime(2026, 2, 2),
      );

      final tx3 = Transaction(
        id: 'tx_find_3',
        bookId: 'book_filter',
        deviceId: 'device1',
        amount: 70000, // 700.00 in cents
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 3),
        note: 'Note 3',
        merchant: 'Merchant 3',
        currentHash: '',
        createdAt: DateTime(2026, 2, 3),
        updatedAt: DateTime(2026, 2, 3),
      );

      // Mock hash calculation for all inserts
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_find_1',
        amount: 50000.0,
        timestamp: tx1.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash_tx_find_1');

      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_find_2',
        amount: 60000.0,
        timestamp: tx2.timestamp.millisecondsSinceEpoch,
        previousHash: 'hash_tx_find_1',
      )).thenReturn('hash_tx_find_2');

      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_find_3',
        amount: 70000.0,
        timestamp: tx3.timestamp.millisecondsSinceEpoch,
        previousHash: 'hash_tx_find_2',
      )).thenReturn('hash_tx_find_3');

      when(mockEncryptionService.encryptField('Note 1'))
          .thenAnswer((_) async => 'encrypted_note_1');
      when(mockEncryptionService.encryptField('Merchant 1'))
          .thenAnswer((_) async => 'encrypted_merchant_1');
      when(mockEncryptionService.encryptField('Note 2'))
          .thenAnswer((_) async => 'encrypted_note_2');
      when(mockEncryptionService.encryptField('Merchant 2'))
          .thenAnswer((_) async => 'encrypted_merchant_2');
      when(mockEncryptionService.encryptField('Note 3'))
          .thenAnswer((_) async => 'encrypted_note_3');
      when(mockEncryptionService.encryptField('Merchant 3'))
          .thenAnswer((_) async => 'encrypted_merchant_3');

      // Insert transactions
      await repository.insert(tx1);
      await repository.insert(tx2);
      await repository.insert(tx3);

      // Mock decryption for findByBook
      when(mockEncryptionService.decryptField('encrypted_note_1'))
          .thenAnswer((_) async => 'Note 1');
      when(mockEncryptionService.decryptField('encrypted_merchant_1'))
          .thenAnswer((_) async => 'Merchant 1');
      when(mockEncryptionService.decryptField('encrypted_note_2'))
          .thenAnswer((_) async => 'Note 2');
      when(mockEncryptionService.decryptField('encrypted_merchant_2'))
          .thenAnswer((_) async => 'Merchant 2');
      when(mockEncryptionService.decryptField('encrypted_note_3'))
          .thenAnswer((_) async => 'Note 3');
      when(mockEncryptionService.decryptField('encrypted_merchant_3'))
          .thenAnswer((_) async => 'Merchant 3');

      // Act: Find all transactions for book
      final result = await repository.findByBook(bookId: 'book_filter');

      // Assert: All 3 transactions found and decrypted
      expect(result, hasLength(3));

      // Verify newest first (tx_find_3, tx_find_2, tx_find_1)
      expect(result[0].id, 'tx_find_3');
      expect(result[0].note, 'Note 3'); // Decrypted
      expect(result[0].merchant, 'Merchant 3'); // Decrypted

      expect(result[1].id, 'tx_find_2');
      expect(result[1].note, 'Note 2'); // Decrypted
      expect(result[1].merchant, 'Merchant 2'); // Decrypted

      expect(result[2].id, 'tx_find_1');
      expect(result[2].note, 'Note 1'); // Decrypted
      expect(result[2].merchant, 'Merchant 1'); // Decrypted
    });

    test('should filter by date range', () async {
      // Arrange: Insert 2 transactions in different months
      final txJan = Transaction(
        id: 'tx_jan',
        bookId: 'book_date_filter',
        deviceId: 'device1',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 1, 15), // January
        note: 'January transaction',
        merchant: 'Merchant Jan',
        currentHash: '',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
      );

      final txFeb = Transaction(
        id: 'tx_feb',
        bookId: 'book_date_filter',
        deviceId: 'device1',
        amount: 60000,
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 15), // February
        note: 'February transaction',
        merchant: 'Merchant Feb',
        currentHash: '',
        createdAt: DateTime(2026, 2, 15),
        updatedAt: DateTime(2026, 2, 15),
      );

      // Mock hash calculation for both inserts
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_jan',
        amount: 50000.0,
        timestamp: txJan.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash_tx_jan');

      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_feb',
        amount: 60000.0,
        timestamp: txFeb.timestamp.millisecondsSinceEpoch,
        previousHash: 'hash_tx_jan',
      )).thenReturn('hash_tx_feb');

      when(mockEncryptionService.encryptField('January transaction'))
          .thenAnswer((_) async => 'encrypted_jan');
      when(mockEncryptionService.encryptField('Merchant Jan'))
          .thenAnswer((_) async => 'encrypted_merchant_jan');
      when(mockEncryptionService.encryptField('February transaction'))
          .thenAnswer((_) async => 'encrypted_feb');
      when(mockEncryptionService.encryptField('Merchant Feb'))
          .thenAnswer((_) async => 'encrypted_merchant_feb');

      // Insert transactions
      await repository.insert(txJan);
      await repository.insert(txFeb);

      // Mock decryption for February transaction only
      when(mockEncryptionService.decryptField('encrypted_feb'))
          .thenAnswer((_) async => 'February transaction');
      when(mockEncryptionService.decryptField('encrypted_merchant_feb'))
          .thenAnswer((_) async => 'Merchant Feb');

      // Act: Filter for February only
      final result = await repository.findByBook(
        bookId: 'book_date_filter',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28, 23, 59, 59),
      );

      // Assert: Only February transaction returned
      expect(result, hasLength(1));
      expect(result[0].id, 'tx_feb');
      expect(result[0].note, 'February transaction'); // Decrypted
      expect(result[0].merchant, 'Merchant Feb'); // Decrypted
    });
  });

  group('TransactionRepositoryImpl - update', () {
    test('should update transaction with re-encryption', () async {
      // Arrange: Insert transaction with original values
      final transaction = Transaction(
        id: 'tx_update',
        bookId: 'book1',
        deviceId: 'device1',
        amount: 100000, // 1000.00 in cents
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 4),
        note: 'Original note',
        merchant: 'Original merchant',
        currentHash: '',
        createdAt: DateTime(2026, 2, 4),
        updatedAt: DateTime(2026, 2, 4),
      );

      // Mock hash calculation for insert
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_update',
        amount: 100000.0,
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash_update');

      // Mock encryption for insert
      when(mockEncryptionService.encryptField('Original note'))
          .thenAnswer((_) async => 'encrypted_original_note');
      when(mockEncryptionService.encryptField('Original merchant'))
          .thenAnswer((_) async => 'encrypted_original_merchant');

      // Insert transaction
      await repository.insert(transaction);

      // Mock encryption for update with NEW values
      when(mockEncryptionService.encryptField('Updated note'))
          .thenAnswer((_) async => 'encrypted_updated_note');
      when(mockEncryptionService.encryptField('Updated merchant'))
          .thenAnswer((_) async => 'encrypted_updated_merchant');

      // Act: Update transaction with new values
      final updatedTransaction = transaction.copyWith(
        note: 'Updated note',
        merchant: 'Updated merchant',
        amount: 150000, // Change amount to 1500.00
      );
      await repository.update(updatedTransaction);

      // Mock decryption for verification
      when(mockEncryptionService.decryptField('encrypted_updated_note'))
          .thenAnswer((_) async => 'Updated note');
      when(mockEncryptionService.decryptField('encrypted_updated_merchant'))
          .thenAnswer((_) async => 'Updated merchant');

      // Assert: Verify encryption was called with NEW values
      verify(mockEncryptionService.encryptField('Updated note')).called(1);
      verify(mockEncryptionService.encryptField('Updated merchant')).called(1);

      // Assert: Verify transaction updated in database with encrypted data
      final retrieved = await repository.findById('tx_update');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'tx_update');
      expect(retrieved.note, 'Updated note'); // Decrypted
      expect(retrieved.merchant, 'Updated merchant'); // Decrypted
      expect(retrieved.amount, 150000);
    });
  });

  group('TransactionRepositoryImpl - delete', () {
    test('should hard delete transaction', () async {
      // Arrange: Insert transaction
      final transaction = Transaction(
        id: 'tx_delete',
        bookId: 'book1',
        deviceId: 'device1',
        amount: 100000,
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 4),
        note: 'Delete test',
        merchant: 'Merchant',
        currentHash: '',
        createdAt: DateTime(2026, 2, 4),
        updatedAt: DateTime(2026, 2, 4),
      );

      // Mock hash and encryption for insert
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_delete',
        amount: 100000.0,
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash_delete');

      when(mockEncryptionService.encryptField('Delete test'))
          .thenAnswer((_) async => 'encrypted_delete_test');
      when(mockEncryptionService.encryptField('Merchant'))
          .thenAnswer((_) async => 'encrypted_merchant');

      // Insert transaction
      await repository.insert(transaction);

      // Act: Delete transaction
      await repository.delete('tx_delete');

      // Assert: Transaction no longer exists
      final result = await repository.findById('tx_delete');
      expect(result, isNull);
    });

    test('should soft delete transaction', () async {
      // Arrange: Insert transaction
      final transaction = Transaction(
        id: 'tx_soft_delete',
        bookId: 'book1',
        deviceId: 'device1',
        amount: 100000,
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 4),
        note: 'Soft delete test',
        merchant: 'Merchant',
        currentHash: '',
        createdAt: DateTime(2026, 2, 4),
        updatedAt: DateTime(2026, 2, 4),
      );

      // Mock hash and encryption for insert
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_soft_delete',
        amount: 100000.0,
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash_soft_delete');

      when(mockEncryptionService.encryptField('Soft delete test'))
          .thenAnswer((_) async => 'encrypted_soft_delete_test');
      when(mockEncryptionService.encryptField('Merchant'))
          .thenAnswer((_) async => 'encrypted_merchant');

      // Insert transaction
      await repository.insert(transaction);

      // Act: Soft delete transaction
      await repository.softDelete('tx_soft_delete');

      // Assert: Transaction not returned by findById (soft deleted are excluded)
      final result = await repository.findById('tx_soft_delete');
      expect(result, isNull);
    });
  });

  group('TransactionRepositoryImpl - utilities', () {
    test('should get latest hash', () async {
      // Arrange: Insert transaction
      final transaction = Transaction(
        id: 'tx_hash',
        bookId: 'book_hash',
        deviceId: 'device1',
        amount: 100000,
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 4),
        note: 'Hash test',
        merchant: 'Merchant',
        currentHash: '',
        createdAt: DateTime(2026, 2, 4),
        updatedAt: DateTime(2026, 2, 4),
      );

      // Mock hash and encryption for insert
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_hash',
        amount: 100000.0,
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash_tx_hash');

      when(mockEncryptionService.encryptField('Hash test'))
          .thenAnswer((_) async => 'encrypted_hash_test');
      when(mockEncryptionService.encryptField('Merchant'))
          .thenAnswer((_) async => 'encrypted_merchant');

      // Insert transaction
      await repository.insert(transaction);

      // Act: Get latest hash
      final latestHash = await repository.getLatestHash('book_hash');

      // Assert: Latest hash is returned
      expect(latestHash, isNotNull);
      expect(latestHash, 'hash_tx_hash');
    });

    test('should count transactions', () async {
      // Arrange: Insert 5 transactions for same book
      for (int i = 1; i <= 5; i++) {
        final tx = Transaction(
          id: 'tx_count_$i',
          bookId: 'book_count',
          deviceId: 'device1',
          amount: i * 10000, // Vary amounts
          type: TransactionType.expense,
          categoryId: 'cat1',
          ledgerType: LedgerType.survival,
          timestamp: DateTime(2026, 2, i),
          note: 'Count test $i',
          merchant: 'Merchant $i',
          currentHash: '',
          createdAt: DateTime(2026, 2, i),
          updatedAt: DateTime(2026, 2, i),
        );

        // Mock hash calculation (chain each transaction)
        final prevHash = i == 1 ? 'GENESIS' : 'hash_tx_count_${i - 1}';
        when(mockHashChainService.calculateTransactionHash(
          transactionId: 'tx_count_$i',
          amount: (i * 10000).toDouble(),
          timestamp: tx.timestamp.millisecondsSinceEpoch,
          previousHash: prevHash,
        )).thenReturn('hash_tx_count_$i');

        // Mock encryption
        when(mockEncryptionService.encryptField('Count test $i'))
            .thenAnswer((_) async => 'encrypted_count_$i');
        when(mockEncryptionService.encryptField('Merchant $i'))
            .thenAnswer((_) async => 'encrypted_merchant_$i');

        await repository.insert(tx);
      }

      // Act: Count transactions
      final count = await repository.count('book_count');

      // Assert: Count is 5
      expect(count, 5);
    });

    test('should verify valid hash chain', () async {
      // Arrange: Insert 3 transactions with proper chain
      final tx1 = Transaction(
        id: 'tx_chain_1',
        bookId: 'book_chain',
        deviceId: 'device1',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 1),
        note: 'Chain 1',
        merchant: 'Merchant 1',
        currentHash: '',
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final tx2 = Transaction(
        id: 'tx_chain_2',
        bookId: 'book_chain',
        deviceId: 'device1',
        amount: 20000,
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 2),
        note: 'Chain 2',
        merchant: 'Merchant 2',
        currentHash: '',
        createdAt: DateTime(2026, 2, 2),
        updatedAt: DateTime(2026, 2, 2),
      );

      final tx3 = Transaction(
        id: 'tx_chain_3',
        bookId: 'book_chain',
        deviceId: 'device1',
        amount: 30000,
        type: TransactionType.expense,
        categoryId: 'cat1',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 3),
        note: 'Chain 3',
        merchant: 'Merchant 3',
        currentHash: '',
        createdAt: DateTime(2026, 2, 3),
        updatedAt: DateTime(2026, 2, 3),
      );

      // Mock hash calculation for chain (tx1 -> tx2 -> tx3)
      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_chain_1',
        amount: 10000.0,
        timestamp: tx1.timestamp.millisecondsSinceEpoch,
        previousHash: 'GENESIS',
      )).thenReturn('hash_chain_1');

      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_chain_2',
        amount: 20000.0,
        timestamp: tx2.timestamp.millisecondsSinceEpoch,
        previousHash: 'hash_chain_1',
      )).thenReturn('hash_chain_2');

      when(mockHashChainService.calculateTransactionHash(
        transactionId: 'tx_chain_3',
        amount: 30000.0,
        timestamp: tx3.timestamp.millisecondsSinceEpoch,
        previousHash: 'hash_chain_2',
      )).thenReturn('hash_chain_3');

      // Mock encryption for all
      when(mockEncryptionService.encryptField('Chain 1'))
          .thenAnswer((_) async => 'encrypted_chain_1');
      when(mockEncryptionService.encryptField('Merchant 1'))
          .thenAnswer((_) async => 'encrypted_merchant_1');
      when(mockEncryptionService.encryptField('Chain 2'))
          .thenAnswer((_) async => 'encrypted_chain_2');
      when(mockEncryptionService.encryptField('Merchant 2'))
          .thenAnswer((_) async => 'encrypted_merchant_2');
      when(mockEncryptionService.encryptField('Chain 3'))
          .thenAnswer((_) async => 'encrypted_chain_3');
      when(mockEncryptionService.encryptField('Merchant 3'))
          .thenAnswer((_) async => 'encrypted_merchant_3');

      // Insert transactions
      await repository.insert(tx1);
      await repository.insert(tx2);
      await repository.insert(tx3);

      // Act: Verify hash chain
      final isValid = await repository.verifyHashChain('book_chain');

      // Assert: Chain is valid
      expect(isValid, true);
    });

    test('should return true for empty book', () async {
      // Act: Verify hash chain for book with no transactions
      final isValid = await repository.verifyHashChain('empty_book');

      // Assert: Empty chain is valid
      expect(isValid, true);
    });
  });
}
