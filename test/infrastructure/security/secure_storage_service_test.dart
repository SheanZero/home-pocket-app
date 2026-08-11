import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void _expectEstablishedOptions(
  IOSOptions iosOptions,
  AndroidOptions androidOptions,
) {
  expect(iosOptions.accessibility, KeychainAccessibility.unlocked_this_device);
  expect(androidOptions.toMap(), const AndroidOptions().toMap());
}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  group('write', () {
    test('writes value with platform-specific options', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async {});

      await service.write(key: 'test_key', value: 'test_value');

      final options = verify(
        () => mockStorage.write(
          key: 'test_key',
          value: 'test_value',
          iOptions: captureAny(named: 'iOptions'),
          aOptions: captureAny(named: 'aOptions'),
        ),
      ).captured;
      _expectEstablishedOptions(
        options[0] as IOSOptions,
        options[1] as AndroidOptions,
      );
    });
  });

  group('read', () {
    test('reads value with platform-specific options', () async {
      when(
        () => mockStorage.read(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => 'stored_value');

      final result = await service.read(key: 'test_key');

      expect(result, 'stored_value');
      final options = verify(
        () => mockStorage.read(
          key: 'test_key',
          iOptions: captureAny(named: 'iOptions'),
          aOptions: captureAny(named: 'aOptions'),
        ),
      ).captured;
      _expectEstablishedOptions(
        options[0] as IOSOptions,
        options[1] as AndroidOptions,
      );
    });

    test('returns null for missing key', () async {
      when(
        () => mockStorage.read(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => null);

      final result = await service.read(key: 'missing_key');

      expect(result, isNull);
    });
  });

  group('delete', () {
    test('deletes key with platform-specific options', () async {
      when(
        () => mockStorage.delete(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async {});

      await service.delete(key: 'test_key');

      final options = verify(
        () => mockStorage.delete(
          key: 'test_key',
          iOptions: captureAny(named: 'iOptions'),
          aOptions: captureAny(named: 'aOptions'),
        ),
      ).captured;
      _expectEstablishedOptions(
        options[0] as IOSOptions,
        options[1] as AndroidOptions,
      );
    });
  });

  group('containsKey', () {
    test('returns true when key exists', () async {
      when(
        () => mockStorage.containsKey(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => true);

      expect(await service.containsKey(key: 'existing_key'), isTrue);
      final options = verify(
        () => mockStorage.containsKey(
          key: 'existing_key',
          iOptions: captureAny(named: 'iOptions'),
          aOptions: captureAny(named: 'aOptions'),
        ),
      ).captured;
      _expectEstablishedOptions(
        options[0] as IOSOptions,
        options[1] as AndroidOptions,
      );
    });

    test('returns false when key does not exist', () async {
      when(
        () => mockStorage.containsKey(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => false);

      expect(await service.containsKey(key: 'missing_key'), isFalse);
    });
  });

  group('clearAll', () {
    test('deletes only StorageKeys.allKeys, not other keys', () async {
      when(
        () => mockStorage.delete(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async {});

      await service.clearAll();

      for (final key in StorageKeys.allKeys) {
        verify(
          () => mockStorage.delete(
            key: key,
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
          ),
        ).called(1);
      }
      verifyNever(
        () => mockStorage.deleteAll(
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      );
    });

    test(
      'clearUserData deletes identity and lock material but preserves master key',
      () async {
        when(
          () => mockStorage.delete(
            key: any(named: 'key'),
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenAnswer((_) async {});

        await service.clearUserData();

        for (final key in StorageKeys.userDataKeys) {
          verify(
            () => mockStorage.delete(
              key: key,
              iOptions: any(named: 'iOptions'),
              aOptions: any(named: 'aOptions'),
            ),
          ).called(1);
        }
        verifyNever(
          () => mockStorage.delete(
            key: StorageKeys.masterKey,
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
          ),
        );
      },
    );
  });

  group('typed convenience methods', () {
    test('setDevicePrivateKey writes to correct key', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async {});

      await service.setDevicePrivateKey('base64_private_key');

      verify(
        () => mockStorage.write(
          key: StorageKeys.devicePrivateKey,
          value: 'base64_private_key',
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).called(1);
    });

    test('getDevicePrivateKey reads from correct key', () async {
      when(
        () => mockStorage.read(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => 'base64_private_key');

      final result = await service.getDevicePrivateKey();

      expect(result, 'base64_private_key');
    });

    test('getPinHash reads from correct key', () async {
      when(
        () => mockStorage.read(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => 'sha256_hash');

      final result = await service.getPinHash();

      expect(result, 'sha256_hash');
    });

    test('deletePinHash deletes the correct key', () async {
      when(
        () => mockStorage.delete(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async {});

      await service.deletePinHash();

      verify(
        () => mockStorage.delete(
          key: StorageKeys.pinHash,
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).called(1);
    });

    test('getDeviceId reads from correct key', () async {
      when(
        () => mockStorage.read(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((_) async => 'device_id_16ch');

      final result = await service.getDeviceId();

      expect(result, 'device_id_16ch');
    });
  });

  group('platform failure and layering contracts', () {
    test(
      'wraps every core CRUD platform failure without exposing a value',
      () async {
        final writeFailure = StateError('write failure');
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(writeFailure);
        await expectLater(
          () => service.write(key: 'test_key', value: 'secret-value'),
          throwsA(
            isA<SecureStorageException>()
                .having(
                  (error) => error.originalError,
                  'originalError',
                  writeFailure,
                )
                .having(
                  (error) => error.message,
                  'message',
                  isNot(contains('secret-value')),
                ),
          ),
        );

        final readFailure = StateError('read failure');
        when(
          () => mockStorage.read(
            key: any(named: 'key'),
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(readFailure);
        await expectLater(
          () => service.read(key: 'test_key'),
          throwsA(
            isA<SecureStorageException>().having(
              (error) => error.originalError,
              'originalError',
              readFailure,
            ),
          ),
        );

        final deleteFailure = StateError('delete failure');
        when(
          () => mockStorage.delete(
            key: any(named: 'key'),
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(deleteFailure);
        await expectLater(
          () => service.delete(key: 'test_key'),
          throwsA(
            isA<SecureStorageException>().having(
              (error) => error.originalError,
              'originalError',
              deleteFailure,
            ),
          ),
        );

        final containsFailure = StateError('contains failure');
        when(
          () => mockStorage.containsKey(
            key: any(named: 'key'),
            iOptions: any(named: 'iOptions'),
            aOptions: any(named: 'aOptions'),
          ),
        ).thenThrow(containsFailure);
        await expectLater(
          () => service.containsKey(key: 'test_key'),
          throwsA(
            isA<SecureStorageException>().having(
              (error) => error.originalError,
              'originalError',
              containsFailure,
            ),
          ),
        );
      },
    );

    test(
      'pins provider/service accessibility and allowed plugin boundaries',
      () {
        final providerSource = File(
          'lib/infrastructure/security/providers.dart',
        ).readAsStringSync();
        final serviceSource = File(
          'lib/infrastructure/security/secure_storage_service.dart',
        ).readAsStringSync();
        expect(
          providerSource,
          contains('KeychainAccessibility.unlocked_this_device'),
        );
        expect(
          serviceSource,
          contains('KeychainAccessibility.unlocked_this_device'),
        );

        final pluginImports = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (file) => file.readAsStringSync().contains(
                'package:flutter_secure_storage/flutter_secure_storage.dart',
              ),
            )
            .map((file) => file.path)
            .toList();
        expect(
          pluginImports,
          everyElement(
            anyOf(
              contains('lib/infrastructure/security/'),
              contains('lib/infrastructure/crypto/repositories/'),
            ),
          ),
        );
      },
    );
  });
}
