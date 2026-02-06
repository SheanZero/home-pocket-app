import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMasterKeyRepository extends Mock implements MasterKeyRepository {}

void main() {
  late MockMasterKeyRepository mockMasterKeyRepo;
  late EncryptionRepositoryImpl repository;

  setUp(() {
    mockMasterKeyRepo = MockMasterKeyRepository();
    repository = EncryptionRepositoryImpl(
      masterKeyRepository: mockMasterKeyRepo,
    );

    // Return a consistent derived key for field encryption
    final testKey = SecretKey(List<int>.generate(32, (i) => i + 1));
    when(
      () => mockMasterKeyRepo.deriveKey('field_encryption'),
    ).thenAnswer((_) async => testKey);
  });

  group('encryptField / decryptField', () {
    test('encrypt then decrypt round-trip returns original text', () async {
      const plaintext = 'lunch expense';
      final encrypted = await repository.encryptField(plaintext);
      final decrypted = await repository.decryptField(encrypted);

      expect(decrypted, plaintext);
    });

    test('encrypted output is Base64 and differs from plaintext', () async {
      const plaintext = 'secret note';
      final encrypted = await repository.encryptField(plaintext);

      expect(encrypted, isNot(equals(plaintext)));
      // Should be valid Base64
      expect(() => base64Decode(encrypted), returnsNormally);
    });

    test(
      'same plaintext produces different ciphertexts (random nonce)',
      () async {
        const plaintext = 'same text';
        final encrypted1 = await repository.encryptField(plaintext);
        final encrypted2 = await repository.encryptField(plaintext);

        expect(encrypted1, isNot(equals(encrypted2)));
      },
    );

    test('empty string round-trip', () async {
      final encrypted = await repository.encryptField('');
      final decrypted = await repository.decryptField(encrypted);

      expect(decrypted, '');
    });

    test('unicode text round-trip', () async {
      const plaintext = 'lunch 午餐 ランチ';
      final encrypted = await repository.encryptField(plaintext);
      final decrypted = await repository.decryptField(encrypted);

      expect(decrypted, plaintext);
    });

    test('decrypting tampered data throws MacValidationException', () async {
      final encrypted = await repository.encryptField('data');
      final bytes = base64Decode(encrypted);

      // Tamper with the last byte (part of MAC)
      bytes[bytes.length - 1] ^= 0xFF;
      final tampered = base64Encode(bytes);

      expect(
        () => repository.decryptField(tampered),
        throwsA(isA<MacValidationException>()),
      );
    });

    test('decrypting too-short data throws MacValidationException', () async {
      final tooShort = base64Encode(List<int>.filled(10, 0));

      expect(
        () => repository.decryptField(tooShort),
        throwsA(isA<MacValidationException>()),
      );
    });
  });

  group('encryptAmount / decryptAmount', () {
    test('round-trip preserves amount value', () async {
      const amount = 1234.56;
      final encrypted = await repository.encryptAmount(amount);
      final decrypted = await repository.decryptAmount(encrypted);

      expect(decrypted, amount);
    });

    test('zero amount round-trip', () async {
      final encrypted = await repository.encryptAmount(0.0);
      final decrypted = await repository.decryptAmount(encrypted);

      expect(decrypted, 0.0);
    });

    test('negative amount round-trip', () async {
      final encrypted = await repository.encryptAmount(-500.25);
      final decrypted = await repository.decryptAmount(encrypted);

      expect(decrypted, -500.25);
    });
  });

  group('clearCache', () {
    test('clears cached key and re-derives on next use', () async {
      // First encrypt to populate cache
      await repository.encryptField('test');

      // Clear cache
      await repository.clearCache();

      // Should still work (re-derives key)
      final encrypted = await repository.encryptField('after clear');
      final decrypted = await repository.decryptField(encrypted);

      expect(decrypted, 'after clear');
    });
  });
}
