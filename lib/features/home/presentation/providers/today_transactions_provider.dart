import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/get_transactions_use_case.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../accounting/presentation/providers/use_case_providers.dart';

part 'today_transactions_provider.g.dart';

/// Fetches today's non-deleted transactions for the given [bookId].
///
/// Uses [GetTransactionsUseCase] with date range for the current day
/// (00:00:00 to 23:59:59) and filters out soft-deleted records.
@riverpod
Future<List<Transaction>> todayTransactions(
  Ref ref, {
  required String bookId,
}) async {
  final useCase = ref.watch(getTransactionsUseCaseProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final result = await useCase.execute(
    GetTransactionsParams(
      bookId: bookId,
      startDate: todayStart,
      endDate: todayEnd,
    ),
  );

  if (result.isError) {
    throw Exception(result.error ?? 'Failed to fetch today\'s transactions');
  }

  final transactions = result.data ?? [];
  return transactions.where((tx) => !tx.isDeleted).toList();
}
