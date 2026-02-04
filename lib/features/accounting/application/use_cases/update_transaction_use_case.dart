import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/shared/utils/result.dart';

/// Use case for updating an existing transaction
///
/// Handles:
/// - Transaction validation (exists)
/// - Category validation (if changing)
/// - Selective field updates (only update provided fields)
/// - Updated timestamp
///
/// Note: Field encryption is handled by Repository layer
class UpdateTransactionUseCase {
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  UpdateTransactionUseCase({
    required this.transactionRepository,
    required this.categoryRepository,
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

      // 3. Create updated transaction with selective updates
      // Repository will handle encryption for note and merchant
      final updatedTransaction = existingTransaction.copyWith(
        amount: amount ?? existingTransaction.amount,
        type: type ?? existingTransaction.type,
        categoryId: categoryId ?? existingTransaction.categoryId,
        ledgerType: ledgerType ?? existingTransaction.ledgerType,
        note: note ?? existingTransaction.note, // ✅ Pass plaintext - Repository will encrypt
        merchant: merchant ?? existingTransaction.merchant, // ✅ Pass plaintext - Repository will encrypt
        photoHash: photoHash ?? existingTransaction.photoHash,
        metadata: metadata ?? existingTransaction.metadata,
        updatedAt: DateTime.now(),
      );

      // 4. Persist updated transaction (Repository handles encryption)
      await transactionRepository.update(updatedTransaction);

      return Result.success(updatedTransaction);
    } catch (e) {
      return Result.error('Failed to update transaction: ${e.toString()}');
    }
  }
}
