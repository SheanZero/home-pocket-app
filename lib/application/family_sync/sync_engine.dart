import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/sync_status_model.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/family_sync/domain/repositories/sync_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/push_notification_service.dart';
import '../../infrastructure/sync/sync_lifecycle_observer.dart';
import '../../infrastructure/sync/sync_scheduler.dart';
import '../../infrastructure/sync/websocket_service.dart';
import 'complete_member_activation_use_case.dart';
import 'control_plane_reconciliation_use_case.dart';
import 'group_key_recovery_use_case.dart';
import 'refresh_group_snapshot_use_case.dart';
import 'sync_orchestrator.dart';

typedef JoinRequestLifecycleHandler = Future<void> Function(String groupId);
typedef MemberLeftLifecycleHandler =
    Future<void> Function(
      String groupId,
      String deviceId,
      String? reason,
      int? keyEpoch,
    );
typedef GroupDissolvedLifecycleHandler = Future<void> Function(String groupId);
typedef DurableOutboxRecoveryCallback = Future<int> Function();
typedef InboundQuarantineMaintenanceCallback = Future<void> Function();
typedef AvatarStagingMaintenanceCallback = Future<void> Function();
typedef SyncIssueResolutionCallback = Future<void> Function();

/// Unified sync entry point. Combines SyncScheduler + SyncOrchestrator
/// and exposes a reactive SyncStatus stream.
class SyncEngine {
  SyncEngine({
    required SyncOrchestrator orchestrator,
    required GroupRepository groupRepo,
    required WebSocketService webSocketService,
    required KeyManager keyManager,
    CompleteMemberActivationUseCase? memberActivation,
    RefreshGroupSnapshotUseCase? groupSnapshotRefresh,
    GroupKeyRecoveryCoordinator? groupKeyRecovery,
    ControlPlaneReconciliationUseCase? controlPlaneReconciliation,
    DurableOutboxRecoveryCallback? recoverDurableOutbox,
    InboundQuarantineMaintenanceCallback? maintainInboundQuarantine,
    AvatarStagingMaintenanceCallback? maintainAvatarStaging,
    SyncIssueResolutionCallback? resolveSyncIssues,
  }) : _orchestrator = orchestrator,
       _groupRepo = groupRepo,
       _webSocketService = webSocketService,
       _keyManager = keyManager,
       _memberActivation = memberActivation,
       _groupSnapshotRefresh = groupSnapshotRefresh,
       _groupKeyRecovery = groupKeyRecovery,
       _controlPlaneReconciliation = controlPlaneReconciliation,
       _recoverDurableOutbox = recoverDurableOutbox,
       _maintainInboundQuarantine = maintainInboundQuarantine,
       _maintainAvatarStaging = maintainAvatarStaging,
       _resolveSyncIssues = resolveSyncIssues {
    _scheduler = SyncScheduler(
      onSyncRequested: _handleSyncRequest,
      checkNeedsFullPull: _orchestrator.needsFullPull,
    );
  }

  final SyncOrchestrator _orchestrator;
  final GroupRepository _groupRepo;
  final WebSocketService _webSocketService;
  final KeyManager _keyManager;
  final CompleteMemberActivationUseCase? _memberActivation;
  final RefreshGroupSnapshotUseCase? _groupSnapshotRefresh;
  final GroupKeyRecoveryCoordinator? _groupKeyRecovery;
  final ControlPlaneReconciliationUseCase? _controlPlaneReconciliation;
  final DurableOutboxRecoveryCallback? _recoverDurableOutbox;
  final InboundQuarantineMaintenanceCallback? _maintainInboundQuarantine;
  final AvatarStagingMaintenanceCallback? _maintainAvatarStaging;
  final SyncIssueResolutionCallback? _resolveSyncIssues;
  late final SyncScheduler _scheduler;
  SyncLifecycleObserver? _lifecycleObserver;
  StreamSubscription<WebSocketEvent>? _wsEventSubscription;
  Future<void>? _webSocketCancellation;
  JoinRequestLifecycleHandler? _onJoinRequest;
  MemberLeftLifecycleHandler? _onMemberLeft;
  GroupDissolvedLifecycleHandler? _onGroupDissolved;
  Future<void>? _foregroundReconciliation;
  bool _membershipReconciliationRequested = false;
  int? _pendingMembershipStatusCode;
  String? _pendingMembershipReason;
  bool _localDataWipeSuspended = false;
  final Set<Future<void>> _activeLifecycleOperations = {};

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = const SyncStatus(state: SyncState.noGroup);

