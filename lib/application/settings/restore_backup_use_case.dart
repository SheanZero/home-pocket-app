import 'dart:io';

import '../../shared/utils/result.dart';

/// The database-writing portion of a backup restore.
typedef BackupRestoreImport =
    Future<Result<void>> Function({
      required File backupFile,
      required String password,
    });

/// Coordinates an encrypted backup import with the family-sync write barrier.
///
/// The importer remains responsible for decrypting, validating, and atomically
/// replacing accounting rows. This use case owns the boundary around that
/// write: no pull, push, WebSocket lifecycle action, or scheduler task may
/// overlap the replacement transaction.
class RestoreBackupUseCase {
  RestoreBackupUseCase({
    required BackupRestoreImport importBackup,
    required Future<void> Function() suspendSync,
    required Future<void> Function() resetFamilySyncState,
    required Future<void> Function() resumeSync,
  }) : _importBackup = importBackup,
       _suspendSync = suspendSync,
       _resetFamilySyncState = resetFamilySyncState,
       _resumeSync = resumeSync;

  final BackupRestoreImport _importBackup;
  final Future<void> Function() _suspendSync;
  final Future<void> Function() _resetFamilySyncState;
  final Future<void> Function() _resumeSync;

  // A backup screen cannot normally be opened twice, but this makes the
  // database boundary safe across duplicate taps and independently mounted
  // settings routes too. All callers observe the same completed result.
  static Future<Result<void>>? _inFlightRestore;

  Future<Result<void>> execute({
    required File backupFile,
    required String password,
  }) {
    final active = _inFlightRestore;
    if (active != null) return active;

    late final Future<Result<void>> tracked;
    tracked = _executeOnce(backupFile: backupFile, password: password)
        .whenComplete(() {
          if (identical(_inFlightRestore, tracked)) {
            _inFlightRestore = null;
          }
        });
    _inFlightRestore = tracked;
    return tracked;
  }

  Future<Result<void>> _executeOnce({
    required File backupFile,
    required String password,
  }) async {
    var barrierEntered = false;
    late Result<void> result;

    try {
      // Set this before awaiting so a partially completed suspension is always
      // unwound if one of its ingress shutdown operations reports an error.
      barrierEntered = true;
      await _suspendSync();

      result = await _importBackup(backupFile: backupFile, password: password);
      if (result.isSuccess) {
        // Restored transactions are imported local-only. Remove stale
        // ciphertext and semantic operations from the pre-restore family
        // state so a resumed push cannot publish the replaced ledger.
        await _resetFamilySyncState();
      }
    } catch (error) {
      result = Result.error('Backup restore failed: $error');
    }

    if (barrierEntered) {
      try {
        await _resumeSync();
      } catch (error) {
        if (result.isSuccess) {
          result = Result.error('Backup restore resumed incompletely: $error');
        }
      }
    }
    return result;
  }
}
