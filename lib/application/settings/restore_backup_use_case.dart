import 'dart:io';

import '../../shared/utils/result.dart';

/// The database-writing portion of a backup restore.
typedef BackupRestoreImport =
    Future<Result<void>> Function({
      required File backupFile,
      required String password,
    });

/// The outstanding post-restore action while the sync barrier is held.
///
/// A cleanup retry must not re-import the backup, and a resumption retry must
/// not rerun cleanup. Both operations are intentionally idempotent, but the
/// distinction prevents accidental work and makes the failure state explicit.
enum _RestoreBarrierState {
  idle,
  recoverFailedSuspension,
  cleanupPending,
  resumeAfterSuccessfulRestore,
  resumeAfterFailedRestore,
}

/// Coordinates an encrypted backup import with the family-sync write barrier.
///
/// The importer remains responsible for decrypting, validating, and atomically
/// replacing accounting rows. This use case owns the boundary around that
/// write: no pull, push, WebSocket lifecycle action, or scheduler task may
/// overlap the replacement transaction.
class RestoreBackupUseCase {
  RestoreBackupUseCase({
    required this._importBackup,
    required this._suspendSync,
    required this._resetFamilySyncState,
    required this._resumeSync,
  });

  final BackupRestoreImport _importBackup;
  final Future<void> Function() _suspendSync;
  final Future<void> Function() _resetFamilySyncState;
  final Future<void> Function() _resumeSync;

  _RestoreBarrierState _barrierState = _RestoreBarrierState.idle;

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
    switch (_barrierState) {
      case _RestoreBarrierState.cleanupPending:
        return _retryCleanupAndResume();
      case _RestoreBarrierState.resumeAfterSuccessfulRestore:
        return _resumeAfterSuccessfulRestore();
      case _RestoreBarrierState.resumeAfterFailedRestore:
        return _resumeAfterFailedRestore();
      case _RestoreBarrierState.recoverFailedSuspension:
        return _recoverFailedSuspension();
      case _RestoreBarrierState.idle:
        return _beginRestore(backupFile: backupFile, password: password);
    }
  }

  Future<Result<void>> _beginRestore({
    required File backupFile,
    required String password,
  }) async {
    // Set this before awaiting so a partial suspension is always recovered if
    // one ingress shutdown operation reports an error.
    _barrierState = _RestoreBarrierState.recoverFailedSuspension;

    try {
      await _suspendSync();
    } catch (error) {
      return _recoverFailedSuspension(failure: 'Backup restore failed: $error');
    }

    late final Result<void> result;
    try {
      result = await _importBackup(backupFile: backupFile, password: password);
    } catch (error) {
      _barrierState = _RestoreBarrierState.resumeAfterFailedRestore;
      return _resumeAfterFailedRestore(
        originalFailure: Result.error('Backup restore failed: $error'),
      );
    }
    if (result.isError) {
      _barrierState = _RestoreBarrierState.resumeAfterFailedRestore;
      return _resumeAfterFailedRestore(originalFailure: result);
    }

    // Restored transactions are imported local-only. Remove stale ciphertext
    // and semantic operations from the pre-restore family state before a push
    // can run. If any cleanup step fails, the barrier deliberately remains
    // closed; a retry resumes at cleanup instead of re-importing data.
    _barrierState = _RestoreBarrierState.cleanupPending;
    return _retryCleanupAndResume();
  }

  Future<Result<void>> _retryCleanupAndResume() async {
    try {
      await _resetFamilySyncState();
    } catch (error) {
      return Result.error(
        'Backup restore cleanup incomplete; sync remains paused. '
        'Retry the restore to finish cleanup: $error',
      );
    }

    _barrierState = _RestoreBarrierState.resumeAfterSuccessfulRestore;
    return _resumeAfterSuccessfulRestore();
  }

  Future<Result<void>> _resumeAfterSuccessfulRestore() async {
    final resumed = await _resumeBarrier();
    return resumed ?? Result.success(null);
  }

  Future<Result<void>> _resumeAfterFailedRestore({
    Result<void>? originalFailure,
  }) async {
    final resumed = await _resumeBarrier();
    if (resumed != null) return resumed;
    return originalFailure ??
        Result.error(
          'Backup restore did not complete; sync is available again. '
          'Retry the restore.',
        );
  }

  Future<Result<void>> _recoverFailedSuspension({String? failure}) async {
    final resumed = await _resumeBarrier();
    if (resumed != null) return resumed;
    return Result.error(
      failure ??
          'Backup restore did not begin; sync is available again. '
              'Retry the restore.',
    );
  }

  /// Resumes at most once per execution. A failure deliberately leaves the
  /// corresponding pending state in place, so the next user retry only
  /// retries the unsafe boundary instead of replaying the completed step.
  Future<Result<void>?> _resumeBarrier() async {
    try {
      await _resumeSync();
      _barrierState = _RestoreBarrierState.idle;
      return null;
    } catch (error) {
      return Result.error('Backup restore resumed incompletely: $error');
    }
  }
}
