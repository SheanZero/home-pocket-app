import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/device_key_pair.dart';

part 'key_manager.g.dart';

class KeyManager {
  final FlutterSecureStorage _secureStorage;
  final Ed25519 _ed25519 = Ed25519();

  KeyManager({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  /// 生成设备主密钥对（首次启动时调用）
  Future<DeviceKeyPair> generateDeviceKeyPair() async {
    // 1. 生成Ed25519密钥对
    final keyPair = await _ed25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // 2. 将私钥存储到安全存储（iOS Keychain / Android Keystore）
    await _secureStorage.write(
      key: 'device_private_key',
      value: base64Encode(privateKeyBytes),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );

    // 3. 公钥可以明文存储
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    await _secureStorage.write(
      key: 'device_public_key',
      value: publicKeyBase64,
    );

    // 4. 生成设备ID（公钥的哈希）
    final deviceId = _generateDeviceId(publicKey.bytes);
    await _secureStorage.write(key: 'device_id', value: deviceId);

    return DeviceKeyPair(
      publicKey: publicKeyBase64,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  /// 生成设备ID（公钥哈希的前16字符）
  String _generateDeviceId(List<int> publicKeyBytes) {
    final hash = sha256.convert(publicKeyBytes);
    return base64UrlEncode(hash.bytes).substring(0, 16);
  }

  /// 获取当前设备的公钥
  Future<String?> getPublicKey() async {
    return await _secureStorage.read(key: 'device_public_key');
  }

  /// 获取当前设备ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: 'device_id');
  }

  /// 检查是否已生成密钥对
  Future<bool> hasKeyPair() async {
    final privateKey = await _secureStorage.read(key: 'device_private_key');
    return privateKey != null;
  }

  /// 签名数据（用于哈希链）
  Future<Signature> signData(List<int> data) async {
    final privateKeyBase64 = await _secureStorage.read(key: 'device_private_key');
    if (privateKeyBase64 == null) {
      throw KeyNotFoundException('设备私钥未找到');
    }

    final privateKeyBytes = base64Decode(privateKeyBase64);
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeyBytes);

    return await _ed25519.sign(data, keyPair: keyPair);
  }

  /// 验证签名
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  }) async {
    final publicKeyBytes = base64Decode(publicKeyBase64);
    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);

    return await _ed25519.verify(data, signature: signature);
  }
}

// 异常类
class KeyNotFoundException implements Exception {
  final String message;
  KeyNotFoundException(this.message);

  @override
  String toString() => 'KeyNotFoundException: $message';
}

class InvalidMnemonicException implements Exception {
  final String message;
  InvalidMnemonicException(this.message);

  @override
  String toString() => 'InvalidMnemonicException: $message';
}

// Provider
@riverpod
KeyManager keyManager(KeyManagerRef ref) {
  return KeyManager(
    secureStorage: const FlutterSecureStorage(),
  );
}

@riverpod
Future<bool> hasKeyPair(HasKeyPairRef ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  return await keyManager.hasKeyPair();
}
