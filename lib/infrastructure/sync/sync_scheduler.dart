import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/sync_status_model.dart';

/// Callback invoked when the scheduler determines a sync should happen.
typedef SyncRequestCallback = Future<void> Function(SyncMode mode);

/// Callback to check if a full pull is needed (>24h since last sync).
typedef NeedsFullPullCallback = Future<bool> Function();

/// Scheduling layer: manages when to sync via debounce, polling, and thresholds.
///
/// Pure platform mechanism — no business logic. Outputs [SyncMode] requests
/// via the [onSyncRequested] callback.
class SyncScheduler {
  SyncScheduler({
    required this._onSyncRequested,
    required this._checkNeedsFullPull,
  });

  final SyncRequestCallback _onSyncRequested;
  final NeedsFullPullCallback _checkNeedsFullPull;

  Timer? _debounceTimer;
  Timer? _pollingTimer;
  bool _isSyncing = false;
  bool _isSuspended = false;
  Completer<void>? _activeSyncCompletion;
  final Set<SyncMode> _pendingModes = {};
  final Set<Future<void>> _activeThresholdChecks = {};

  static const _debounceDuration = Duration(seconds: 10);
  static const _pollingInterval = Duration(minutes: 15);

  /// Transaction changed — reset 10-second debounce timer.
  void onTransactionChanged() {
    if (_isSuspended) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _enqueueSync(SyncMode.incrementalPush);
    });
  }

  /// App resumed — immediate pull + start 15-min polling.
  Future<void> onAppResumed() async {
    if (_isSuspended) return;
    await _enqueueSync(SyncMode.incrementalPull);
    if (_isSuspended) return;
    _startPollingTimer();
    _check24HourThreshold();
  }

  /// App paused — flush pending debounce + stop polling.
  void onAppPaused() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      _enqueueSync(SyncMode.incrementalPush);
    }
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Realtime control event: syncAvailable — immediate pull.
  void onSyncAvailable() {
    if (_isSuspended) return;
    _enqueueSync(SyncMode.incrementalPull);
  }

  /// Confirmed membership — initial sync, serialized with any active work.
  Future<void> onMemberConfirmed() async {
    if (_isSuspended) return;
    await _enqueueSync(SyncMode.initialSync);
  }

  /// User changed profile — immediate profile sync.
  void onProfileChanged() {
    if (_isSuspended) return;
    _enqueueSync(SyncMode.profileSync);
  }

  /// Manual sync — skip debounce, immediate push + pull.
  void onManualSync() {
    if (_isSuspended) return;
    _debounceTimer?.cancel();
    _enqueueSync(SyncMode.incrementalPush);
    _enqueueSync(SyncMode.incrementalPull);
  }

  void dispose() {
    _isSuspended = true;
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _debounceTimer = null;
    _pollingTimer = null;
    _pendingModes.clear();
  }

  /// Prevents any new request, cancels timers and waits until the active sync
  /// callback has returned. This is the write barrier used before a local data
  /// wipe starts deleting database rows.
  Future<void> suspendAndWait() async {
    _isSuspended = true;
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _debounceTimer = null;
    _pollingTimer = null;
    _pendingModes.clear();
    await _activeSyncCompletion?.future;
    while (_activeThresholdChecks.isNotEmpty) {
      await Future.wait(_activeThresholdChecks.toList());
    }
  }

  /// Clears stale scheduling state after the wipe. No timers are restarted;
  /// future lifecycle/user events may schedule work against the fresh identity.
  void resetAfterLocalDataWipe() {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _debounceTimer = null;
    _pollingTimer = null;
    _pendingModes.clear();
    _isSuspended = false;
  }

  bool get isSuspended => _isSuspended;

  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _enqueueSync(SyncMode.incrementalPull);
      _check24HourThreshold();
    });
  }

  void _check24HourThreshold() {
    if (_isSuspended) return;
    late final Future<void> tracked;
    tracked = _checkNeedsFullPull()
        .then((needs) async {
          if (needs && !_isSuspended) {
            await _enqueueSync(SyncMode.fullPull);
          }
        })
        .catchError((_) {})
        .whenComplete(() => _activeThresholdChecks.remove(tracked));
    _activeThresholdChecks.add(tracked);
    unawaited(tracked);
  }

  Future<void> _enqueueSync(SyncMode mode) async {
    if (_isSuspended) return;
    if (_isSyncing) {
      _pendingModes.add(mode);
      return;
    }

    _isSyncing = true;
    final completion = Completer<void>();
    _activeSyncCompletion = completion;
    try {
      await _onSyncRequested(mode);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncScheduler: sync failed for $mode: $e');
      }
    } finally {
      _isSyncing = false;
      if (!completion.isCompleted) completion.complete();
      if (identical(_activeSyncCompletion, completion)) {
        _activeSyncCompletion = null;
      }
      if (!_isSuspended && _pendingModes.isNotEmpty) {
        final sorted = _pendingModes.toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
        _pendingModes.clear();
        for (final pending in sorted) {
          await _enqueueSync(pending);
        }
      }
    }
  }
}
