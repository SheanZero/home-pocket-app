import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/device_test_crypto.dart';

const _plaintextSqliteHeader = <int>[
  0x53,
  0x51,
  0x4c,
  0x69,
  0x74,
  0x65,
  0x20,
  0x66,
  0x6f,
  0x72,
  0x6d,
  0x61,
  0x74,
  0x20,
  0x33,
  0x00,
];

Future<String> _scalar(AppDatabase database, String statement) async {
  final rows = await database.customSelect(statement).get();
  expect(rows, hasLength(1), reason: '$statement returned no scalar value');
  return rows.single.data.values.single.toString().toLowerCase();
}

Future<void> _assertEncryptedHeader(File databaseFile) async {
  final header = await databaseFile
      .openRead(0, _plaintextSqliteHeader.length)
      .first;
  expect(header, isNot(orderedEquals(_plaintextSqliteHeader)));
}

Future<void> _assertCurrentSqlCipher(AppDatabase database) async {
  final sqliteMasterCount = await database
      .customSelect('SELECT count(*) AS count FROM sqlite_master')
      .getSingle();
  expect(
    await _scalar(database, 'PRAGMA cipher_version'),
    matches(RegExp(r'^4\.17\.\d+(?:\s|$)')),
  );
  expect(await _scalar(database, 'PRAGMA cipher_status'), '1');
  expect(sqliteMasterCount.read<int>('count'), greaterThan(0));
  expect(await _scalar(database, 'PRAGMA user_version'), '36');
  expect(await _scalar(database, 'PRAGMA integrity_check'), 'ok');
}

Future<void> _assertSentinel(AppDatabase database) async {
  expect(
    await _scalar(
      database,
      "SELECT event FROM audit_logs WHERE id = 'current-schema-lifecycle'",
    ),
    'current_schema_write',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'production SQLCipher creates, writes, and cold-reopens the current schema',
    (tester) async {
      final root = await Directory.systemTemp.createTemp(
        'sqlcipher-native-assets-current-',
      );
      final databaseFile = File('${root.path}/current-schema.db');
      AppDatabase? database;
      try {
        final keys = DeviceTestMasterKeyRepository();
        database = AppDatabase(
          await createDeviceTestEncryptedExecutor(keys, databaseFile),
        );
        await _assertCurrentSqlCipher(database);
        await _assertEncryptedHeader(databaseFile);

        await database.customStatement(
          "INSERT INTO audit_logs (id, event, device_id, timestamp) VALUES ('current-schema-lifecycle', 'current_schema_write', 'fixture-device', 1700000000001)",
        );
        await _assertSentinel(database);

        await database.close();
        await _assertEncryptedHeader(databaseFile);
        database = AppDatabase(
          await createDeviceTestEncryptedExecutor(keys, databaseFile),
        );
        await _assertCurrentSqlCipher(database);
        await _assertSentinel(database);
        await _assertEncryptedHeader(databaseFile);
      } finally {
        await database?.close();
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
