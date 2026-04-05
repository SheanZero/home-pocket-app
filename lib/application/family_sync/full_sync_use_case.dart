import 'package:flutter/foundation.dart';

import 'push_sync_use_case.dart';

/// Callback to fetch all local transactions.
typedef FetchAllTransactionsCallback =
    Future<List<Map<String, dynamic>>> Function();

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

  /// Execute full sync.
  ///
  /// Returns the total number of operations pushed.
  Future<int> execute() async {
    final allTransactions = await _fetchAllTransactions();

    if (kDebugMode) {
      debugPrint('[FullSync] Found ${allTransactions.length} transactions');
    }

    if (allTransactions.isEmpty) {
      if (kDebugMode) {
        debugPrint('[FullSync] No transactions to push');
      }
      return 0;
    }

    var totalPushed = 0;
    final totalChunks = (allTransactions.length / _chunkSize).ceil();

    // Chunk and push
    for (var i = 0; i < allTransactions.length; i += _chunkSize) {
      final end = (i + _chunkSize < allTransactions.length)
          ? i + _chunkSize
          : allTransactions.length;
      final chunk = allTransactions.sublist(i, end);
      final chunkNumber = (i ~/ _chunkSize) + 1;

      if (kDebugMode) {
        debugPrint(
          '[FullSync] Pushing chunk $chunkNumber/$totalChunks (${chunk.length} ops)',
        );
      }

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

    if (kDebugMode) {
      debugPrint('[FullSync] Complete: pushed $totalPushed operations');
    }

    return totalPushed;
  }
}
