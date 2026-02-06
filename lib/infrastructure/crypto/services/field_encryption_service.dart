import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/encryption_repository.dart';
import '../repositories/encryption_repository_impl.dart';
import 'key_manager.dart';

part 'field_encryption_service.g.dart';

/// Application service for field-level encryption
///
/// This is a thin wrapper around [EncryptionRepository] that provides
/// a backward-compatible interface. All encryption operations are delegated
/// to the repository layer, following Clean Architecture principles.
class FieldEncryptionService {
  FieldEncryptionService({required EncryptionRepository repository})
      : _repository = repository;
  final EncryptionRepository _repository;

  /// Encrypt a plaintext string
  Future<String> encryptField(String plaintext) async {
    return _repository.encryptField(plaintext);
  }

  /// Decrypt a ciphertext string
  Future<String> decryptField(String ciphertext) async {
    return _repository.decryptField(ciphertext);
  }

  /// Encrypt an amount (double) as string
  Future<String> encryptAmount(double amount) async {
    return _repository.encryptAmount(amount);
  }

  /// Decrypt and parse amount back to double
  Future<double> decryptAmount(String encryptedAmount) async {
    return _repository.decryptAmount(encryptedAmount);
  }

  /// Clear any cached encryption keys from memory
  Future<void> clearCache() async {
    return _repository.clearCache();
  }
}

// Providers
@riverpod
EncryptionRepository encryptionRepository(EncryptionRepositoryRef ref) {
  final keyRepository = ref.watch(keyRepositoryProvider);
  return EncryptionRepositoryImpl(keyRepository: keyRepository);
}

@riverpod
FieldEncryptionService fieldEncryptionService(FieldEncryptionServiceRef ref) {
  final repository = ref.watch(encryptionRepositoryProvider);
  return FieldEncryptionService(repository: repository);
}
