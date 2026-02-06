import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized secure storage key constants.
///
/// All secure storage keys MUST be defined here.
/// Using hardcoded key strings anywhere else is prohibited.
///
/// NOTE: These keys must stay synchronized with:
/// - `MasterKeyRepositoryImpl._masterKeyStorageKey` (crypto infrastructure)
abstract final class StorageKeys {
  /// Ed25519 private key (Base64).
  static const String devicePrivateKey = 'device_private_key';

  /// Ed25519 public key (Base64).
  static const String devicePublicKey = 'device_public_key';

  /// Device ID — SHA-256(publicKey) first 16 chars.
  static const String deviceId = 'device_id';

  /// PIN SHA-256 hash.
  static const String pinHash = 'pin_hash';

  /// Recovery kit mnemonic SHA-256 hash.
  static const String recoveryKitHash = 'recovery_kit_hash';

  /// Master encryption key (256-bit).
  ///
  /// IMPORTANT: This key name MUST match `MasterKeyRepositoryImpl._masterKeyStorageKey`
  /// from `lib/infrastructure/crypto/repositories/master_key_repository_impl.dart`.
  /// Both use 'master_key' as the storage key.
  static const String masterKey = 'master_key';

  /// All known keys (used by [SecureStorageService.clearAll]).
  static const List<String> allKeys = [
    devicePrivateKey,
    devicePublicKey,
    deviceId,
    pinHash,
    recoveryKitHash,
    masterKey,
  ];
}

/// Exception thrown when secure storage operations fail.
///
/// Wraps platform-specific exceptions with consistent error handling.
class SecureStorageException implements Exception {
  SecureStorageException(this.message, [this.originalError]);

  /// Human-readable error message.
  final String message;

  /// Original platform exception, if available.
  final Object? originalError;

  @override
  String toString() => 'SecureStorageException: $message';
}

/// Unified secure storage service wrapping platform-specific APIs.
///
/// Provides iOS Keychain / Android Keystore access through
/// [FlutterSecureStorage] with centralized platform options.
///
/// Use [StorageKeys] constants for key names.
/// Use typed convenience methods (e.g. [getDevicePrivateKey])
/// for domain-specific operations.
///
/// All methods may throw [SecureStorageException] on platform errors.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// iOS Keychain: unlocked + this device only (no iCloud sync).
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  );

  /// Android Keystore: encrypted shared preferences.
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // ── Core CRUD ──

  /// Write a key-value pair to secure storage.
  ///
  /// Throws [SecureStorageException] on platform error.
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(
        key: key,
        value: value,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw SecureStorageException('Failed to write key "$key"', e);
    }
  }

  /// Read a value from secure storage. Returns null if key does not exist.
  ///
  /// Throws [SecureStorageException] on platform error.
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw SecureStorageException('Failed to read key "$key"', e);
    }
  }

  /// Delete a key from secure storage. Silent if key does not exist.
  ///
  /// Throws [SecureStorageException] on platform error.
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw SecureStorageException('Failed to delete key "$key"', e);
    }
  }

  /// Check if a key exists in secure storage.
  ///
  /// Throws [SecureStorageException] on platform error.
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw SecureStorageException('Failed to check key "$key"', e);
    }
  }

  /// Delete all known application keys.
  ///
  /// Does NOT use [FlutterSecureStorage.deleteAll] to avoid
  /// deleting keys written by other SDKs.
  ///
  /// Throws [SecureStorageException] if any deletion fails.
  Future<void> clearAll() async {
    for (final key in StorageKeys.allKeys) {
      await delete(key: key);
    }
  }

  // ── Typed Convenience Methods ──

  Future<String?> getDevicePrivateKey() =>
      read(key: StorageKeys.devicePrivateKey);
  Future<void> setDevicePrivateKey(String value) =>
      write(key: StorageKeys.devicePrivateKey, value: value);

  Future<String?> getDevicePublicKey() =>
      read(key: StorageKeys.devicePublicKey);
  Future<void> setDevicePublicKey(String value) =>
      write(key: StorageKeys.devicePublicKey, value: value);

  Future<String?> getDeviceId() => read(key: StorageKeys.deviceId);
  Future<void> setDeviceId(String value) =>
      write(key: StorageKeys.deviceId, value: value);

  Future<String?> getPinHash() => read(key: StorageKeys.pinHash);
  Future<void> setPinHash(String value) =>
      write(key: StorageKeys.pinHash, value: value);
  Future<void> deletePinHash() => delete(key: StorageKeys.pinHash);

  Future<String?> getRecoveryKitHash() =>
      read(key: StorageKeys.recoveryKitHash);

  Future<void> setRecoveryKitHash(String value) =>
      write(key: StorageKeys.recoveryKitHash, value: value);
}
