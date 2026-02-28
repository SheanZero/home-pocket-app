/// Sync status for the family sync module.
enum SyncStatus {
  /// Not paired with any device.
  unpaired,

  /// Pairing in progress (waiting for confirmation).
  pairing,

  /// Paired and sync is up to date.
  synced,

  /// Paired and currently syncing.
  syncing,

  /// Paired but sync encountered an error.
  syncError,

  /// Paired but offline (operations queued).
  offline,
}
