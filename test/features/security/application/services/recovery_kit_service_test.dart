import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/features/security/application/services/recovery_kit_service.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';

@GenerateMocks([FlutterSecureStorage, KeyManager])
import 'recovery_kit_service_test.mocks.dart';

void main() {
  group('RecoveryKitService', () {
    late RecoveryKitService service;
    late MockFlutterSecureStorage mockSecureStorage;
    late MockKeyManager mockKeyManager;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      mockKeyManager = MockKeyManager();
      service = RecoveryKitService(
        secureStorage: mockSecureStorage,
        keyManager: mockKeyManager,
      );
    });

    group('generateRecoveryKit', () {
      test('should generate 24-word mnemonic', () async {
        // Arrange
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => null);

        // Act
        final mnemonic = await service.generateRecoveryKit();

        // Assert
        final words = mnemonic.split(' ');
        expect(words.length, 24);
        expect(words.every((word) => word.isNotEmpty), true);

        // Verify hash stored
        verify(mockSecureStorage.write(
          key: 'recovery_kit_hash',
          value: anyNamed('value'),
        )).called(1);
      });

      test('should generate different mnemonics on each call', () async {
        // Arrange
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenAnswer((_) async => null);

        // Act
        final mnemonic1 = await service.generateRecoveryKit();
        final mnemonic2 = await service.generateRecoveryKit();

        // Assert
        expect(mnemonic1, isNot(equals(mnemonic2)));
      });
    });

    group('verifyRecoveryKit', () {
      test('should return true for correct mnemonic', () async {
        // Arrange
        const testMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
        final hash = service.hashMnemonic(testMnemonic);

        when(mockSecureStorage.read(key: 'recovery_kit_hash'))
            .thenAnswer((_) async => hash);

        // Act
        final isValid = await service.verifyRecoveryKit(testMnemonic);

        // Assert
        expect(isValid, true);
      });

      test('should return false for incorrect mnemonic', () async {
        // Arrange
        const storedMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
        const inputMnemonic = 'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong';

        final storedHash = service.hashMnemonic(storedMnemonic);
        when(mockSecureStorage.read(key: 'recovery_kit_hash'))
            .thenAnswer((_) async => storedHash);

        // Act
        final isValid = await service.verifyRecoveryKit(inputMnemonic);

        // Assert
        expect(isValid, false);
      });

      test('should return false for invalid word count', () async {
        // Arrange
        const invalidMnemonic = 'abandon abandon abandon';

        when(mockSecureStorage.read(key: 'recovery_kit_hash'))
            .thenAnswer((_) async => 'some_hash');

        // Act
        final isValid = await service.verifyRecoveryKit(invalidMnemonic);

        // Assert
        expect(isValid, false);
      });

      test('should return false when no stored hash', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'recovery_kit_hash'))
            .thenAnswer((_) async => null);

        // Act
        final isValid = await service.verifyRecoveryKit('some mnemonic');

        // Assert
        expect(isValid, false);
      });
    });

    group('getRandomWordsForVerification', () {
      test('should return 3 random word indices', () {
        // Act
        final indices = service.getRandomWordsForVerification();

        // Assert
        expect(indices.length, 3);
        expect(indices.every((i) => i >= 0 && i < 24), true);
        expect(indices.toSet().length, 3); // All unique
      });
    });
  });
}
