import '../../shared/utils/result.dart';
import '../../infrastructure/storage/privacy_wipe_journal.dart';

typedef ClearAllDataStep = Future<void> Function();

/// Observable stages of the local-only privacy wipe.
///
/// Database deletion is atomic. Files, secure storage, and preferences cannot
/// share that transaction, so every later stage is idempotent and the entire
/// state machine can be retried after [failed]. Success is returned only after
/// all stages complete.
enum ClearAllDataStage {
  idle,
  suspendingSync,
  clearingDatabase,
  clearingAppOwnedFiles,
  clearingSecureUserData,
  resettingSettings,
  resettingInMemoryState,
  completed,
  failed,
}

/// Erases all local Home Pocket user data without sending a server operation.
class ClearAllDataUseCase {
  ClearAllDataUseCase({
    required ClearAllDataStep suspendSync,
    required PrivacyWipeJournalStore journalStore,
    required ClearAllDataStep wipeDatabase,
    required ClearAllDataStep wipeAppOwnedFiles,
    required ClearAllDataStep clearSecureUserData,
    required ClearAllDataStep resetSettings,
    required ClearAllDataStep resetInMemoryState,
  }) : _journalStore = journalStore,
       _suspendSync = suspendSync,
       _wipeDatabase = wipeDatabase,
       _wipeAppOwnedFiles = wipeAppOwnedFiles,
       _clearSecureUserData = clearSecureUserData,
       _resetSettings = resetSettings,
       _resetInMemoryState = resetInMemoryState;

  final PrivacyWipeJournalStore _journalStore;
  final ClearAllDataStep _suspendSync;
  final ClearAllDataStep _wipeDatabase;
  final ClearAllDataStep _wipeAppOwnedFiles;
  final ClearAllDataStep _clearSecureUserData;
  final ClearAllDataStep _resetSettings;
  final ClearAllDataStep _resetInMemoryState;

  ClearAllDataStage _stage = ClearAllDataStage.idle;
  static final Map<String, Future<Result<void>>> _globalInFlight = {};

  ClearAllDataStage get stage => _stage;

  Future<Result<void>> execute() => _coordinate(startIfAbsent: true);

  /// Resumes a durable wipe during cold start, or returns success without
  /// touching sync/data when no journal exists.
  Future<Result<void>> resumePending() => _coordinate(startIfAbsent: false);

  Future<Result<void>> _coordinate({required bool startIfAbsent}) {
    final key = _journalStore.coordinationKey;
    final active = _globalInFlight[key];
    if (active != null) return active;

    late final Future<Result<void>> tracked;
    tracked = _executeOnce(startIfAbsent: startIfAbsent).whenComplete(() {
      if (identical(_globalInFlight[key], tracked)) {
        _globalInFlight.remove(key);
      }
    });
    _globalInFlight[key] = tracked;
    return tracked;
  }

  Future<Result<void>> _executeOnce({required bool startIfAbsent}) async {
    try {
      var journal = await _journalStore.read();
      if (journal == null) {
        if (!startIfAbsent) return Result.success(null);
        journal = _journalStore.newEntry(
          PrivacyWipeJournalStage.databasePending,
        );
        await _journalStore.write(journal);
      }

      _stage = ClearAllDataStage.suspendingSync;
      await _suspendSync();

      if (journal.stage == PrivacyWipeJournalStage.databasePending) {
        _stage = ClearAllDataStage.clearingDatabase;
        await _wipeDatabase();
        journal = _journalStore.newEntry(PrivacyWipeJournalStage.filesPending);
        await _journalStore.write(journal);
      }

      if (journal.stage == PrivacyWipeJournalStage.filesPending) {
        _stage = ClearAllDataStage.clearingAppOwnedFiles;
        await _wipeAppOwnedFiles();
        journal = _journalStore.newEntry(
          PrivacyWipeJournalStage.secureUserDataPending,
        );
        await _journalStore.write(journal);
      }

      if (journal.stage == PrivacyWipeJournalStage.secureUserDataPending) {
        _stage = ClearAllDataStage.clearingSecureUserData;
        await _clearSecureUserData();
        journal = _journalStore.newEntry(
          PrivacyWipeJournalStage.settingsPending,
        );
        await _journalStore.write(journal);
      }

      if (journal.stage == PrivacyWipeJournalStage.settingsPending) {
        _stage = ClearAllDataStage.resettingSettings;
        await _resetSettings();
        journal = _journalStore.newEntry(PrivacyWipeJournalStage.memoryPending);
        await _journalStore.write(journal);
      }

      if (journal.stage == PrivacyWipeJournalStage.memoryPending) {
        _stage = ClearAllDataStage.resettingInMemoryState;
        await _resetInMemoryState();
      }

      // Last durable operation: a remaining journal always means startup must
      // fail closed and replay its pending boundary before identity/bootstrap.
      await _journalStore.delete();
      _stage = ClearAllDataStage.completed;
      return Result.success(null);
    } catch (error) {
      _stage = ClearAllDataStage.failed;
      return Result.error('Failed to clear local data: $error');
    }
  }
}