  /// Tracks event key → timestamp for cross-source deduplication.
  /// Prevents double-processing when the same event arrives via
  /// both WebSocket and push notification.
  final _recentEvents = <String, DateTime>{};
  static const _deduplicationWindow = Duration(seconds: 10);

  /// Current sync status.
  SyncStatus get currentStatus => _currentStatus;

  /// Stream of sync status changes.
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Initialize the engine: set up lifecycle observer and WebSocket.
  ///
  /// Call once at app startup after provider container is ready.
  Future<void> initialize() async {
    if (_localDataWipeSuspended) return;
    if (_lifecycleObserver == null) {
      _lifecycleObserver = SyncLifecycleObserver(
        onResume: _runForegroundReconciliation,
        onPaused: () => _scheduler.onAppPaused(),
      );
      _lifecycleObserver!.start();
    }
    await _runForegroundReconciliation();
  }

  /// Configure the application-layer effects for membership lifecycle events.
  ///
  /// Kept separate from [connectPushNotifications] so handlers can be installed
  /// before push initialization consumes a cold-start message.
  void configureLifecycleHandlers({
    required JoinRequestLifecycleHandler onJoinRequest,
    required MemberLeftLifecycleHandler onMemberLeft,
    required GroupDissolvedLifecycleHandler onGroupDissolved,
  }) {
    _onJoinRequest = onJoinRequest;
    _onMemberLeft = onMemberLeft;
    _onGroupDissolved = onGroupDissolved;
  }

  /// Wire every push notification handler to the unified sync lifecycle.
  ///
  /// Call before [PushNotificationService.initialize] so foreground, opened-app,
  /// and cold-start messages all enter the same handler chain.
  void connectPushNotifications(PushNotificationService pushService) {
    pushService.registerHandlers(
      onSyncAvailable: (_) async => onSyncAvailable(),
      onMemberConfirmed: onMemberConfirmed,
      onJoinRequest: (data) =>
          _runLifecycleOperation(() => _handleJoinRequest(data)),
      onMemberLeft: (data) =>
          _runLifecycleOperation(() => _handleMemberLeft(data)),
      onGroupDissolved: (data) =>
          _runLifecycleOperation(() => _handleGroupDissolved(data)),
      onGroupSnapshotInvalidated: (data) =>
          _runLifecycleOperation(() => _handleGroupSnapshotInvalidated(data)),
      onGroupKeyRequested: (_) => _runLifecycleOperation(() async {
        await _groupKeyRecovery?.respondForCurrentGroup();
      }),
    );
  }

  /// Dispose all timers, observers, and WebSocket connection.
  void dispose() {
    _scheduler.dispose();
    _lifecycleObserver?.dispose();
    _lifecycleObserver = null;
    _disconnectWebSocket();
    unawaited(_statusController.close());
  }

  // --- Public API (called by transaction use cases, push handlers, etc.) ---

  /// Transaction created/updated/deleted.
  void onTransactionChanged() {
    if (_localDataWipeSuspended) return;
    if (kDebugMode) {
      debugPrint('[SyncEngine] onTransactionChanged');
    }
    _scheduler.onTransactionChanged();
  }

  /// User modified profile (name/avatar).
  void onProfileChanged() {
    if (_localDataWipeSuspended) return;
    _scheduler.onProfileChanged();
  }

  /// Push notification: syncAvailable.
  void onSyncAvailable() {
    if (_localDataWipeSuspended) return;
    if (_isDuplicate('syncAvailable')) return;
    _scheduler.onSyncAvailable();
  }

  /// Push notification or WebSocket: memberConfirmed (Group activated).
  Future<void> onMemberConfirmed([Map<String, dynamic>? data]) {
    return _runLifecycleOperation(() => _onMemberConfirmed(data));
  }

