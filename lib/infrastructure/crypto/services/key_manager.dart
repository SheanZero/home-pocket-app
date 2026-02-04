import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/device_key_pair.dart';
import '../repositories/key_repository.dart';
import '../repositories/key_repository_impl.dart';

part 'key_manager.g.dart';

/// Application service for key management
///
/// This is a thin wrapper around [KeyRepository] that provides
/// a backward-compatible interface. All key operations are delegated
/// to the repository layer, following Clean Architecture principles.
class KeyManager {
  final KeyRepository _repository;

  KeyManager({required KeyRepository repository})
      : _repository = repository;

  /// Generate device master key pair (called on first launch)
  Future<DeviceKeyPair> generateDeviceKeyPair() async {
    return await _repository.generateKeyPair();
  }

  /// Get current device's public key
  Future<String?> getPublicKey() async {
    return await _repository.getPublicKey();
  }

  /// Get current device ID
  Future<String?> getDeviceId() async {
    return await _repository.getDeviceId();
  }

  /// Check if key pair has been generated
  Future<bool> hasKeyPair() async {
    return await _repository.hasKeyPair();
  }

  /// Sign data (used for hash chain)
  Future<Signature> signData(List<int> data) async {
    return await _repository.signData(data);
  }

  /// Verify signature
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  }) async {
    return await _repository.verifySignature(
      data: data,
      signature: signature,
      publicKeyBase64: publicKeyBase64,
    );
  }

  /// Recover key pair from seed
  Future<DeviceKeyPair> recoverFromSeed(List<int> seed) async {
    return await _repository.recoverFromSeed(seed);
  }

  /// Clear all keys (destructive operation)
  Future<void> clearKeys() async {
    return await _repository.clearKeys();
  }
}

// Providers
@riverpod
KeyRepository keyRepository(KeyRepositoryRef ref) {
  return KeyRepositoryImpl(
    secureStorage: const FlutterSecureStorage(),
  );
}

@riverpod
KeyManager keyManager(KeyManagerRef ref) {
  final repository = ref.watch(keyRepositoryProvider);
  return KeyManager(repository: repository);
}

@riverpod
Future<bool> hasKeyPair(HasKeyPairRef ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  return await keyManager.hasKeyPair();
}
