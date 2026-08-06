import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:integration_test/integration_test.dart';

import 'fixtures/sqlcipher_4_10_v35_fixture.dart';
import 'helpers/device_test_crypto.dart';

const _fixtureSha256 =
    '58d6f6f1f40e636323e13d40cf013cd9e541a8eb892f60b507cd898e2328c004';
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

Future<String> _scalarText(AppDatabase database, String pragma) async {
  final rows = await database.customSelect(pragma).get();
  expect(rows, hasLength(1), reason: '$pragma returned no scalar value');
  return rows.single.data.values.single.toString().toLowerCase();
}

Future<void> _assertSqlCipher417(AppDatabase database) async {
  final version = await _scalarText(database, 'PRAGMA cipher_version');
  expect(version, matches(RegExp(r'^4\.17\.\d+(?:\s|$)')));

  final status = await _scalarText(database, 'PRAGMA cipher_status');
  expect(status, '1');

  final schemaRows = await database
      .customSelect('SELECT count(*) AS count FROM sqlite_master')
      .get();
  expect(schemaRows, hasLength(1));
  expect(schemaRows.single.read<int>('count'), greaterThan(0));
}

Future<void> _assertEncryptedFileHeader(File file) async {
  final bytes = await file.openRead(0, _plaintextSqliteHeader.length).first;
  expect(bytes, isNot(equals(_plaintextSqliteHeader)));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SQLCipher 4.17 Native Asset opens and migrates a real 4.10 database',
    (tester) async {
      final root = await Directory.systemTemp.createTemp(
        'sqlcipher-native-assets-',
      );
      final databaseFile = File('${root.path}/sqlcipher-4.10-v35.db');
      final fixtureBytes = base64Decode(
        sqlCipher410V35FixtureBase64.replaceAll(RegExp(r'\s'), ''),
      );
      expect(sha256.convert(fixtureBytes).toString(), _fixtureSha256);
      await databaseFile.writeAsBytes(fixtureBytes, flush: true);
      await _assertEncryptedFileHeader(databaseFile);

      AppDatabase? database;
      try {
        final keys = DeviceTestMasterKeyRepository();
        database = AppDatabase(
          await createDeviceTestEncryptedExecutor(keys, databaseFile),
        );

        await _assertSqlCipher417(database);
        expect(await _scalarText(database, 'PRAGMA user_version'), '36');

        final migratedShoppingItem = await database.customSelect('''
              SELECT name, sync_revision, sync_origin_device_id
              FROM shopping_items WHERE id = 'fixture-item'
            ''').getSingle();
        expect(migratedShoppingItem.read<String>('name'), 'fixture-value');
        expect(migratedShoppingItem.read<int>('sync_revision'), 200000);
        expect(
          migratedShoppingItem.read<String>('sync_origin_device_id'),
          'fixture-device',
        );

        await database.customStatement(
          '''
            UPDATE shopping_items
            SET name = ?, sync_revision = sync_revision + 1
            WHERE id = 'fixture-item'
          ''',
          ['written-by-4.17'],
        );
        final journalMode = await _scalarText(database, 'PRAGMA journal_mode');
        // This marker is intentionally non-sensitive device evidence consumed
        // by the release verification report.
        // ignore: avoid_print
        print('SQLCIPHER_DEVICE_EVIDENCE journal_mode=$journalMode');

        await database.close();
        database = null;
        await _assertEncryptedFileHeader(databaseFile);

        database = AppDatabase(
          await createDeviceTestEncryptedExecutor(keys, databaseFile),
        );
        await _assertSqlCipher417(database);
        expect(await _scalarText(database, 'PRAGMA user_version'), '36');

        final reopened = await database.customSelect('''
              SELECT name, sync_revision FROM shopping_items
              WHERE id = 'fixture-item'
            ''').getSingle();
        expect(reopened.read<String>('name'), 'written-by-4.17');
        expect(reopened.read<int>('sync_revision'), 200001);
      } finally {
        await database?.close();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
