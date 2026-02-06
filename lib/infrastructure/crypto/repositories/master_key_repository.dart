import 'package:cryptography/cryptography.dart';

/// Master key not initialized.
class MasterKeyNotInitializedException implements Exception {
  MasterKeyNotInitializedException([
    this.message = 'Master key not initialized',
  ]);
  final String message;

  @override
  String toString() => 'MasterKeyNotInitializedException: $message';
}

/// Key derivation failed.
class KeyDerivationException implements Exception {
  KeyDerivationException(this.message);
  final String message;

  @override
  String toString() => 'KeyDerivationException: $message';
}

/// Abstract interface for master key management.
///
/// The master key is a 256-bit cryptographically secure random key
/// stored in platform secure storage (iOS Keychain / Android Keystore).
/// All derived keys (database, field, file, sync) are derived from this master key.
abstract class MasterKeyRepository {
  /// Initialize master key (first app launch only).
  /// Throws StateError if master key already exists.
  Future<void> initializeMasterKey();

  /// Check if master key exists.
  Future<bool> hasMasterKey();

  /// Get raw master key bytes (256-bit).
  /// Throws MasterKeyNotInitializedException if not initialized.
  Future<List<int>> getMasterKey();

  /// Derive a purpose-specific key using HKDF-SHA256.
  /// [purpose]: e.g., 'database_encryption', 'field_encryption', 'file_encryption'
  Future<SecretKey> deriveKey(String purpose);

  /// Clear master key (DANGEROUS - all data becomes unreadable).
  Future<void> clearMasterKey();
}
