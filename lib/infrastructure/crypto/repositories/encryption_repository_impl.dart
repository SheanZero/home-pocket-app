import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'encryption_repository.dart';
import 'master_key_repository.dart';

/// ChaCha20-Poly1305 AEAD field encryption.
///
/// Cipher format: Base64(nonce[12B] + encrypted_data + mac[16B])
/// Key derived via HKDF-SHA256 from master key using [MasterKeyRepository].
class EncryptionRepositoryImpl implements EncryptionRepository {
  EncryptionRepositoryImpl({required MasterKeyRepository masterKeyRepository})
    : _masterKeyRepository = masterKeyRepository;

  final MasterKeyRepository _masterKeyRepository;
  final _algorithm = Chacha20.poly1305Aead();
  final _random = Random.secure();

  /// Cached derived encryption key (cleared on logout).
  SecretKey? _cachedKey;

  @override
  Future<String> encryptField(String plaintext) async {
    final key = await _getOrDeriveKey();
    final nonce = _generateNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    final combined = <int>[
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    return base64Encode(combined);
  }

  @override
  Future<String> decryptField(String ciphertext) async {
    final data = base64Decode(ciphertext);

    // Minimum: 12 (nonce) + 0 (empty plaintext) + 16 (MAC) = 28 bytes
    if (data.length < 28) {
      throw MacValidationException(
        'Ciphertext too short: ${data.length} bytes (minimum 28)',
      );
    }

    final nonce = data.sublist(0, 12);
    final macBytes = data.sublist(data.length - 16);
    final cipherData = data.sublist(12, data.length - 16);

    final key = await _getOrDeriveKey();

    try {
      final secretBox = SecretBox(cipherData, nonce: nonce, mac: Mac(macBytes));

      final plaintext = await _algorithm.decrypt(secretBox, secretKey: key);
      return utf8.decode(plaintext);
    } catch (e) {
      throw MacValidationException('Decryption failed: $e');
    }
  }

  @override
  Future<String> encryptAmount(double amount) async {
    return encryptField(amount.toString());
  }

  @override
  Future<double> decryptAmount(String encryptedAmount) async {
    final decrypted = await decryptField(encryptedAmount);
    return double.parse(decrypted);
  }

  @override
  Future<void> clearCache() async {
    _cachedKey = null;
  }

  Future<SecretKey> _getOrDeriveKey() async {
    if (_cachedKey != null) return _cachedKey!;
    _cachedKey = await _masterKeyRepository.deriveKey('field_encryption');
    return _cachedKey!;
  }

  List<int> _generateNonce() {
    return List<int>.generate(12, (_) => _random.nextInt(256));
  }
}
