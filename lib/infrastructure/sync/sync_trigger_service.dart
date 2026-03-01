import 'package:flutter/foundation.dart';

import '../../application/family_sync/pull_sync_use_case.dart';
import '../../application/family_sync/push_sync_use_case.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'push_notification_service.dart';
import 'sync_lifecycle_observer.dart';
import 'sync_queue_manager.dart';

/// Coordinates sync triggers from various sources:
/// - App lifecycle (resume -> pull)
/// - Transaction changes (create/update/delete -> push)
/// - Push notifications (member_confirmed -> confirm local + pull, sync_available -> pull)
class SyncTriggerService {
  SyncTriggerService({
    required GroupRepository groupRepo,
    required PullSyncUseCase pullSync,
    required PushSyncUseCase pushSync,
    required SyncQueueManager queueManager,
    required PushNotificationService pushNotificationService,
  }) : _groupRepo = groupRepo,
       _pullSync = pullSync,
       _pushSync = pushSync,
       _queueManager = queueManager,
       _pushNotificationService = pushNotificationService;

  final GroupRepository _groupRepo;
  final PullSyncUseCase _pullSync;
  final PushSyncUseCase _pushSync;
  final SyncQueueManager _queueManager;
  final PushNotificationService _pushNotificationService;

  SyncLifecycleObserver? _lifecycleObserver;

  /// Initialize sync triggers.
  ///
  /// Sets up lifecycle observer and push notification handlers.
  void initialize() {
    // Set up lifecycle observer
    _lifecycleObserver = SyncLifecycleObserver(onResume: _handleAppResume);
    _lifecycleObserver!.start();

    // Register push notification handlers
    _pushNotificationService.registerHandlers(
      onMemberConfirmed: _handleMemberConfirmed,
      onSyncAvailable: _handleSyncAvailable,
    );
  }

  /// Dispose sync triggers.
  void dispose() {
    _lifecycleObserver?.dispose();
    _lifecycleObserver = null;
  }

  /// Called when app resumes from background.
  ///
  /// If a group is active, pulls pending sync messages and drains offline queue.
  Future<void> _handleAppResume() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return;

    if (kDebugMode) {
      debugPrint('SyncTrigger: app resumed, pulling sync data');
    }

    await _pullSync.execute();
    await _queueManager.drainQueue();
  }

  /// Called after a transaction is created, updated, or deleted.
  ///
  /// If a group is active, pushes the CRDT operations to the relay server.
  /// Operations format:
  /// ```json
  /// [{"op": "insert", "table": "transactions", "data": {...}}]
  /// ```
  ///
  /// The [vectorClock] tracks causal ordering. Callers should pass
  /// `{deviceId: sequenceNumber}` to maintain happens-before relations.
  Future<void> onTransactionChanged({
    required List<Map<String, dynamic>> operations,
    Map<String, int> vectorClock = const {},
  }) async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return;

    if (kDebugMode) {
      debugPrint(
        'SyncTrigger: transaction changed, pushing ${operations.length} ops',
      );
    }

    await _pushSync.execute(operations: operations, vectorClock: vectorClock);
  }

  /// Convenience method for pushing a single create operation.
  Future<void> onTransactionCreated(
    Map<String, dynamic> transactionData,
  ) async {
    await onTransactionChanged(
      operations: [
        {'op': 'insert', 'table': 'transactions', 'data': transactionData},
      ],
    );
  }

  /// Convenience method for pushing a single update operation.
  Future<void> onTransactionUpdated(
    Map<String, dynamic> transactionData,
  ) async {
    await onTransactionChanged(
      operations: [
        {'op': 'update', 'table': 'transactions', 'data': transactionData},
      ],
    );
  }

  /// Convenience method for pushing a single delete operation.
  Future<void> onTransactionDeleted(String transactionId) async {
    await onTransactionChanged(
      operations: [
        {'op': 'delete', 'table': 'transactions', 'id': transactionId},
      ],
    );
  }

  /// Handle push notification: member confirmed.
  ///
  /// Device B receives this after Device A confirms the membership.
  /// We transition Device B's group from `confirming` -> `active` locally,
  /// then pull initial sync data from the server.
  Future<void> _handleMemberConfirmed(Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('SyncTrigger: member confirmed notification received');
    }

    final groupId = data['groupId'] as String?;
    if (groupId == null) return;

    try {
      final group = await _groupRepo.getPendingGroup();
      if (group == null || group.groupId != groupId) {
        if (kDebugMode) {
          debugPrint(
            'SyncTrigger: no matching confirming group found for $groupId',
          );
        }
        return;
      }

      await _groupRepo.confirmLocalGroup(groupId);

      if (kDebugMode) {
        debugPrint(
          'SyncTrigger: group $groupId confirmed locally, pulling sync',
        );
      }

      await _pullSync.execute();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncTrigger: member confirmation failed: $e');
      }
    }
  }

  /// Handle push notification: sync available.
  ///
  /// Partner has pushed new data, pull it.
  Future<void> _handleSyncAvailable(Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('SyncTrigger: sync available notification received');
    }

    await _pullSync.execute();
  }
}
