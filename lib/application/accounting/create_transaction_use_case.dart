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
  }) : _transactionRepo = transactionRepository,
       _categoryRepo = categoryRepository,
       _hashChainService = hashChainService;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final HashChainService _hashChainService;

  /// Genesis hash: 64 zero characters (no previous transaction).
  static const _genesisHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

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
    final prevHash =
        await _transactionRepo.getLatestHash(params.bookId) ?? _genesisHash;

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
