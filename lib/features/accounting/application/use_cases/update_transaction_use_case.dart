import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/shared/utils/result.dart';

/// Use case for updating an existing transaction
///
/// Handles:
/// - Transaction validation (exists)
/// - Category validation (if changing)
/// - Field encryption (note, merchant) for new values
/// - Selective field updates (only update provided fields)
/// - Updated timestamp
class UpdateTransactionUseCase {
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final FieldEncryptionService fieldEncryptionService;

  UpdateTransactionUseCase({
    required this.transactionRepository,
    required this.categoryRepository,
    required this.fieldEncryptionService,
  });

  /// Execute the use case
  ///
  /// Only updates fields that are explicitly provided (non-null parameters).
  /// Returns Result<Transaction> with updated transaction or error message.
  Future<Result<Transaction>> execute({
    required String transactionId,
    int? amount,
    TransactionType? type,
    String? categoryId,
    LedgerType? ledgerType,
    String? note,
    String? merchant,
    String? photoHash,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. Get existing transaction
      final existingTransaction =
          await transactionRepository.findById(transactionId);

      if (existingTransaction == null) {
        return Result.error('Transaction not found: $transactionId');
      }

      // 2. Validate new category if changing
      if (categoryId != null && categoryId != existingTransaction.categoryId) {
        final category = await categoryRepository.findById(categoryId);
        if (category == null) {
          return Result.error('Category not found: $categoryId');
        }
      }

      // 3. Encrypt new sensitive fields if provided
      String? encryptedNote = note != null && note.isNotEmpty
          ? await fieldEncryptionService.encryptField(note)
          : (note == null ? existingTransaction.note : null);

      String? encryptedMerchant = merchant != null && merchant.isNotEmpty
          ? await fieldEncryptionService.encryptField(merchant)
          : (merchant == null ? existingTransaction.merchant : null);

      // 4. Create updated transaction with selective updates
      final updatedTransaction = existingTransaction.copyWith(
        amount: amount ?? existingTransaction.amount,
        type: type ?? existingTransaction.type,
        categoryId: categoryId ?? existingTransaction.categoryId,
        ledgerType: ledgerType ?? existingTransaction.ledgerType,
        note: note != null ? encryptedNote : existingTransaction.note,
        merchant:
            merchant != null ? encryptedMerchant : existingTransaction.merchant,
        photoHash: photoHash ?? existingTransaction.photoHash,
        metadata: metadata ?? existingTransaction.metadata,
        updatedAt: DateTime.now(),
      );

      // 5. Persist updated transaction
      await transactionRepository.update(updatedTransaction);

      return Result.success(updatedTransaction);
    } catch (e) {
      return Result.error('Failed to update transaction: ${e.toString()}');
    }
  }
}
