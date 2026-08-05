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
}
