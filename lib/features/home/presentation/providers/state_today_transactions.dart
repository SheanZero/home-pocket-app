import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/get_transactions_use_case.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    show getTransactionsUseCaseProvider;
import 'state_shadow_books.dart';

part 'state_today_transactions.g.dart';

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

/// Fetches today's transactions across the primary book and every active
/// family shadow book, then presents them as one creation-newest-first feed.
@riverpod
Future<List<Transaction>> familyTodayTransactions(
  Ref ref, {
  required String bookId,
}) async {
  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final bookIds = <String>[bookId, ...shadowBooks.map((item) => item.book.id)];
  final batches = await Future.wait(
    bookIds.map((id) => _fetchTodayTransactions(ref, id)),
  );
  final transactions = batches.expand((batch) => batch).toList()
    ..sort((a, b) {
      final byCreatedAt = b.createdAt.compareTo(a.createdAt);
      return byCreatedAt != 0 ? byCreatedAt : b.id.compareTo(a.id);
    });
  return transactions;
}

Future<List<Transaction>> _fetchTodayTransactions(
  Ref ref,
  String bookId,
) async {
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
    throw Exception(result.error ?? 'Failed to fetch family transactions');
  }
  return (result.data ?? const <Transaction>[])
      .where((transaction) => !transaction.isDeleted)
      .toList();
}
