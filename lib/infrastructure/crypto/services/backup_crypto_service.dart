import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Password-based encryption for `.hpb` backup files.
///
/// Backup files leave the device via the share sheet, so offline brute force
/// is the threat model. Encryption is Argon2id (OWASP profile, same as
/// pin_kdf.dart) + AES-256-GCM, with a self-describing versioned header so
/// KDF parameters can be raised later without breaking old files:
///
///   v2 layout: 'HPB'(3) + version(1) + m KiB(uint32 BE) + t(1) + p(1)
///              + salt(16) + nonce(12) + ciphertext + mac(16)
///
/// Files without the magic are the legacy headerless format
/// (PBKDF2-HMAC-SHA256 100k iterations, salt(16) + nonce(12) + ciphertext
/// + mac(16)) and stay importable — [decrypt] auto-detects.
///
/// KDF params parsed from a header are capped ([_kMaxMemoryKib] etc.): a
/// hostile file must not be able to demand unbounded Argon2id memory.
class BackupCryptoService {
  /// Encrypts [plaintext] into the current (v2) backup format.
  Future<Uint8List> encrypt(Uint8List plaintext, String password) async {
    final salt = _randomBytes(_kSaltLength);
    final nonce = _randomBytes(_kNonceLength);

    final key = await Isolate.run(
      () => _deriveArgon2id(
        _KdfArgs(password, salt, _kMemoryKib, _kIterations, _kParallelism),
      ),
    );

    final secretBox = await AesGcm.with256bits().encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
    );

    final header = ByteData(_kHeaderLength);
    header.setUint8(0, 0x48); // H
    header.setUint8(1, 0x50); // P
    header.setUint8(2, 0x42); // B
    header.setUint8(3, _kFormatVersion);
    header.setUint32(4, _kMemoryKib);
    header.setUint8(8, _kIterations);
    header.setUint8(9, _kParallelism);

