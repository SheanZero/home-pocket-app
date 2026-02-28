import 'package:flutter/foundation.dart';

import '../../application/family_sync/pull_sync_use_case.dart';
import '../../application/family_sync/push_sync_use_case.dart';
import '../../features/family_sync/domain/repositories/pair_repository.dart';
import 'push_notification_service.dart';
import 'sync_lifecycle_observer.dart';
import 'sync_queue_manager.dart';

/// Coordinates sync triggers from various sources:
/// - App lifecycle (resume -> pull)
/// - Transaction changes (create/update/delete -> push)
/// - Push notifications (pair_confirmed -> confirm local + pull, sync_available -> pull)
class SyncTriggerService {
  SyncTriggerService({
    required PairRepository pairRepo,
    required PullSyncUseCase pullSync,
    required PushSyncUseCase pushSync,
    required SyncQueueManager queueManager,
    required PushNotificationService pushNotificationService,
  })  : _pairRepo = pairRepo,
        _pullSync = pullSync,
        _pushSync = pushSync,
        _queueManager = queueManager,
        _pushNotificationService = pushNotificationService;

  final PairRepository _pairRepo;
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
    _lifecycleObserver = SyncLifecycleObserver(
      onResume: _handleAppResume,
    );
    _lifecycleObserver!.start();

    // Register push notification handlers
    _pushNotificationService.registerHandlers(
      onPairConfirmed: _handlePairConfirmed,
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
  /// If paired, pulls pending sync messages and drains offline queue.
  Future<void> _handleAppResume() async {
    final pair = await _pairRepo.getActivePair();
    if (pair == null) return;

    if (kDebugMode) {
      debugPrint('SyncTrigger: app resumed, pulling sync data');
    }

    await _pullSync.execute();
    await _queueManager.drainQueue();
  }

  /// Called after a transaction is created, updated, or deleted.
  ///
  /// If paired, pushes the CRDT operations to the partner.
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
    final pair = await _pairRepo.getActivePair();
    if (pair == null) return;

    if (kDebugMode) {
      debugPrint(
        'SyncTrigger: transaction changed, pushing ${operations.length} ops',
      );
    }

    await _pushSync.execute(
      operations: operations,
      vectorClock: vectorClock,
    );
  }

  /// Convenience method for pushing a single create operation.
  Future<void> onTransactionCreated(Map<String, dynamic> transactionData) async {
    await onTransactionChanged(
      operations: [
        {'op': 'insert', 'table': 'transactions', 'data': transactionData},
      ],
    );
  }

  /// Convenience method for pushing a single update operation.
  Future<void> onTransactionUpdated(Map<String, dynamic> transactionData) async {
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

  /// Handle push notification: pair confirmed.
  ///
  /// Device B receives this after Device A confirms the pair.
  /// We transition Device B's pair from `confirming` -> `active` locally,
  /// then pull initial sync data from the server.
  ///
  /// IMPORTANT: This must NOT call ConfirmPairUseCase (which hits the server).
  /// The server-side confirmation was already done by Device A. This handler
  /// only transitions the local pair status.
  Future<void> _handlePairConfirmed(Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('SyncTrigger: pair confirmed notification received');
    }

    final pairId = data['pairId'] as String?;
    if (pairId == null) return;

    try {
      // Get pending/confirming pair
      final pair = await _pairRepo.getPendingPair();
      if (pair == null || pair.pairId != pairId) {
        if (kDebugMode) {
          debugPrint(
            'SyncTrigger: no matching confirming pair found for $pairId',
          );
        }
        return;
      }

      // Transition confirming -> active locally
      await _pairRepo.confirmLocalPair(pairId);

      if (kDebugMode) {
        debugPrint('SyncTrigger: pair $pairId confirmed locally, pulling sync');
      }

      // Pull initial sync data
      await _pullSync.execute();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncTrigger: pair confirmation failed: $e');
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
