import 'package:flutter/foundation.dart';

import '../../features/accounting/domain/models/transaction_family_sync_policy.dart';
import 'push_sync_use_case.dart';
import 'sync_vector_clock.dart';

/// Callback to fetch all local transactions.
typedef FetchAllTransactionsCallback =
    Future<List<Map<String, dynamic>>> Function();

/// Callback to fetch versioned reconciliation operations for every local
/// PUBLIC shopping item, including tombstones.
typedef FetchAllShoppingOpsCallback =
    Future<List<Map<String, dynamic>>> Function();
typedef FetchAdditionalFamilySyncOpsCallback =
    Future<List<Map<String, dynamic>>> Function();
typedef FullSyncOperationsAcceptedCallback =
    Future<void> Function(List<Map<String, dynamic>> operations);

/// Performs a full sync by pushing all local transactions and public
/// shopping items to the partner.
///
/// Triggered by ConfirmPairUseCase after successful pairing.
/// Chunks all local operations and pushes via PushSyncUseCase.
class FullSyncUseCase {
  FullSyncUseCase({
    required this._pushSync,
    required this._fetchAllTransactions,
    required this._fetchAllShoppingOps,
    this._fetchAdditionalOperations,
    this._onOperationsAccepted,
  });

  final PushSyncUseCase _pushSync;
  final FetchAllTransactionsCallback _fetchAllTransactions;
  final FetchAllShoppingOpsCallback _fetchAllShoppingOps;
  final FetchAdditionalFamilySyncOpsCallback? _fetchAdditionalOperations;
  final FullSyncOperationsAcceptedCallback? _onOperationsAccepted;

  static const _chunkSize = 50;

  /// Execute full sync.
  ///
  /// Returns the total number of operations pushed.
  Future<int> execute() async {
    final allTransactions = await _fetchAllTransactions();
    final allShoppingOps = await _fetchAllShoppingOps();
    final additionalOperations =
        await _fetchAdditionalOperations?.call() ?? const [];
    final safeTransactions = allTransactions
        .where(TransactionFamilySyncPolicy.isSafeOutboundOperation)
        .toList(growable: false);

    // W1 / D37-06 second safety net: the provider callback already fetches
    // only public items, but defensively re-filter here — a private item must
    // never reach the push pipeline. Both live snapshots and tombstones carry
    // data.listType so the privacy gate applies uniformly.
    final publicShoppingOps = allShoppingOps
        .where(
          (op) =>
              (op['data'] as Map<String, dynamic>?)?['listType'] == 'public',
        )
        .toList();

    if (kDebugMode) {
      debugPrint(
        '[FullSync] Found ${safeTransactions.length} safe transactions '
        '(${allTransactions.length - safeTransactions.length} unsafe dropped), '
        '${publicShoppingOps.length} public shopping ops '
        '(${allShoppingOps.length - publicShoppingOps.length} non-public '
        'dropped)',
      );
    }

    final allOperations = [
      ...safeTransactions,
      ...publicShoppingOps,
      ...additionalOperations,
    ];
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
        vectorClock: buildSyncVectorClock(chunk),
        syncType: 'full',
      );

      if (result is PushSyncSuccess) {
        totalPushed += result.operationCount;
        await _onOperationsAccepted?.call(chunk);
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
