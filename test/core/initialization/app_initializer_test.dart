import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/initialization/app_initializer.dart';
import 'package:home_pocket/core/initialization/init_result.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:mocktail/mocktail.dart';

class _FakeMasterKeyRepository extends Mock implements MasterKeyRepository {}

class _FakeKeyRepository extends Mock implements KeyRepository {}

/// Build a ProviderContainerFactory with fake crypto repositories so no
/// platform channel (flutter_secure_storage) is ever invoked during tests.
ProviderContainerFactory _makeContainerFactory({
  required MasterKeyRepository masterKeyRepo,
  required KeyRepository keyRepo,
}) {
  return ({overrides = const []}) {
    return ProviderContainer(overrides: [
      masterKeyRepositoryProvider.overrideWithValue(masterKeyRepo),
      keyRepositoryProvider.overrideWithValue(keyRepo),
      ...overrides,
    ]);
  };
}

AppDatabaseFactory _successDatabaseFactory() {
  return (_) async => AppDatabase.forTesting();
}

AppDatabaseFactory _failingDatabaseFactory(Object error) {
  return (_) async => throw error;
}

SeedRunner _noopSeedRunner() => (_) async {};

SeedRunner _failingSeedRunner(Object error) => (_) async => throw error;

void main() {
  late _FakeMasterKeyRepository fakeMasterKeyRepo;
  late _FakeKeyRepository fakeKeyRepo;

  setUp(() {
    fakeMasterKeyRepo = _FakeMasterKeyRepository();
    fakeKeyRepo = _FakeKeyRepository();

    // Happy-path defaults
    when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async => true);
    when(() => fakeMasterKeyRepo.initializeMasterKey()).thenAnswer(
      (_) async {},
    );
    when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
    when(() => fakeKeyRepo.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => fakeKeyRepo.generateKeyPair()).thenAnswer(
      (_) async => DeviceKeyPair(
        deviceId: 'device-1',
        publicKey: 'pubkey',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  AppInitializer _makeInitializer({
    AppDatabaseFactory? databaseFactory,
    SeedRunner? seedRunner,
  }) {
    return AppInitializer(
      containerFactory: _makeContainerFactory(
        masterKeyRepo: fakeMasterKeyRepo,
        keyRepo: fakeKeyRepo,
      ),
      databaseFactory: databaseFactory ?? _successDatabaseFactory(),
      seedRunner: seedRunner ?? _noopSeedRunner(),
    );
  }

  group('AppInitializer — happy path', () {
    test('returns InitSuccess with a ProviderContainer', () async {
      final result = await _makeInitializer().initialize();

      expect(result, isA<InitSuccess>());
      (result as InitSuccess).container.dispose();
    });

    test('returned container has appDatabaseProvider overridden', () async {
      final result = await _makeInitializer().initialize();
      final container = (result as InitSuccess).container;
      addTearDown(container.dispose);

      expect(() => container.read(appDatabaseProvider), returnsNormally);
    });

    test('does NOT call initializeMasterKey when key already exists', () async {
      when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async => true);
      final result = await _makeInitializer().initialize();
      (result as InitSuccess).container.dispose();

      verifyNever(() => fakeMasterKeyRepo.initializeMasterKey());
    });

    test('calls initializeMasterKey when no key exists', () async {
      when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async => false);
      final result = await _makeInitializer().initialize();
      (result as InitSuccess).container.dispose();

      verify(() => fakeMasterKeyRepo.initializeMasterKey()).called(1);
    });

    test('does NOT call generateKeyPair when key pair already exists', () async {
      when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
      final result = await _makeInitializer().initialize();
      (result as InitSuccess).container.dispose();

      verifyNever(() => fakeKeyRepo.generateKeyPair());
    });

    test('calls generateKeyPair when no key pair exists', () async {
      when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => false);
      final result = await _makeInitializer().initialize();
      (result as InitSuccess).container.dispose();

      verify(() => fakeKeyRepo.generateKeyPair()).called(1);
    });

    test('calls seedRunner with the final container', () async {
      ProviderContainer? captured;
      final result = await AppInitializer(
        containerFactory: _makeContainerFactory(
          masterKeyRepo: fakeMasterKeyRepo,
          keyRepo: fakeKeyRepo,
        ),
        databaseFactory: _successDatabaseFactory(),
        seedRunner: (container) async {
          captured = container;
        },
      ).initialize();

      final success = result as InitSuccess;
      addTearDown(success.container.dispose);
      expect(captured, same(success.container));
    });
  });

  group('AppInitializer — masterKey failure', () {
    test('returns InitFailure(masterKey) when hasMasterKey throws', () async {
      when(() => fakeMasterKeyRepo.hasMasterKey()).thenThrow(
        Exception('secure storage unavailable'),
      );

      final result = await _makeInitializer().initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, equals(InitFailureType.masterKey));
    });

    test('returns InitFailure(masterKey) when initializeMasterKey throws',
        () async {
      when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async => false);
      when(() => fakeMasterKeyRepo.initializeMasterKey()).thenThrow(
        Exception('key generation failed'),
      );

      final result = await _makeInitializer().initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, equals(InitFailureType.masterKey));
    });

    test('returns InitFailure(masterKey) when getDeviceId returns null',
        () async {
      when(() => fakeKeyRepo.getDeviceId()).thenAnswer((_) async => null);

      final result = await _makeInitializer().initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, equals(InitFailureType.masterKey));
    });
  });

  group('AppInitializer — database failure', () {
    test('returns InitFailure(database) when databaseFactory throws', () async {
      final result = await _makeInitializer(
        databaseFactory: _failingDatabaseFactory(Exception('db open failed')),
      ).initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, equals(InitFailureType.database));
    });

    test('InitFailure(database) carries the thrown error', () async {
      final error = Exception('db corrupted');
      final result = await _makeInitializer(
        databaseFactory: _failingDatabaseFactory(error),
      ).initialize();

      expect((result as InitFailure).error, same(error));
      expect(result.stackTrace, isNotNull);
    });
  });

  group('AppInitializer — seed failure', () {
    test('returns InitFailure(seed) when seedRunner throws', () async {
      final result = await _makeInitializer(
        seedRunner: _failingSeedRunner(Exception('seed failed')),
      ).initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, equals(InitFailureType.seed));
    });

    test('InitFailure(seed) carries the original error', () async {
      final originalError = Exception('categories missing');
      final result = await _makeInitializer(
        seedRunner: _failingSeedRunner(originalError),
      ).initialize();

      final failure = result as InitFailure;
      expect(failure.error, same(originalError));
      expect(failure.stackTrace, isNotNull);
    });
  });
}
