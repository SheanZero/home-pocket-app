import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/crypto/database/encrypted_database.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';

import '../../../../integration_test/fixtures/sqlcipher_4_10_v35_fixture.dart';

const _databaseKeyHex =
    'd20e6a6b3552604219429fa56be09635728b7bd44db96c02357959e6392faa5a';
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

class _FixtureKeyRepository implements MasterKeyRepository {
  static final _databaseKey = Uint8List.fromList([
    for (var offset = 0; offset < _databaseKeyHex.length; offset += 2)
      int.parse(_databaseKeyHex.substring(offset, offset + 2), radix: 16),
  ]);

  @override
  Future<void> initializeMasterKey() async {}

  @override
  Future<bool> hasMasterKey() async => true;

  @override
  Future<List<int>> getMasterKey() async => List<int>.filled(32, 0);

  @override
  Future<SecretKey> deriveKey(String purpose) async {
    expect(purpose, 'database_encryption');
    return SecretKey(_databaseKey);
  }

  @override
  Future<void> clearMasterKey() async {}
}

Future<String> _scalar(AppDatabase database, String sql) async {
  final rows = await database.customSelect(sql).get();
  return rows.single.data.values.single.toString().toLowerCase();
}

Future<void> _expectEncryptedHeader(File file) async {
  final header = await file.openRead(0, _plaintextSqliteHeader.length).first;
  expect(header, isNot(equals(_plaintextSqliteHeader)));
}

void main() {
  test(
    'production executor rejects an existing plaintext SQLite file',
    () async {
      final root = await Directory.systemTemp.createTemp('plaintext-db-guard-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/plaintext.db');
      await file.writeAsBytes([
        ..._plaintextSqliteHeader,
        ...List.filled(32, 0),
      ]);

      await expectLater(
        createEncryptedExecutor(_FixtureKeyRepository(), databaseFile: file),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('plaintext SQLite'),
          ),
        ),
      );
    },
  );

  test('SQLCipher 4.17 migrates, writes, and reopens the 4.10 fixture', () async {
    final root = await Directory.systemTemp.createTemp('sqlcipher-4.10-host-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/fixture.db');
    await file.writeAsBytes(
      base64Decode(sqlCipher410V35FixtureBase64.replaceAll(RegExp(r'\s'), '')),
      flush: true,
    );

    final keys = _FixtureKeyRepository();
    var database = AppDatabase(
      await createEncryptedExecutor(keys, databaseFile: file),
    );
    expect(
      await _scalar(database, 'PRAGMA cipher_version'),
      startsWith('4.17.'),
    );
    expect(await _scalar(database, 'PRAGMA cipher_status'), '1');
    expect(await _scalar(database, 'PRAGMA user_version'), '36');
    expect(
      int.parse(await _scalar(database, 'SELECT count(*) FROM sqlite_master')),
      greaterThan(0),
    );

    await database.customStatement(
      "UPDATE shopping_items SET name = 'host-write' WHERE id = 'fixture-item'",
    );
    await database.close();
    await _expectEncryptedHeader(file);

    database = AppDatabase(
      await createEncryptedExecutor(keys, databaseFile: file),
    );
    addTearDown(database.close);
    expect(
      await _scalar(database, 'PRAGMA cipher_version'),
      startsWith('4.17.'),
    );
    expect(await _scalar(database, 'PRAGMA cipher_status'), '1');
    expect(
      await _scalar(
        database,
        "SELECT name FROM shopping_items WHERE id = 'fixture-item'",
      ),
      'host-write',
    );
  });
}
