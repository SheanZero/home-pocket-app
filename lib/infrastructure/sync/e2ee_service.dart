import 'dart:convert';
import 'dart:math';

import 'package:pinenacl/tweetnacl.dart';
import 'package:pinenacl/x25519.dart';

import '../crypto/services/key_manager.dart';

/// End-to-End Encryption service using NaCl box (X25519-XSalsa20-Poly1305).
///
/// Handles:
/// 1. Ed25519 -> X25519 key conversion
/// 2. X25519 Diffie-Hellman shared secret
/// 3. XSalsa20-Poly1305 encrypt/decrypt (NaCl box)
/// 4. Output format: base64(nonce_24bytes + ciphertext)
class E2EEService {
  E2EEService({required KeyManager keyManager}) : _keyManager = keyManager;

  final KeyManager _keyManager;

  String generateGroupKey() {
    final random = Random.secure();
    final key = Uint8List(32);
    for (var index = 0; index < key.length; index++) {
      key[index] = random.nextInt(256);
    }
    return base64Encode(key);
  }

  /// Encrypt plaintext for the paired partner.
  ///
  /// Returns base64(nonce_24bytes + ciphertext).
  Future<String> encrypt({
    required String plaintext,
    required String recipientPublicKey,
  }) async {
    final myPrivateKeyBase64 = await _keyManager.getPrivateKey();
    if (myPrivateKeyBase64 == null) {
      throw StateError('Device private key not found');
    }

    final myEd25519Seed = base64Decode(myPrivateKeyBase64);
    final recipientEd25519Pub = base64Decode(recipientPublicKey);

    // Convert Ed25519 keys to X25519
    final myX25519Sk = _ed25519SeedToX25519Private(myEd25519Seed);
    final recipientX25519Pk = _ed25519PublicToX25519Public(recipientEd25519Pub);

    // Create NaCl Box and encrypt
    final box = Box(
      myPrivateKey: PrivateKey(myX25519Sk),
      theirPublicKey: PublicKey(recipientX25519Pk),
    );

    final messageBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encrypted = box.encrypt(messageBytes);

    // Output: base64(nonce_24bytes + ciphertext)
    return base64Encode(encrypted.asTypedList);
  }

  /// Decrypt ciphertext from the paired partner.
  ///
  /// Input format: base64(nonce_24bytes + ciphertext).
  Future<String> decrypt({
    required String ciphertext,
    required String senderPublicKey,
  }) async {
    final myPrivateKeyBase64 = await _keyManager.getPrivateKey();
    if (myPrivateKeyBase64 == null) {
      throw StateError('Device private key not found');
    }

    final raw = base64Decode(ciphertext);
    if (raw.length <= EncryptedMessage.nonceLength) {
      throw ArgumentError('Ciphertext too short');
    }

    final myEd25519Seed = base64Decode(myPrivateKeyBase64);
    final senderEd25519Pub = base64Decode(senderPublicKey);

    // Convert Ed25519 keys to X25519
    final myX25519Sk = _ed25519SeedToX25519Private(myEd25519Seed);
    final senderX25519Pk = _ed25519PublicToX25519Public(senderEd25519Pub);

    // Create NaCl Box and decrypt
    final box = Box(
      myPrivateKey: PrivateKey(myX25519Sk),
      theirPublicKey: PublicKey(senderX25519Pk),
    );

    final encryptedMessage = EncryptedMessage.fromList(Uint8List.fromList(raw));
    final plainBytes = box.decrypt(encryptedMessage);
    return utf8.decode(plainBytes);
  }

  String encryptForGroup({
    required String plaintext,
    required String groupKeyBase64,
  }) {
    final groupKey = base64Decode(groupKeyBase64);
    final box = SecretBox(Uint8List.fromList(groupKey));
    final encrypted = box.encrypt(Uint8List.fromList(utf8.encode(plaintext)));
    final combined =
        Uint8List(encrypted.nonce.length + encrypted.cipherText.length)
          ..setAll(0, encrypted.nonce)
          ..setAll(encrypted.nonce.length, encrypted.cipherText);

    return jsonEncode({'v': 2, 't': 'D', 'p': base64Encode(combined)});
  }

  String decryptFromGroup({
    required String encryptedPayload,
    required String groupKeyBase64,
  }) {
    final envelope = jsonDecode(encryptedPayload) as Map<String, dynamic>;
    final raw = base64Decode(envelope['p'] as String);
    final nonce = Uint8List.fromList(raw.sublist(0, 24));
    final cipherText = Uint8List.fromList(raw.sublist(24));
    final groupKey = base64Decode(groupKeyBase64);
    final box = SecretBox(Uint8List.fromList(groupKey));
    final decrypted = box.decrypt(ByteList(cipherText), nonce: nonce);
    return utf8.decode(decrypted);
  }

  Future<String> encryptGroupKeyForMember({
    required String groupKeyBase64,
    required String memberDeviceId,
    required String memberPublicKey,
  }) async {
    final encrypted = await encrypt(
      plaintext: groupKeyBase64,
      recipientPublicKey: memberPublicKey,
    );
    return jsonEncode({
      'v': 2,
      't': 'K',
      'toDeviceId': memberDeviceId,
      'p': encrypted,
    });
  }

  Future<String> decryptGroupKeyFromOwner({
    required String encryptedPayload,
    required String ownerPublicKey,
  }) async {
    final envelope = jsonDecode(encryptedPayload) as Map<String, dynamic>;
    return decrypt(
      ciphertext: envelope['p'] as String,
      senderPublicKey: ownerPublicKey,
    );
  }

  static String detectPayloadType(String payload) {
    if (payload.startsWith('{')) {
      try {
        final envelope = jsonDecode(payload) as Map<String, dynamic>;
        if (envelope['v'] == 2) {
          return envelope['t'] == 'K' ? 'v2_key' : 'v2_data';
        }
      } catch (_) {
        return 'v1';
      }
    }
    return 'v1';
  }

  /// Convert Ed25519 seed (32 bytes) to X25519 private key (32 bytes).
  ///
  /// Uses TweetNaClExt which internally:
  /// Ed25519 seed -> SHA-512 -> take first 32 bytes -> clamp -> X25519 private key
  Uint8List _ed25519SeedToX25519Private(List<int> ed25519Seed) {
    final x25519Sk = Uint8List(32);
    TweetNaClExt.crypto_sign_ed25519_sk_to_x25519_sk(
      x25519Sk,
      Uint8List.fromList(ed25519Seed),
    );
    return x25519Sk;
  }

  /// Convert Ed25519 public key (32 bytes) to X25519 public key (32 bytes).
  ///
  /// Uses the birational map: Xmont = (1 + Yed)/(1 - Yed) mod p
  Uint8List _ed25519PublicToX25519Public(List<int> ed25519Public) {
    final x25519Pk = Uint8List(32);
    TweetNaClExt.crypto_sign_ed25519_pk_to_x25519_pk(
      x25519Pk,
      Uint8List.fromList(ed25519Public),
    );
    return x25519Pk;
  }
}
