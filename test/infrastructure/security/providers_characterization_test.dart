// Characterization test: locks lib/infrastructure/security/providers.dart
// PRE-Plan-03-02 behavior. Plan 03-02 Task 3 replaces UnimplementedError
// with a diagnostic StateError; that's a documented behavior change for
// CRIT-03 closure, NOT a regression — Plan 03-02 ships
// test/infrastructure/security/providers_test.dart which supersedes
// the StateError assertion below.
//
// The remaining behaviors locked here (override pass-through, auditLogger
// wiring) MUST stay GREEN through Plan 03-02 — they are the contracts
// the auditLogger and other consumers depend on.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/security/audit_logger.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class _FakeSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeBiometricService extends Mock implements BiometricService {}

void main() {
  group('appDatabaseProvider current behavior (PRE-Plan-03-02)', () {
    test('throws when read without override (current placeholder)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(appDatabaseProvider),
        throwsA(
          // BEFORE Plan 03-02: UnimplementedError
          // AFTER Plan 03-02: StateError (Plan 03-02 Task 3 replaces this assertion)
          anyOf(
            isA<UnimplementedError>(),
            isA<StateError>(),
          ),
        ),
      );
    });

    test('returns the supplied AppDatabase when overrideWithValue applied', () {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      expect(identical(container.read(appDatabaseProvider), db), isTrue);
    });
  });

  group('auditLoggerProvider wiring', () {
    test('resolves when appDatabaseProvider and flutterSecureStorageProvider overridden', () {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final fakeStorage = _FakeSecureStorage();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          flutterSecureStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      final logger = container.read(auditLoggerProvider);
      expect(logger, isA<AuditLogger>());
    });
  });

  group('secureStorageServiceProvider wiring', () {
    test('resolves to a SecureStorageService when storage overridden', () {
      final fakeStorage = _FakeSecureStorage();
      final container = ProviderContainer(
        overrides: [
          flutterSecureStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(secureStorageServiceProvider),
        isA<SecureStorageService>(),
      );
    });

    test('returns same SecureStorageService on repeated reads (provider caching)', () {
      final fakeStorage = _FakeSecureStorage();
      final container = ProviderContainer(
        overrides: [
          flutterSecureStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      final s1 = container.read(secureStorageServiceProvider);
      final s2 = container.read(secureStorageServiceProvider);
      // Both reads should be the same provider instance
      expect(identical(s1, s2), isTrue);
    });
  });

  group('biometricServiceProvider wiring', () {
    test('resolves to a BiometricService instance by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(biometricServiceProvider), isA<BiometricService>());
    });
  });

  group('biometricAvailabilityProvider wiring', () {
    test('resolves with availability when biometricServiceProvider overridden', () async {
      final fakeBiometric = _FakeBiometricService();
      when(() => fakeBiometric.checkAvailability()).thenAnswer(
        (_) async => BiometricAvailability.notSupported,
      );
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(fakeBiometric),
        ],
      );
      addTearDown(container.dispose);

      final availability = await container.read(biometricAvailabilityProvider.future);
      expect(availability, equals(BiometricAvailability.notSupported));
    });
  });
}
