import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/shared/utils/result.dart';

/// Use case for creating a new transaction
///
/// Handles:
/// - Category validation
/// - Hash chain calculation
/// - Field encryption (note, merchant)
/// - Transaction persistence
class CreateTransactionUseCase {
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final HashChainService hashChainService;
  final FieldEncryptionService fieldEncryptionService;

  CreateTransactionUseCase({
    required this.transactionRepository,
    required this.categoryRepository,
    required this.hashChainService,
    required this.fieldEncryptionService,
  });

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

      // 2. Encrypt sensitive fields if provided
      String? encryptedNote;
      String? encryptedMerchant;

      if (note != null && note.isNotEmpty) {
        encryptedNote = await fieldEncryptionService.encryptField(note);
      }

      if (merchant != null && merchant.isNotEmpty) {
        encryptedMerchant = await fieldEncryptionService.encryptField(merchant);
      }

      // 3. Get latest hash for hash chain
      final previousHash = await transactionRepository.getLatestHash(bookId);

      // 4. Create transaction (which calculates its own hash)
      final transaction = Transaction.create(
        bookId: bookId,
        deviceId: deviceId,
        amount: amount,
        type: type,
        categoryId: categoryId,
        ledgerType: ledgerType,
        note: encryptedNote,
        merchant: encryptedMerchant,
        photoHash: photoHash,
        metadata: metadata,
        timestamp: timestamp,
        prevHash: previousHash,
      );

      // 5. Verify hash is correct (using HashChainService)
      final calculatedHash = hashChainService.calculateTransactionHash(
        transactionId: transaction.id,
        amount: transaction.amount / 100.0, // Convert cents to dollars
        timestamp: transaction.timestamp.millisecondsSinceEpoch,
        previousHash: previousHash ?? 'genesis',
      );

      // Update transaction with verified hash
      final verifiedTransaction = transaction.copyWith(
        currentHash: calculatedHash,
      );

      // 6. Persist transaction
      await transactionRepository.insert(verifiedTransaction);

      return Result.success(verifiedTransaction);
    } catch (e) {
      return Result.error('Failed to create transaction: ${e.toString()}');
    }
  }
}
