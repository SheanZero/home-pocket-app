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
}
