import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late KeyRepositoryImpl repository;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    repository = KeyRepositoryImpl(secureStorage: mockStorage);
  });

  group('hasKeyPair', () {
    test('returns false when no key exists', () async {
      when(
        () => mockStorage.read(key: 'device_private_key'),
      ).thenAnswer((_) async => null);

      expect(await repository.hasKeyPair(), false);
    });

    test('returns true when key exists', () async {
      when(
        () => mockStorage.read(key: 'device_private_key'),
      ).thenAnswer((_) async => 'some_key_data');

      expect(await repository.hasKeyPair(), true);
    });
  });

  group('generateKeyPair', () {
    test('generates and stores Ed25519 key pair', () async {
      when(
        () => mockStorage.read(key: 'device_private_key'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final keyPair = await repository.generateKeyPair();

      expect(keyPair.publicKey, isNotEmpty);
      expect(keyPair.deviceId.length, 16);
      expect(keyPair.createdAt, isNotNull);

      verify(
        () => mockStorage.write(
          key: 'device_private_key',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'device_public_key',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'device_id',
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('throws StateError if key pair already exists', () async {
      when(
        () => mockStorage.read(key: 'device_private_key'),
      ).thenAnswer((_) async => 'existing_key');

      expect(() => repository.generateKeyPair(), throwsStateError);
    });
  });

  group('getPublicKey', () {
    test('returns stored public key', () async {
      when(
        () => mockStorage.read(key: 'device_public_key'),
      ).thenAnswer((_) async => 'test_public_key');

      expect(await repository.getPublicKey(), 'test_public_key');
    });

    test('returns null when no key stored', () async {
      when(
        () => mockStorage.read(key: 'device_public_key'),
      ).thenAnswer((_) async => null);

      expect(await repository.getPublicKey(), null);
    });
  });

  group('getDeviceId', () {
    test('returns stored device id', () async {
      when(
        () => mockStorage.read(key: 'device_id'),
      ).thenAnswer((_) async => 'abc123def456ghij');

      expect(await repository.getDeviceId(), 'abc123def456ghij');
    });
  });

  group('signData and verifySignature', () {
    test('sign then verify round-trip succeeds', () async {
      // Generate a real key pair for sign/verify test
      final ed25519 = Ed25519();
      final realKeyPair = await ed25519.newKeyPair();
      final privateKeyBytes = await realKeyPair.extractPrivateKeyBytes();
      final publicKey = await realKeyPair.extractPublicKey();
      final publicKeyBase64 = base64Encode(publicKey.bytes);

      when(
        () => mockStorage.read(key: 'device_private_key'),
      ).thenAnswer((_) async => base64Encode(privateKeyBytes));

      final data = utf8.encode('hello world');
      final signature = await repository.signData(data);

      final isValid = await repository.verifySignature(
        data: data,
        signature: signature,
        publicKeyBase64: publicKeyBase64,
      );

      expect(isValid, true);
    });

    test('verify fails with wrong data', () async {
      final ed25519 = Ed25519();
      final realKeyPair = await ed25519.newKeyPair();
      final privateKeyBytes = await realKeyPair.extractPrivateKeyBytes();
      final publicKey = await realKeyPair.extractPublicKey();
      final publicKeyBase64 = base64Encode(publicKey.bytes);

      when(
        () => mockStorage.read(key: 'device_private_key'),
      ).thenAnswer((_) async => base64Encode(privateKeyBytes));

      final data = utf8.encode('hello world');
      final signature = await repository.signData(data);

      final isValid = await repository.verifySignature(
        data: utf8.encode('tampered data'),
        signature: signature,
        publicKeyBase64: publicKeyBase64,
      );

      expect(isValid, false);
    });

    test('signData throws KeyNotFoundException when no key', () async {
      when(
        () => mockStorage.read(key: 'device_private_key'),
      ).thenAnswer((_) async => null);

      expect(
        () => repository.signData(utf8.encode('data')),
        throwsA(isA<KeyNotFoundException>()),
      );
    });
  });

  group('clearKeys', () {
    test('deletes all key entries', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await repository.clearKeys();

      verify(() => mockStorage.delete(key: 'device_private_key')).called(1);
      verify(() => mockStorage.delete(key: 'device_public_key')).called(1);
      verify(() => mockStorage.delete(key: 'device_id')).called(1);
    });
  });
}