  Future<void> _onMemberConfirmed(Map<String, dynamic>? data) async {
    final groupId = _nonEmptyString(data?['groupId']);
    final eventKey = 'memberConfirmed:${groupId ?? 'authoritative'}';
    if (_isDuplicate(eventKey)) return;
    if (kDebugMode) {
      debugPrint('[SyncEngine] onMemberConfirmed');
    }

    final activation = _memberActivation;
    if (activation == null) {
      _scheduler.onMemberConfirmed();
      return;
    }

    _updateStatus(_currentStatus.copyWith(state: SyncState.initialSyncing));
    final result = await activation.execute(expectedGroupId: groupId);
    switch (result) {
      case MemberActivationReady():
        final queue = await _orchestrator.getQueueSummary();
        final activeGroup = await _groupRepo.getActiveGroup();
        _updateStatus(
          SyncStatus(
            state: _queueState(queue, otherwise: SyncState.synced),
            lastSyncAt: activeGroup?.lastSyncAt,
            pendingQueueCount: queue.pendingCount,
            deadLetterCount: queue.deadLetterCount,
          ),
        );
        await _connectWebSocket();
      case MemberActivationAwaitingKey(:final message):
        _recentEvents.remove(eventKey);
        _updateStatus(
          SyncStatus(state: SyncState.awaitingKey, errorMessage: message),
        );
      case MemberActivationPendingApproval():
        _recentEvents.remove(eventKey);
        _updateStatus(const SyncStatus(state: SyncState.noGroup));
      case MemberActivationNotInGroup():
        _recentEvents.remove(eventKey);
        _updateStatus(const SyncStatus(state: SyncState.noGroup));
      case MemberActivationError(:final message):
        _recentEvents.remove(eventKey);
        _updateStatus(
          SyncStatus(state: SyncState.error, errorMessage: message),
        );
    }
  }

  /// Manual sync button pressed.
  void onManualSync() {
    if (_localDataWipeSuspended) return;
    if (kDebugMode) {
      debugPrint('[SyncEngine] onManualSync');
    }
    _scheduler.onManualSync();
  }

  /// Stops every local sync ingress before destructive privacy erasure.
  /// New scheduler, lifecycle, push, and WebSocket work is rejected; active
  /// scheduler/foreground/event work is awaited so it cannot repopulate rows
  /// after the database transaction commits.
  Future<void> suspendForLocalDataWipe() async {
    _localDataWipeSuspended = true;
    await _disconnectWebSocketAndWait();
    await _scheduler.suspendAndWait();
    await _foregroundReconciliation;
    while (_activeLifecycleOperations.isNotEmpty) {
      await Future.wait(_activeLifecycleOperations.toList());
    }
    // A transport connect that began before the suspension gate may have
    // completed while the in-flight operation was draining.
    await _disconnectWebSocketAndWait();
  }

  /// Drops identity-bound in-memory state after all wipe resources complete.
  /// Timers and sockets remain stopped; the scheduler merely becomes eligible
  /// for future events created by the fresh post-wipe identity.
  void resetAfterLocalDataWipe() {
    _recentEvents.clear();
    _membershipReconciliationRequested = false;
    _pendingMembershipStatusCode = null;
    _pendingMembershipReason = null;
    _disconnectWebSocket();
    _scheduler.resetAfterLocalDataWipe();
    _localDataWipeSuspended = false;
    _updateStatus(const SyncStatus(state: SyncState.noGroup));
  }

  bool get isLocalDataWipeSuspended => _localDataWipeSuspended;

  // --- WebSocket ---

  Future<void> _connectWebSocket() async {
    if (_localDataWipeSuspended) return;
    final group = await _groupRepo.getActiveGroup();
    if (group == null || _localDataWipeSuspended) return;

    final deviceId = await _keyManager.getDeviceId();
    if (deviceId == null || _localDataWipeSuspended) return;

    // Subscribe to events (idempotent — only subscribe once)
    _wsEventSubscription ??= _webSocketService.eventStream.listen(
      _handleWebSocketEvent,
    );

    _webSocketService.connect(
      groupId: group.groupId,
      deviceId: deviceId,
      signMessage: (message) async {
        final sig = await _keyManager.signData(utf8.encode(message));
        return base64Encode(sig.bytes);
      },
    );
    _webSocketService.startLifecycleObservation();
  }

  void _disconnectWebSocket() {
    unawaited(_disconnectWebSocketAndWait());
  }

