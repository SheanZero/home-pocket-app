import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/shared/utils/result.dart';

/// Use case for retrieving transactions
///
/// Handles:
/// - Querying transactions by book with filters
/// - Field decryption (note, merchant)
/// - Pagination support
class GetTransactionsUseCase {
  final TransactionRepository transactionRepository;
  final FieldEncryptionService fieldEncryptionService;

  GetTransactionsUseCase({
    required this.transactionRepository,
    required this.fieldEncryptionService,
  });

  /// Execute the use case
  ///
  /// Returns Result<List<Transaction>> with transactions or error message
  Future<Result<List<Transaction>>> execute({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    LedgerType? ledgerType,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // 1. Query transactions from repository
      final transactions = await transactionRepository.findByBook(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        categoryIds: categoryIds,
        ledgerType: ledgerType,
        limit: limit,
        offset: offset,
      );

      // 2. Decrypt encrypted fields
      final decryptedTransactions = <Transaction>[];

      for (final transaction in transactions) {
        String? decryptedNote;
        String? decryptedMerchant;

        // Decrypt note if present
        if (transaction.note != null && transaction.note!.isNotEmpty) {
          try {
            decryptedNote =
                await fieldEncryptionService.decryptField(transaction.note!);
          } catch (e) {
            // If decryption fails, keep encrypted value
            decryptedNote = transaction.note;
          }
        }

        // Decrypt merchant if present
        if (transaction.merchant != null &&
            transaction.merchant!.isNotEmpty) {
          try {
            decryptedMerchant = await fieldEncryptionService
                .decryptField(transaction.merchant!);
          } catch (e) {
            // If decryption fails, keep encrypted value
            decryptedMerchant = transaction.merchant;
          }
        }

        // Create transaction with decrypted fields
        final decryptedTransaction = transaction.copyWith(
          note: decryptedNote,
          merchant: decryptedMerchant,
        );

        decryptedTransactions.add(decryptedTransaction);
      }

      return Result.success(decryptedTransactions);
    } catch (e) {
      return Result.error('Failed to get transactions: ${e.toString()}');
    }
  }
}
