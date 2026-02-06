import '../repositories/encryption_repository.dart';

/// High-level field encryption API.
///
/// Encrypts sensitive transaction fields (notes, merchant names, amounts).
/// Delegates to [EncryptionRepository] for crypto operations.
class FieldEncryptionService {
  FieldEncryptionService({required EncryptionRepository repository})
    : _repository = repository;

  final EncryptionRepository _repository;

  Future<String> encryptField(String plaintext) =>
      _repository.encryptField(plaintext);

  Future<String> decryptField(String ciphertext) =>
      _repository.decryptField(ciphertext);

  Future<String> encryptAmount(double amount) =>
      _repository.encryptAmount(amount);

  Future<double> decryptAmount(String encrypted) =>
      _repository.decryptAmount(encrypted);

  Future<void> clearCache() => _repository.clearCache();
}