  Future<void> _disconnectWebSocketAndWait() {
    final previousCancellation = _webSocketCancellation;
    final subscription = _wsEventSubscription;
    _wsEventSubscription = null;
    _webSocketService
      ..stopLifecycleObservation()
      ..disconnect();

    final cancellations = <Future<void>>[];
    if (previousCancellation != null) {
      cancellations.add(previousCancellation);
    }
    if (subscription != null) {
      cancellations.add(subscription.cancel());
    }
    late final Future<void> tracked;
    tracked = Future.wait<void>(cancellations).whenComplete(() {
      if (identical(_webSocketCancellation, tracked)) {
        _webSocketCancellation = null;
      }
    });
    _webSocketCancellation = tracked;
    return tracked;
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    if (_localDataWipeSuspended) return;
    if (kDebugMode) {
      debugPrint('[SyncEngine] WebSocket event: ${event.type}');
    }
    switch (event.type) {
      case WebSocketEventType.authError:
        _launchLifecycleOperation(_reconcileAfterTransportMembershipFailure);
      case WebSocketEventType.syncAvailable:
        onSyncAvailable();
      case WebSocketEventType.groupKeyRequested:
        final groupId = event.groupId;
        if (groupId != null) {
          _launchLifecycleOperation(
            () async => _groupKeyRecovery?.respondToPending(groupId: groupId),
          );
        }
      case WebSocketEventType.ownerTransferred:
        final groupId = event.groupId;
        if (groupId != null) {
          _launchLifecycleOperation(
            () => _handleOwnerTransferred(groupId, event.data),
          );
        }
      case WebSocketEventType.memberConfirmed:
        _launchLifecycleOperation(
          () => _onMemberConfirmed({
            ...?event.data,
            if (event.groupId != null) 'groupId': event.groupId,
          }),
        );
      case WebSocketEventType.joinRequest:
        final groupId = event.groupId;
        if (groupId != null) {
          _launchLifecycleOperation(() async => _onJoinRequest?.call(groupId));
        }
      case WebSocketEventType.joinRequestResolved:
        final groupId = event.groupId;
        if (groupId != null) {
          _launchLifecycleOperation(() async => _onJoinRequest?.call(groupId));
        }
      case WebSocketEventType.memberLeft:
        final groupId = event.groupId;
        final data = event.data;
        if (groupId != null && data != null) {
          _launchLifecycleOperation(
            () => _handleMemberLeft({...data, 'groupId': groupId}),
          );
        }
      case WebSocketEventType.groupDissolved:
        final groupId = event.groupId;
        if (groupId != null) {
          _launchLifecycleOperation(
            () => _handleGroupDissolved({'groupId': groupId}),
          );
        }
      case WebSocketEventType.groupStatus:
        final groupId = event.groupId;
        if (groupId != null) {
          _launchLifecycleOperation(
            () => _handleOwnerTransferred(groupId, event.data),
          );
        }
      case WebSocketEventType.groupNameUpdated:
        final groupId = event.groupId;
        if (groupId != null) {
          _launchLifecycleOperation(
            () => _refreshGroupSnapshot(groupId, event.data),
          );
        }
    }
  }

  Future<void> _runLifecycleOperation(Future<void> Function() operation) {
    if (_localDataWipeSuspended) return Future.value();
    late final Future<void> tracked;
    tracked = operation().whenComplete(() {
      _activeLifecycleOperations.remove(tracked);
    });
    _activeLifecycleOperations.add(tracked);
    return tracked;
  }

  void _launchLifecycleOperation(Future<void> Function() operation) {
    unawaited(_runLifecycleOperation(operation));
  }

  Future<void> _handleJoinRequest(Map<String, dynamic> data) async {
    final groupId = _nonEmptyString(data['groupId']);
    if (groupId == null) return;
    await _onJoinRequest?.call(groupId);
  }

  Future<void> _handleMemberLeft(Map<String, dynamic> data) async {
    final groupId = _nonEmptyString(data['groupId']);
    final deviceId = _nonEmptyString(data['deviceId']);
    if (groupId == null || deviceId == null) return;

    await _onMemberLeft?.call(
      groupId,
      deviceId,
      _nonEmptyString(data['reason']),
      _positiveInt(data['keyEpoch']),
    );
    await _refreshGroupSnapshot(groupId, data);
    await _handleSyncRequest(SyncMode.incrementalPull);
    await _refreshInitialStatus();
    if (_currentStatus.state == SyncState.noGroup) {
      _disconnectWebSocket();
    }
  }

  Future<void> _handleGroupDissolved(Map<String, dynamic> data) async {
    final groupId = _nonEmptyString(data['groupId']);
    if (groupId == null) return;

    await _onGroupDissolved?.call(groupId);
    _disconnectWebSocket();
    await _refreshInitialStatus();
  }

  Future<void> _handleGroupSnapshotInvalidated(
    Map<String, dynamic> data,
  ) async {
    final groupId = _nonEmptyString(data['groupId']);
    if (groupId == null) return;
    if (data['type'] == 'owner_transferred') {
      await _handleOwnerTransferred(groupId, data);
      return;
    }
    await _refreshGroupSnapshot(groupId, data);
  }

