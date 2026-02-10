import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../security/secure_storage_service.dart';
import 'master_key_repository.dart';

/// Implementation of [MasterKeyRepository] using FlutterSecureStorage.
///
/// The master key is a 256-bit (32-byte) cryptographically secure random key.
/// All encryption keys are derived from this master key using HKDF-SHA256.
class MasterKeyRepositoryImpl implements MasterKeyRepository {
  MasterKeyRepositoryImpl({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  static const String _hkdfSalt = 'homepocket-v1-2026';

  /// Cache for derived keys to avoid repeated HKDF operations.
  final Map<String, SecretKey> _derivedKeyCache = {};

  @override
  Future<void> initializeMasterKey() async {
    if (await hasMasterKey()) {
      throw StateError('Master key already exists. Cannot reinitialize.');
    }

    // Generate 256-bit cryptographically secure random key
    final random = Random.secure();
    final masterKeyBytes = List<int>.generate(32, (_) => random.nextInt(256));

    // Store in secure storage
    await _secureStorage.write(
      key: StorageKeys.masterKey,
      value: base64Encode(masterKeyBytes),
    );
  }

  @override
  Future<bool> hasMasterKey() async {
    final value = await _secureStorage.read(key: StorageKeys.masterKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<List<int>> getMasterKey() async {
    final value = await _secureStorage.read(key: StorageKeys.masterKey);
    if (value == null || value.isEmpty) {
      throw MasterKeyNotInitializedException();
    }
    return base64Decode(value);
  }

  @override
  Future<SecretKey> deriveKey(String purpose) async {
    // Check cache first
    if (_derivedKeyCache.containsKey(purpose)) {
      return _derivedKeyCache[purpose]!;
    }

    final masterKeyBytes = await getMasterKey();

    // Use HKDF-SHA256 to derive purpose-specific key
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(masterKeyBytes),
      info: utf8.encode(purpose),
      nonce: utf8.encode(_hkdfSalt),
    );

    // Cache the derived key
    _derivedKeyCache[purpose] = derivedKey;

    return derivedKey;
  }

  @override
  Future<void> clearMasterKey() async {
    _derivedKeyCache.clear();
    await _secureStorage.delete(key: StorageKeys.masterKey);
  }
}
