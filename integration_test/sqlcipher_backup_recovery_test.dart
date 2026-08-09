import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/sqlcipher_backup_sandbox.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'current HPB v2 export clear restore cold-reopen and re-export stay isolated',
    (tester) async {
      final sandbox = await SqlCipherBackupSandbox.create();
      addTearDown(sandbox.close);

      await sandbox.seedCurrentV2State();
      final before = await sandbox.snapshot();
      final originalBackup = await sandbox.exportCurrentV2();

      await sandbox.clearAllData();
      await sandbox.restoreCurrentV2(originalBackup);

      await sandbox.expectSupportedStateEquals(before);
      await sandbox.expectPhotoBackupPolicy();
      await sandbox.expectCurrentSqlCipherColdReopen();

      final reexport = await sandbox.exportCurrentV2();
      await sandbox.expectCurrentV2Backup(originalBackup);
      await sandbox.expectCurrentV2Backup(reexport);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  testWidgets(
    'current HPB v2 input remains byte-stable through restore and re-export',
    (tester) async {
      final sandbox = await SqlCipherBackupSandbox.create();
      addTearDown(sandbox.close);

      await sandbox.seedCurrentV2State();
      final originalBackup = await sandbox.exportCurrentV2();
      final originalDigest = await sandbox.backupDigest(originalBackup);

      await sandbox.clearAllData();
      await sandbox.restoreCurrentV2(originalBackup);
      expect(await sandbox.backupDigest(originalBackup), originalDigest);

      final reexport = await sandbox.exportCurrentV2();
      await sandbox.expectCurrentV2Backup(reexport);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  testWidgets(
    'hostile and non-v2 inputs reject before changing the isolated sandbox',
    (tester) async {
      const cases = <BackupHostileInput>[
        BackupHostileInput.wrongPassword,
        BackupHostileInput.truncatedHeader,
        BackupHostileInput.truncatedBody,
        BackupHostileInput.truncatedMac,
        BackupHostileInput.unknownVersion,
        BackupHostileInput.nonV2Headerless,
        BackupHostileInput.invalidMagicLength,
        BackupHostileInput.hostileMemoryKib,
        BackupHostileInput.hostileIterations,
        BackupHostileInput.hostileParallelism,
        BackupHostileInput.corruptAuthenticatedPayload,
        BackupHostileInput.invalidCompressedPayload,
        BackupHostileInput.invalidJson,
        BackupHostileInput.invalidSchema,
        BackupHostileInput.invalidTransaction,
        BackupHostileInput.encryptedSizeLimit,
        BackupHostileInput.decompressedSizeLimit,
      ];

      for (final input in cases) {
        final sandbox = await SqlCipherBackupSandbox.create();
        addTearDown(sandbox.close);
        await sandbox.seedCurrentV2State();
        final originalBackup = await sandbox.exportCurrentV2();
        final before = await sandbox.snapshot(backup: originalBackup);

        final hostileBackup = await sandbox.createHostileBackup(
          originalBackup,
          input,
        );
        final result = await sandbox.attemptRestore(
          hostileBackup,
          input: input,
        );

        expect(result.isError, isTrue, reason: input.name);
        await sandbox.expectSnapshotUnchanged(
          before,
          originalBackup: originalBackup,
        );
        await sandbox.expectCurrentSqlCipherColdReopen();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  testWidgets(
    'pre-commit restore interruptions compensate every isolated store',
    (tester) async {
      const faults = <BackupRestoreFault>[
        BackupRestoreFault.syncSuspend,
        BackupRestoreFault.transactionCommit,
        BackupRestoreFault.settingsApply,
      ];

      for (final fault in faults) {
        final sandbox = await SqlCipherBackupSandbox.create();
        addTearDown(sandbox.close);
        await sandbox.seedCurrentV2State();
        final originalBackup = await sandbox.exportCurrentV2();
        final before = await sandbox.snapshot(backup: originalBackup);
        final session = sandbox.createFaultSession(fault);

        final result = await session.restore(originalBackup);

        expect(result.isError, isTrue, reason: fault.name);
        expect(session.importCalls, lessThanOrEqualTo(1), reason: fault.name);
        expect(
          session.resumeCalls,
          greaterThanOrEqualTo(1),
          reason: fault.name,
        );
        await sandbox.expectSnapshotUnchanged(
          before,
          originalBackup: originalBackup,
        );
        await sandbox.expectCurrentSqlCipherColdReopen();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  testWidgets(
    'cleanup and resume retries never re-import a valid current-v2 restore',
    (tester) async {
      const faults = <BackupRestoreFault>[
        BackupRestoreFault.syncCleanup,
        BackupRestoreFault.syncResume,
      ];

      for (final fault in faults) {
        final sandbox = await SqlCipherBackupSandbox.create();
        addTearDown(sandbox.close);
        await sandbox.seedCurrentV2State();
        final expectedRestore = await sandbox.snapshot();
        final originalBackup = await sandbox.exportCurrentV2();
        await sandbox.clearAllData();
        final session = sandbox.createFaultSession(fault);

        final first = await session.restore(originalBackup);
        expect(first.isError, isTrue, reason: fault.name);
        expect(session.importCalls, 1, reason: fault.name);
        expect(session.isSyncSuspended, isTrue, reason: fault.name);

        final retry = await session.restore(originalBackup);
        expect(retry.isSuccess, isTrue, reason: fault.name);
        expect(session.importCalls, 1, reason: fault.name);
        expect(session.isSyncSuspended, isFalse, reason: fault.name);
        await sandbox.expectSupportedStateEquals(expectedRestore);
        await sandbox.expectCurrentSqlCipherColdReopen();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
