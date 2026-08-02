import 'package:flutter/foundation.dart';

import '../../features/accounting/domain/models/transaction_family_sync_policy.dart';

/// Tracks transaction operations pending sync push.
///
/// When a transaction is created/deleted locally, the operation
/// is recorded here. On incrementalPush, all pending operations
/// are flushed and pushed.
///
/// This in-memory list is only a low-latency coalescing/trigger seam for
/// legacy callers. Transaction mutations use the SQLCipher-backed
/// `family_sync_outbox` as their durable source of truth; process death before
/// this tracker flushes must never decide delivery or privacy withdrawal.
class TransactionChangeTracker {
  final _pendingOps = <Map<String, dynamic>>[];

  /// Record a create operation for sync.
  void trackCreate(Map<String, dynamic> operation) {
    _trackIfSafe(operation);
  }

  /// Record an update operation for sync.
  ///
  /// The receiving sync engine already handles `op: 'update'` payloads via
  /// the existing [TransactionSyncMapper.toUpdateOperation] producer.
  void trackUpdate(Map<String, dynamic> operation) {
    _trackIfSafe(operation);
  }

  /// Record a delete operation for sync.
  void trackDelete({
    required String transactionId,
    required String bookId,
    Map<String, dynamic>? operation,
  }) {
    final now = DateTime.now().toUtc();
    _trackIfSafe(
      operation ??
          <String, dynamic>{
            'op': 'delete',
            'entityType': 'bill',
            'entityId': transactionId,
            'data': {
              'isDeleted': true,
              'syncRevision': now.microsecondsSinceEpoch,
              'syncOriginDeviceId': '',
            },
            'revision': now.microsecondsSinceEpoch,
            'originDeviceId': '',
            'timestamp': now.toIso8601String(),
          },
    );
  }

  void _trackIfSafe(Map<String, dynamic> operation) {
    if (!TransactionFamilySyncPolicy.isSafeOutboundOperation(operation)) {
      if (kDebugMode) {
        debugPrint('[ChangeTracker] unsafe family operation dropped');
      }
      return;
    }
    _pendingOps.add(operation);
  }

  /// Flush all pending operations. Returns the list and clears internal state.
  List<Map<String, dynamic>> flush() {
    final ops = List<Map<String, dynamic>>.of(_pendingOps);
    _pendingOps.clear();
    if (kDebugMode) {
      if (ops.isNotEmpty) {
        debugPrint('[ChangeTracker] pending changes flushed');
      }
    }
    return ops;
  }

  /// Discards identity-bound transient operations during a local privacy wipe.
  void clear() => _pendingOps.clear();

  /// Number of pending operations.
  int get pendingCount => _pendingOps.length;
}
