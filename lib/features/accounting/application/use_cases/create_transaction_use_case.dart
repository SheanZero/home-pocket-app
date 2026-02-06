import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:uuid/uuid.dart';

/// Use case for creating a new transaction
///
/// Handles:
/// - Category validation
/// - Hash chain calculation
/// - Transaction persistence
///
/// Note: Field encryption is handled by Repository layer
class CreateTransactionUseCase {
  CreateTransactionUseCase({
    required this.transactionRepository,
    required this.categoryRepository,
    required this.hashChainService,
  });
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final HashChainService hashChainService;

  /// Execute the use case
  ///
  /// Returns Result<Transaction> with created transaction or error message
  Future<Result<Transaction>> execute({
    required String bookId,
    required String deviceId,
    required int amount,
    required TransactionType type,
    required String categoryId,
    required LedgerType ledgerType,
    String? note,
    String? merchant,
    String? photoHash,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) async {
    try {
      // 1. Validate category exists
      final category = await categoryRepository.findById(categoryId);
      if (category == null) {
        return Result.error('Category not found: $categoryId');
      }

      // 2. Get latest hash for hash chain
      final previousHash = await transactionRepository.getLatestHash(bookId);

      // 3. Generate transaction ID (needed for hash calculation)
      final transactionId = const Uuid().v4();
      final txTimestamp = timestamp ?? DateTime.now();

      // 4. Calculate hash using HashChainService (BEFORE creating transaction)
      final currentHash = hashChainService.calculateTransactionHash(
        transactionId: transactionId,
        amount: amount / 100.0, // Convert cents to dollars
        timestamp: txTimestamp.millisecondsSinceEpoch,
        previousHash: previousHash ?? 'genesis',
      );

      // 5. Create transaction with plaintext fields
      // Repository will handle encryption during persistence
      final transaction = Transaction(
        id: transactionId,
        bookId: bookId,
        deviceId: deviceId,
        amount: amount,
        type: type,
        categoryId: categoryId,
        ledgerType: ledgerType,
        currentHash: currentHash,
        timestamp: txTimestamp,
        note: note, // ✅ Pass plaintext - Repository will encrypt
        merchant: merchant, // ✅ Pass plaintext - Repository will encrypt
        photoHash: photoHash,
        metadata: metadata,
        prevHash: previousHash,
        createdAt: DateTime.now(),
      );

      // 6. Persist transaction (Repository handles encryption)
      await transactionRepository.insert(transaction);

      return Result.success(transaction);
    } catch (e) {
      return Result.error('Failed to create transaction: ${e.toString()}');
    }
  }
}
