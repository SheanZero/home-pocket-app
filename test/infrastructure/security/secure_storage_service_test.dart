import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

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

      verify(
        () => mockStorage.write(
          key: 'test_key',
          value: 'test_value',
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).called(1);
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

      verify(
        () => mockStorage.delete(
          key: 'test_key',
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).called(1);
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
}
