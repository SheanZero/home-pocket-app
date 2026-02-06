import 'package:cryptography/cryptography.dart';
import '../models/device_key_pair.dart';
import '../repositories/key_repository.dart';

/// High-level key management service.
///
/// Delegates to [KeyRepository] for storage operations.
/// This is the primary API for key operations throughout the app.
class KeyManager {
  KeyManager({required KeyRepository repository}) : _repository = repository;

  final KeyRepository _repository;

  Future<DeviceKeyPair> generateDeviceKeyPair() =>
      _repository.generateKeyPair();

  Future<String?> getPublicKey() => _repository.getPublicKey();

  Future<String?> getDeviceId() => _repository.getDeviceId();

  Future<bool> hasKeyPair() => _repository.hasKeyPair();

  Future<Signature> signData(List<int> data) => _repository.signData(data);

  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  }) => _repository.verifySignature(
    data: data,
    signature: signature,
    publicKeyBase64: publicKeyBase64,
  );

  Future<DeviceKeyPair> recoverFromSeed(List<int> seed) =>
      _repository.recoverFromSeed(seed);

  Future<void> clearKeys() => _repository.clearKeys();
}
