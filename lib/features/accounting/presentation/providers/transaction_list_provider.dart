import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_list_provider.g.dart';

/// Transaction List Provider
/// Manages the list of transactions for display with filtering and pagination
@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<Transaction>> build({
    required String bookId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    LedgerType? ledgerType,
    int limit = 50,
    int offset = 0,
  }) async {
    // Get the use case
    final useCase = ref.watch(getTransactionsUseCaseProvider);

    // Execute query with filters
    final result = await useCase.execute(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      categoryIds: categoryIds,
      ledgerType: ledgerType,
      limit: limit,
      offset: offset,
    );

    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception(result.error ?? 'Failed to load transactions');
    }
  }

  /// Refresh the transaction list
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Delete a transaction by ID
  Future<void> deleteTransaction(String transactionId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Get delete use case
      final deleteUseCase = ref.read(deleteTransactionUseCaseProvider);

      // Delete the transaction
      final result = await deleteUseCase.execute(transactionId: transactionId);

      if (!result.isSuccess) {
        throw Exception(result.error ?? 'Failed to delete transaction');
      }

      // Return updated list (filter out deleted transaction)
      return state.value?.where((tx) => tx.id != transactionId).toList() ?? [];
    });
  }
}
