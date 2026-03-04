import 'push_sync_use_case.dart';

/// Callback to fetch all local transactions for a book.
typedef FetchAllTransactionsCallback =
    Future<List<Map<String, dynamic>>> Function(String bookId);

/// Performs a full sync by pushing all local transactions to the partner.
///
/// Triggered by ConfirmPairUseCase after successful pairing.
/// Chunks all local transactions and pushes via PushSyncUseCase.
class FullSyncUseCase {
  FullSyncUseCase({
    required PushSyncUseCase pushSync,
    required FetchAllTransactionsCallback fetchAllTransactions,
  }) : _pushSync = pushSync,
       _fetchAllTransactions = fetchAllTransactions;

  final PushSyncUseCase _pushSync;
  final FetchAllTransactionsCallback _fetchAllTransactions;

  static const _chunkSize = 50;

  /// Execute full sync for a book.
  ///
  /// Returns the total number of operations pushed.
  Future<int> execute(String bookId) async {
    final allTransactions = await _fetchAllTransactions(bookId);

    if (allTransactions.isEmpty) return 0;

    var totalPushed = 0;

    // Chunk and push
    for (var i = 0; i < allTransactions.length; i += _chunkSize) {
      final end = (i + _chunkSize < allTransactions.length)
          ? i + _chunkSize
          : allTransactions.length;
      final chunk = allTransactions.sublist(i, end);

      final result = await _pushSync.execute(
        operations: chunk,
        vectorClock: {'full_sync': i ~/ _chunkSize},
        syncType: 'full',
      );

      if (result is PushSyncSuccess) {
        totalPushed += result.operationCount;
      } else if (result is PushSyncQueued) {
        totalPushed += result.operationCount;
      }
    }

    return totalPushed;
  }
}
