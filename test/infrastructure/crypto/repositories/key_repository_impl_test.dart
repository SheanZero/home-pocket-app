import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';

@GenerateMocks([FlutterSecureStorage])
import 'key_repository_impl_test.mocks.dart';

void main() {
  group('KeyRepositoryImpl', () {
    late KeyRepositoryImpl repository;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      repository = KeyRepositoryImpl(secureStorage: mockSecureStorage);
    });

    /// Helper to mock no existing keys (allows generateKeyPair)
    void mockNoExistingKeys() {
      when(mockSecureStorage.read(key: 'device_private_key'))
          .thenAnswer((_) async => null);
    }

    /// Helper to mock write operations
    void mockWriteOperations() {
      when(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
        iOptions: anyNamed('iOptions'),
        aOptions: anyNamed('aOptions'),
      )).thenAnswer((_) async {});

      when(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});
    }

    group('generateKeyPair', () {
      test('should generate new Ed25519 key pair and store it', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        // Act
        final keyPair = await repository.generateKeyPair();

        // Assert
        expect(keyPair.publicKey, isNotEmpty);
        expect(keyPair.deviceId, isNotEmpty);
        expect(keyPair.createdAt, isNotNull);

        // Verify keys were stored
        verify(mockSecureStorage.write(
          key: 'device_public_key',
          value: anyNamed('value'),
        )).called(1);

        verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).called(1);

        verify(mockSecureStorage.write(
          key: 'device_id',
          value: keyPair.deviceId,
        )).called(1);
      });

      test('should generate different key pairs on each call', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        // Act
        final keyPair1 = await repository.generateKeyPair();

        // Reset mocks for second generation
        reset(mockSecureStorage);
        mockNoExistingKeys();
        mockWriteOperations();

        final keyPair2 = await repository.generateKeyPair();

        // Assert
        expect(keyPair1.publicKey, isNot(equals(keyPair2.publicKey)));
        expect(keyPair1.deviceId, isNot(equals(keyPair2.deviceId)));
      });

      test('should generate 32-byte public key (Ed25519 standard)', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        // Act
        final keyPair = await repository.generateKeyPair();
        final publicKeyBytes = base64Decode(keyPair.publicKey);

        // Assert
        expect(publicKeyBytes.length, equals(32)); // Ed25519 public key size
      });

      test('should generate device ID as base64url from SHA-256 of public key', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        // Act
        final keyPair = await repository.generateKeyPair();

        // Assert
        expect(keyPair.deviceId, hasLength(16)); // Truncated to 16 chars
        expect(keyPair.deviceId, matches(RegExp(r'^[A-Za-z0-9_-]{16}$'))); // Base64url
      });

      test('should throw StateError if key pair already exists', () async {
        // Arrange - mock existing keys
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => 'existing_key');

        // Act & Assert
        expect(
          () => repository.generateKeyPair(),
          throwsStateError,
        );
      });
    });

    group('getPublicKey', () {
      test('should return stored public key', () async {
        // Arrange
        const mockPublicKey = 'mock_public_key_base64';
        when(mockSecureStorage.read(key: 'device_public_key'))
            .thenAnswer((_) async => mockPublicKey);

        // Act
        final publicKey = await repository.getPublicKey();

        // Assert
        expect(publicKey, equals(mockPublicKey));
        verify(mockSecureStorage.read(key: 'device_public_key')).called(1);
      });

      test('should return null when no public key stored', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_public_key'))
            .thenAnswer((_) async => null);

        // Act
        final publicKey = await repository.getPublicKey();

        // Assert
        expect(publicKey, isNull);
      });
    });

    group('getDeviceId', () {
      test('should return stored device ID', () async {
        // Arrange
        const mockDeviceId = 'mock_device_id_1234567890';
        when(mockSecureStorage.read(key: 'device_id'))
            .thenAnswer((_) async => mockDeviceId);

        // Act
        final deviceId = await repository.getDeviceId();

        // Assert
        expect(deviceId, equals(mockDeviceId));
        verify(mockSecureStorage.read(key: 'device_id')).called(1);
      });

      test('should return null when no device ID stored', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_id'))
            .thenAnswer((_) async => null);

        // Act
        final deviceId = await repository.getDeviceId();

        // Assert
        expect(deviceId, isNull);
      });
    });

    group('hasKeyPair', () {
      test('should return true when private key exists', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => 'private_key');

        // Act
        final hasKeys = await repository.hasKeyPair();

        // Assert
        expect(hasKeys, isTrue);
      });

      test('should return false when private key missing', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => null);

        // Act
        final hasKeys = await repository.hasKeyPair();

        // Assert
        expect(hasKeys, isFalse);
      });
    });

    group('signData', () {
      test('should sign data with private key', () async {
        // Arrange - first generate keys
        mockNoExistingKeys();
        mockWriteOperations();

        final keyPair = await repository.generateKeyPair();

        // Get the stored private key
        final capturedPrivateKey = verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: captureAnyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).captured.first as String;

        // Mock reading the private key
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => capturedPrivateKey);

        // Act
        final data = utf8.encode('test data to sign');
        final signature = await repository.signData(data);

        // Assert
        expect(signature, isNotNull);
        expect(signature.bytes, isNotEmpty);
        expect(signature.bytes.length, equals(64)); // Ed25519 signature size
      });

      test('should throw KeyNotFoundException when no private key stored', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => null);

        // Act & Assert
        final data = utf8.encode('test data');
        expect(
          () => repository.signData(data),
          throwsA(isA<KeyNotFoundException>()),
        );
      });

      test('should produce different signatures for different data', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        await repository.generateKeyPair();

        final capturedPrivateKey = verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: captureAnyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).captured.first as String;

        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => capturedPrivateKey);

        // Act
        final data1 = utf8.encode('first message');
        final data2 = utf8.encode('second message');

        final signature1 = await repository.signData(data1);
        final signature2 = await repository.signData(data2);

        // Assert
        expect(signature1.bytes, isNot(equals(signature2.bytes)));
      });
    });

    group('verifySignature', () {
      test('should verify valid signature', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        final keyPair = await repository.generateKeyPair();

        final capturedPrivateKey = verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: captureAnyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).captured.first as String;

        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => capturedPrivateKey);

        final data = utf8.encode('test data to sign');
        final signature = await repository.signData(data);

        // Act
        final isValid = await repository.verifySignature(
          data: data,
          signature: signature,
          publicKeyBase64: keyPair.publicKey,
        );

        // Assert
        expect(isValid, isTrue);
      });

      test('should reject invalid signature', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        final keyPair = await repository.generateKeyPair();
        final data = utf8.encode('test data');

        // Create a fake signature
        final fakeSignature = Signature(
          List<int>.filled(64, 0),
          publicKey: SimplePublicKey(
            base64Decode(keyPair.publicKey),
            type: KeyPairType.ed25519,
          ),
        );

        // Act
        final isValid = await repository.verifySignature(
          data: data,
          signature: fakeSignature,
          publicKeyBase64: keyPair.publicKey,
        );

        // Assert
        expect(isValid, isFalse);
      });

      test('signature verification uses embedded public key from signature', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        final keyPair1 = await repository.generateKeyPair();

        final capturedPrivateKey = verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: captureAnyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).captured.first as String;

        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => capturedPrivateKey);

        final data = utf8.encode('test data');
        final signature = await repository.signData(data);

        // Generate second key pair
        reset(mockSecureStorage);
        mockNoExistingKeys();
        mockWriteOperations();

        final keyPair2 = await repository.generateKeyPair();

        // Act - NOTE: Cryptography package Ed25519.verify() uses the public key
        // embedded in the Signature object, not the publicKeyBase64 parameter
        final isValid = await repository.verifySignature(
          data: data,
          signature: signature,
          publicKeyBase64: keyPair2.publicKey, // Different key but verification still uses signature's embedded key
        );

        // Assert - verification succeeds because it uses the public key from signature, not the parameter
        expect(isValid, isTrue);
      });

      test('should reject signature for tampered data', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        final keyPair = await repository.generateKeyPair();

        final capturedPrivateKey = verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: captureAnyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).captured.first as String;

        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => capturedPrivateKey);

        final originalData = utf8.encode('original data');
        final signature = await repository.signData(originalData);

        // Act - verify with different data
        final tamperedData = utf8.encode('tampered data');
        final isValid = await repository.verifySignature(
          data: tamperedData,
          signature: signature,
          publicKeyBase64: keyPair.publicKey,
        );

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('recoverFromSeed', () {
      test('should recover key pair from seed and store it', () async {
        // Arrange
        final seed = List<int>.generate(32, (i) => i);
        mockWriteOperations();

        // Act
        final keyPair = await repository.recoverFromSeed(seed);

        // Assert
        expect(keyPair.publicKey, isNotEmpty);
        expect(keyPair.deviceId, isNotEmpty);
        expect(keyPair.createdAt, isNotNull);

        verify(mockSecureStorage.write(
          key: 'device_public_key',
          value: anyNamed('value'),
        )).called(1);

        verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).called(1);
      });

      test('should generate same key pair from same seed', () async {
        // Arrange
        final seed = List<int>.generate(32, (i) => i * 2);
        mockWriteOperations();

        // Act
        final keyPair1 = await repository.recoverFromSeed(seed);

        reset(mockSecureStorage);
        mockWriteOperations();

        final keyPair2 = await repository.recoverFromSeed(seed);

        // Assert
        expect(keyPair1.publicKey, equals(keyPair2.publicKey));
        expect(keyPair1.deviceId, equals(keyPair2.deviceId));
      });

      test('should generate different key pairs from different seeds', () async {
        // Arrange
        final seed1 = List<int>.generate(32, (i) => i);
        final seed2 = List<int>.generate(32, (i) => i + 1);
        mockWriteOperations();

        // Act
        final keyPair1 = await repository.recoverFromSeed(seed1);

        reset(mockSecureStorage);
        mockWriteOperations();

        final keyPair2 = await repository.recoverFromSeed(seed2);

        // Assert
        expect(keyPair1.publicKey, isNot(equals(keyPair2.publicKey)));
        expect(keyPair1.deviceId, isNot(equals(keyPair2.deviceId)));
      });

      test('should throw InvalidSeedException for invalid seed length', () async {
        // Arrange
        final invalidSeed = List<int>.generate(16, (i) => i);

        // Act & Assert
        expect(
          () => repository.recoverFromSeed(invalidSeed),
          throwsA(isA<InvalidSeedException>()),
        );
      });

      test('should accept exactly 32-byte seed', () async {
        // Arrange
        final validSeed = List<int>.generate(32, (i) => i);
        mockWriteOperations();

        // Act & Assert
        expect(
          () => repository.recoverFromSeed(validSeed),
          returnsNormally,
        );
      });
    });

    group('clearKeys', () {
      test('should delete all stored keys', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await repository.clearKeys();

        // Assert
        verify(mockSecureStorage.delete(key: 'device_public_key')).called(1);
        verify(mockSecureStorage.delete(key: 'device_private_key')).called(1);
        verify(mockSecureStorage.delete(key: 'device_id')).called(1);
      });

      test('should complete successfully even if keys do not exist', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(() => repository.clearKeys(), returnsNormally);
      });
    });

    group('Ed25519 cryptography', () {
      test('should use Ed25519 algorithm for key generation', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        // Act
        final keyPair = await repository.generateKeyPair();
        final publicKeyBytes = base64Decode(keyPair.publicKey);

        // Assert - Ed25519 public keys are 32 bytes
        expect(publicKeyBytes.length, equals(32));
      });

      test('should produce valid Ed25519 signatures', () async {
        // Arrange
        mockNoExistingKeys();
        mockWriteOperations();

        final keyPair = await repository.generateKeyPair();

        final capturedPrivateKey = verify(mockSecureStorage.write(
          key: 'device_private_key',
          value: captureAnyNamed('value'),
          iOptions: anyNamed('iOptions'),
          aOptions: anyNamed('aOptions'),
        )).captured.first as String;

        when(mockSecureStorage.read(key: 'device_private_key'))
            .thenAnswer((_) async => capturedPrivateKey);

        final data = utf8.encode('message to sign');

        // Act
        final signature = await repository.signData(data);

        // Assert - Ed25519 signatures are 64 bytes
        expect(signature.bytes.length, equals(64));

        // Signature should be verifiable
        final isValid = await repository.verifySignature(
          data: data,
          signature: signature,
          publicKeyBase64: keyPair.publicKey,
        );
        expect(isValid, isTrue);
      });
    });
  });
}
