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

  final file = await _getDatabaseFile();

  return NativeDatabase(file, setup: (db) => _setupEncryption(db, dbKey));
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

Future<String> _databaseFilePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'databases', 'home_pocket.db');
}

Future<File> _getDatabaseFile() async {
  final path = await _databaseFilePath();
  final dbDir = Directory(p.dirname(path));
  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }
  return File(path);
}

/// Whether the on-disk encrypted database file already exists.
///
/// Used by AppInitializer to distinguish a genuine first launch (no master key
/// AND no database) from a dangerous state where the master key is missing but
/// an encrypted database is still present. In the latter case a new random
/// master key must NOT be generated — it would permanently orphan the existing
/// (still-encrypted) data. This check is read-only: it never creates the
/// `databases/` directory.
Future<bool> encryptedDatabaseExists() async {
  final path = await _databaseFilePath();
  return File(path).exists();
}

/// Load SQLCipher native library for the current platform.
///
/// Must be called before any database operations. On Android, this applies
/// a workaround for older versions and overrides the default sqlite3 loader
/// to use SQLCipher instead.
Future<void> ensureNativeLibrary() async {
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}
