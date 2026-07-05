import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/services/backup_crypto_service.dart';

/// Builds a legacy (pre-v2, headerless) backup blob:
/// salt(16) + nonce(12) + ciphertext + mac(16), PBKDF2-HMAC-SHA256 100k.
Future<Uint8List> _encryptLegacy(List<int> plaintext, String password) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );
  final random = Random.secure();
  final salt = List.generate(16, (_) => random.nextInt(256));
  final nonce = List.generate(12, (_) => random.nextInt(256));
  final secretKey = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
  final secretBox = await AesGcm.with256bits().encrypt(
    plaintext,
    secretKey: secretKey,
    nonce: nonce,
  );
  return Uint8List.fromList([
    ...salt,
    ...nonce,
    ...secretBox.cipherText,
    ...secretBox.mac.bytes,
  ]);
}

void main() {
  final service = BackupCryptoService();
  final plaintext = Uint8List.fromList(
    utf8.encode('{"backup":"payload","n":42}'),
  );
  const password = 'correct-horse-battery';

  group('v2 format (Argon2id + AES-256-GCM)', () {
    test('encrypt → decrypt round-trips', () async {
      final encrypted = await service.encrypt(plaintext, password);
      final decrypted = await service.decrypt(encrypted, password);
      expect(decrypted, equals(plaintext));
    });

    test('output carries the HPB magic and version 2 header', () async {
      final encrypted = await service.encrypt(plaintext, password);
      expect(encrypted.sublist(0, 3), equals(utf8.encode('HPB')));
      expect(encrypted[3], equals(2));
    });

    test(
      'two encryptions of the same payload differ (fresh salt/nonce)',
      () async {
        final a = await service.encrypt(plaintext, password);
        final b = await service.encrypt(plaintext, password);
        expect(a, isNot(equals(b)));
      },
    );

    test('wrong password throws BackupDecryptionException', () async {
      final encrypted = await service.encrypt(plaintext, password);
      expect(
        () => service.decrypt(encrypted, 'wrong-password'),
        throwsA(isA<BackupDecryptionException>()),
      );
    });

    test('tampered ciphertext throws BackupDecryptionException', () async {
      final encrypted = await service.encrypt(plaintext, password);
      // Flip a bit in the middle of the ciphertext (past the header).
      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 20] ^= 0xFF;
      expect(
        () => service.decrypt(tampered, password),
        throwsA(isA<BackupDecryptionException>()),
      );
    });

    test(
      'unknown version byte throws UnsupportedBackupFormatException',
      () async {
        final encrypted = await service.encrypt(plaintext, password);
        final future = Uint8List.fromList(encrypted);
        future[3] = 0x7F;
        expect(
          () => service.decrypt(future, password),
          throwsA(isA<UnsupportedBackupFormatException>()),
        );
      },
    );

    test('hostile KDF params in header are rejected, not honored', () async {
      // A crafted header demanding ~4 TiB of Argon2id memory must throw
      // instead of OOMing the device.
      final encrypted = await service.encrypt(plaintext, password);
      final hostile = Uint8List.fromList(encrypted);
      hostile.buffer.asByteData().setUint32(4, 0xFFFFFFFF); // m (KiB)
      expect(
        () => service.decrypt(hostile, password),
        throwsA(isA<UnsupportedBackupFormatException>()),
      );
    });
  });

  group('legacy format (headerless PBKDF2 100k) back-compat', () {
    test('pre-v2 backup decrypts with the correct password', () async {
      final legacy = await _encryptLegacy(plaintext, password);
      final decrypted = await service.decrypt(legacy, password);
      expect(decrypted, equals(plaintext));
    });

    test('pre-v2 backup with wrong password throws', () async {
      final legacy = await _encryptLegacy(plaintext, password);
      expect(
        () => service.decrypt(legacy, 'wrong-password'),
        throwsA(isA<BackupDecryptionException>()),
      );
    });
  });

  group('malformed input', () {
    test('too-small data throws InvalidBackupFormatException', () async {
      expect(
        () => service.decrypt(Uint8List.fromList([1, 2, 3]), password),
        throwsA(isA<InvalidBackupFormatException>()),
      );
    });
  });
}
