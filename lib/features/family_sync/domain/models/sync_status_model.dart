import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_status_model.freezed.dart';

/// States of the sync engine.
enum SyncState {
  /// No group joined or created yet.
  noGroup,

  /// Group exists, no sync in progress.
  idle,

  /// First-time full sync after joining a group.
  initialSyncing,

  /// Incremental sync in progress.
  syncing,

  /// Sync completed successfully.
  synced,

  /// Sync encountered an error.
  error,

  /// Offline with operations queued for later sync.
  queuedOffline,
}

/// Sync mode determines what orchestration flow to run.
///
/// Lower priority values run first when multiple modes are queued.
enum SyncMode {
  /// Full initial sync when joining a group.
  initialSync(0),

  /// Pull all data from remote.
  fullPull(1),

  /// Push local changes to remote.
  incrementalPush(2),

  /// Pull incremental changes from remote.
  incrementalPull(2),

  /// Sync profile/group metadata only.
  profileSync(3);

  const SyncMode(this.priority);

  /// Scheduling priority. Lower values = higher priority.
  final int priority;
}

/// Rich sync status with metadata, replacing the old plain SyncStatus enum.
@freezed
abstract class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    required SyncState state,
    DateTime? lastSyncAt,
    int? pendingQueueCount,
    String? errorMessage,
  }) = _SyncStatus;
}
