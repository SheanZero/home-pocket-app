import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../repositories/master_key_repository.dart';

/// Creates an encrypted SQLCipher database executor.
///
/// Must be called after MasterKeyRepository is initialized (has master key).
///
/// SQLCipher config:
/// - Cipher: AES-256-CBC
/// - KDF: PBKDF2-HMAC-SHA512, 256,000 iterations
/// - Key: 32 bytes derived from master key using HKDF
Future<QueryExecutor> createEncryptedExecutor(
  MasterKeyRepository masterKeyRepository, {
  bool inMemory = false,
}) async {
  if (!await masterKeyRepository.hasMasterKey()) {
    throw MasterKeyNotInitializedException();
  }

  final dbKey = await _deriveDatabaseKey(masterKeyRepository);

  if (inMemory) {
    return NativeDatabase.memory(setup: (db) => _setupEncryption(db, dbKey));
  }

  await _ensureNativeLibrary();
  final file = await _getDatabaseFile();

  return NativeDatabase.createInBackground(
    file,
    setup: (db) => _setupEncryption(db, dbKey),
  );
}

void _setupEncryption(sqlite3.Database db, String dbKey) {
  // Apply SQLCipher encryption key
  db.execute("PRAGMA key = \"x'$dbKey'\";");
  db.execute('PRAGMA cipher = "aes-256-cbc";');
  db.execute('PRAGMA kdf_iter = 256000;');

  // Verify encryption is active
  final result = db.select('PRAGMA cipher_version;');
  if (result.isEmpty) {
    throw StateError('SQLCipher not loaded - encryption unavailable');
  }
}

/// Derive database encryption key using HKDF-SHA256.
///
/// This is cryptographically secure key derivation per ADR-006.
Future<String> _deriveDatabaseKey(
  MasterKeyRepository masterKeyRepository,
) async {
  final secretKey = await masterKeyRepository.deriveKey('database_encryption');
  final keyBytes = await secretKey.extractBytes();
  return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}

Future<File> _getDatabaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbDir = Directory(p.join(dir.path, 'databases'));
  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }
  return File(p.join(dbDir.path, 'home_pocket.db'));
}

/// Load SQLCipher native library for the current platform.
Future<void> _ensureNativeLibrary() async {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}
