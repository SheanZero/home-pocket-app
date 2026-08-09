import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../repositories/master_key_repository.dart';

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

final _requiredSqlCipherVersion = RegExp(r'^4\.17\.\d+(?:\s|$)');

/// Loads the sqlite3 Native Asset selected by the package build hook.
///
/// This deliberately reads the native library version without opening a
/// database, deriving a key, or creating any database file. SQLCipher identity
/// and encrypted-handle checks remain owned by [createEncryptedExecutor].
Future<void> ensureNativeLibrary() async {
  final version = sqlite3.sqlite3.version.libVersion.trim();
  if (version.isEmpty) {
    throw StateError('sqlite3 Native Asset reported an empty library version');
  }
}

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
  File? databaseFile,
}) async {
  if (inMemory && databaseFile != null) {
    throw ArgumentError.value(
      databaseFile,
      'databaseFile',
      'Cannot provide a database file for an in-memory database.',
    );
  }

  if (!await masterKeyRepository.hasMasterKey()) {
    throw MasterKeyNotInitializedException();
  }

  final dbKey = await _deriveDatabaseKey(masterKeyRepository);

  if (inMemory) {
    return NativeDatabase.memory(setup: (db) => _setupEncryption(db, dbKey));
  }

  final file = databaseFile ?? await _getDatabaseFile();
  await _ensureDatabaseParentExists(file);
  await _rejectPlaintextDatabase(file);

  return NativeDatabase(file, setup: (db) => _setupEncryption(db, dbKey));
}

void _setupEncryption(sqlite3.Database db, String dbKey) {
  // Apply SQLCipher encryption key
  db.execute("PRAGMA key = \"x'$dbKey'\";");
  db.execute('PRAGMA cipher = "aes-256-cbc";');
  db.execute('PRAGMA kdf_iter = 256000;');

  // Fail closed if the Native Asset is missing, stale, unkeyed, or unable to
  // read the encrypted schema. `cipher_version` alone is not sufficient: plain
  // SQLite ignores unknown PRAGMAs, and a wrong key is only detected when a
  // database page is actually read.
  final versionRows = db.select('PRAGMA cipher_version;');
  final version = versionRows.isEmpty
      ? ''
      : versionRows.first.values.first.toString();
  if (!_requiredSqlCipherVersion.hasMatch(version)) {
    throw StateError('Required SQLCipher 4.17.x Native Asset is unavailable');
  }

  final statusRows = db.select('PRAGMA cipher_status;');
  final status = statusRows.isEmpty ? null : statusRows.first.values.first;
  if (status?.toString() != '1') {
    throw StateError('SQLCipher database handle is not encrypted');
  }

  final schemaRows = db.select('SELECT count(*) AS count FROM sqlite_master;');
  if (schemaRows.length != 1 || schemaRows.single['count'] is! int) {
    throw StateError('Encrypted database schema is unreadable');
  }
}

Future<void> _rejectPlaintextDatabase(File file) async {
  if (!await file.exists() ||
      await file.length() < _plaintextSqliteHeader.length) {
    return;
  }
  final handle = await file.open();
  try {
    final header = await handle.read(_plaintextSqliteHeader.length);
    if (_bytesEqual(header, _plaintextSqliteHeader)) {
      throw StateError('Refusing to open a plaintext SQLite database');
    }
  } finally {
    await handle.close();
  }
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
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
  return File(path);
}

Future<void> _ensureDatabaseParentExists(File file) async {
  final parent = file.parent;
  if (!await parent.exists()) {
    await parent.create(recursive: true);
  }
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
