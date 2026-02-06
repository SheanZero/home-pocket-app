import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([KeyRepository])
import 'key_manager_test.mocks.dart';

void main() {
  group('KeyManager', () {
    late KeyManager keyManager;
    late MockKeyRepository mockRepository;

    setUp(() {
      mockRepository = MockKeyRepository();
      keyManager = KeyManager(repository: mockRepository);
    });

    group('generateDeviceKeyPair', () {
      test('should delegate to repository', () async {
        // Arrange
        final mockKeyPair = DeviceKeyPair(
          publicKey: 'mockPublicKey',
          deviceId: 'mockDeviceId1234',
          createdAt: DateTime.now(),
        );
        when(mockRepository.generateKeyPair())
            .thenAnswer((_) async => mockKeyPair);

        // Act
        final keyPair = await keyManager.generateDeviceKeyPair();

        // Assert
        expect(keyPair, mockKeyPair);
        verify(mockRepository.generateKeyPair()).called(1);
      });
    });

    group('getPublicKey', () {
      test('should delegate to repository', () async {
        // Arrange
        when(mockRepository.getPublicKey())
            .thenAnswer((_) async => 'mockPublicKey');

        // Act
        final publicKey = await keyManager.getPublicKey();

        // Assert
        expect(publicKey, 'mockPublicKey');
        verify(mockRepository.getPublicKey()).called(1);
      });
    });

    group('getDeviceId', () {
      test('should delegate to repository', () async {
        // Arrange
        when(mockRepository.getDeviceId())
            .thenAnswer((_) async => 'mockDeviceId1234');

        // Act
        final deviceId = await keyManager.getDeviceId();

        // Assert
        expect(deviceId, 'mockDeviceId1234');
        verify(mockRepository.getDeviceId()).called(1);
      });
    });

    group('hasKeyPair', () {
      test('should delegate to repository and return true', () async {
        // Arrange
        when(mockRepository.hasKeyPair()).thenAnswer((_) async => true);

        // Act
        final hasKeys = await keyManager.hasKeyPair();

        // Assert
        expect(hasKeys, true);
        verify(mockRepository.hasKeyPair()).called(1);
      });

      test('should delegate to repository and return false', () async {
        // Arrange
        when(mockRepository.hasKeyPair()).thenAnswer((_) async => false);

        // Act
        final hasKeys = await keyManager.hasKeyPair();

        // Assert
        expect(hasKeys, false);
        verify(mockRepository.hasKeyPair()).called(1);
      });
    });

    group('signData', () {
      test('should delegate to repository', () async {
        // Arrange
        final data = [1, 2, 3, 4, 5];
        final mockPublicKey = SimplePublicKey(
          List.generate(32, (i) => i),
          type: KeyPairType.ed25519,
        );
        final mockSignature =
            Signature([6, 7, 8, 9, 10], publicKey: mockPublicKey);
        when(mockRepository.signData(data))
            .thenAnswer((_) async => mockSignature);

        // Act
        final signature = await keyManager.signData(data);

        // Assert
        expect(signature, mockSignature);
        verify(mockRepository.signData(data)).called(1);
      });
    });

    group('verifySignature', () {
      test('should delegate to repository', () async {
        // Arrange
        final data = [1, 2, 3, 4, 5];
        final mockPublicKey = SimplePublicKey(
          List.generate(32, (i) => i),
          type: KeyPairType.ed25519,
        );
        final signature = Signature([6, 7, 8, 9, 10], publicKey: mockPublicKey);
        const publicKey = 'mockPublicKey';

        when(
          mockRepository.verifySignature(
            data: data,
            signature: signature,
            publicKeyBase64: publicKey,
          ),
        ).thenAnswer((_) async => true);

        // Act
        final result = await keyManager.verifySignature(
          data: data,
          signature: signature,
          publicKeyBase64: publicKey,
        );

        // Assert
        expect(result, true);
        verify(
          mockRepository.verifySignature(
            data: data,
            signature: signature,
            publicKeyBase64: publicKey,
          ),
        ).called(1);
      });
    });

    group('recoverFromSeed', () {
      test('should delegate to repository', () async {
        // Arrange
        final seed = List.generate(32, (i) => i);
        final mockKeyPair = DeviceKeyPair(
          publicKey: 'recoveredPublicKey',
          deviceId: 'recoveredId1234',
          createdAt: DateTime.now(),
        );
        when(mockRepository.recoverFromSeed(seed))
            .thenAnswer((_) async => mockKeyPair);

        // Act
        final keyPair = await keyManager.recoverFromSeed(seed);

        // Assert
        expect(keyPair, mockKeyPair);
        verify(mockRepository.recoverFromSeed(seed)).called(1);
      });
    });

    group('clearKeys', () {
      test('should delegate to repository', () async {
        // Arrange
        when(mockRepository.clearKeys()).thenAnswer((_) async {});

        // Act
        await keyManager.clearKeys();

        // Assert
        verify(mockRepository.clearKeys()).called(1);
      });
    });
  });
}
