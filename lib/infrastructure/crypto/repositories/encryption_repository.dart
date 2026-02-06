/// MAC validation failed during decryption (data tampered or wrong key).
class MacValidationException implements Exception {
  MacValidationException(this.message);
  final String message;

  @override
  String toString() => 'MacValidationException: $message';
}

/// Abstract interface for field-level encryption operations.
///
/// Uses ChaCha20-Poly1305 AEAD with HKDF-derived keys from MasterKeyRepository.
abstract class EncryptionRepository {
  Future<String> encryptField(String plaintext);
  Future<String> decryptField(String ciphertext);
  Future<String> encryptAmount(double amount);
  Future<double> decryptAmount(String encryptedAmount);
  Future<void> clearCache();
}
