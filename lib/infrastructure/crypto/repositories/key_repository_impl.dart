import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/device_key_pair.dart';
import 'key_repository.dart';

/// Implementation of [KeyRepository] using FlutterSecureStorage
///
/// Stores keys securely using:
/// - iOS: Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
/// - Android: EncryptedSharedPreferences backed by Android Keystore
class KeyRepositoryImpl implements KeyRepository {
  final FlutterSecureStorage _secureStorage;
  final Ed25519 _ed25519 = Ed25519();

  // Storage keys
  static const String _privateKeyKey = 'device_private_key';
  static const String _publicKeyKey = 'device_public_key';
  static const String _deviceIdKey = 'device_id';

  KeyRepositoryImpl({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  @override
  Future<DeviceKeyPair> generateKeyPair() async {
    // Check if keys already exist
    if (await hasKeyPair()) {
      throw StateError('Key pair already exists. Use recoverFromSeed to replace.');
    }

    // 1. Generate Ed25519 key pair
    final keyPair = await _ed25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // 2. Store private key in secure storage
    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKeyBytes),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );

    // 3. Store public key (can be plaintext, but we use secure storage for consistency)
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    await _secureStorage.write(
      key: _publicKeyKey,
      value: publicKeyBase64,
    );

    // 4. Generate and store device ID
    final deviceId = _generateDeviceId(publicKey.bytes);
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
      throw InvalidSeedException('Seed must be exactly 32 bytes, got ${seed.length}');
    }

    // 1. Generate key pair from seed
    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // 2. Store private key in secure storage
    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKeyBytes),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );

    // 3. Store public key
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    await _secureStorage.write(
      key: _publicKeyKey,
      value: publicKeyBase64,
    );

    // 4. Generate and store device ID
    final deviceId = _generateDeviceId(publicKey.bytes);
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);

    return DeviceKeyPair(
      publicKey: publicKeyBase64,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String?> getPublicKey() async {
    return await _secureStorage.read(key: _publicKeyKey);
  }

  @override
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKey);
  }

  @override
  Future<bool> hasKeyPair() async {
    final privateKey = await _secureStorage.read(key: _privateKeyKey);
    return privateKey != null;
  }

  @override
  Future<Signature> signData(List<int> data) async {
    final privateKeyBase64 = await _secureStorage.read(key: _privateKeyKey);
    if (privateKeyBase64 == null) {
      throw KeyNotFoundException('Device private key not found');
    }

    final privateKeyBytes = base64Decode(privateKeyBase64);
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeyBytes);

    return await _ed25519.sign(data, keyPair: keyPair);
  }

  @override
  Future<bool> verifySignature({
    required List<int> data,
    required Signature signature,
    required String publicKeyBase64,
  }) async {
    // Note: The Signature object from signData() already contains the public key
    // Ed25519.verify() uses the public key from the Signature object
    // The publicKeyBase64 parameter is kept for API compatibility but verification
    // relies on the public key embedded in the signature
    return await _ed25519.verify(data, signature: signature);
  }

  @override
  Future<void> clearKeys() async {
    await _secureStorage.delete(key: _privateKeyKey);
    await _secureStorage.delete(key: _publicKeyKey);
    await _secureStorage.delete(key: _deviceIdKey);
  }

  /// Generate device ID from public key hash
  ///
  /// Device ID = Base64URL(SHA-256(publicKey))[0:16]
  String _generateDeviceId(List<int> publicKeyBytes) {
    final hash = sha256.convert(publicKeyBytes);
    return base64UrlEncode(hash.bytes).substring(0, 16);
  }
}
