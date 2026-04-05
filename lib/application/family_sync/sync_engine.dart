import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/sync_status_model.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/sync_lifecycle_observer.dart';
import '../../infrastructure/sync/sync_scheduler.dart';
import 'sync_orchestrator.dart';

/// Unified sync entry point. Combines SyncScheduler + SyncOrchestrator
/// and exposes a reactive SyncStatus stream.
class SyncEngine {
  SyncEngine({
    required SyncOrchestrator orchestrator,
    required GroupRepository groupRepo,
  }) : _orchestrator = orchestrator,
       _groupRepo = groupRepo {
    _scheduler = SyncScheduler(
      onSyncRequested: _handleSyncRequest,
      checkNeedsFullPull: _orchestrator.needsFullPull,
    );
  }

  final SyncOrchestrator _orchestrator;
  final GroupRepository _groupRepo;
  late final SyncScheduler _scheduler;
  SyncLifecycleObserver? _lifecycleObserver;

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

  /// Initialize the engine: set up lifecycle observer.
  ///
  /// Call once at app startup after provider container is ready.
  void initialize() {
    _lifecycleObserver = SyncLifecycleObserver(
      onResume: () async => _scheduler.onAppResumed(),
      onPaused: () => _scheduler.onAppPaused(),
    );
    _lifecycleObserver!.start();

    // Set initial status based on group presence
    unawaited(_refreshInitialStatus());
  }

  /// Dispose all timers and observers.
  void dispose() {
    _scheduler.dispose();
    _lifecycleObserver?.dispose();
    _lifecycleObserver = null;
    unawaited(_statusController.close());
  }

  // --- Public API (called by transaction use cases, push handlers, etc.) ---

  /// Transaction created/updated/deleted.
  void onTransactionChanged() {
    if (kDebugMode) {
      debugPrint('[SyncEngine] onTransactionChanged');
    }
    _scheduler.onTransactionChanged();
  }

  /// User modified profile (name/avatar).
  void onProfileChanged() => _scheduler.onProfileChanged();

  /// Push notification: syncAvailable.
  void onSyncAvailable() {
    if (_isDuplicate('syncAvailable')) return;
    _scheduler.onSyncAvailable();
  }

  /// Push notification or WebSocket: memberConfirmed (Group activated).
  void onMemberConfirmed() {
    if (_isDuplicate('memberConfirmed')) return;
    if (kDebugMode) {
      debugPrint('[SyncEngine] onMemberConfirmed');
    }
    _scheduler.onMemberConfirmed();
  }

  /// Manual sync button pressed.
  void onManualSync() {
    if (kDebugMode) {
      debugPrint('[SyncEngine] onManualSync');
    }
    _scheduler.onManualSync();
  }

  // --- Internal ---

  Future<void> _refreshInitialStatus() async {
    final group = await _groupRepo.getActiveGroup();
    if (group != null) {
      final pendingCount = await _orchestrator.getPendingQueueCount();
      _updateStatus(SyncStatus(
        state: pendingCount > 0 ? SyncState.queuedOffline : SyncState.idle,
        lastSyncAt: group.lastSyncAt,
        pendingQueueCount: pendingCount,
      ));
    } else {
      _updateStatus(const SyncStatus(state: SyncState.noGroup));
    }
  }

  Future<void> _handleSyncRequest(SyncMode mode) async {
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

    // Compute final status
    switch (result) {
      case SyncOrchestratorSuccess():
        final pendingCount = await _orchestrator.getPendingQueueCount();
        final refreshedGroup = await _groupRepo.getActiveGroup();
        _updateStatus(SyncStatus(
          state: pendingCount > 0 ? SyncState.queuedOffline : SyncState.synced,
          lastSyncAt: refreshedGroup?.lastSyncAt,
          pendingQueueCount: pendingCount,
        ));
      case SyncOrchestratorNoGroup():
        _updateStatus(const SyncStatus(state: SyncState.noGroup));
      case SyncOrchestratorError(:final message):
        final pendingCount = await _orchestrator.getPendingQueueCount();
        _updateStatus(SyncStatus(
          state: SyncState.error,
          lastSyncAt: _currentStatus.lastSyncAt,
          pendingQueueCount: pendingCount,
          errorMessage: message,
        ));
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
