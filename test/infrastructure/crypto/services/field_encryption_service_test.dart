import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([EncryptionRepository])
import 'field_encryption_service_test.mocks.dart';

void main() {
  group('FieldEncryptionService', () {
    late FieldEncryptionService encryptionService;
    late MockEncryptionRepository mockRepository;

    setUp(() {
      mockRepository = MockEncryptionRepository();
      encryptionService = FieldEncryptionService(repository: mockRepository);
    });

    group('encryptField', () {
      test('should delegate to repository', () async {
        // Arrange
        const plaintext = 'Secret data';
        const encrypted = 'encrypted_data_base64';
        when(mockRepository.encryptField(plaintext))
            .thenAnswer((_) async => encrypted);

        // Act
        final result = await encryptionService.encryptField(plaintext);

        // Assert
        expect(result, encrypted);
        verify(mockRepository.encryptField(plaintext)).called(1);
      });
    });

    group('decryptField', () {
      test('should delegate to repository', () async {
        // Arrange
        const ciphertext = 'encrypted_data_base64';
        const plaintext = 'Secret data';
        when(mockRepository.decryptField(ciphertext))
            .thenAnswer((_) async => plaintext);

        // Act
        final result = await encryptionService.decryptField(ciphertext);

        // Assert
        expect(result, plaintext);
        verify(mockRepository.decryptField(ciphertext)).called(1);
      });
    });

    group('encryptAmount', () {
      test('should delegate to repository', () async {
        // Arrange
        const amount = 12345.67;
        const encrypted = 'encrypted_amount_base64';
        when(mockRepository.encryptAmount(amount))
            .thenAnswer((_) async => encrypted);

        // Act
        final result = await encryptionService.encryptAmount(amount);

        // Assert
        expect(result, encrypted);
        verify(mockRepository.encryptAmount(amount)).called(1);
      });
    });

    group('decryptAmount', () {
      test('should delegate to repository', () async {
        // Arrange
        const encryptedAmount = 'encrypted_amount_base64';
        const amount = 12345.67;
        when(mockRepository.decryptAmount(encryptedAmount))
            .thenAnswer((_) async => amount);

        // Act
        final result = await encryptionService.decryptAmount(encryptedAmount);

        // Assert
        expect(result, amount);
        verify(mockRepository.decryptAmount(encryptedAmount)).called(1);
      });
    });

    group('clearCache', () {
      test('should delegate to repository', () async {
        // Arrange
        when(mockRepository.clearCache()).thenAnswer((_) async {});

        // Act
        await encryptionService.clearCache();

        // Assert
        verify(mockRepository.clearCache()).called(1);
      });
    });
  });
}
