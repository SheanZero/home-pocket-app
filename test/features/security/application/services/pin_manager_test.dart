import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/security/application/services/pin_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FlutterSecureStorage])
import 'pin_manager_test.mocks.dart';

void main() {
  group('PINManager', () {
    late PINManager pinManager;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      pinManager = PINManager(secureStorage: mockSecureStorage);
    });

    group('isPINSet', () {
      test('should return true when PIN hash exists', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => 'some_hash_value');

        // Act
        final isSet = await pinManager.isPINSet();

        // Assert
        expect(isSet, true);
      });

      test('should return false when PIN hash does not exist', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => null);

        // Act
        final isSet = await pinManager.isPINSet();

        // Assert
        expect(isSet, false);
      });
    });

    group('setPIN', () {
      test('should store PIN hash when setting new PIN', () async {
        // Arrange
        const pin = '123456';

        when(
          mockSecureStorage.write(
            key: anyNamed('key'),
            value: anyNamed('value'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await pinManager.setPIN(pin);

        // Assert
        verify(
          mockSecureStorage.write(
            key: 'pin_hash',
            value: anyNamed('value'),
          ),
        ).called(1);
      });

      test('should store different hashes for different PINs', () async {
        // Arrange
        const pin1 = '123456';
        const pin2 = '654321';

        String? storedHash1;
        String? storedHash2;

        when(
          mockSecureStorage.write(
            key: anyNamed('key'),
            value: anyNamed('value'),
          ),
        ).thenAnswer((invocation) async {
          final value =
              invocation.namedArguments[const Symbol('value')] as String;
          if (storedHash1 == null) {
            storedHash1 = value;
          } else {
            storedHash2 = value;
          }
        });

        // Act
        await pinManager.setPIN(pin1);
        await pinManager.setPIN(pin2);

        // Assert
        expect(storedHash1, isNotNull);
        expect(storedHash2, isNotNull);
        expect(storedHash1, isNot(equals(storedHash2)));
      });
    });

    group('verifyPIN', () {
      test('should return true for correct PIN', () async {
        // Arrange
        const pin = '123456';
        final hash = pinManager.hashPIN(pin);

        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => hash);

        // Act
        final isValid = await pinManager.verifyPIN(pin);

        // Assert
        expect(isValid, true);
      });

      test('should return false for incorrect PIN', () async {
        // Arrange
        const correctPIN = '123456';
        const incorrectPIN = '654321';
        final hash = pinManager.hashPIN(correctPIN);

        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => hash);

        // Act
        final isValid = await pinManager.verifyPIN(incorrectPIN);

        // Assert
        expect(isValid, false);
      });

      test('should return false when no PIN is set', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => null);

        // Act
        final isValid = await pinManager.verifyPIN('123456');

        // Assert
        expect(isValid, false);
      });

      test('should validate PIN length (6 digits)', () {
        // Act & Assert
        expect(() => pinManager.hashPIN('12345'), throwsArgumentError);
        expect(() => pinManager.hashPIN('1234567'), throwsArgumentError);
        expect(() => pinManager.hashPIN('abcdef'), throwsArgumentError);
        expect(() => pinManager.hashPIN('123456'), returnsNormally);
      });
    });

    group('changePIN', () {
      test('should update PIN hash when old PIN is correct', () async {
        // Arrange
        const oldPIN = '123456';
        const newPIN = '654321';
        final oldHash = pinManager.hashPIN(oldPIN);

        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => oldHash);
        when(
          mockSecureStorage.write(
            key: anyNamed('key'),
            value: anyNamed('value'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final success = await pinManager.changePIN(oldPIN, newPIN);

        // Assert
        expect(success, true);
        verify(
          mockSecureStorage.write(
            key: 'pin_hash',
            value: anyNamed('value'),
          ),
        ).called(1);
      });

      test('should fail when old PIN is incorrect', () async {
        // Arrange
        const correctOldPIN = '123456';
        const incorrectOldPIN = '111111';
        const newPIN = '654321';
        final oldHash = pinManager.hashPIN(correctOldPIN);

        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => oldHash);

        // Act
        final success = await pinManager.changePIN(incorrectOldPIN, newPIN);

        // Assert
        expect(success, false);
        verifyNever(
          mockSecureStorage.write(
            key: anyNamed('key'),
            value: anyNamed('value'),
          ),
        );
      });
    });

    group('deletePIN', () {
      test('should delete PIN hash when correct PIN provided', () async {
        // Arrange
        const pin = '123456';
        final hash = pinManager.hashPIN(pin);

        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => hash);
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        final success = await pinManager.deletePIN(pin);

        // Assert
        expect(success, true);
        verify(mockSecureStorage.delete(key: 'pin_hash')).called(1);
      });

      test('should fail when incorrect PIN provided', () async {
        // Arrange
        const correctPIN = '123456';
        const incorrectPIN = '654321';
        final hash = pinManager.hashPIN(correctPIN);

        when(mockSecureStorage.read(key: 'pin_hash'))
            .thenAnswer((_) async => hash);

        // Act
        final success = await pinManager.deletePIN(incorrectPIN);

        // Assert
        expect(success, false);
        verifyNever(mockSecureStorage.delete(key: anyNamed('key')));
      });
    });
  });
}
