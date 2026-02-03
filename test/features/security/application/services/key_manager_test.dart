import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/features/security/application/services/key_manager.dart';

@GenerateMocks([FlutterSecureStorage])
import 'key_manager_test.mocks.dart';

void main() {
  group('KeyManager', () {
    late KeyManager keyManager;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      keyManager = KeyManager(secureStorage: mockSecureStorage);
    });

    group('generateDeviceKeyPair', () {
      test('should generate valid Ed25519 key pair', () async {
        // Arrange
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).thenAnswer((_) async => null);

        // Act
        final keyPair = await keyManager.generateDeviceKeyPair();

        // Assert
        expect(keyPair.publicKey, isNotEmpty);
        expect(keyPair.deviceId, isNotEmpty);
        expect(keyPair.deviceId.length, 16);
        expect(keyPair.createdAt, isA<DateTime>());

        // Verify private key stored securely
        verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).called(1);

        // Verify public key stored
        verify(mockSecureStorage.write(
          key: 'device_public_key',
          value: anyNamed('value'),
        )).called(1);

        // Verify device ID stored
        verify(mockSecureStorage.write(
          key: 'device_id',
          value: anyNamed('value'),
        )).called(1);
      });

      test('should generate different keys on each call', () async {
        // Arrange
        when(mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).thenAnswer((_) async => null);

        // Act
        final keyPair1 = await keyManager.generateDeviceKeyPair();
        final keyPair2 = await keyManager.generateDeviceKeyPair();

        // Assert
        expect(keyPair1.publicKey, isNot(equals(keyPair2.publicKey)));
        expect(keyPair1.deviceId, isNot(equals(keyPair2.deviceId)));
      });
    });

    group('hasKeyPair', () {
      test('should return true when private key exists', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => 'mock_private_key_base64');

        // Act
        final hasKey = await keyManager.hasKeyPair();

        // Assert
        expect(hasKey, true);
      });

      test('should return false when private key does not exist', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => null);

        // Act
        final hasKey = await keyManager.hasKeyPair();

        // Assert
        expect(hasKey, false);
      });
    });

    group('getPublicKey', () {
      test('should return stored public key', () async {
        // Arrange
        const mockPublicKey = 'mock_public_key_base64';
        when(mockSecureStorage.read(key: 'device_public_key'))
            .thenAnswer((_) async => mockPublicKey);

        // Act
        final publicKey = await keyManager.getPublicKey();

        // Assert
        expect(publicKey, mockPublicKey);
      });

      test('should return null when public key not found', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_public_key'))
            .thenAnswer((_) async => null);

        // Act
        final publicKey = await keyManager.getPublicKey();

        // Assert
        expect(publicKey, isNull);
      });
    });

    group('getDeviceId', () {
      test('should return stored device ID', () async {
        // Arrange
        const mockDeviceId = 'abc123def4567890';
        when(mockSecureStorage.read(key: 'device_id'))
            .thenAnswer((_) async => mockDeviceId);

        // Act
        final deviceId = await keyManager.getDeviceId();

        // Assert
        expect(deviceId, mockDeviceId);
        expect(deviceId?.length, 16);
      });
    });

    group('signData', () {
      test('should throw KeyNotFoundException when private key not found', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => keyManager.signData([1, 2, 3]),
          throwsA(isA<KeyNotFoundException>()),
        );
      });
    });
  });
}
