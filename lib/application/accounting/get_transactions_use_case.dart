import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/result.dart';

/// Parameters for querying transactions.
class GetTransactionsParams {
  final String bookId;
  final LedgerType? ledgerType;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const GetTransactionsParams({
    required this.bookId,
    this.ledgerType,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.limit = 100,
    this.offset = 0,
  });
}

/// Fetches transactions for a book with optional filters.
class GetTransactionsUseCase {
  GetTransactionsUseCase({
    required TransactionRepository transactionRepository,
  }) : _transactionRepo = transactionRepository;

  final TransactionRepository _transactionRepo;

  Future<Result<List<Transaction>>> execute(
      GetTransactionsParams params) async {
    if (params.bookId.isEmpty) {
      return Result.error('bookId must not be empty');
    }

    final transactions = await _transactionRepo.findByBookId(
      params.bookId,
      ledgerType: params.ledgerType,
      categoryId: params.categoryId,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      offset: params.offset,
    );

    return Result.success(transactions);
  }
}
