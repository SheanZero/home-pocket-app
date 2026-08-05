import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/restore_backup_use_case.dart';
import 'package:home_pocket/shared/utils/result.dart';

void main() {
  test(
    'waits for an active pull barrier before restore writes can begin',
    () async {
      final activePull = Completer<void>();
      final calls = <String>[];
      var importStarted = false;
      final useCase = RestoreBackupUseCase(
        suspendSync: () async {
          calls.add('suspend');
          await activePull.future;
        },
        importBackup: ({required backupFile, required password}) async {
          importStarted = true;
          calls.add('restore');
          return Result.success(null);
        },
        resetFamilySyncState: () async => calls.add('reset'),
        resumeSync: () async => calls.add('resume'),
      );

      final restoring = useCase.execute(
        backupFile: File('unused.hpb'),
        password: 'password',
      );
      await Future<void>.delayed(Duration.zero);

      expect(importStarted, isFalse);
      expect(calls, ['suspend']);

      activePull.complete();
      expect((await restoring).isSuccess, isTrue);
      expect(calls, ['suspend', 'restore', 'reset', 'resume']);
    },
  );

  test('does not resume sync before a successful restore completes', () async {
    final restoreCompleted = Completer<void>();
    final calls = <String>[];
    final useCase = RestoreBackupUseCase(
      suspendSync: () async => calls.add('suspend'),
      importBackup: ({required backupFile, required password}) async {
        calls.add('restore-start');
        await restoreCompleted.future;
        calls.add('restore-complete');
        return Result.success(null);
      },
      resetFamilySyncState: () async => calls.add('reset'),
      resumeSync: () async => calls.add('resume'),
    );

    final restoring = useCase.execute(
      backupFile: File('unused.hpb'),
      password: 'password',
    );
    await Future<void>.delayed(Duration.zero);

    expect(calls, ['suspend', 'restore-start']);
    expect(calls, isNot(contains('resume')));

    restoreCompleted.complete();
    expect((await restoring).isSuccess, isTrue);
    expect(calls, [
      'suspend',
      'restore-start',
      'restore-complete',
      'reset',
      'resume',
    ]);
  });

  test(
    'coalesces concurrent restore requests into one database mutation',
    () async {
      final releaseImport = Completer<void>();
      var imports = 0;
      final useCase = RestoreBackupUseCase(
        suspendSync: () async {},
        importBackup: ({required backupFile, required password}) async {
          imports++;
          await releaseImport.future;
          return Result.success(null);
        },
        resetFamilySyncState: () async {},
        resumeSync: () async {},
      );

      final first = useCase.execute(
        backupFile: File('first.hpb'),
        password: 'password',
      );
      final second = useCase.execute(
        backupFile: File('second.hpb'),
        password: 'another-password',
      );
      await Future<void>.delayed(Duration.zero);

      expect(imports, 1);
      releaseImport.complete();
      expect((await first).isSuccess, isTrue);
      expect((await second).isSuccess, isTrue);
      expect(imports, 1);
    },
  );

  test(
    'resumes the barrier once when restore fails without resetting sync data',
    () async {
      var suspensions = 0;
      var resumes = 0;
      var resets = 0;
      final useCase = RestoreBackupUseCase(
        suspendSync: () async => suspensions++,
        importBackup: ({required backupFile, required password}) async =>
            Result.error('corrupt backup'),
        resetFamilySyncState: () async => resets++,
        resumeSync: () async => resumes++,
      );

      final result = await useCase.execute(
        backupFile: File('unused.hpb'),
        password: 'password',
      );

      expect(result.isError, isTrue);
      expect(suspensions, 1);
      expect(resets, 0);
      expect(resumes, 1);
    },
  );

  test('recovers the barrier when sync suspension fails', () async {
    var imports = 0;
    var resumes = 0;
    final useCase = RestoreBackupUseCase(
      suspendSync: () async => throw StateError('scheduler unavailable'),
      importBackup: ({required backupFile, required password}) async {
        imports++;
        return Result.success(null);
      },
      resetFamilySyncState: () async {},
      resumeSync: () async => resumes++,
    );

    final result = await useCase.execute(
      backupFile: File('unused.hpb'),
      password: 'password',
    );

    expect(result.isError, isTrue);
    expect(result.error, contains('scheduler unavailable'));
    expect(imports, 0);
    expect(resumes, 1);
  });

  test('resumes the barrier when the importer throws', () async {
    var cleanupAttempts = 0;
    var resumes = 0;
    final useCase = RestoreBackupUseCase(
      suspendSync: () async {},
      importBackup: ({required backupFile, required password}) async =>
          throw StateError('unreadable backup'),
      resetFamilySyncState: () async => cleanupAttempts++,
      resumeSync: () async => resumes++,
    );

    final result = await useCase.execute(
      backupFile: File('unused.hpb'),
      password: 'password',
    );

    expect(result.isError, isTrue);
    expect(result.error, contains('unreadable backup'));
    expect(cleanupAttempts, 0);
    expect(resumes, 1);
  });

  test(
    'keeps sync suspended when post-import sync cleanup fails, then retries cleanup safely',
    () async {
      var suspensions = 0;
      var imports = 0;
      var cleanupAttempts = 0;
      var resumes = 0;
      final useCase = RestoreBackupUseCase(
        suspendSync: () async => suspensions++,
        importBackup: ({required backupFile, required password}) async {
          imports++;
          return Result.success(null);
        },
        resetFamilySyncState: () async {
          cleanupAttempts++;
          if (cleanupAttempts == 1) {
            throw StateError('sync queue unavailable');
          }
        },
        resumeSync: () async => resumes++,
      );

      final first = await useCase.execute(
        backupFile: File('unused.hpb'),
        password: 'password',
      );

      expect(first.isError, isTrue);
      expect(first.error, contains('cleanup incomplete'));
      expect(suspensions, 1);
      expect(imports, 1);
      expect(cleanupAttempts, 1);
      expect(resumes, 0);

      final retry = await useCase.execute(
        backupFile: File('unused.hpb'),
        password: 'password',
      );

      expect(retry.isSuccess, isTrue);
      expect(suspensions, 1);
      expect(imports, 1);
      expect(cleanupAttempts, 2);
      expect(resumes, 1);
    },
  );

  test(
    'does not repeat cleanup while retrying a failed sync resumption',
    () async {
      var cleanupAttempts = 0;
      var resumeAttempts = 0;
      final useCase = RestoreBackupUseCase(
        suspendSync: () async {},
        importBackup: ({required backupFile, required password}) async =>
            Result.success(null),
        resetFamilySyncState: () async => cleanupAttempts++,
        resumeSync: () async {
          resumeAttempts++;
          if (resumeAttempts == 1) {
            throw StateError('push registration unavailable');
          }
        },
      );

      final first = await useCase.execute(
        backupFile: File('unused.hpb'),
        password: 'password',
      );
      expect(first.isError, isTrue);
      expect(first.error, contains('resumed incompletely'));
      expect(cleanupAttempts, 1);
      expect(resumeAttempts, 1);

      final retry = await useCase.execute(
        backupFile: File('unused.hpb'),
        password: 'password',
      );
      expect(retry.isSuccess, isTrue);
      expect(cleanupAttempts, 1);
      expect(resumeAttempts, 2);
    },
  );
}
