import 'package:flutter/foundation.dart';

/// Tracks transaction operations pending sync push.
///
/// When a transaction is created/deleted locally, the operation
/// is recorded here. On incrementalPush, all pending operations
/// are flushed and pushed.
///
/// In-memory only. If the app is killed before flush, pending ops
/// are lost. This is acceptable because the 10s debounce means ops
/// flush quickly, and fullSync on next launch will reconcile.
class TransactionChangeTracker {
  final _pendingOps = <Map<String, dynamic>>[];

  /// Record a create operation for sync.
  void trackCreate(Map<String, dynamic> operation) {
    _pendingOps.add(operation);
    if (kDebugMode) {
      debugPrint('[ChangeTracker] trackCreate: ${operation['entityId']}');
    }
  }

  /// Record a delete operation for sync.
  void trackDelete({
    required String transactionId,
    required String bookId,
  }) {
    _pendingOps.add({
      'op': 'delete',
      'entityType': 'bill',
      'entityId': transactionId,
      'data': {'bookId': bookId},
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    if (kDebugMode) {
      debugPrint('[ChangeTracker] trackDelete: $transactionId');
    }
  }

  /// Flush all pending operations. Returns the list and clears internal state.
  List<Map<String, dynamic>> flush() {
    final ops = List<Map<String, dynamic>>.of(_pendingOps);
    _pendingOps.clear();
    if (kDebugMode && ops.isNotEmpty) {
      debugPrint('[ChangeTracker] Flushed ${ops.length} operations');
    }
    return ops;
  }

  /// Number of pending operations.
  int get pendingCount => _pendingOps.length;
}