    return Uint8List.fromList([
      ...header.buffer.asUint8List(),
      ...salt,
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  /// Decrypts a backup blob in either the v2 or the legacy format.
  ///
  /// Throws [InvalidBackupFormatException] on structurally impossible input,
  /// [UnsupportedBackupFormatException] on an unknown version or hostile KDF
  /// parameters, and [BackupDecryptionException] when authentication fails
  /// (wrong password or tampered data — indistinguishable by design).
  Future<Uint8List> decrypt(Uint8List data, String password) async {
    if (_hasMagic(data)) {
      return _decryptVersioned(data, password);
    }
    return _decryptLegacy(data, password);
  }

  Future<Uint8List> _decryptVersioned(Uint8List data, String password) async {
    if (data.length < _kMinVersionedLength) {
      throw const InvalidBackupFormatException('too small');
    }
    final version = data[3];
    if (version != _kFormatVersion) {
      throw UnsupportedBackupFormatException(
        'unsupported backup version: $version',
      );
    }

    final header = ByteData.sublistView(data, 0, _kHeaderLength);
    final memoryKib = header.getUint32(4);
    final iterations = header.getUint8(8);
    final parallelism = header.getUint8(9);
    if (memoryKib < _kMinMemoryKib ||
        memoryKib > _kMaxMemoryKib ||
        iterations < 1 ||
        iterations > _kMaxIterations ||
        parallelism != 1) {
      throw UnsupportedBackupFormatException(
        'KDF parameters out of bounds (m=$memoryKib, t=$iterations, '
        'p=$parallelism)',
      );
    }

    final salt = data.sublist(_kHeaderLength, _kHeaderLength + _kSaltLength);
    final nonce = data.sublist(
      _kHeaderLength + _kSaltLength,
      _kHeaderLength + _kSaltLength + _kNonceLength,
    );
    final cipherText = data.sublist(
      _kHeaderLength + _kSaltLength + _kNonceLength,
      data.length - _kMacLength,
    );
    final mac = Mac(data.sublist(data.length - _kMacLength));

    final key = await Isolate.run(
      () => _deriveArgon2id(
        _KdfArgs(password, salt, memoryKib, iterations, parallelism),
      ),
    );
    return _aesGcmDecrypt(cipherText, key, nonce, mac);
  }

  Future<Uint8List> _decryptLegacy(Uint8List data, String password) async {
    // salt(16) + nonce(12) + mac(16) with empty ciphertext = 44 bytes.
    if (data.length < _kMinLegacyLength) {
      throw const InvalidBackupFormatException('too small');
    }
    final salt = data.sublist(0, _kSaltLength);
    final nonce = data.sublist(_kSaltLength, _kSaltLength + _kNonceLength);
    final cipherText = data.sublist(
      _kSaltLength + _kNonceLength,
      data.length - _kMacLength,
    );
    final mac = Mac(data.sublist(data.length - _kMacLength));

    final key = await Isolate.run(
      () => _deriveLegacyPbkdf2(_KdfArgs(password, salt, 0, 0, 0)),
    );
    return _aesGcmDecrypt(cipherText, key, nonce, mac);
  }

  Future<Uint8List> _aesGcmDecrypt(
    List<int> cipherText,
    List<int> key,
    List<int> nonce,
    Mac mac,
  ) async {
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    try {
      final plaintext = await AesGcm.with256bits().decrypt(
        secretBox,
        secretKey: SecretKey(key),
      );
      return Uint8List.fromList(plaintext);
    } on SecretBoxAuthenticationError {
      throw const BackupDecryptionException();
    }
  }

  bool _hasMagic(Uint8List data) {
    return data.length >= 4 &&
        data[0] == 0x48 &&
        data[1] == 0x50 &&
        data[2] == 0x42;
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(256));
  }
}

// ── format constants ──

const int _kFormatVersion = 2;
const int _kHeaderLength = 10; // magic(3) + version(1) + m(4) + t(1) + p(1)
const int _kSaltLength = 16;
const int _kNonceLength = 12;
const int _kMacLength = 16;
const int _kMinLegacyLength = _kSaltLength + _kNonceLength + _kMacLength;
const int _kMinVersionedLength = _kHeaderLength + _kMinLegacyLength;

// Argon2id write-path parameters — OWASP profile, mirrors pin_kdf.dart.
// p is pinned to 1: DartArgon2id with parallelism > 1 spawns nested isolates
// inside the Isolate.run used here.
const int _kMemoryKib = 19456;
const int _kIterations = 2;
const int _kParallelism = 1;
const int _kKeyLength = 32;

// Read-path sanity caps for header-supplied parameters.
const int _kMinMemoryKib = 8;
const int _kMaxMemoryKib = 65536; // 64 MiB
const int _kMaxIterations = 10;

/// Isolate-sendable KDF arguments (primitives only).
class _KdfArgs {
  const _KdfArgs(
    this.password,
    this.salt,
    this.memoryKib,
    this.iterations,
    this.parallelism,
  );

  final String password;
  final List<int> salt;
  final int memoryKib;
  final int iterations;
  final int parallelism;
}

Future<List<int>> _deriveArgon2id(_KdfArgs args) async {
  final algorithm = Argon2id(
    parallelism: args.parallelism,
    memory: args.memoryKib,
    iterations: args.iterations,
    hashLength: _kKeyLength,
  );
  final secret = await algorithm.deriveKey(
    secretKey: SecretKey(utf8.encode(args.password)),
    nonce: args.salt,
  );
  return secret.extractBytes();
}

Future<List<int>> _deriveLegacyPbkdf2(_KdfArgs args) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );
  final secret = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(args.password)),
    nonce: args.salt,
  );
  return secret.extractBytes();
}

/// Structurally impossible backup data (e.g. truncated below minimum size).
class InvalidBackupFormatException implements Exception {
  const InvalidBackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'Invalid backup file: $message';
}

/// A well-formed header advertising a version or KDF cost this build cannot
/// (or refuses to) process.
class UnsupportedBackupFormatException implements Exception {
  const UnsupportedBackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Authentication failure: wrong password or tampered data.
class BackupDecryptionException implements Exception {
  const BackupDecryptionException();

  @override
  String toString() => 'Incorrect password';
}
