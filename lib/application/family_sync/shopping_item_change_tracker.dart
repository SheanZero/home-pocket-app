import 'package:flutter/foundation.dart';

// kShoppingItemEntityType moved to the domain model (shopping_item.dart) so the
// domain sync-mapper can reference it without an upward application import.
import '../../features/shopping_list/domain/models/shopping_item.dart';

/// Tracks shopping item operations pending sync push.
///
/// When a shopping item is created/updated/deleted locally, the operation
/// is recorded here. On incrementalPush, all pending operations are flushed
/// and pushed.
///
/// In-memory only. If the app is killed before flush, pending ops are lost.
/// This is acceptable because the 10s debounce means ops flush quickly,
/// and fullSync on next launch will reconcile.
///
/// Privacy gate (D37-06): This tracker enforces a SECOND safety net —
/// trackCreate and trackUpdate silently drop private items. The primary
/// enforcement is at the use-case boundary (caller must check listType == 'public'
/// before calling track*). Defense-in-depth: even if a caller bypasses the
/// use-case gate, private items never reach the sync pipeline.
class ShoppingItemChangeTracker {
  final _pendingOps = <Map<String, dynamic>>[];

  /// Record a create operation for sync.
  ///
  /// D37-06: second safety net — use-case gate is primary; tracker never accepts
  /// private items. If [operation]['data']['listType'] != 'public', the op is
  /// silently dropped.
  void trackCreate(Map<String, dynamic> operation) {
    // D37-06: second safety net — use-case gate is primary; tracker never accepts private items
    final data = operation['data'] as Map<String, dynamic>?;
    if (data?['listType'] != 'public') return;
    _pendingOps.add(operation);
  }

  /// Record an update operation for sync.
  ///
  /// D37-06: second safety net — same listType guard as trackCreate.
  void trackUpdate(Map<String, dynamic> operation) {
    // D37-06: second safety net — use-case gate is primary; tracker never accepts private items
    final data = operation['data'] as Map<String, dynamic>?;
    if (data?['listType'] != 'public') return;
    _pendingOps.add(operation);
  }

  /// Record a delete operation for sync.
  ///
  /// Delete ops carry no listType in data — the use case (caller) enforces
  /// the D37-06 privacy gate before calling this method. This tracker always
  /// enqueues delete ops unconditionally.
  void trackDelete({required String itemId}) {
    _pendingOps.add({
      'op': 'delete',
      'entityType': kShoppingItemEntityType,
      'entityId': itemId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Flush all pending operations. Returns the list and clears internal state.
  List<Map<String, dynamic>> flush() {
    final ops = List<Map<String, dynamic>>.of(_pendingOps);
    _pendingOps.clear();
    if (kDebugMode) {
      if (ops.isNotEmpty) {
        debugPrint('[ShoppingChangeTracker] ${ops.length} ops flushed');
      }
    }
    return ops;
  }

  /// Number of pending operations.
  int get pendingCount => _pendingOps.length;
}
