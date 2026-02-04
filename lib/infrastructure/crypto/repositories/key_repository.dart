import 'package:cryptography/cryptography.dart';
import '../models/device_key_pair.dart';

/// Domain repository interface for cryptographic key management
///
/// This interface defines the contract for secure key storage and operations.
/// Implementations must handle secure storage using platform-specific mechanisms:
/// - iOS: Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
/// - Android: EncryptedSharedPreferences backed by Android Keystore
///
/// All private keys must remain in secure storage and never be exposed.
abstract class KeyRepository {
  /// Generate a new Ed25519 key pair for this device
  ///
  /// This should only be called once during initial device setup.
  /// The private key is stored securely and never exposed.
  /// The public key and device ID are derived and returned.
  ///
  /// Returns [DeviceKeyPair] containing public key and device ID.
  /// Throws [StateError] if a key pair already exists.
  Future<DeviceKeyPair> generateKeyPair();

  /// Recover key pair from a BIP39 recovery seed
  ///
  /// Used to restore keys from a 24-word mnemonic backup.
  /// The seed must be exactly 32 bytes (256 bits).
  ///
  /// [seed] - 32-byte seed derived from BIP39 mnemonic
  ///
  /// Returns [DeviceKeyPair] with recovered keys.
  /// Throws [InvalidSeedException] if seed is invalid.
  Future<DeviceKeyPair> recoverFromSeed(List<int> seed);

  /// Get the device's public key (Base64 encoded)
  ///
  /// Returns the Ed25519 public key in Base64 format, or null if not initialized.
  Future<String?> getPublicKey();

  /// Get the device ID (derived from public key hash)
  ///
  /// The device ID is the first 16 characters of the Base64URL-encoded
  /// SHA-256 hash of the public key.
  ///
  /// Returns the device ID, or null if not initialized.
  Future<String?> getDeviceId();

  /// Check if a key pair has been generated for this device
  ///
  /// Returns true if keys exist in secure storage, false otherwise.
  Future<bool> hasKeyPair();

  /// Sign data using the device's private key
  ///
  /// Uses Ed25519 signature algorithm.
  /// The private key is accessed from secure storage but never exposed.
  ///
  /// [data] - Raw bytes to sign
  ///
  /// Returns [Signature] containing the signature bytes.
  /// Throws [KeyNotFoundException] if private key is not available.
  Future<Signature> signData(List<int> data);

  /// Verify a signature using a public key
  ///
  /// [data] - Original data that was signed
  /// [signature] - Signature to verify
  /// [publicKeyBase64] - Base64-encoded Ed25519 public key
  ///
  /// Returns true if signature is valid, false otherwise.
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  });

  /// Clear all keys from secure storage
  ///
  /// ⚠️ WARNING: This is a destructive operation.
  /// All keys will be permanently deleted unless backed up via recovery kit.
  ///
  /// Only call this when:
  /// - Resetting the device
  /// - Switching to a different account
  /// - User explicitly requests data deletion
  Future<void> clearKeys();
}

/// Exception thrown when key operations fail due to missing keys
class KeyNotFoundException implements Exception {
  final String message;

  KeyNotFoundException(this.message);

  @override
  String toString() => 'KeyNotFoundException: $message';
}

/// Exception thrown when recovery seed is invalid
class InvalidSeedException implements Exception {
  final String message;

  InvalidSeedException(this.message);

  @override
  String toString() => 'InvalidSeedException: $message';
}
