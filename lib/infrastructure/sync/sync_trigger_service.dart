import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../application/family_sync/pull_sync_use_case.dart';
import '../../application/family_sync/push_sync_use_case.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import 'push_notification_service.dart';
import 'relay_api_client.dart';
import 'sync_lifecycle_observer.dart';
import 'sync_queue_manager.dart';

enum SyncTriggerEventType {
  joinRequest,
  memberConfirmed,
  memberLeft,
  groupDissolved,
  syncAvailable,
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

  const SyncTriggerEvent.syncAvailable({String? groupId})
    : this._(type: SyncTriggerEventType.syncAvailable, groupId: groupId);

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
    required PushNotificationService pushNotificationService,
    required RelayApiClient apiClient,
    required KeyManager keyManager,
  }) : _groupRepo = groupRepo,
       _pullSync = pullSync,
       _pushSync = pushSync,
       _queueManager = queueManager,
       _pushNotificationService = pushNotificationService,
       _apiClient = apiClient,
       _keyManager = keyManager;

  final GroupRepository _groupRepo;
  final PullSyncUseCase _pullSync;
  final PushSyncUseCase _pushSync;
  final SyncQueueManager _queueManager;
  final PushNotificationService _pushNotificationService;
  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final _eventsController = StreamController<SyncTriggerEvent>.broadcast(
    sync: true,
  );

  SyncLifecycleObserver? _lifecycleObserver;
  SyncTriggerEvent? _pendingEvent;
  bool _initialized = false;

  Stream<SyncTriggerEvent> get events => _eventsController.stream;

  /// Initialize sync triggers.
  ///
  /// Sets up lifecycle observer and push notification handlers.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

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
    _initialized = false;
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
      _publishEvent(SyncTriggerEvent.memberConfirmed(groupId: groupId));
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

  /// Handle push notification: join request.
  ///
  /// Device A (Owner) receives this when Device B calls `POST /group/join`.
  /// We fetch the latest group status from the server to get the updated
  /// member list (including the new pending member), persist it locally,
  /// and publish an event so the UI can refresh.
  Future<void> _handleJoinRequest(Map<String, dynamic> data) async {
    final groupId = data['groupId'] as String?;

    if (kDebugMode) {
      debugPrint('SyncTrigger: join request received for group $groupId');
    }

    if (groupId != null) {
      try {
        final status = await _apiClient.getGroupStatus(groupId);
        final rawMembers = status['members'] as List<dynamic>? ?? const [];
        final members = rawMembers
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList();
        await _groupRepo.updateMembers(groupId, members);

        if (kDebugMode) {
          debugPrint(
            'SyncTrigger: updated ${members.length} members for group $groupId',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'SyncTrigger: failed to refresh group on join request: $e',
          );
        }
      }
    }

    _publishEvent(SyncTriggerEvent.joinRequest(groupId: groupId));
  }

  /// Handle push notification: member left or was removed.
  ///
  /// Protocol fields: groupId, deviceId, deviceName, reason ("left"|"removed").
  /// If this device was removed (reason == "removed" and deviceId matches local),
  /// deactivate the group locally. Otherwise, remove the member from the local list.
  Future<void> _handleMemberLeft(Map<String, dynamic> data) async {
    final groupId = data['groupId'] as String?;
    final deviceId = data['deviceId'] as String?;
    final reason = data['reason'] as String?;
    if (groupId == null || deviceId == null) return;

    if (kDebugMode) {
      debugPrint(
        'SyncTrigger: member_left received for group $groupId '
        'device $deviceId reason=$reason',
      );
    }

    final localDeviceId = await _keyManager.getDeviceId();
    if (localDeviceId != null &&
        deviceId == localDeviceId &&
        reason == 'removed') {
      // This device was removed by the owner
      await _queueManager.clearQueue();
      await _groupRepo.deactivateGroup(groupId);
      _publishEvent(SyncTriggerEvent.memberLeft(groupId: groupId));
      return;
    }

    // Another member left or was removed — update local member list
    final group =
        await _groupRepo.getGroupById(groupId) ??
        await _groupRepo.getActiveGroup();
    if (group == null || group.groupId != groupId) return;

    final updatedMembers = group.members
        .where((m) => m.deviceId != deviceId)
        .toList();
    await _groupRepo.updateMembers(groupId, updatedMembers);
    _publishEvent(SyncTriggerEvent.memberLeft(groupId: groupId));
  }

  /// Handle push notification: group dissolved by owner.
  ///
  /// Protocol fields: groupId.
  /// Clean up local group data and notify UI.
  Future<void> _handleGroupDissolved(Map<String, dynamic> data) async {
    final groupId = data['groupId'] as String?;
    if (groupId == null) return;

    if (kDebugMode) {
      debugPrint('SyncTrigger: group_dissolved received for group $groupId');
    }

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
