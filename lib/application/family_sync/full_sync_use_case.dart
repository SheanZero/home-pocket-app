import 'package:flutter/foundation.dart';

import 'push_sync_use_case.dart';

/// Callback to fetch all local transactions.
typedef FetchAllTransactionsCallback =
    Future<List<Map<String, dynamic>>> Function();

/// Callback to fetch all local PUBLIC shopping items as create operations.
typedef FetchAllShoppingOpsCallback =
    Future<List<Map<String, dynamic>>> Function();

/// Performs a full sync by pushing all local transactions and public
/// shopping items to the partner.
///
/// Triggered by ConfirmPairUseCase after successful pairing.
/// Chunks all local operations and pushes via PushSyncUseCase.
class FullSyncUseCase {
  FullSyncUseCase({
    required PushSyncUseCase pushSync,
    required FetchAllTransactionsCallback fetchAllTransactions,
    required FetchAllShoppingOpsCallback fetchAllShoppingOps,
  }) : _pushSync = pushSync,
       _fetchAllTransactions = fetchAllTransactions,
       _fetchAllShoppingOps = fetchAllShoppingOps;

  final PushSyncUseCase _pushSync;
  final FetchAllTransactionsCallback _fetchAllTransactions;
  final FetchAllShoppingOpsCallback _fetchAllShoppingOps;

  static const _chunkSize = 50;

  /// Execute full sync.
  ///
  /// Returns the total number of operations pushed.
  Future<int> execute() async {
    final allTransactions = await _fetchAllTransactions();
    final allShoppingOps = await _fetchAllShoppingOps();

    // W1 / D37-06 second safety net: the provider callback already fetches
    // only public items, but defensively re-filter here — a private item must
    // never reach the push pipeline. Full sync emits create ops only, so
    // every op carries data.listType.
    final publicShoppingOps = allShoppingOps
        .where(
          (op) => (op['data'] as Map<String, dynamic>?)?['listType'] ==
              'public',
        )
        .toList();

    if (kDebugMode) {
      debugPrint(
        '[FullSync] Found ${allTransactions.length} transactions, '
        '${publicShoppingOps.length} public shopping ops '
        '(${allShoppingOps.length - publicShoppingOps.length} non-public '
        'dropped)',
      );
    }

    final allOperations = [...allTransactions, ...publicShoppingOps];

    if (allOperations.isEmpty) {
      if (kDebugMode) {
        debugPrint('[FullSync] No operations to push');
      }
      return 0;
    }

    var totalPushed = 0;
    final totalChunks = (allOperations.length / _chunkSize).ceil();

    // Chunk and push
    for (var i = 0; i < allOperations.length; i += _chunkSize) {
      final end = (i + _chunkSize < allOperations.length)
          ? i + _chunkSize
          : allOperations.length;
      final chunk = allOperations.sublist(i, end);
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
