/// Domain repository interface for field-level encryption
///
/// Provides secure encryption/decryption of sensitive fields using
/// ChaCha20-Poly1305 AEAD (Authenticated Encryption with Associated Data).
///
/// Key features:
/// - 256-bit key derived via HKDF from device master key
/// - 96-bit random nonce per encryption operation
/// - 128-bit MAC for authentication
/// - Deterministic key derivation for consistent encryption across app restarts
///
/// Use this for encrypting:
/// - Transaction amounts
/// - Transaction notes/descriptions
/// - Merchant names
/// - Any other sensitive text fields
abstract class EncryptionRepository {
  /// Encrypt a plaintext string
  ///
  /// Encrypts the input using ChaCha20-Poly1305 AEAD.
  /// Returns Base64-encoded ciphertext containing:
  /// - 12-byte nonce (96 bits)
  /// - Encrypted data
  /// - 16-byte MAC (128 bits)
  ///
  /// [plaintext] - Text to encrypt
  ///
  /// Returns Base64-encoded ciphertext.
  /// Throws [StateError] if device key is not initialized.
  Future<String> encryptField(String plaintext);

  /// Decrypt a ciphertext string
  ///
  /// Decrypts data previously encrypted by [encryptField].
  /// Automatically verifies MAC to detect tampering.
  ///
  /// [ciphertext] - Base64-encoded ciphertext from [encryptField]
  ///
  /// Returns decrypted plaintext.
  /// Throws [FormatException] if ciphertext is malformed.
  /// Throws [MacValidationException] if MAC verification fails (tampered data).
  /// Throws [StateError] if device key is not initialized.
  Future<String> decryptField(String ciphertext);

  /// Encrypt a numeric amount (double)
  ///
  /// Convenience method for encrypting transaction amounts.
  /// Converts the amount to string before encryption.
  ///
  /// [amount] - Numeric amount to encrypt
  ///
  /// Returns Base64-encoded ciphertext.
  Future<String> encryptAmount(double amount);

  /// Decrypt and parse an amount back to double
  ///
  /// Convenience method for decrypting transaction amounts.
  /// Decrypts the ciphertext and parses back to double.
  ///
  /// [encryptedAmount] - Base64-encoded encrypted amount
  ///
  /// Returns decrypted numeric amount.
  /// Throws [FormatException] if decrypted string is not a valid number.
  Future<double> decryptAmount(String encryptedAmount);

  /// Clear any cached encryption keys from memory
  ///
  /// Call this when:
  /// - User logs out
  /// - App goes to background (optional, for extra security)
  /// - Device lock is activated
  ///
  /// Keys will be re-derived on next encryption/decryption operation.
  Future<void> clearCache();
}

/// Exception thrown when MAC validation fails
///
/// This indicates that the encrypted data has been tampered with
/// or corrupted. The data should not be trusted.
class MacValidationException implements Exception {
  final String message;

  MacValidationException(this.message);

  @override
  String toString() => 'MacValidationException: $message';
}
