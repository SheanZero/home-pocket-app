import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/services/backup_crypto_service.dart';

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

  group('non-v2 input', () {
    test('headerless payload rejects before decryption', () async {
      expect(
        () => service.decrypt(Uint8List.fromList(List.filled(44, 0)), password),
        throwsA(isA<InvalidBackupFormatException>()),
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
