import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';

/// Implementation of TransactionRepository
///
/// LOCATION: lib/data/repositories/ (SHARED)
/// This is in the shared data layer because multiple features need transaction access:
/// - Accounting module (create/edit transactions)
/// - Reports module (read transaction history)
/// - Budgets module (analyze spending)
/// - Sync module (sync transaction data)
///
/// Per CLAUDE.md Capability Classification Rule: "Will other features need this?" → YES
/// Per Phase 2 Design Doc: Repositories are shared capabilities in lib/data/
///
/// Handles:
/// - Database operations via DAO
/// - Field encryption/decryption for sensitive data
/// - Hash chain management for integrity
class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase database;
  final TransactionDao dao;
  final FieldEncryptionService encryptionService;
  final HashChainService hashChainService;

  TransactionRepositoryImpl({
    required this.database,
    required this.dao,
    required this.encryptionService,
    required this.hashChainService,
  });

  @override
  Future<void> insert(Transaction transaction) async {
    // 1. Get previous hash from DAO (or 'GENESIS' if first transaction)
    final previousHash =
        await dao.getLatestHash(transaction.bookId) ?? 'GENESIS';

    // 2. Calculate current hash using HashChainService
    final currentHash = hashChainService.calculateTransactionHash(
      transactionId: transaction.id,
      amount: transaction.amount.toDouble(),
      timestamp: transaction.timestamp.millisecondsSinceEpoch,
      previousHash: previousHash,
    );

    // 3. Encrypt sensitive fields (note, merchant)
    String? encryptedNote;
    if (transaction.note != null) {
      encryptedNote = await encryptionService.encryptField(transaction.note!);
    }

    String? encryptedMerchant;
    if (transaction.merchant != null) {
      encryptedMerchant =
          await encryptionService.encryptField(transaction.merchant!);
    }

    // 4. Create transaction with hash and encrypted data
    final transactionWithHash = transaction.copyWith(
      currentHash: currentHash,
      prevHash: previousHash,
      note: encryptedNote,
      merchant: encryptedMerchant,
    );

    // 5. Insert via DAO
    await dao.insertTransaction(transactionWithHash);
  }

  @override
  Future<void> update(Transaction transaction) async {
    // 1. Re-encrypt sensitive fields with new values
    String? encryptedNote;
    if (transaction.note != null) {
      encryptedNote = await encryptionService.encryptField(transaction.note!);
    }

    String? encryptedMerchant;
    if (transaction.merchant != null) {
      encryptedMerchant =
          await encryptionService.encryptField(transaction.merchant!);
    }

    // 2. Set updatedAt to current time
    final now = DateTime.now();

    // 3. Create transaction with encrypted data and updated timestamp
    final transactionToUpdate = transaction.copyWith(
      note: encryptedNote,
      merchant: encryptedMerchant,
      updatedAt: now,
    );

    // 4. Update via DAO
    await dao.updateTransaction(transactionToUpdate);
  }

  @override
  Future<void> delete(String id) async {
    // Hard delete via DAO
    await dao.deleteTransaction(id);
  }

  @override
  Future<void> softDelete(String id) async {
    // Soft delete via DAO
    await dao.softDeleteTransaction(id);
  }

  @override
  Future<Transaction?> findById(String id) async {
    // 1. Get transaction from DAO
    final transaction = await dao.getTransactionById(id);

    // 2. Return null if not found or soft deleted
    if (transaction == null || transaction.isDeleted) {
      return null;
    }

    // 3. Decrypt sensitive fields and return
    return _decryptTransaction(transaction);
  }

  @override
  Future<List<Transaction>> findByBook({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    LedgerType? ledgerType,
    int limit = 100,
    int offset = 0,
  }) async {
    // 1. Get transactions from DAO with filters
    final transactions = await dao.getTransactionsByBook(
      bookId,
      startDate: startDate,
      endDate: endDate,
      categoryIds: categoryIds,
      ledgerType: ledgerType,
      limit: limit,
      offset: offset,
    );

    // 2. Decrypt all transactions
    final decryptedTransactions = <Transaction>[];
    for (final transaction in transactions) {
      final decrypted = await _decryptTransaction(transaction);
      decryptedTransactions.add(decrypted);
    }

    // 3. Return decrypted list (already sorted newest first by DAO)
    return decryptedTransactions;
  }

  @override
  Future<String?> getLatestHash(String bookId) async {
    // Delegate to DAO
    return dao.getLatestHash(bookId);
  }

  @override
  Future<int> count(String bookId) async {
    // Delegate to DAO
    return dao.countTransactions(bookId);
  }

  @override
  Future<bool> verifyHashChain(String bookId) async {
    // 1. Get all transactions for the book, ordered by timestamp (oldest first)
    final transactions = await dao.getTransactionsByBook(
      bookId,
      limit: 999999, // Get all transactions
      offset: 0,
    );

    // 2. If no transactions, chain is valid
    if (transactions.isEmpty) {
      return true;
    }

    // 3. Verify first transaction has prevHash = 'GENESIS'
    final firstTx = transactions.last; // List is newest first, so last = oldest
    if (firstTx.prevHash != 'GENESIS') {
      return false;
    }

    // 4. Verify each transaction's hash matches calculated hash
    // and each transaction's prevHash matches previous transaction's currentHash
    // Iterate in reverse order (oldest to newest)
    for (int i = transactions.length - 1; i >= 0; i--) {
      final tx = transactions[i];

      // Get previous hash
      final expectedPrevHash = i == transactions.length - 1
          ? 'GENESIS'
          : transactions[i + 1].currentHash;

      // Verify prevHash is correct
      if (tx.prevHash != expectedPrevHash) {
        return false;
      }

      // Calculate expected hash
      final calculatedHash = hashChainService.calculateTransactionHash(
        transactionId: tx.id,
        amount: tx.amount.toDouble(),
        timestamp: tx.timestamp.millisecondsSinceEpoch,
        previousHash:
            tx.prevHash ?? 'GENESIS', // Use GENESIS if null (shouldn't happen)
      );

      // Verify currentHash matches calculated hash
      if (tx.currentHash != calculatedHash) {
        return false;
      }
    }

    // 5. All verifications passed
    return true;
  }

  /// Helper method to decrypt sensitive fields in a transaction
  Future<Transaction> _decryptTransaction(Transaction transaction) async {
    String? decryptedNote;
    if (transaction.note != null) {
      decryptedNote = await encryptionService.decryptField(transaction.note!);
    }

    String? decryptedMerchant;
    if (transaction.merchant != null) {
      decryptedMerchant =
          await encryptionService.decryptField(transaction.merchant!);
    }

    return transaction.copyWith(
      note: decryptedNote,
      merchant: decryptedMerchant,
    );
  }
}
