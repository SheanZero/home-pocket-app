import 'package:cryptography/cryptography.dart';
import '../models/device_key_pair.dart';

/// Key not found in secure storage.
class KeyNotFoundException implements Exception {
  KeyNotFoundException(this.message);
  final String message;

  @override
  String toString() => 'KeyNotFoundException: $message';
}

/// Invalid seed for key recovery.
class InvalidSeedException implements Exception {
  InvalidSeedException(this.message);
  final String message;

  @override
  String toString() => 'InvalidSeedException: $message';
}

/// Abstract interface for device key pair management.
///
/// Implementations store keys in platform secure storage
/// (iOS Keychain / Android Keystore).
abstract class KeyRepository {
  Future<DeviceKeyPair> generateKeyPair();
  Future<DeviceKeyPair> recoverFromSeed(List<int> seed);
  Future<String?> getPublicKey();
  Future<String?> getDeviceId();
  Future<bool> hasKeyPair();
  Future<Signature> signData(List<int> data);
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  });
  Future<void> clearKeys();
}
