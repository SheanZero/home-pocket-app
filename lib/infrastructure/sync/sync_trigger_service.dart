import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../application/family_sync/pull_sync_use_case.dart';
import '../../application/family_sync/push_sync_use_case.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../crypto/services/key_manager.dart';
import 'push_notification_service.dart';
import 'relay_api_client.dart';
import 'sync_lifecycle_observer.dart';
import 'sync_queue_manager.dart';

enum SyncTriggerEventType {
  joinRequest,
  memberConfirmed,
  memberLeft,
  groupDissolved,
}

class SyncTriggerEvent {
  const SyncTriggerEvent._({required this.type, this.groupId});

  const SyncTriggerEvent.joinRequest({String? groupId})
    : this._(type: SyncTriggerEventType.joinRequest, groupId: groupId);

  const SyncTriggerEvent.memberConfirmed({String? groupId})
    : this._(type: SyncTriggerEventType.memberConfirmed, groupId: groupId);

  const SyncTriggerEvent.memberLeft({String? groupId})
    : this._(type: SyncTriggerEventType.memberLeft, groupId: groupId);

  const SyncTriggerEvent.groupDissolved({String? groupId})
    : this._(type: SyncTriggerEventType.groupDissolved, groupId: groupId);

  final SyncTriggerEventType type;
  final String? groupId;

  @override
  bool operator ==(Object other) {
    return other is SyncTriggerEvent &&
        other.type == type &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(type, groupId);
}

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
    required KeyManager keyManager,
    required RelayApiClient relayApiClient,
    required PushNotificationService pushNotificationService,
  }) : _groupRepo = groupRepo,
       _pullSync = pullSync,
       _pushSync = pushSync,
       _queueManager = queueManager,
       _keyManager = keyManager,
       _relayApiClient = relayApiClient,
       _pushNotificationService = pushNotificationService;

  final GroupRepository _groupRepo;
  final PullSyncUseCase _pullSync;
  final PushSyncUseCase _pushSync;
  final SyncQueueManager _queueManager;
  final KeyManager _keyManager;
  final RelayApiClient _relayApiClient;
  final PushNotificationService _pushNotificationService;
  final _eventsController = StreamController<SyncTriggerEvent>.broadcast();

  SyncLifecycleObserver? _lifecycleObserver;
  SyncTriggerEvent? _pendingEvent;

  Stream<SyncTriggerEvent> get events => _eventsController.stream;

  /// Initialize sync triggers.
  ///
  /// Sets up lifecycle observer and push notification handlers.
  Future<void> initialize() async {
    // Set up lifecycle observer
    _lifecycleObserver = SyncLifecycleObserver(onResume: _handleAppResume);
    _lifecycleObserver!.start();

    // Register push notification handlers
    _pushNotificationService.registerHandlers(
      onMemberConfirmed: _handleMemberConfirmed,
      onSyncAvailable: _handleSyncAvailable,
      onJoinRequest: _handleJoinRequest,
      onMemberLeft: _handleMemberLeft,
      onGroupDissolved: _handleGroupDissolved,
    );
    await _pushNotificationService.initialize();
  }

  /// Dispose sync triggers.
  void dispose() {
    _lifecycleObserver?.dispose();
    _lifecycleObserver = null;
    unawaited(_eventsController.close());
  }

  SyncTriggerEvent? takePendingEvent() {
    final event = _pendingEvent;
    _pendingEvent = null;
    return event;
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
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': transactionData['id'] as String,
          'data': transactionData,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ],
    );
  }

  /// Convenience method for pushing a single update operation.
  Future<void> onTransactionUpdated(
    Map<String, dynamic> transactionData,
  ) async {
    await onTransactionChanged(
      operations: [
        {
          'op': 'update',
          'entityType': 'bill',
          'entityId': transactionData['id'] as String,
          'data': transactionData,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ],
    );
  }

  /// Convenience method for pushing a single delete operation.
  Future<void> onTransactionDeleted(String transactionId) async {
    await onTransactionChanged(
      operations: [
        {
          'op': 'delete',
          'entityType': 'bill',
          'entityId': transactionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
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

    try {
      final group = await _groupRepo.getPendingGroup();
      if (group == null) {
        return;
      }

      if (groupId != null && group.groupId != groupId) {
        if (kDebugMode) {
          debugPrint(
            'SyncTrigger: no matching confirming group found for $groupId',
          );
        }
        return;
      }

      final effectiveGroupId = groupId ?? group.groupId;
      await _groupRepo.confirmLocalGroup(effectiveGroupId);
      await _refreshGroupStatus(effectiveGroupId);

      if (kDebugMode) {
        debugPrint(
          'SyncTrigger: group $effectiveGroupId confirmed locally, pulling sync',
        );
      }

      await _pullSync.execute();
      _publishEvent(
        SyncTriggerEvent.memberConfirmed(groupId: effectiveGroupId),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncTrigger: member confirmation failed: $e');
      }
    }
  }

  Future<void> _refreshGroupStatus(String groupId) async {
    try {
      final status = await _relayApiClient.getGroupStatus(groupId);
      final rawMembers = status['members'] as List?;
      if (rawMembers == null) return;

      final members = rawMembers
          .whereType<Map<String, dynamic>>()
          .map(
            (member) => GroupMember(
              deviceId: member['deviceId'] as String,
              publicKey: member['publicKey'] as String,
              deviceName: member['deviceName'] as String,
              role: member['role'] as String,
              status: member['status'] as String,
            ),
          )
          .toList();
      await _groupRepo.updateMembers(groupId, members);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncTrigger: group status refresh failed: $e');
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

  Future<void> _handleJoinRequest(Map<String, dynamic> data) async {
    final groupId = data['groupId'] as String?;
    _publishEvent(SyncTriggerEvent.joinRequest(groupId: groupId));
  }

  Future<void> _handleMemberLeft(Map<String, dynamic> data) async {
    final groupId = data['groupId'] as String?;
    final deviceId = data['deviceId'] as String?;
    final reason = data['reason'] as String?;
    if (groupId == null || deviceId == null) return;

    final localDeviceId = await _keyManager.getDeviceId();
    if (localDeviceId != null &&
        deviceId == localDeviceId &&
        reason == 'removed') {
      await _groupRepo.deactivateGroup(groupId);
      _publishEvent(SyncTriggerEvent.memberLeft(groupId: groupId));
      return;
    }

    final group =
        await _groupRepo.getGroupById(groupId) ??
        await _groupRepo.getActiveGroup();
    if (group == null || group.groupId != groupId) return;

    final updatedMembers = group.members
        .where((member) => member.deviceId != deviceId)
        .toList();
    await _groupRepo.updateMembers(groupId, updatedMembers);
    _publishEvent(SyncTriggerEvent.memberLeft(groupId: groupId));
  }

  Future<void> _handleGroupDissolved(Map<String, dynamic> data) async {
    final groupId = data['groupId'] as String?;
    if (groupId == null) return;

    final activeGroup = await _groupRepo.getActiveGroup();
    if (activeGroup == null || activeGroup.groupId != groupId) return;

    await _queueManager.clearQueue();
    await _groupRepo.deactivateGroup(groupId);
    _publishEvent(SyncTriggerEvent.groupDissolved(groupId: groupId));
  }

  void _publishEvent(SyncTriggerEvent event) {
    _pendingEvent = event;
    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }
  }
}
