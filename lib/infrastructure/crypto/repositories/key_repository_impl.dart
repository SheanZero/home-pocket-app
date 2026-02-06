import 'dart:convert';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/device_key_pair.dart';
import 'key_repository.dart';

class KeyRepositoryImpl implements KeyRepository {
  KeyRepositoryImpl({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;
  final _ed25519 = Ed25519();

  static const _privateKeyKey = 'device_private_key';
  static const _publicKeyKey = 'device_public_key';
  static const _deviceIdKey = 'device_id';

  @override
  Future<bool> hasKeyPair() async {
    final key = await _secureStorage.read(key: _privateKeyKey);
    return key != null;
  }

  @override
  Future<DeviceKeyPair> generateKeyPair() async {
    if (await hasKeyPair()) {
      throw StateError('Key pair already exists. Call clearKeys() first.');
    }

    final keyPair = await _ed25519.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    final deviceId = _generateDeviceId(publicKey.bytes);

    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKeyBytes),
    );
    await _secureStorage.write(key: _publicKeyKey, value: publicKeyBase64);
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);

    return DeviceKeyPair(
      publicKey: publicKeyBase64,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<DeviceKeyPair> recoverFromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw InvalidSeedException('Seed must be 32 bytes, got ${seed.length}');
    }

    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    final deviceId = _generateDeviceId(publicKey.bytes);

    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKeyBytes),
    );
    await _secureStorage.write(key: _publicKeyKey, value: publicKeyBase64);
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);

    return DeviceKeyPair(
      publicKey: publicKeyBase64,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String?> getPublicKey() async {
    return _secureStorage.read(key: _publicKeyKey);
  }

  @override
  Future<String?> getDeviceId() async {
    return _secureStorage.read(key: _deviceIdKey);
  }

  @override
  Future<Signature> signData(List<int> data) async {
    final privateKeyStr = await _secureStorage.read(key: _privateKeyKey);
    if (privateKeyStr == null) {
      throw KeyNotFoundException('Private key not found in secure storage');
    }

    final privateKeyBytes = base64Decode(privateKeyStr);
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeyBytes);
    final signature = await _ed25519.sign(data, keyPair: keyPair);
    return signature;
  }

  @override
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  }) async {
    final publicKeyBytes = base64Decode(publicKeyBase64);
    final publicKey = SimplePublicKey(
      publicKeyBytes,
      type: KeyPairType.ed25519,
    );

    return _ed25519.verify(
      data,
      signature: Signature(signature.bytes, publicKey: publicKey),
    );
  }

  @override
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _privateKeyKey);
    await _secureStorage.delete(key: _publicKeyKey);
    await _secureStorage.delete(key: _deviceIdKey);
  }

  /// Base64URL(SHA-256(publicKey))[0:16]
  String _generateDeviceId(List<int> publicKeyBytes) {
    final digest = hash_lib.sha256.convert(publicKeyBytes);
    return base64UrlEncode(digest.bytes).substring(0, 16);
  }
}
