import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'encryption_repository.dart';
import 'key_repository.dart';

/// Implementation of [EncryptionRepository] using ChaCha20-Poly1305 AEAD
///
/// Uses HKDF (HMAC-based Key Derivation Function) to derive encryption keys
/// from the device master key. Keys are cached in memory for performance.
class EncryptionRepositoryImpl implements EncryptionRepository {
  final KeyRepository _keyRepository;
  final _chacha20 = Chacha20.poly1305Aead();
  final _random = Random.secure();

  // Key derivation configuration
  static const String _keyDerivationVersion = 'v1';
  static const String _keyDerivationInfo = 'homepocket_field_encryption_$_keyDerivationVersion';

  // Cached encryption key (cleared on logout/background)
  SecretKey? _cachedEncryptionKey;

  EncryptionRepositoryImpl({required KeyRepository keyRepository})
      : _keyRepository = keyRepository;

  @override
  Future<String> encryptField(String plaintext) async {
    // 1. Get or derive encryption key
    final encryptionKey = await _getOrDeriveEncryptionKey();

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

  @override
  Future<String> decryptField(String ciphertext) async {
    try {
      // 1. Decode base64
      final combined = base64Decode(ciphertext);

      if (combined.length < 28) {
        // Minimum: 12-byte nonce + 16-byte MAC
        throw FormatException('Invalid ciphertext: too short (${combined.length} bytes)');
      }

      // 2. Extract nonce (first 12 bytes)
      final nonce = combined.sublist(0, 12);

      // 3. Extract MAC (last 16 bytes)
      final mac = Mac(combined.sublist(combined.length - 16));

      // 4. Extract ciphertext (middle part)
      final encryptedData = combined.sublist(12, combined.length - 16);

      // 5. Get decryption key
      final encryptionKey = await _getOrDeriveEncryptionKey();

      // 6. Create SecretBox for decryption
      final secretBox = SecretBox(
        encryptedData,
        nonce: nonce,
        mac: mac,
      );

      // 7. Decrypt with ChaCha20-Poly1305 (automatically verifies MAC)
      final plaintextBytes = await _chacha20.decrypt(
        secretBox,
        secretKey: encryptionKey,
      );

      // 8. Convert bytes back to string
      return utf8.decode(plaintextBytes);
    } on FormatException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw MacValidationException(
        'MAC validation failed - data has been tampered with or corrupted',
      );
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  @override
  Future<String> encryptAmount(double amount) async {
    return await encryptField(amount.toString());
  }

  @override
  Future<double> decryptAmount(String encryptedAmount) async {
    final decrypted = await decryptField(encryptedAmount);
    return double.parse(decrypted);
  }

  @override
  Future<void> clearCache() async {
    _cachedEncryptionKey = null;
  }

  /// Get cached encryption key or derive a new one
  Future<SecretKey> _getOrDeriveEncryptionKey() async {
    if (_cachedEncryptionKey != null) {
      return _cachedEncryptionKey!;
    }

    _cachedEncryptionKey = await _deriveEncryptionKey();
    return _cachedEncryptionKey!;
  }

  /// Derive 256-bit encryption key from device public key using HKDF
  ///
  /// Uses HKDF (HMAC-based Key Derivation Function) with SHA-256.
  /// The derived key is deterministic (same input = same output) but
  /// cryptographically secure.
  ///
  /// Key derivation:
  /// - Input: Device public key (32 bytes)
  /// - Algorithm: HKDF-SHA256
  /// - Info: Context-specific string for domain separation
  /// - Output: 256-bit encryption key
  Future<SecretKey> _deriveEncryptionKey() async {
    final publicKeyBase64 = await _keyRepository.getPublicKey();

    if (publicKeyBase64 == null) {
      throw StateError('Device key not initialized');
    }

    // Configure HKDF with SHA-256
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32, // 256 bits
    );

    final publicKeyBytes = base64Decode(publicKeyBase64);

    // Derive key with context-specific info string
    // This ensures keys for different purposes are different
    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(publicKeyBytes),
      info: utf8.encode(_keyDerivationInfo),
      nonce: const [], // Empty nonce for deterministic derivation
    );

    return derivedKey;
  }

  /// Generate random 12-byte nonce for ChaCha20
  ///
  /// ChaCha20 requires a 96-bit (12-byte) nonce.
  /// Using a cryptographically secure random generator.
  List<int> _generateNonce() {
    return List<int>.generate(12, (_) => _random.nextInt(256));
  }
}
