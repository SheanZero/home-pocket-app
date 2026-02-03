import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:home_pocket/features/security/application/services/field_encryption_service.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';

@GenerateMocks([KeyManager])
import 'field_encryption_service_test.mocks.dart';

void main() {
  group('FieldEncryptionService', () {
    late FieldEncryptionService encryptionService;
    late MockKeyManager mockKeyManager;

    setUp(() {
      mockKeyManager = MockKeyManager();
      encryptionService = FieldEncryptionService(keyManager: mockKeyManager);
    });

    group('encryptField', () {
      test('should encrypt plaintext and return base64 encoded string', () async {
        // Arrange
        const plaintext = 'Secret data 12345';
        final mockKey = List<int>.filled(32, 42); // 256-bit key

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptField(plaintext);

        // Assert
        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(plaintext)));
        // Encrypted data should be base64 encoded
        expect(() => base64Decode(encrypted), returnsNormally);
      });

      test('should produce different ciphertext for same plaintext (nonce randomness)', () async {
        // Arrange
        const plaintext = 'Same data';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted1 = await encryptionService.encryptField(plaintext);
        final encrypted2 = await encryptionService.encryptField(plaintext);

        // Assert
        expect(encrypted1, isNot(equals(encrypted2))); // Different due to random nonce
      });

      test('should encrypt empty string', () async {
        // Arrange
        const plaintext = '';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptField(plaintext);

        // Assert
        expect(encrypted, isNotEmpty);
      });

      test('should encrypt Unicode characters', () async {
        // Arrange
        const plaintext = '日本語テスト 中文测试 🎉';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptField(plaintext);

        // Assert
        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(plaintext)));
      });
    });

    group('decryptField', () {
      test('should decrypt ciphertext back to original plaintext', () async {
        // Arrange
        const plaintext = 'Secret data 12345';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptField(plaintext);
        final decrypted = await encryptionService.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('should decrypt empty string', () async {
        // Arrange
        const plaintext = '';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptField(plaintext);
        final decrypted = await encryptionService.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('should decrypt Unicode characters', () async {
        // Arrange
        const plaintext = '日本語テスト 中文测试 🎉';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptField(plaintext);
        final decrypted = await encryptionService.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(plaintext));
      });

      test('should throw exception for invalid ciphertext', () async {
        // Arrange
        const invalidCiphertext = 'not-valid-encrypted-data';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act & Assert
        expect(
          () => encryptionService.decryptField(invalidCiphertext),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw exception for tampered ciphertext', () async {
        // Arrange
        const plaintext = 'Secret data';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        final encrypted = await encryptionService.encryptField(plaintext);

        // Tamper with the encrypted data
        final tamperedEncrypted = encrypted.substring(0, encrypted.length - 4) + 'XXXX';

        // Act & Assert
        expect(
          () => encryptionService.decryptField(tamperedEncrypted),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('encryptAmount', () {
      test('should encrypt amount as string', () async {
        // Arrange
        const amount = 12345.67;
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptAmount(amount);
        final decrypted = await encryptionService.decryptField(encrypted);

        // Assert
        expect(decrypted, equals(amount.toString()));
      });

      test('should handle zero amount', () async {
        // Arrange
        const amount = 0.0;
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptAmount(amount);
        final decrypted = await encryptionService.decryptField(encrypted);

        // Assert
        expect(decrypted, equals('0.0'));
      });

      test('should handle negative amount', () async {
        // Arrange
        const amount = -999.99;
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptAmount(amount);
        final decrypted = await encryptionService.decryptField(encrypted);

        // Assert
        expect(decrypted, equals('-999.99'));
      });
    });

    group('decryptAmount', () {
      test('should decrypt and parse amount correctly', () async {
        // Arrange
        const amount = 12345.67;
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        // Act
        final encrypted = await encryptionService.encryptAmount(amount);
        final decrypted = await encryptionService.decryptAmount(encrypted);

        // Assert
        expect(decrypted, equals(amount));
      });

      test('should throw exception for invalid amount string', () async {
        // Arrange
        const plaintext = 'not-a-number';
        final mockKey = List<int>.filled(32, 42);

        when(mockKeyManager.getPublicKey()).thenAnswer((_) async => base64Encode(mockKey));

        final encrypted = await encryptionService.encryptField(plaintext);

        // Act & Assert
        expect(
          () => encryptionService.decryptAmount(encrypted),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