  Future<void> _handleOwnerTransferred(
    String groupId, [
    Map<String, dynamic>? controlEvent,
  ]) async {
    // Apply role + authoritative epoch first. This clears a retired local key,
    // then pull installs the server-backed targeted transfer envelope.
    await _refreshGroupSnapshot(groupId, controlEvent);
    await _handleSyncRequest(SyncMode.incrementalPull);
    await _refreshInitialStatus();
  }

  Future<void> _refreshGroupSnapshot(
    String groupId, [
    Map<String, dynamic>? controlEvent,
  ]) async {
    await _groupSnapshotRefresh?.execute(
      groupId: groupId,
      controlEvent: controlEvent,
    );
  }

  String? _nonEmptyString(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  int? _positiveInt(Object? value) {
    final parsed = switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text),
      _ => null,
    };
    return parsed != null && parsed > 0 ? parsed : null;
  }

  // --- Internal ---

  Future<void> _runForegroundReconciliation() {
    if (_localDataWipeSuspended) return Future.value();
    final existing = _foregroundReconciliation;
    if (existing != null) return existing;

    late final Future<void> tracked;
    tracked = _runForegroundReconciliationOnce().whenComplete(() {
      if (identical(_foregroundReconciliation, tracked)) {
        _foregroundReconciliation = null;
      }
    });
    _foregroundReconciliation = tracked;
    return tracked;
  }

  Future<void> _runForegroundReconciliationOnce() async {
    if (_localDataWipeSuspended) return;
    try {
      await _maintainAvatarStaging?.call();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SyncEngine: avatar staging maintenance failed');
      }
    }
    try {
      await _maintainInboundQuarantine?.call();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SyncEngine: inbound quarantine maintenance failed');
      }
    }
    final reconciliation = _controlPlaneReconciliation;
    if (reconciliation == null) {
      // Source-compatible path for lightweight legacy test doubles. Production
      // always injects the control-plane reconciler below.
      await _recoverDurableOutbox?.call();
      await _resolveSyncIssuesSafely();
      await _refreshInitialStatus();
      await _connectWebSocket();
      await _groupKeyRecovery?.respondForCurrentGroup();
      return;
    }

    final controlResult = await reconciliation.execute();
    if (controlResult is! ControlPlaneReconciliationReconciled) {
      if (controlResult is ControlPlaneReconciliationNoGroup) {
        _disconnectWebSocket();
      }
      await _refreshInitialStatus();
      return;
    }

    // Data-plane ordering contract: control snapshot and membership first,
    // durable writes second, pull (including C1 key envelopes) third, WS last.
    await _recoverDurableOutbox?.call();
    _membershipReconciliationRequested = false;
    _pendingMembershipStatusCode = null;
    _pendingMembershipReason = null;
    await _scheduler.onAppResumed();

    if (_membershipReconciliationRequested) {
      _membershipReconciliationRequested = false;
      final statusCode = _pendingMembershipStatusCode;
      final reason = _pendingMembershipReason;
      _pendingMembershipStatusCode = null;
      _pendingMembershipReason = null;
      final retry = statusCode == 403 || statusCode == 404
          ? await reconciliation.executeAfterAuthenticatedMembershipFailure(
              statusCode: statusCode!,
              reason: reason ?? 'Membership rejected by relay',
            )
          : await reconciliation.execute();
      if (retry is! ControlPlaneReconciliationReconciled) {
        if (retry is ControlPlaneReconciliationNoGroup) {
          _disconnectWebSocket();
        }
        await _refreshInitialStatus();
        return;
      }
    }

    await _connectWebSocket();
    await _refreshInitialStatus();
    await _groupKeyRecovery?.respondForCurrentGroup();
  }

  Future<void> _resolveSyncIssuesSafely() async {
    try {
      await _resolveSyncIssues?.call();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SyncEngine: automatic sync issue resolution failed');
      }
    }
  }

  Future<void> _reconcileAfterTransportMembershipFailure({
    int? statusCode,
    String? reason,
  }) async {
    if (_localDataWipeSuspended) return;
    _membershipReconciliationRequested = true;
    if (statusCode == 403 || statusCode == 404) {
      _pendingMembershipStatusCode = statusCode;
      _pendingMembershipReason = reason;
    }
    if (_foregroundReconciliation != null) return;
    final reconciliation = _controlPlaneReconciliation;
    if (reconciliation == null) return;

    _membershipReconciliationRequested = false;
    final pendingStatusCode = _pendingMembershipStatusCode;
    final pendingReason = _pendingMembershipReason;
    _pendingMembershipStatusCode = null;
    _pendingMembershipReason = null;
    final result = pendingStatusCode == 403 || pendingStatusCode == 404
        ? await reconciliation.executeAfterAuthenticatedMembershipFailure(
            statusCode: pendingStatusCode!,
            reason: pendingReason ?? 'Membership rejected by relay',
          )
        : await reconciliation.execute();
    if (result is ControlPlaneReconciliationNoGroup) {
      _disconnectWebSocket();
    }
    await _refreshInitialStatus();
  }

  Future<void> _refreshInitialStatus() async {
    final group = await _groupRepo.getActiveGroup();
    if (group != null) {
      if (group.groupKey?.isNotEmpty != true) {
        final recovery = await _groupKeyRecovery?.requestKey(
          groupId: group.groupId,
        );
        _updateStatus(
          SyncStatus(
            state: SyncState.awaitingKey,
            lastSyncAt: group.lastSyncAt,
            errorMessage: recovery?.message,
          ),
        );
        return;
      }
      final queue = await _orchestrator.getQueueSummary();
      _updateStatus(
        SyncStatus(
          state: _queueState(queue, otherwise: SyncState.idle),
          lastSyncAt: group.lastSyncAt,
          pendingQueueCount: queue.pendingCount,
          deadLetterCount: queue.deadLetterCount,
        ),
      );
    } else {
      _updateStatus(const SyncStatus(state: SyncState.noGroup));
    }
  }

  Future<void> _handleSyncRequest(SyncMode mode) async {
    if (_localDataWipeSuspended) return;
    if (kDebugMode) {
      debugPrint('[SyncEngine] Sync requested: $mode');
    }
    final group = await _groupRepo.getActiveGroup();
    if (group == null) {
      _updateStatus(const SyncStatus(state: SyncState.noGroup));
      return;
    }

    // Emit syncing state
    final syncingState = mode == SyncMode.initialSync
        ? SyncState.initialSyncing
        : SyncState.syncing;
    _updateStatus(_currentStatus.copyWith(state: syncingState));

    final result = await _orchestrator.execute(mode);
    await _resolveSyncIssuesSafely();

    // Compute final status
    switch (result) {
      case SyncOrchestratorSuccess():
        final queue = await _orchestrator.getQueueSummary();
        final refreshedGroup = await _groupRepo.getActiveGroup();
        _updateStatus(
          SyncStatus(
            state: _queueState(queue, otherwise: SyncState.synced),
            lastSyncAt: refreshedGroup?.lastSyncAt,
            pendingQueueCount: queue.pendingCount,
            deadLetterCount: queue.deadLetterCount,
          ),
        );
      case SyncOrchestratorNoGroup():
        _disconnectWebSocket();
        _updateStatus(const SyncStatus(state: SyncState.noGroup));
      case SyncOrchestratorError(:final message, :final statusCode):
        if (statusCode == 403 || statusCode == 404) {
          _launchLifecycleOperation(
            () => _reconcileAfterTransportMembershipFailure(
              statusCode: statusCode,
              reason: message,
            ),
          );
        }
        final queue = await _orchestrator.getQueueSummary();
        _updateStatus(
          SyncStatus(
            state: queue.needsAttention
                ? SyncState.needsAttention
                : SyncState.error,
            lastSyncAt: _currentStatus.lastSyncAt,
            pendingQueueCount: queue.pendingCount,
            deadLetterCount: queue.deadLetterCount,
            errorMessage: message,
          ),
        );
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    if (kDebugMode) {
      debugPrint('[SyncEngine] Status: ${status.state}');
    }
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  SyncState _queueState(
    SyncQueueSummary summary, {
    required SyncState otherwise,
  }) {
    if (summary.needsAttention) return SyncState.needsAttention;
    if (summary.pendingCount > 0) return SyncState.queuedOffline;
    return otherwise;
  }

  /// Returns true if this event should be suppressed (duplicate).
  bool _isDuplicate(String eventKey) {
    final now = DateTime.now();

    // Prune expired entries
    _recentEvents.removeWhere(
      (_, ts) => now.difference(ts) > _deduplicationWindow,
    );

    if (_recentEvents.containsKey(eventKey)) {
      return true;
    }

    _recentEvents[eventKey] = now;
    return false;
  }
}
