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
    required SyncRequestCallback onSyncRequested,
    required NeedsFullPullCallback checkNeedsFullPull,
  }) : _onSyncRequested = onSyncRequested,
       _checkNeedsFullPull = checkNeedsFullPull;

  final SyncRequestCallback _onSyncRequested;
  final NeedsFullPullCallback _checkNeedsFullPull;

  Timer? _debounceTimer;
  Timer? _pollingTimer;
  bool _isSyncing = false;
  final Set<SyncMode> _pendingModes = {};

  static const _debounceDuration = Duration(minutes: 1);
  static const _pollingInterval = Duration(minutes: 15);

  /// Transaction changed — reset 1-minute debounce timer.
  void onTransactionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _enqueueSync(SyncMode.incrementalPush);
    });
  }

  /// App resumed — immediate pull + start 15-min polling.
  void onAppResumed() {
    _enqueueSync(SyncMode.incrementalPull);
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

  /// Push notification: syncAvailable — immediate pull.
  void onSyncAvailable() {
    _enqueueSync(SyncMode.incrementalPull);
  }

  /// Push notification: memberConfirmed — initial sync.
  void onMemberConfirmed() {
    _enqueueSync(SyncMode.initialSync);
  }

  /// User changed profile — immediate profile sync.
  void onProfileChanged() {
    _enqueueSync(SyncMode.profileSync);
  }

  /// Manual sync — skip debounce, immediate push + pull.
  void onManualSync() {
    _debounceTimer?.cancel();
    _enqueueSync(SyncMode.incrementalPush);
    _enqueueSync(SyncMode.incrementalPull);
  }

  void dispose() {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _debounceTimer = null;
    _pollingTimer = null;
    _pendingModes.clear();
  }

  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _enqueueSync(SyncMode.incrementalPull);
      _check24HourThreshold();
    });
  }

  void _check24HourThreshold() {
    unawaited(
      _checkNeedsFullPull().then((needs) {
        if (needs) _enqueueSync(SyncMode.fullPull);
      }).catchError((_) {}),
    );
  }

  Future<void> _enqueueSync(SyncMode mode) async {
    if (_isSyncing) {
      _pendingModes.add(mode);
      return;
    }

    _isSyncing = true;
    try {
      await _onSyncRequested(mode);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncScheduler: sync failed for $mode: $e');
      }
    } finally {
      _isSyncing = false;
      if (_pendingModes.isNotEmpty) {
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
