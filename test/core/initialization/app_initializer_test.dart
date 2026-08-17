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
    return ProviderContainer(
      overrides: [
        masterKeyRepositoryProvider.overrideWithValue(masterKeyRepo),
        keyRepositoryProvider.overrideWithValue(keyRepo),
        ...overrides,
      ],
    );
  };
}

AppDatabaseFactory _successDatabaseFactory() {
  return (_) async => AppDatabase.forTesting();
}

AppDatabaseFactory _failingDatabaseFactory(Object error) {
  return (_) async => throw error;
}

SeedRunner _noopSeedRunner() => (_) async {};

SeedRunner _failingSeedRunner(Object error) =>
    (_) async => throw error;

void main() {
  late _FakeMasterKeyRepository fakeMasterKeyRepo;
  late _FakeKeyRepository fakeKeyRepo;

  setUp(() {
    fakeMasterKeyRepo = _FakeMasterKeyRepository();
    fakeKeyRepo = _FakeKeyRepository();

    // Happy-path defaults
    when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async => true);
    when(
      () => fakeMasterKeyRepo.initializeMasterKey(),
    ).thenAnswer((_) async {});
    when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
    when(() => fakeKeyRepo.clearKeys()).thenAnswer((_) async {});
    when(() => fakeKeyRepo.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => fakeKeyRepo.generateKeyPair()).thenAnswer(
      (_) async => DeviceKeyPair(
        deviceId: 'device-1',
        publicKey: 'pubkey',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  AppInitializer makeInitializer({
    AppDatabaseFactory? databaseFactory,
    SeedRunner? seedRunner,
    EncryptedDatabaseExists? databaseExists,
    PendingPrivacyWipeResumer? pendingPrivacyWipeResumer,
    NativeLibraryReadiness? ensureNativeLibrary,
  }) {
    return AppInitializer(
      containerFactory: _makeContainerFactory(
        masterKeyRepo: fakeMasterKeyRepo,
        keyRepo: fakeKeyRepo,
      ),
      databaseFactory: databaseFactory ?? _successDatabaseFactory(),
      databaseExists: databaseExists ?? (() async => true),
      seedRunner: seedRunner ?? _noopSeedRunner(),
      pendingPrivacyWipeResumer: pendingPrivacyWipeResumer,
      ensureNativeLibrary: ensureNativeLibrary ?? (() async {}),
    );
  }

  group('AppInitializer — happy path', () {
    test('returns InitSuccess with a ProviderContainer', () async {
      final result = await makeInitializer().initialize();

      expect(result, isA<InitSuccess>());
      (result as InitSuccess).container.dispose();
    });

    test('returned container has appDatabaseProvider overridden', () async {
      final result = await makeInitializer().initialize();
      final container = (result as InitSuccess).container;
      addTearDown(container.dispose);

      expect(() => container.read(appDatabaseProvider), returnsNormally);
    });

    test('does NOT call initializeMasterKey when key already exists', () async {
      when(
        () => fakeMasterKeyRepo.hasMasterKey(),
      ).thenAnswer((_) async => true);
      final result = await makeInitializer().initialize();
      (result as InitSuccess).container.dispose();

      verifyNever(() => fakeMasterKeyRepo.initializeMasterKey());
    });

    test('calls initializeMasterKey when no key exists', () async {
      when(
        () => fakeMasterKeyRepo.hasMasterKey(),
      ).thenAnswer((_) async => false);
      final result = await makeInitializer(
        databaseExists: () async => false,
      ).initialize();
      (result as InitSuccess).container.dispose();

      verify(() => fakeMasterKeyRepo.initializeMasterKey()).called(1);
    });

    test(
      'completes master-key initialization before database construction',
      () async {
        final calls = <String>[];
        when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async {
          calls.add('hasMasterKey');
          return false;
        });
        when(() => fakeMasterKeyRepo.initializeMasterKey()).thenAnswer((
          _,
        ) async {
          calls.add('initializeMasterKey');
        });

        final result = await makeInitializer(
          databaseExists: () async {
            calls.add('databaseExists');
            return false;
          },
          databaseFactory: (_) async {
            calls.add('databaseFactory');
            return AppDatabase.forTesting();
          },
        ).initialize();

        expect(result, isA<InitSuccess>());
        (result as InitSuccess).container.dispose();
        expect(
          calls,
          equals([
            'hasMasterKey',
            'databaseExists',
            'initializeMasterKey',
            'databaseFactory',
          ]),
        );
      },
    );

    test(
      'completes native-library readiness before key and database construction',
      () async {
        final calls = <String>[];
        when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async {
          calls.add('hasMasterKey');
          return true;
        });

        final result = await makeInitializer(
          ensureNativeLibrary: () async {
            calls.add('nativeLibrary');
          },
          databaseExists: () async {
            calls.add('databaseExists');
            return true;
          },
          databaseFactory: (_) async {
            calls.add('databaseFactory');
            return AppDatabase.forTesting();
          },
        ).initialize();

        expect(result, isA<InitSuccess>());
        (result as InitSuccess).container.dispose();
        expect(calls, [
          'nativeLibrary',
          'hasMasterKey',
          'databaseExists',
          'databaseFactory',
        ]);
      },
    );

    test(
      'replaces a retained device identity before creating a fresh database',
      () async {
        final calls = <String>[];
        when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async {
          calls.add('hasKeyPair');
          return true;
        });
        when(() => fakeKeyRepo.clearKeys()).thenAnswer((_) async {
          calls.add('clearKeys');
        });
        when(() => fakeKeyRepo.generateKeyPair()).thenAnswer((_) async {
          calls.add('generateKeyPair');
          return DeviceKeyPair(
            deviceId: 'device-2',
            publicKey: 'pubkey-2',
            createdAt: DateTime(2026, 8, 17),
          );
        });
        when(
          () => fakeKeyRepo.getDeviceId(),
        ).thenAnswer((_) async => 'device-2');

        final result = await makeInitializer(
          databaseExists: () async {
            calls.add('databaseExists');
            return false;
          },
          databaseFactory: (_) async {
            calls.add('databaseFactory');
            return AppDatabase.forTesting();
          },
        ).initialize();

        expect(result, isA<InitSuccess>());
        (result as InitSuccess).container.dispose();
        expect(
          calls,
          containsAllInOrder([
            'databaseExists',
            'hasKeyPair',
            'clearKeys',
            'generateKeyPair',
            'databaseFactory',
          ]),
        );
        verify(() => fakeKeyRepo.clearKeys()).called(1);
        verify(() => fakeKeyRepo.generateKeyPair()).called(1);
      },
    );

    test('does not clear identity when the database already exists', () async {
      final result = await makeInitializer(
        databaseExists: () async => true,
      ).initialize();

      expect(result, isA<InitSuccess>());
      (result as InitSuccess).container.dispose();
      verifyNever(() => fakeKeyRepo.clearKeys());
      verifyNever(() => fakeKeyRepo.generateKeyPair());
    });

    test(
      'fresh first launch generates identity without clearing keys',
      () async {
        when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => false);

        final result = await makeInitializer(
          databaseExists: () async => false,
        ).initialize();

        expect(result, isA<InitSuccess>());
        (result as InitSuccess).container.dispose();
        verifyNever(() => fakeKeyRepo.clearKeys());
        verify(() => fakeKeyRepo.generateKeyPair()).called(1);
      },
    );

    test(
      'does not create a fresh database when replacement identity fails',
      () async {
        when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
        when(
          () => fakeKeyRepo.generateKeyPair(),
        ).thenThrow(StateError('secure storage write failed'));
        var databaseFactoryCalled = false;

        final result = await makeInitializer(
          databaseExists: () async => false,
          databaseFactory: (_) async {
            databaseFactoryCalled = true;
            return AppDatabase.forTesting();
          },
        ).initialize();

        expect(result, isA<InitFailure>());
        expect((result as InitFailure).type, InitFailureType.masterKey);
        expect(databaseFactoryCalled, isFalse);
        verify(() => fakeKeyRepo.clearKeys()).called(1);
      },
    );

    test(
      'does NOT call generateKeyPair when key pair already exists',
      () async {
        when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
        final result = await makeInitializer().initialize();
        (result as InitSuccess).container.dispose();

        verifyNever(() => fakeKeyRepo.generateKeyPair());
      },
    );

    test('calls generateKeyPair when no key pair exists', () async {
      when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => false);
      final result = await makeInitializer().initialize();
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
        databaseExists: () async => true,
        seedRunner: (container) async {
          captured = container;
        },
        ensureNativeLibrary: () async {},
      ).initialize();

      final success = result as InitSuccess;
      addTearDown(success.container.dispose);
      expect(captured, same(success.container));
    });

    test(
      'resumes pending wipe after database opens but before identity and seed',
      () async {
        final calls = <String>[];
        when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async {
          calls.add('identity');
          return true;
        });

        final result = await makeInitializer(
          databaseFactory: (_) async {
            calls.add('database');
            return AppDatabase.forTesting();
          },
          pendingPrivacyWipeResumer: (container) async {
            expect(() => container.read(appDatabaseProvider), returnsNormally);
            calls.add('resume');
          },
          seedRunner: (_) async => calls.add('seed'),
        ).initialize();

        expect(result, isA<InitSuccess>());
        (result as InitSuccess).container.dispose();
        expect(calls, ['database', 'resume', 'identity', 'seed']);
      },
    );

    test(
      'pending wipe failure stops identity generation and seeding',
      () async {
        var seeded = false;
        final result = await makeInitializer(
          pendingPrivacyWipeResumer: (_) async {
            throw StateError('corrupt privacy wipe journal');
          },
          seedRunner: (_) async => seeded = true,
        ).initialize();

        expect(result, isA<InitFailure>());
        expect((result as InitFailure).type, InitFailureType.privacyWipe);
        verifyNever(() => fakeKeyRepo.hasKeyPair());
        verifyNever(() => fakeKeyRepo.generateKeyPair());
        expect(seeded, isFalse);
      },
    );
  });

  group('AppInitializer — missing key with existing data guard', () {
    test(
      'checks native readiness before rejecting missing key with existing data',
      () async {
        final calls = <String>[];
        when(() => fakeMasterKeyRepo.hasMasterKey()).thenAnswer((_) async {
          calls.add('hasMasterKey');
          return false;
        });

        final result = await makeInitializer(
          ensureNativeLibrary: () async {
            calls.add('nativeLibrary');
          },
          databaseExists: () async {
            calls.add('databaseExists');
            return true;
          },
          databaseFactory: (_) async {
            calls.add('databaseFactory');
            return AppDatabase.forTesting();
          },
        ).initialize();

        expect(
          (result as InitFailure).type,
          InitFailureType.masterKeyMissingWithData,
        );
        expect(calls, ['nativeLibrary', 'hasMasterKey', 'databaseExists']);
        verifyNever(() => fakeMasterKeyRepo.initializeMasterKey());
      },
    );

    test(
      'does NOT mint a new key when an encrypted DB already exists',
      () async {
        when(
          () => fakeMasterKeyRepo.hasMasterKey(),
        ).thenAnswer((_) async => false);

        final result = await makeInitializer(
          databaseExists: () async => true,
        ).initialize();

        expect(result, isA<InitFailure>());
        expect(
          (result as InitFailure).type,
          equals(InitFailureType.masterKeyMissingWithData),
        );
        verifyNever(() => fakeMasterKeyRepo.initializeMasterKey());
      },
    );

    test(
      'does not construct the database when existing data has no key',
      () async {
        when(
          () => fakeMasterKeyRepo.hasMasterKey(),
        ).thenAnswer((_) async => false);
        var databaseFactoryCalled = false;

        final result = await makeInitializer(
          databaseExists: () async => true,
          databaseFactory: (_) async {
            databaseFactoryCalled = true;
            return AppDatabase.forTesting();
          },
        ).initialize();

        expect(
          (result as InitFailure).type,
          InitFailureType.masterKeyMissingWithData,
        );
        expect(databaseFactoryCalled, isFalse);
        verifyNever(() => fakeMasterKeyRepo.initializeMasterKey());
        verifyNever(() => fakeKeyRepo.hasKeyPair());
      },
    );

    test(
      'InitFailure(masterKeyMissingWithData) carries the guard error',
      () async {
        when(
          () => fakeMasterKeyRepo.hasMasterKey(),
        ).thenAnswer((_) async => false);

        final result = await makeInitializer(
          databaseExists: () async => true,
        ).initialize();

        expect(
          (result as InitFailure).error,
          isA<MasterKeyMissingWithExistingDataError>(),
        );
      },
    );

    test(
      'still mints a key on a genuine first launch (no key, no DB)',
      () async {
        when(
          () => fakeMasterKeyRepo.hasMasterKey(),
        ).thenAnswer((_) async => false);

        final result = await makeInitializer(
          databaseExists: () async => false,
        ).initialize();

        expect(result, isA<InitSuccess>());
        (result as InitSuccess).container.dispose();
        verify(() => fakeMasterKeyRepo.initializeMasterKey()).called(1);
      },
    );
  });

  group('AppInitializer — masterKey failure', () {
    test('returns InitFailure(masterKey) when hasMasterKey throws', () async {
      when(
        () => fakeMasterKeyRepo.hasMasterKey(),
      ).thenThrow(Exception('secure storage unavailable'));

      final result = await makeInitializer().initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, equals(InitFailureType.masterKey));
    });

    test(
      'does not construct the database after a master-key read failure',
      () async {
        when(
          () => fakeMasterKeyRepo.hasMasterKey(),
        ).thenThrow(Exception('secure storage unavailable'));
        var databaseFactoryCalled = false;

        final result = await makeInitializer(
          databaseFactory: (_) async {
            databaseFactoryCalled = true;
            return AppDatabase.forTesting();
          },
        ).initialize();

        expect((result as InitFailure).type, InitFailureType.masterKey);
        expect(databaseFactoryCalled, isFalse);
        verifyNever(() => fakeKeyRepo.hasKeyPair());
      },
    );

    test(
      'returns InitFailure(masterKey) when initializeMasterKey throws',
      () async {
        when(
          () => fakeMasterKeyRepo.hasMasterKey(),
        ).thenAnswer((_) async => false);
        when(
          () => fakeMasterKeyRepo.initializeMasterKey(),
        ).thenThrow(Exception('key generation failed'));

        final result = await makeInitializer(
          databaseExists: () async => false,
        ).initialize();

        expect(result, isA<InitFailure>());
        expect((result as InitFailure).type, equals(InitFailureType.masterKey));
      },
    );

    test(
      'returns InitFailure(masterKey) when getDeviceId returns null',
      () async {
        when(() => fakeKeyRepo.getDeviceId()).thenAnswer((_) async => null);

        final result = await makeInitializer().initialize();

        expect(result, isA<InitFailure>());
        expect((result as InitFailure).type, equals(InitFailureType.masterKey));
      },
    );
  });

  group('AppInitializer — native library failure', () {
    test('fails closed before provider, key, or database access', () async {
      final calls = <String>[];
      final initializer = AppInitializer(
        containerFactory: ({overrides = const []}) {
          calls.add('containerFactory');
          return _makeContainerFactory(
            masterKeyRepo: fakeMasterKeyRepo,
            keyRepo: fakeKeyRepo,
          )(overrides: overrides);
        },
        databaseFactory: (_) async {
          calls.add('databaseFactory');
          return AppDatabase.forTesting();
        },
        databaseExists: () async {
          calls.add('databaseExists');
          return false;
        },
        seedRunner: _noopSeedRunner(),
        ensureNativeLibrary: () async {
          calls.add('nativeLibrary');
          throw StateError('selected native library unavailable');
        },
      );

      final result = await initializer.initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, InitFailureType.database);
      expect(calls, ['nativeLibrary']);
      verifyNever(() => fakeMasterKeyRepo.hasMasterKey());
      verifyNever(() => fakeMasterKeyRepo.initializeMasterKey());
    });
  });

  group('AppInitializer — database failure', () {
    test('returns InitFailure(database) when databaseFactory throws', () async {
      final result = await makeInitializer(
        databaseFactory: _failingDatabaseFactory(Exception('db open failed')),
      ).initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, equals(InitFailureType.database));
    });

    test('InitFailure(database) carries the thrown error', () async {
      final error = Exception('db corrupted');
      final result = await makeInitializer(
        databaseFactory: _failingDatabaseFactory(error),
      ).initialize();

      expect((result as InitFailure).error, same(error));
      expect(result.stackTrace, isNotNull);
    });
  });

  group('AppInitializer — seed failure', () {
    test('returns InitFailure(seed) when seedRunner throws', () async {
      final result = await makeInitializer(
        seedRunner: _failingSeedRunner(Exception('seed failed')),
      ).initialize();

      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, equals(InitFailureType.seed));
    });

    test('InitFailure(seed) carries the original error', () async {
      final originalError = Exception('categories missing');
      final result = await makeInitializer(
        seedRunner: _failingSeedRunner(originalError),
      ).initialize();

      final failure = result as InitFailure;
      expect(failure.error, same(originalError));
      expect(failure.stackTrace, isNotNull);
    });
  });
}
