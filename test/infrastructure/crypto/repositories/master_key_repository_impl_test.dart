import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository_impl.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MasterKeyRepositoryImpl repository;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    repository = MasterKeyRepositoryImpl(secureStorage: mockStorage);
  });

  group('initializeMasterKey', () {
    test('creates and stores 256-bit master key on first call', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await repository.initializeMasterKey();

      final captured = verify(
        () => mockStorage.write(
          key: 'master_key',
          value: captureAny(named: 'value'),
        ),
      ).captured;

      // Verify Base64-encoded 32 bytes (44 chars with padding)
      final storedValue = captured.first as String;
      final decodedBytes = base64Decode(storedValue);
      expect(decodedBytes.length, 32);
    });

    test('throws StateError if master key already exists', () async {
      when(
        () => mockStorage.read(key: 'master_key'),
      ).thenAnswer((_) async => 'existing_key');

      expect(() => repository.initializeMasterKey(), throwsStateError);
    });
  });

  group('hasMasterKey', () {
    test('returns true when master key exists', () async {
      when(
        () => mockStorage.read(key: 'master_key'),
      ).thenAnswer((_) async => 'some_base64_key');

      expect(await repository.hasMasterKey(), true);
    });

    test('returns false when master key does not exist', () async {
      when(
        () => mockStorage.read(key: 'master_key'),
      ).thenAnswer((_) async => null);

      expect(await repository.hasMasterKey(), false);
    });
  });

  group('getMasterKey', () {
    test('returns master key bytes when initialized', () async {
      final testKey = List<int>.filled(32, 42);
      final testKeyBase64 = base64Encode(testKey);
      when(
        () => mockStorage.read(key: 'master_key'),
      ).thenAnswer((_) async => testKeyBase64);

      final result = await repository.getMasterKey();

      expect(result, equals(testKey));
    });

    test(
      'throws MasterKeyNotInitializedException when not initialized',
      () async {
        when(
          () => mockStorage.read(key: 'master_key'),
        ).thenAnswer((_) async => null);

        expect(
          () => repository.getMasterKey(),
          throwsA(isA<MasterKeyNotInitializedException>()),
        );
      },
    );
  });

  group('deriveKey', () {
    test('derives different keys for different purposes', () async {
      final testKey = List<int>.filled(32, 42);
      final testKeyBase64 = base64Encode(testKey);
      when(
        () => mockStorage.read(key: 'master_key'),
      ).thenAnswer((_) async => testKeyBase64);

      final dbKey = await repository.deriveKey('database_encryption');
      final fieldKey = await repository.deriveKey('field_encryption');

      final dbBytes = await dbKey.extractBytes();
      final fieldBytes = await fieldKey.extractBytes();

      expect(dbBytes, isNot(equals(fieldBytes)));
      expect(dbBytes.length, 32);
      expect(fieldBytes.length, 32);
    });

    test('returns same key for same purpose (cached)', () async {
      final testKey = List<int>.filled(32, 42);
      final testKeyBase64 = base64Encode(testKey);
      when(
        () => mockStorage.read(key: 'master_key'),
      ).thenAnswer((_) async => testKeyBase64);

      final key1 = await repository.deriveKey('database_encryption');
      final key2 = await repository.deriveKey('database_encryption');

      expect(identical(key1, key2), true);
    });
  });

  group('clearMasterKey', () {
    test('deletes master key from storage', () async {
      when(
        () => mockStorage.delete(key: 'master_key'),
      ).thenAnswer((_) async {});

      await repository.clearMasterKey();

      verify(() => mockStorage.delete(key: 'master_key')).called(1);
    });
  });
}
