import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/infrastructure/storage/privacy_wipe_journal.dart';

void main() {
  test('runs the restart-safe wipe stages in privacy-safe order', () async {
    final calls = <String>[];
    final useCase = ClearAllDataUseCase(
      journalStore: InMemoryPrivacyWipeJournalStore(),
      suspendSync: () async => calls.add('suspend'),
      wipeDatabase: () async => calls.add('database'),
      wipeAppOwnedFiles: () async => calls.add('files'),
      clearSecureUserData: () async => calls.add('secure'),
      resetSettings: () async => calls.add('settings'),
      resetInMemoryState: () async => calls.add('memory'),
    );

    final result = await useCase.execute();

    expect(result.isSuccess, isTrue);
    expect(calls, [
      'suspend',
      'database',
      'files',
      'secure',
      'settings',
      'memory',
    ]);
    expect(useCase.stage, ClearAllDataStage.completed);
  });

  test('coalesces concurrent callers into one wipe', () async {
    final suspended = Completer<void>();
    var databaseWipes = 0;
    final useCase = ClearAllDataUseCase(
      journalStore: InMemoryPrivacyWipeJournalStore(),
      suspendSync: () => suspended.future,
      wipeDatabase: () async => databaseWipes++,
      wipeAppOwnedFiles: () async {},
      clearSecureUserData: () async {},
      resetSettings: () async {},
      resetInMemoryState: () async {},
    );

    final first = useCase.execute();
    final second = useCase.execute();
    suspended.complete();

    expect((await first).isSuccess, isTrue);
    expect((await second).isSuccess, isTrue);
    expect(databaseWipes, 1);
  });

  test(
    'reports a failed cross-resource stage and a later retry completes',
    () async {
      var fileAttempts = 0;
      var databaseWipes = 0;
      final useCase = ClearAllDataUseCase(
        journalStore: InMemoryPrivacyWipeJournalStore(),
        suspendSync: () async {},
        wipeDatabase: () async => databaseWipes++,
        wipeAppOwnedFiles: () async {
          fileAttempts++;
          if (fileAttempts == 1) throw const FileSystemExceptionForTest();
        },
        clearSecureUserData: () async {},
        resetSettings: () async {},
        resetInMemoryState: () async {},
      );

      final failed = await useCase.execute();
      expect(failed.isError, isTrue);
      expect(useCase.stage, ClearAllDataStage.failed);

      final retried = await useCase.execute();
      expect(retried.isSuccess, isTrue);
      expect(fileAttempts, 2);
      expect(
        databaseWipes,
        1,
        reason: 'durable filesPending boundary skips the completed DB stage',
      );
    },
  );

  test(
    'secure-storage failure prevents false success and is retryable',
    () async {
      var secureAttempts = 0;
      var settingsResets = 0;
      final useCase = ClearAllDataUseCase(
        journalStore: InMemoryPrivacyWipeJournalStore(),
        suspendSync: () async {},
        wipeDatabase: () async {},
        wipeAppOwnedFiles: () async {},
        clearSecureUserData: () async {
          secureAttempts++;
          if (secureAttempts == 1) throw StateError('injected secure failure');
        },
        resetSettings: () async => settingsResets++,
        resetInMemoryState: () async {},
      );

      expect((await useCase.execute()).isError, isTrue);
      expect(settingsResets, 0);
      expect((await useCase.execute()).isSuccess, isTrue);
      expect(secureAttempts, 2);
      expect(settingsResets, 1);
    },
  );
}

class FileSystemExceptionForTest implements Exception {
  const FileSystemExceptionForTest();
}
