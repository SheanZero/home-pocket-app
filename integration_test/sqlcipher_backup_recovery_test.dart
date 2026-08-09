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
}
