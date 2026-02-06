import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([KeyRepository])
import 'encryption_repository_impl_test.mocks.dart';

void main() {
  group('EncryptionRepositoryImpl', () {
    late EncryptionRepositoryImpl repository;
    late MockKeyRepository mockKeyRepository;
    late String mockPublicKey;

    setUp(() {
      mockKeyRepository = MockKeyRepository();
      repository = EncryptionRepositoryImpl(keyRepository: mockKeyRepository);

      // Mock public key (32 bytes base64 encoded)
      mockPublicKey = base64Encode(List<int>.generate(32, (i) => i));
      when(mockKeyRepository.getPublicKey())
          .thenAnswer((_) async => mockPublicKey);
    });

    group('encryptField', () {
      test('should encrypt plaintext and return base64 encoded string',
          () async {
        // Arrange
        const plaintext = 'Secret data 12345';

        // Act
        final encrypted = await repository.encryptField(plaintext);

        // Assert
        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(plaintext)));

        // Verify it's valid base64
        expect(() => base64Decode(encrypted), returnsNormally);

        // Verify getPublicKey was called for key derivation
        verify(mockKeyRepository.getPublicKey()).called(1);
      });

      test(
          'should produce different ciphertext for same plaintext due to random nonce',
          () async {
        // Arrange
        const plaintext = 'Same data';

        // Act
        final encrypted1 = await repository.encryptField(plaintext);
        final encrypted2 = await repository.encryptField(plaintext);

        // Assert
        expect(encrypted1, isNot(equals(encrypted2))); // Different nonces
      });

      test('should encrypt empty string', () async {
        // Arrange
        const plaintext = '';

        // Act
        final encrypted = await repository.encryptField(plaintext);

        // Assert
        expect(encrypted, isNotEmpty);

        // Should contain nonce + MAC even for empty plaintext
        final decoded = base64Decode(encrypted);
        expect(
            decoded.length, greaterThanOrEqualTo(28)); // 12 (nonce) + 16 (MAC)
      });

      test('should encrypt Unicode characters correctly', () async {
        // Arrange
        const plaintext = '日本語テスト 中文测试 🎉';

        // Act
        final encrypted = await repository.encryptField(plaintext);

        // Assert
        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(plaintext)));
      });

      test('should throw StateError when device key not initialized', () async {
        // Arrange
        when(mockKeyRepository.getPublicKey()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.encryptField('test'),
          throwsStateError,
        );
      });

      test('should use cached encryption key on second call', () async {
        // Arrange
        const plaintext1 = 'First encryption';
        const plaintext2 = 'Second encryption';

        // Act
        await repository.encryptField(plaintext1);
        await repository.encryptField(plaintext2);

        // Assert
        // getPublicKey should only be called once (key is cached)
        verify(mockKeyRepository.getPublicKey()).called(1);
      });
    });

    group('decryptField', () {
      test('should decrypt ciphertext back to original plaintext', () async {
        // Arrange
        const plaintext = 'Secret data 12345';

        // Act
        final encrypted = await repository.encryptField(plaintext);
        final decrypted = await repository.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('should decrypt empty string', () async {
        // Arrange
        const plaintext = '';

        // Act
        final encrypted = await repository.encryptField(plaintext);
        final decrypted = await repository.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('should decrypt Unicode characters', () async {
        // Arrange
        const plaintext = '日本語テスト 中文测试 🎉';

        // Act
        final encrypted = await repository.encryptField(plaintext);
        final decrypted = await repository.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('should throw FormatException for invalid base64', () async {
        // Arrange
        const invalidCiphertext = 'not-valid-base64!!!';

        // Act & Assert
        expect(
          () => repository.decryptField(invalidCiphertext),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException for too short ciphertext', () async {
        // Arrange
        // Less than 28 bytes (12 nonce + 16 MAC)
        final shortCiphertext = base64Encode(List<int>.filled(20, 0));

        // Act & Assert
        expect(
          () => repository.decryptField(shortCiphertext),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw MacValidationException for tampered ciphertext',
          () async {
        // Arrange
        const plaintext = 'Secret data';
        final encrypted = await repository.encryptField(plaintext);

        // Tamper with the encrypted data (change last byte)
        final decoded = base64Decode(encrypted);
        decoded[decoded.length - 1] = decoded[decoded.length - 1] ^ 0xFF;
        final tamperedEncrypted = base64Encode(decoded);

        // Act & Assert
        expect(
          () => repository.decryptField(tamperedEncrypted),
          throwsA(isA<MacValidationException>()),
        );
      });

      test('should throw exception when decrypting with wrong key', () async {
        // Arrange
        const plaintext = 'Secret data';
        final encrypted = await repository.encryptField(plaintext);

        // Change the public key (different key derivation)
        final differentKey = base64Encode(List<int>.filled(32, 99));
        when(mockKeyRepository.getPublicKey())
            .thenAnswer((_) async => differentKey);

        // Clear cache to force re-derivation with different key
        await repository.clearCache();

        // Act & Assert
        expect(
          () => repository.decryptField(encrypted),
          throwsA(isA<MacValidationException>()),
        );
      });
    });

    group('encryptAmount', () {
      test('should encrypt amount as string', () async {
        // Arrange
        const amount = 12345.67;

        // Act
        final encrypted = await repository.encryptAmount(amount);
        final decrypted = await repository.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(amount.toString()));
      });

      test('should handle zero amount', () async {
        // Arrange
        const amount = 0.0;

        // Act
        final encrypted = await repository.encryptAmount(amount);
        final decrypted = await repository.decryptField(encrypted);

        // Assert
        expect(decrypted, equals('0.0'));
      });

      test('should handle negative amount', () async {
        // Arrange
        const amount = -999.99;

        // Act
        final encrypted = await repository.encryptAmount(amount);
        final decrypted = await repository.decryptField(encrypted);

        // Assert
        expect(decrypted, equals('-999.99'));
      });

      test('should handle very large amounts', () async {
        // Arrange
        const amount = 9999999999.99;

        // Act
        final encrypted = await repository.encryptAmount(amount);
        final decrypted = await repository.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(amount.toString()));
      });
    });

    group('decryptAmount', () {
      test('should decrypt and parse amount correctly', () async {
        // Arrange
        const amount = 12345.67;

        // Act
        final encrypted = await repository.encryptAmount(amount);
        final decrypted = await repository.decryptAmount(encrypted);

        // Assert
        expect(decrypted, equals(amount));
      });

      test('should throw FormatException for invalid amount string', () async {
        // Arrange
        const plaintext = 'not-a-number';
        final encrypted = await repository.encryptField(plaintext);

        // Act & Assert
        expect(
          () => repository.decryptAmount(encrypted),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle zero amount', () async {
        // Arrange
        const amount = 0.0;

        // Act
        final encrypted = await repository.encryptAmount(amount);
        final decrypted = await repository.decryptAmount(encrypted);

        // Assert
        expect(decrypted, equals(0.0));
      });

      test('should handle negative amounts', () async {
        // Arrange
        const amount = -999.99;

        // Act
        final encrypted = await repository.encryptAmount(amount);
        final decrypted = await repository.decryptAmount(encrypted);

        // Assert
        expect(decrypted, equals(amount));
      });
    });

    group('clearCache', () {
      test('should clear cached encryption key', () async {
        // Arrange
        const plaintext = 'Test data';

        // First encryption (caches key)
        await repository.encryptField(plaintext);

        // Verify first call
        verify(mockKeyRepository.getPublicKey()).called(1);

        // Act
        await repository.clearCache();

        // Reset mock to track new calls
        clearInteractions(mockKeyRepository);
        when(mockKeyRepository.getPublicKey())
            .thenAnswer((_) async => mockPublicKey);

        // Second encryption (should re-derive key)
        await repository.encryptField(plaintext);

        // Assert - should be called once more after cache clear
        verify(mockKeyRepository.getPublicKey()).called(1);
      });
    });

    group('HKDF key derivation', () {
      test('should derive consistent encryption key from same public key',
          () async {
        // Arrange
        const plaintext = 'Test data';

        // Act - encrypt twice with same public key
        final encrypted1 = await repository.encryptField(plaintext);

        // Clear cache to force re-derivation
        await repository.clearCache();

        final encrypted2 = await repository.encryptField(plaintext);

        // Decrypt both with same derived key
        final decrypted1 = await repository.decryptField(encrypted1);
        final decrypted2 = await repository.decryptField(encrypted2);

        // Assert
        expect(decrypted1, equals(plaintext));
        expect(decrypted2, equals(plaintext));
      });

      test('should derive different encryption keys for different public keys',
          () async {
        // Arrange
        const plaintext = 'Test data';

        // Encrypt with first key
        final encrypted1 = await repository.encryptField(plaintext);

        // Change public key
        final differentKey = base64Encode(List<int>.filled(32, 99));
        when(mockKeyRepository.getPublicKey())
            .thenAnswer((_) async => differentKey);

        await repository.clearCache();

        // Encrypt with second key
        await repository.encryptField(plaintext);

        // Assert - should not be able to decrypt with wrong key
        expect(
          () => repository.decryptField(encrypted1),
          throwsA(isA<MacValidationException>()),
        );
      });
    });

    group('ChaCha20-Poly1305 encryption format', () {
      test(
          'should produce ciphertext with correct structure: nonce + ciphertext + MAC',
          () async {
        // Arrange
        const plaintext = 'Test';

        // Act
        final encrypted = await repository.encryptField(plaintext);
        final decoded = base64Decode(encrypted);

        // Assert
        // Total length = 12 (nonce) + plaintext_length + 16 (MAC)
        final expectedLength = 12 + utf8.encode(plaintext).length + 16;
        expect(decoded.length, equals(expectedLength));
      });

      test('should use 12-byte nonce for ChaCha20', () async {
        // Arrange
        const plaintext = 'Test';

        // Act
        final encrypted = await repository.encryptField(plaintext);
        final decoded = base64Decode(encrypted);

        // Assert
        // First 12 bytes should be the nonce
        final nonce = decoded.sublist(0, 12);
        expect(nonce.length, equals(12));

        // Nonce should be random (not all zeros)
        expect(nonce, isNot(equals(List<int>.filled(12, 0))));
      });

      test('should append 16-byte MAC for authentication', () async {
        // Arrange
        const plaintext = 'Test';

        // Act
        final encrypted = await repository.encryptField(plaintext);
        final decoded = base64Decode(encrypted);

        // Assert
        // Last 16 bytes should be the MAC
        final mac = decoded.sublist(decoded.length - 16);
        expect(mac.length, equals(16));
      });
    });
  });
}
