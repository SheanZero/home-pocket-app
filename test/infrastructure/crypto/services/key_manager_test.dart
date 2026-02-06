import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockKeyRepository extends Mock implements KeyRepository {}

class FakeSignature extends Fake implements Signature {}

void main() {
  late MockKeyRepository mockRepo;
  late KeyManager keyManager;

  setUpAll(() {
    registerFallbackValue(FakeSignature());
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    mockRepo = MockKeyRepository();
    keyManager = KeyManager(repository: mockRepo);
  });

  group('hasKeyPair', () {
    test('delegates to repository', () async {
      when(() => mockRepo.hasKeyPair()).thenAnswer((_) async => true);

      expect(await keyManager.hasKeyPair(), true);
      verify(() => mockRepo.hasKeyPair()).called(1);
    });
  });

  group('generateDeviceKeyPair', () {
    test('delegates to repository', () async {
      final expected = DeviceKeyPair(
        publicKey: 'pk',
        deviceId: 'did',
        createdAt: DateTime(2026),
      );
      when(() => mockRepo.generateKeyPair()).thenAnswer((_) async => expected);

      final result = await keyManager.generateDeviceKeyPair();

      expect(result, expected);
      verify(() => mockRepo.generateKeyPair()).called(1);
    });
  });

  group('getPublicKey', () {
    test('delegates to repository', () async {
      when(
        () => mockRepo.getPublicKey(),
      ).thenAnswer((_) async => 'public_key_base64');

      expect(await keyManager.getPublicKey(), 'public_key_base64');
    });
  });

  group('getDeviceId', () {
    test('delegates to repository', () async {
      when(
        () => mockRepo.getDeviceId(),
      ).thenAnswer((_) async => 'device_id_16ch');

      expect(await keyManager.getDeviceId(), 'device_id_16ch');
    });
  });

  group('signData', () {
    test('delegates to repository', () async {
      final testData = utf8.encode('data');
      final fakeSignature = Signature([
        1,
        2,
        3,
      ], publicKey: SimplePublicKey([4, 5, 6], type: KeyPairType.ed25519));
      when(
        () => mockRepo.signData(testData),
      ).thenAnswer((_) async => fakeSignature);

      final result = await keyManager.signData(testData);

      expect(result, fakeSignature);
    });
  });

  group('verifySignature', () {
    test('delegates to repository', () async {
      final fakeSignature = Signature([
        1,
        2,
        3,
      ], publicKey: SimplePublicKey([4, 5, 6], type: KeyPairType.ed25519));
      when(
        () => mockRepo.verifySignature(
          data: any(named: 'data'),
          signature: any(named: 'signature'),
          publicKeyBase64: any(named: 'publicKeyBase64'),
        ),
      ).thenAnswer((_) async => true);

      final result = await keyManager.verifySignature(
        data: utf8.encode('data'),
        signature: fakeSignature,
        publicKeyBase64: 'pk_base64',
      );

      expect(result, true);
    });
  });

  group('recoverFromSeed', () {
    test('delegates to repository', () async {
      final seed = List<int>.generate(32, (i) => i);
      final expected = DeviceKeyPair(
        publicKey: 'pk',
        deviceId: 'did',
        createdAt: DateTime(2026),
      );
      when(
        () => mockRepo.recoverFromSeed(any()),
      ).thenAnswer((_) async => expected);

      final result = await keyManager.recoverFromSeed(seed);

      expect(result, expected);
      verify(() => mockRepo.recoverFromSeed(seed)).called(1);
    });
  });

  group('clearKeys', () {
    test('delegates to repository', () async {
      when(() => mockRepo.clearKeys()).thenAnswer((_) async {});

      await keyManager.clearKeys();

      verify(() => mockRepo.clearKeys()).called(1);
    });
  });
}
