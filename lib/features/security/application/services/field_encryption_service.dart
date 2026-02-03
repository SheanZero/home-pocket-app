import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'key_manager.dart';

part 'field_encryption_service.g.dart';

/// Field-level encryption service using ChaCha20-Poly1305 AEAD
///
/// Provides secure encryption for sensitive fields like amounts, notes, and merchant names.
/// Uses ChaCha20-Poly1305 authenticated encryption with 256-bit keys.
class FieldEncryptionService {
  final KeyManager _keyManager;
  final _chacha20 = Chacha20.poly1305Aead();
  final _random = Random.secure();

  FieldEncryptionService({required KeyManager keyManager})
      : _keyManager = keyManager;

  /// Encrypt a plaintext string
  ///
  /// Returns base64-encoded ciphertext containing: nonce (12 bytes) + encrypted data + MAC (16 bytes)
  Future<String> encryptField(String plaintext) async {
    // 1. Get encryption key from device key
    final encryptionKey = await _deriveEncryptionKey();

    // 2. Generate random 12-byte nonce (96 bits for ChaCha20)
    final nonce = _generateNonce();

    // 3. Convert plaintext to bytes
    final plaintextBytes = utf8.encode(plaintext);

    // 4. Encrypt with ChaCha20-Poly1305
    final secretBox = await _chacha20.encrypt(
      plaintextBytes,
      secretKey: encryptionKey,
      nonce: nonce,
    );

    // 5. Combine nonce + ciphertext + MAC into single byte array
    final combined = <int>[
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    // 6. Return base64-encoded result
    return base64Encode(combined);
  }

  /// Decrypt a ciphertext string
  ///
  /// Expects base64-encoded input containing: nonce (12 bytes) + encrypted data + MAC (16 bytes)
  Future<String> decryptField(String ciphertext) async {
    try {
      // 1. Decode base64
      final combined = base64Decode(ciphertext);

      if (combined.length < 28) {
        // Minimum: 12-byte nonce + 16-byte MAC
        throw FormatException('Invalid ciphertext: too short');
      }

      // 2. Extract nonce (first 12 bytes)
      final nonce = combined.sublist(0, 12);

      // 3. Extract MAC (last 16 bytes)
      final mac = Mac(combined.sublist(combined.length - 16));

      // 4. Extract ciphertext (middle part)
      final encryptedData = combined.sublist(12, combined.length - 16);

      // 5. Get decryption key
      final encryptionKey = await _deriveEncryptionKey();

      // 6. Create SecretBox for decryption
      final secretBox = SecretBox(
        encryptedData,
        nonce: nonce,
        mac: mac,
      );

      // 7. Decrypt with ChaCha20-Poly1305
      final plaintextBytes = await _chacha20.decrypt(
        secretBox,
        secretKey: encryptionKey,
      );

      // 8. Convert bytes back to string
      return utf8.decode(plaintextBytes);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  /// Encrypt an amount (double) as string
  Future<String> encryptAmount(double amount) async {
    return await encryptField(amount.toString());
  }

  /// Decrypt and parse amount back to double
  Future<double> decryptAmount(String encryptedAmount) async {
    final decrypted = await decryptField(encryptedAmount);
    return double.parse(decrypted);
  }

  /// Derive 256-bit encryption key from device public key
  ///
  /// In production, this would use HKDF with the device's private key.
  /// For now, we derive from the public key hash for testing purposes.
  Future<SecretKey> _deriveEncryptionKey() async {
    final publicKeyBase64 = await _keyManager.getPublicKey();

    if (publicKeyBase64 == null) {
      throw StateError('Device key not initialized');
    }

    // Derive 32-byte key from public key
    // In production: use HKDF with proper key derivation
    final publicKeyBytes = base64Decode(publicKeyBase64);
    final keyBytes = Uint8List(32);

    // Simple derivation for testing (production would use HKDF)
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = publicKeyBytes[i % publicKeyBytes.length];
    }

    return SecretKey(keyBytes);
  }

  /// Generate random 12-byte nonce for ChaCha20
  List<int> _generateNonce() {
    return List<int>.generate(12, (_) => _random.nextInt(256));
  }
}

// Provider
@riverpod
FieldEncryptionService fieldEncryptionService(FieldEncryptionServiceRef ref) {
  final keyManager = ref.watch(keyManagerProvider);
  return FieldEncryptionService(keyManager: keyManager);
}
