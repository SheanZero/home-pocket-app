# Security Infrastructure (BASIC-002) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the security infrastructure layer (`lib/infrastructure/security/`) providing BiometricService (Face ID/Touch ID/Fingerprint), SecureStorageService (iOS Keychain/Android Keystore wrapper), and AuditLogger (security event audit logging with Drift).

**Architecture:** Clean Architecture 5-layer. All security services live in `lib/infrastructure/security/`. Models use Freezed for immutability. Providers use Riverpod code generation. AuditLogger requires a Drift table in `lib/data/tables/` and a minimal AppDatabase in `lib/data/`. Tests use `mocktail` for mocking platform dependencies.

**Tech Stack:** Flutter/Dart, `local_auth` (biometrics), `flutter_secure_storage` (already installed), `ulid` (unique IDs), `drift` (already installed), `freezed` (already installed), `riverpod` (already installed), `mocktail` (already installed)

---

## Current State

The project has a working crypto infrastructure (`lib/infrastructure/crypto/`) with Ed25519 key management, ChaCha20-Poly1305 field encryption, SHA-256 hash chain, and SQLCipher database encryption (65 tests passing). No security infrastructure exists yet. No `lib/data/tables/` or `lib/data/app_database.dart` exists yet.

## Spec References

- **BASIC-002:** `docs/arch/04-basic/BASIC-002_Security_Infrastructure.md` - Primary implementation spec
- **ARCH-003:** `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md` - Security architecture
- **BASIC-001:** `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md` - Crypto layer (reference pattern)

## Target Directory Structure

```
lib/infrastructure/security/
├── models/
│   ├── auth_result.dart              # Freezed union type for authentication results
│   └── audit_log_entry.dart          # Freezed model for audit log entries
├── biometric_service.dart            # Face ID / Touch ID / Fingerprint
├── secure_storage_service.dart       # iOS Keychain / Android Keystore wrapper
├── audit_logger.dart                 # Security event audit logging
└── providers.dart                    # Riverpod provider definitions

lib/data/
├── tables/
│   └── audit_logs_table.dart         # Drift table definition
└── app_database.dart                 # Minimal Drift database (audit_logs only for now)

test/infrastructure/security/
├── models/
│   ├── auth_result_test.dart
│   └── audit_log_entry_test.dart
├── biometric_service_test.dart
├── secure_storage_service_test.dart
└── audit_logger_test.dart
```

## Existing Patterns to Follow

- **Provider pattern:** See `lib/infrastructure/crypto/providers.dart` — centralized `@riverpod` providers with `ref.watch()` for DI
- **Freezed model pattern:** See `lib/infrastructure/crypto/models/device_key_pair.dart` — `@freezed abstract class` with `const factory`
- **Test pattern:** See `test/infrastructure/crypto/services/key_manager_test.dart` — `mocktail` mocks, `setUp`/`group`/`test` structure
- **Mock pattern:** `class MockX extends Mock implements X {}`

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add `local_auth` and `ulid` packages**

Add to `pubspec.yaml` under `dependencies:`:

```yaml
  # Biometric Authentication
  local_auth: ^2.3.0

  # Unique ID Generation
  ulid: ^2.0.0
```

**Step 2: Run pub get**

Run: `flutter pub get`
Expected: Dependencies resolve successfully, no conflicts.

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add local_auth and ulid dependencies for security infrastructure"
```

---

## Task 2: Create AuthResult Freezed Union Type

**Files:**
- Create: `lib/infrastructure/security/models/auth_result.dart`
- Test: `test/infrastructure/security/models/auth_result_test.dart`

**Step 1: Write the failing test**

Create `test/infrastructure/security/models/auth_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/models/auth_result.dart';

void main() {
  group('AuthResult', () {
    test('creates success variant', () {
      const result = AuthResult.success();
      result.when(
        success: () => expect(true, isTrue),
        failed: (_) => fail('should be success'),
        fallbackToPIN: () => fail('should be success'),
        tooManyAttempts: () => fail('should be success'),
        lockedOut: () => fail('should be success'),
        error: (_) => fail('should be success'),
      );
    });

    test('creates failed variant with attempt count', () {
      const result = AuthResult.failed(failedAttempts: 2);
      result.when(
        success: () => fail('should be failed'),
        failed: (attempts) => expect(attempts, 2),
        fallbackToPIN: () => fail('should be failed'),
        tooManyAttempts: () => fail('should be failed'),
        lockedOut: () => fail('should be failed'),
        error: (_) => fail('should be failed'),
      );
    });

    test('creates fallbackToPIN variant', () {
      const result = AuthResult.fallbackToPIN();
      result.when(
        success: () => fail('should be fallbackToPIN'),
        failed: (_) => fail('should be fallbackToPIN'),
        fallbackToPIN: () => expect(true, isTrue),
        tooManyAttempts: () => fail('should be fallbackToPIN'),
        lockedOut: () => fail('should be fallbackToPIN'),
        error: (_) => fail('should be fallbackToPIN'),
      );
    });

    test('creates tooManyAttempts variant', () {
      const result = AuthResult.tooManyAttempts();
      result.when(
        success: () => fail('should be tooManyAttempts'),
        failed: (_) => fail('should be tooManyAttempts'),
        fallbackToPIN: () => fail('should be tooManyAttempts'),
        tooManyAttempts: () => expect(true, isTrue),
        lockedOut: () => fail('should be tooManyAttempts'),
        error: (_) => fail('should be tooManyAttempts'),
      );
    });

    test('creates lockedOut variant', () {
      const result = AuthResult.lockedOut();
      result.when(
        success: () => fail('should be lockedOut'),
        failed: (_) => fail('should be lockedOut'),
        fallbackToPIN: () => fail('should be lockedOut'),
        tooManyAttempts: () => fail('should be lockedOut'),
        lockedOut: () => expect(true, isTrue),
        error: (_) => fail('should be lockedOut'),
      );
    });

    test('creates error variant with message', () {
      const result = AuthResult.error(message: 'Unknown biometric error');
      result.when(
        success: () => fail('should be error'),
        failed: (_) => fail('should be error'),
        fallbackToPIN: () => fail('should be error'),
        tooManyAttempts: () => fail('should be error'),
        lockedOut: () => fail('should be error'),
        error: (msg) => expect(msg, 'Unknown biometric error'),
      );
    });

    test('supports equality comparison', () {
      expect(const AuthResult.success(), const AuthResult.success());
      expect(
        const AuthResult.failed(failedAttempts: 1),
        const AuthResult.failed(failedAttempts: 1),
      );
      expect(
        const AuthResult.success(),
        isNot(const AuthResult.lockedOut()),
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/security/models/auth_result_test.dart`
Expected: FAIL — file not found / import error.

**Step 3: Write minimal implementation**

Create `lib/infrastructure/security/models/auth_result.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

/// Authentication result union type.
///
/// Used by [BiometricService] to represent all possible
/// outcomes of an authentication attempt. Callers use `when`
/// to exhaustively handle every case.
@freezed
sealed class AuthResult with _$AuthResult {
  /// Authentication succeeded.
  const factory AuthResult.success() = AuthResultSuccess;

  /// Authentication failed. [failedAttempts] is the cumulative count.
  const factory AuthResult.failed({required int failedAttempts}) =
      AuthResultFailed;

  /// Biometric not available — fall back to PIN authentication.
  const factory AuthResult.fallbackToPIN() = AuthResultFallbackToPIN;

  /// Too many consecutive failures (>= 3). Force PIN authentication.
  const factory AuthResult.tooManyAttempts() = AuthResultTooManyAttempts;

  /// Device biometric is locked by the OS.
  const factory AuthResult.lockedOut() = AuthResultLockedOut;

  /// An unexpected platform error occurred.
  const factory AuthResult.error({required String message}) = AuthResultError;
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `auth_result.freezed.dart` is generated successfully.

**Step 5: Run test to verify it passes**

Run: `flutter test test/infrastructure/security/models/auth_result_test.dart`
Expected: All 7 tests PASS.

**Step 6: Commit**

```bash
git add lib/infrastructure/security/models/auth_result.dart test/infrastructure/security/models/auth_result_test.dart
git commit -m "feat: add AuthResult Freezed union type for biometric authentication"
```

---

## Task 3: Create BiometricAvailability Enum and StorageKeys Constants

**Files:**
- Create: `lib/infrastructure/security/biometric_service.dart` (enums only, class comes later)
- Create: `lib/infrastructure/security/secure_storage_service.dart` (constants only, class comes later)

**Step 1: Create BiometricAvailability enum**

Create `lib/infrastructure/security/biometric_service.dart`:

```dart
import 'package:local_auth/local_auth.dart';

import 'models/auth_result.dart';

/// Biometric hardware availability status.
///
/// Android distinguishes between BIOMETRIC_STRONG (Class 3) and
/// BIOMETRIC_WEAK (Class 2). iOS Face ID and Touch ID are always strong.
enum BiometricAvailability {
  /// Face ID available (iOS) — always strong biometric.
  faceId,

  /// Fingerprint available (may be strong or weak on Android).
  fingerprint,

  /// Strong biometric available (Android Class 3).
  ///
  /// Class 3 biometrics meet the strictest security requirements:
  /// - Spoof acceptance rate < 7%
  /// - Must be hardware-backed
  strongBiometric,

  /// Weak biometric available (Android Class 2).
  ///
  /// Class 2 biometrics have relaxed security requirements.
  /// Use with caution for sensitive operations.
  weakBiometric,

  /// Generic biometric available (cannot determine specific type).
  generic,

  /// Device supports biometrics but user has not enrolled.
  notEnrolled,

  /// Device hardware does not support biometrics.
  notSupported,
}
```

> **Note:** We are writing the enum first. The full `BiometricService` class will be added in Task 5. This file will grow.

**Step 2: Create StorageKeys constants**

Create `lib/infrastructure/security/secure_storage_service.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized secure storage key constants.
///
/// All secure storage keys MUST be defined here.
/// Using hardcoded key strings anywhere else is prohibited.
///
/// NOTE: These keys must stay synchronized with:
/// - `MasterKeyRepositoryImpl._masterKeyStorageKey` (crypto infrastructure)
abstract final class StorageKeys {
  /// Ed25519 private key (Base64).
  static const String devicePrivateKey = 'device_private_key';

  /// Ed25519 public key (Base64).
  static const String devicePublicKey = 'device_public_key';

  /// Device ID — SHA-256(publicKey) first 16 chars.
  static const String deviceId = 'device_id';

  /// PIN SHA-256 hash.
  static const String pinHash = 'pin_hash';

  /// Recovery kit mnemonic SHA-256 hash.
  static const String recoveryKitHash = 'recovery_kit_hash';

  /// Master encryption key (256-bit).
  ///
  /// IMPORTANT: This key name MUST match `MasterKeyRepositoryImpl._masterKeyStorageKey`
  /// from `lib/infrastructure/crypto/repositories/master_key_repository_impl.dart`.
  /// Both use 'master_key' as the storage key.
  static const String masterKey = 'master_key';

  /// All known keys (used by [SecureStorageService.clearAll]).
  static const List<String> allKeys = [
    devicePrivateKey,
    devicePublicKey,
    deviceId,
    pinHash,
    recoveryKitHash,
    masterKey,
  ];
}
```

> **Note:** The full `SecureStorageService` class will be added in Task 4. This file will grow.

**Step 3: Verify no analyzer errors**

Run: `flutter analyze lib/infrastructure/security/`
Expected: No issues found.

**Step 4: Commit**

```bash
git add lib/infrastructure/security/biometric_service.dart lib/infrastructure/security/secure_storage_service.dart
git commit -m "feat: add BiometricAvailability enum and StorageKeys constants"
```

---

## Task 4: Implement SecureStorageService (TDD)

**Files:**
- Modify: `lib/infrastructure/security/secure_storage_service.dart`
- Test: `test/infrastructure/security/secure_storage_service_test.dart`

**Step 1: Write the failing tests**

Create `test/infrastructure/security/secure_storage_service_test.dart`:

```dart
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
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/security/secure_storage_service_test.dart`
Expected: FAIL — `SecureStorageService` class not defined.

**Step 3: Write minimal implementation**

Append the `SecureStorageService` class to `lib/infrastructure/security/secure_storage_service.dart` (after the `StorageKeys` class):

```dart
/// Exception thrown when secure storage operations fail.
///
/// Wraps platform-specific exceptions with consistent error handling.
class SecureStorageException implements Exception {
  SecureStorageException(this.message, [this.originalError]);

  /// Human-readable error message.
  final String message;

  /// Original platform exception, if available.
  final Object? originalError;

  @override
  String toString() => 'SecureStorageException: $message';
}

/// Unified secure storage service wrapping platform-specific APIs.
///
/// Provides iOS Keychain / Android Keystore access through
/// [FlutterSecureStorage] with centralized platform options.
///
/// Use [StorageKeys] constants for key names.
/// Use typed convenience methods (e.g. [getDevicePrivateKey])
/// for domain-specific operations.
///
/// All methods may throw [SecureStorageException] on platform errors.
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// iOS Keychain: unlocked + this device only (no iCloud sync).
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  );

  /// Android Keystore: encrypted shared preferences.
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // ── Core CRUD ──

  /// Write a key-value pair to secure storage.
  ///
  /// Throws [SecureStorageException] on platform error.
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(
        key: key,
        value: value,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw SecureStorageException('Failed to write key "$key"', e);
    }
  }

  /// Read a value from secure storage. Returns null if key does not exist.
  ///
  /// Throws [SecureStorageException] on platform error.
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw SecureStorageException('Failed to read key "$key"', e);
    }
  }

  /// Delete a key from secure storage. Silent if key does not exist.
  ///
  /// Throws [SecureStorageException] on platform error.
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw SecureStorageException('Failed to delete key "$key"', e);
    }
  }

  /// Check if a key exists in secure storage.
  ///
  /// Throws [SecureStorageException] on platform error.
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(
        key: key,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } catch (e) {
      throw SecureStorageException('Failed to check key "$key"', e);
    }
  }

  /// Delete all known application keys.
  ///
  /// Does NOT use [FlutterSecureStorage.deleteAll] to avoid
  /// deleting keys written by other SDKs.
  ///
  /// Throws [SecureStorageException] if any deletion fails.
  Future<void> clearAll() async {
    for (final key in StorageKeys.allKeys) {
      await delete(key: key);
    }
  }

  // ── Typed Convenience Methods ──

  Future<String?> getDevicePrivateKey() => read(key: StorageKeys.devicePrivateKey);
  Future<void> setDevicePrivateKey(String value) =>
      write(key: StorageKeys.devicePrivateKey, value: value);

  Future<String?> getDevicePublicKey() => read(key: StorageKeys.devicePublicKey);
  Future<void> setDevicePublicKey(String value) =>
      write(key: StorageKeys.devicePublicKey, value: value);

  Future<String?> getDeviceId() => read(key: StorageKeys.deviceId);
  Future<void> setDeviceId(String value) =>
      write(key: StorageKeys.deviceId, value: value);

  Future<String?> getPinHash() => read(key: StorageKeys.pinHash);
  Future<void> setPinHash(String value) =>
      write(key: StorageKeys.pinHash, value: value);
  Future<void> deletePinHash() => delete(key: StorageKeys.pinHash);

  Future<String?> getRecoveryKitHash() => read(key: StorageKeys.recoveryKitHash);

  Future<void> setRecoveryKitHash(String value) =>
      write(key: StorageKeys.recoveryKitHash, value: value);
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/security/secure_storage_service_test.dart`
Expected: All 11 tests PASS.

**Step 5: Run analyzer**

Run: `flutter analyze lib/infrastructure/security/secure_storage_service.dart`
Expected: No issues found.

**Step 6: Commit**

```bash
git add lib/infrastructure/security/secure_storage_service.dart test/infrastructure/security/secure_storage_service_test.dart
git commit -m "feat: implement SecureStorageService with TDD (11 tests)"
```

---

## Task 5: Implement BiometricService (TDD)

**Files:**
- Modify: `lib/infrastructure/security/biometric_service.dart`
- Test: `test/infrastructure/security/biometric_service_test.dart`

**Step 1: Write the failing tests**

Create `test/infrastructure/security/biometric_service_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/models/auth_result.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuthentication mockAuth;
  late BiometricService service;

  setUp(() {
    mockAuth = MockLocalAuthentication();
    service = BiometricService(localAuth: mockAuth);
  });

  group('checkAvailability', () {
    test('returns notSupported when canCheck and isSupported are both false', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.notSupported);
    });

    test('returns notEnrolled when supported but no biometrics enrolled', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.notEnrolled);
    });

    test('returns faceId when face biometric is available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.faceId);
    });

    test('returns fingerprint when fingerprint biometric is available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.fingerprint);
    });

    test('returns generic when only iris or other biometric is available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.iris]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.generic);
    });

    test('prioritizes faceId when both face and fingerprint are available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face, BiometricType.fingerprint]);

      final result = await service.checkAvailability();

      expect(result, BiometricAvailability.faceId);
    });
  });

  group('authenticate', () {
    void setupAvailableBiometrics() {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
    }

    test('returns success when biometric passes', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenAnswer((_) async => true);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.success());
    });

    test('returns failed with attempt count on first failure', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenAnswer((_) async => false);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.failed(failedAttempts: 1));
    });

    test('returns tooManyAttempts after 3 consecutive failures', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenAnswer((_) async => false);

      // Fail 3 times
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');

      // 4th attempt should be blocked
      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.tooManyAttempts());
    });

    test('resets failed count on success', () async {
      setupAvailableBiometrics();

      // Fail twice
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenAnswer((_) async => false);
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');

      // Then succeed
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenAnswer((_) async => true);
      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.success());

      // Fail again — count should be reset to 1, not 3
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenAnswer((_) async => false);
      final afterReset = await service.authenticate(reason: 'test');

      expect(afterReset, const AuthResult.failed(failedAttempts: 1));
    });

    test('returns fallbackToPIN when biometrics not supported', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.fallbackToPIN());
    });

    test('returns fallbackToPIN when biometrics not enrolled', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.fallbackToPIN());
    });

    test('returns lockedOut on PlatformException with lockedOut code', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenThrow(PlatformException(code: 'LockedOut'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.lockedOut());
    });

    test('returns lockedOut on permanentlyLockedOut', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenThrow(PlatformException(code: 'PermanentlyLockedOut'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.lockedOut());
    });

    test('returns fallbackToPIN on notAvailable exception', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenThrow(PlatformException(code: 'NotAvailable'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.fallbackToPIN());
    });

    test('returns error on unknown PlatformException', () async {
      setupAvailableBiometrics();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenThrow(PlatformException(code: 'UnknownError', message: 'something broke'));

      final result = await service.authenticate(reason: 'test');

      expect(result, const AuthResult.error(message: 'something broke'));
    });
  });

  group('resetFailedAttempts', () {
    test('allows biometric retry after manual reset', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      // Fail 3 times
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenAnswer((_) async => false);
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');
      await service.authenticate(reason: 'test');

      // Verify locked out
      final locked = await service.authenticate(reason: 'test');
      expect(locked, const AuthResult.tooManyAttempts());

      // Reset and succeed
      service.resetFailedAttempts();
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        ),
      ).thenAnswer((_) async => true);

      final result = await service.authenticate(reason: 'test');
      expect(result, const AuthResult.success());
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/security/biometric_service_test.dart`
Expected: FAIL — `BiometricService` class not defined.

**Step 3: Write minimal implementation**

Append the `BiometricService` class to `lib/infrastructure/security/biometric_service.dart` (after the enum):

```dart
/// Biometric authentication service wrapping platform APIs.
///
/// Encapsulates Face ID / Touch ID / Fingerprint authentication
/// with failure counting and lockout strategy.
class BiometricService {
  BiometricService({
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;
  int _failedAttempts = 0;

  /// Maximum consecutive failures before forcing PIN fallback.
  static const int maxFailedAttempts = 3;

  /// Check current device biometric availability.
  Future<BiometricAvailability> checkAvailability() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();

    if (!canCheck && !isSupported) {
      return BiometricAvailability.notSupported;
    }

    final available = await _localAuth.getAvailableBiometrics();

    if (available.isEmpty) {
      return BiometricAvailability.notEnrolled;
    }

    if (available.contains(BiometricType.face)) {
      return BiometricAvailability.faceId;
    }
    if (available.contains(BiometricType.fingerprint)) {
      return BiometricAvailability.fingerprint;
    }
    return BiometricAvailability.generic;
  }

  /// Execute biometric authentication.
  ///
  /// [reason] is displayed in the system authentication dialog.
  /// [biometricOnly] prevents device PIN fallback if true.
  Future<AuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    final availability = await checkAvailability();
    if (availability == BiometricAvailability.notSupported ||
        availability == BiometricAvailability.notEnrolled) {
      return const AuthResult.fallbackToPIN();
    }

    if (_failedAttempts >= maxFailedAttempts) {
      return const AuthResult.tooManyAttempts();
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          sensitiveTransaction: true,
        ),
        authMessages: const <AuthMessages>[],
      );

      if (authenticated) {
        _failedAttempts = 0;
        return const AuthResult.success();
      } else {
        _failedAttempts++;
        return AuthResult.failed(failedAttempts: _failedAttempts);
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  /// Manually reset the failure counter (e.g. after successful PIN auth).
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }

  AuthResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return const AuthResult.lockedOut();
      case 'NotAvailable':
      case 'NotEnrolled':
        return const AuthResult.fallbackToPIN();
      default:
        return AuthResult.error(message: e.message ?? 'Unknown biometric error');
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/security/biometric_service_test.dart`
Expected: All 14 tests PASS.

**Step 5: Run analyzer**

Run: `flutter analyze lib/infrastructure/security/biometric_service.dart`
Expected: No issues found.

**Step 6: Commit**

```bash
git add lib/infrastructure/security/biometric_service.dart test/infrastructure/security/biometric_service_test.dart
git commit -m "feat: implement BiometricService with TDD (14 tests)"
```

---

## Task 6: Create AuditEvent Enum and AuditLogEntry Model (TDD)

**Files:**
- Create: `lib/infrastructure/security/models/audit_log_entry.dart`
- Test: `test/infrastructure/security/models/audit_log_entry_test.dart`

**Step 1: Write the failing test**

Create `test/infrastructure/security/models/audit_log_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/models/audit_log_entry.dart';

void main() {
  group('AuditEvent', () {
    test('has all expected values', () {
      expect(AuditEvent.values, contains(AuditEvent.appLaunched));
      expect(AuditEvent.values, contains(AuditEvent.biometricAuthSuccess));
      expect(AuditEvent.values, contains(AuditEvent.biometricAuthFailed));
      expect(AuditEvent.values, contains(AuditEvent.pinAuthSuccess));
      expect(AuditEvent.values, contains(AuditEvent.pinAuthFailed));
      expect(AuditEvent.values, contains(AuditEvent.chainVerified));
      expect(AuditEvent.values, contains(AuditEvent.tamperDetected));
      expect(AuditEvent.values, contains(AuditEvent.keyGenerated));
      expect(AuditEvent.values, contains(AuditEvent.keyRotated));
      expect(AuditEvent.values, contains(AuditEvent.recoveryKitGenerated));
      expect(AuditEvent.values, contains(AuditEvent.keyRecovered));
    });

    test('enum name matches expected string', () {
      expect(AuditEvent.biometricAuthSuccess.name, 'biometricAuthSuccess');
      expect(AuditEvent.tamperDetected.name, 'tamperDetected');
    });
  });

  group('AuditLogEntry', () {
    test('creates instance with required fields', () {
      final now = DateTime(2026, 2, 6, 14, 30);
      final entry = AuditLogEntry(
        id: '01ARYZ6S41000000000000001',
        event: AuditEvent.biometricAuthSuccess,
        deviceId: 'test_device_id',
        timestamp: now,
      );

      expect(entry.id, '01ARYZ6S41000000000000001');
      expect(entry.event, AuditEvent.biometricAuthSuccess);
      expect(entry.deviceId, 'test_device_id');
      expect(entry.bookId, isNull);
      expect(entry.transactionId, isNull);
      expect(entry.details, isNull);
      expect(entry.timestamp, now);
    });

    test('creates instance with optional fields', () {
      final entry = AuditLogEntry(
        id: '01ARYZ6S41000000000000002',
        event: AuditEvent.tamperDetected,
        deviceId: 'test_device',
        bookId: 'book_001',
        transactionId: 'tx_42',
        details: '{"tamperedIds": ["tx_42"]}',
        timestamp: DateTime(2026, 2, 6),
      );

      expect(entry.bookId, 'book_001');
      expect(entry.transactionId, 'tx_42');
      expect(entry.details, '{"tamperedIds": ["tx_42"]}');
    });

    test('supports equality comparison', () {
      final now = DateTime(2026, 2, 6);
      final a = AuditLogEntry(
        id: 'id1',
        event: AuditEvent.appLaunched,
        deviceId: 'dev1',
        timestamp: now,
      );
      final b = AuditLogEntry(
        id: 'id1',
        event: AuditEvent.appLaunched,
        deviceId: 'dev1',
        timestamp: now,
      );

      expect(a, equals(b));
    });

    test('supports copyWith', () {
      final original = AuditLogEntry(
        id: 'id1',
        event: AuditEvent.appLaunched,
        deviceId: 'dev1',
        timestamp: DateTime(2026, 2, 6),
      );
      final copied = original.copyWith(event: AuditEvent.tamperDetected);

      expect(copied.id, 'id1');
      expect(copied.event, AuditEvent.tamperDetected);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/security/models/audit_log_entry_test.dart`
Expected: FAIL — file not found.

**Step 3: Write minimal implementation**

Create `lib/infrastructure/security/models/audit_log_entry.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log_entry.freezed.dart';

/// Security audit event types.
///
/// Every auditable action in the app has an entry here.
/// Add new events as needed; keep sorted by category.
enum AuditEvent {
  // ── App lifecycle ──
  appLaunched,
  databaseOpened,

  // ── Authentication ──
  biometricAuthSuccess,
  biometricAuthFailed,
  pinAuthSuccess,
  pinAuthFailed,

  // ── Integrity ──
  chainVerified,
  tamperDetected,

  // ── Key management ──
  keyGenerated,
  keyRotated,
  recoveryKitGenerated,
  keyRecovered,

  // ── Sync (Phase 3) ──
  syncStarted,
  syncCompleted,
  syncFailed,
  devicePaired,
  deviceUnpaired,

  // ── Data management ──
  backupExported,
  backupImported,
  securitySettingsChanged,
}

/// A single audit log entry.
///
/// Immutable record of a security-relevant event.
/// Stored in the `audit_logs` Drift table.
@freezed
sealed class AuditLogEntry with _$AuditLogEntry {
  const factory AuditLogEntry({
    /// ULID — time-sortable unique identifier.
    required String id,

    /// The type of security event.
    required AuditEvent event,

    /// Device that produced this event.
    required String deviceId,

    /// Associated book ID (optional).
    String? bookId,

    /// Associated transaction ID (optional).
    String? transactionId,

    /// Extra JSON details. MUST NOT contain keys, PINs, or amounts.
    String? details,

    /// When the event occurred.
    required DateTime timestamp,
  }) = _AuditLogEntry;
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `audit_log_entry.freezed.dart` generated successfully.

**Step 5: Run test to verify it passes**

Run: `flutter test test/infrastructure/security/models/audit_log_entry_test.dart`
Expected: All 5 tests PASS.

**Step 6: Commit**

```bash
git add lib/infrastructure/security/models/audit_log_entry.dart test/infrastructure/security/models/audit_log_entry_test.dart
git commit -m "feat: add AuditEvent enum and AuditLogEntry Freezed model (5 tests)"
```

---

## Task 7: Create AuditLogs Drift Table and Minimal AppDatabase

**Files:**
- Create: `lib/data/tables/audit_logs_table.dart`
- Create: `lib/data/app_database.dart`

> **Important:** The AuditLogger needs a Drift database. This task creates the minimal `AppDatabase` containing only the `audit_logs` table. Future tasks will expand this database with transaction, category, and book tables.

**Step 1: Create the Drift table definition**

Create `lib/data/tables/audit_logs_table.dart`:

```dart
import 'package:drift/drift.dart';

/// Audit log table — stores security event records.
///
/// See [AuditEvent] enum for valid event type values.
/// The `event` column stores enum `.name` strings.
class AuditLogs extends Table {
  /// ULID — time-sortable unique identifier.
  TextColumn get id => text()();

  /// Event type (AuditEvent.name string).
  TextColumn get event => text()();

  /// Device that produced this event.
  TextColumn get deviceId => text()();

  /// Associated book ID (optional).
  TextColumn get bookId => text().nullable()();

  /// Associated transaction ID (optional).
  TextColumn get transactionId => text().nullable()();

  /// Extra JSON details (optional). MUST NOT contain sensitive data.
  TextColumn get details => text().nullable()();

  /// When the event occurred.
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 2: Create the minimal AppDatabase**

Create `lib/data/app_database.dart`:

```dart
import 'package:drift/drift.dart';

import 'tables/audit_logs_table.dart';

part 'app_database.g.dart';

/// Main application database.
///
/// Currently contains only the audit_logs table.
/// Will be expanded with transaction, category, and book tables
/// in Phase 2 (MOD-001 Basic Accounting).
@DriftDatabase(tables: [AuditLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for testing.
  AppDatabase.forTesting()
      : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
```

**Step 3: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `app_database.g.dart` is generated successfully.

**Step 4: Run analyzer**

Run: `flutter analyze lib/data/`
Expected: No issues found.

**Step 5: Commit**

```bash
git add lib/data/tables/audit_logs_table.dart lib/data/app_database.dart
git commit -m "feat: add AuditLogs Drift table and minimal AppDatabase"
```

---

## Task 8: Implement AuditLogger (TDD)

**Files:**
- Create: `lib/infrastructure/security/audit_logger.dart`
- Test: `test/infrastructure/security/audit_logger_test.dart`

**Step 1: Write the failing tests**

Create `test/infrastructure/security/audit_logger_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/security/audit_logger.dart';
import 'package:home_pocket/infrastructure/security/models/audit_log_entry.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AppDatabase db;
  late MockSecureStorageService mockStorage;
  late AuditLogger logger;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockStorage = MockSecureStorageService();
    when(() => mockStorage.getDeviceId()).thenAnswer((_) async => 'test_device_id');
    logger = AuditLogger(database: db, storageService: mockStorage);
  });

  tearDown(() async {
    await db.close();
  });

  group('log', () {
    test('creates entry with correct fields', () async {
      await logger.log(event: AuditEvent.biometricAuthSuccess);

      final logs = await logger.getLogs();

      expect(logs.length, 1);
      expect(logs.first.event, AuditEvent.biometricAuthSuccess);
      expect(logs.first.deviceId, 'test_device_id');
      expect(logs.first.id, isNotEmpty);
      expect(logs.first.timestamp, isNotNull);
    });

    test('creates entry with optional bookId and details', () async {
      await logger.log(
        event: AuditEvent.tamperDetected,
        bookId: 'book_001',
        transactionId: 'tx_42',
        details: '{"tamperedIds": ["tx_42"]}',
      );

      final logs = await logger.getLogs();

      expect(logs.first.bookId, 'book_001');
      expect(logs.first.transactionId, 'tx_42');
      expect(logs.first.details, '{"tamperedIds": ["tx_42"]}');
    });

    test('uses "unknown" deviceId when storage returns null', () async {
      when(() => mockStorage.getDeviceId()).thenAnswer((_) async => null);

      await logger.log(event: AuditEvent.appLaunched);

      final logs = await logger.getLogs();
      expect(logs.first.deviceId, 'unknown');
    });

    test('generates unique IDs for each entry', () async {
      await logger.log(event: AuditEvent.appLaunched);
      await logger.log(event: AuditEvent.databaseOpened);

      final logs = await logger.getLogs();

      expect(logs[0].id, isNot(logs[1].id));
    });
  });

  group('getLogs', () {
    test('returns logs in descending timestamp order', () async {
      await logger.log(event: AuditEvent.appLaunched);
      await Future.delayed(const Duration(milliseconds: 10));
      await logger.log(event: AuditEvent.databaseOpened);

      final logs = await logger.getLogs();

      expect(logs.length, 2);
      expect(logs.first.event, AuditEvent.databaseOpened); // newest first
      expect(logs.last.event, AuditEvent.appLaunched);
    });

    test('filters by eventType', () async {
      await logger.log(event: AuditEvent.biometricAuthSuccess);
      await logger.log(event: AuditEvent.biometricAuthFailed);
      await logger.log(event: AuditEvent.pinAuthSuccess);

      final logs = await logger.getLogs(eventType: AuditEvent.biometricAuthFailed);

      expect(logs.length, 1);
      expect(logs.first.event, AuditEvent.biometricAuthFailed);
    });

    test('filters by bookId', () async {
      await logger.log(event: AuditEvent.chainVerified, bookId: 'book_A');
      await logger.log(event: AuditEvent.chainVerified, bookId: 'book_B');

      final logs = await logger.getLogs(bookId: 'book_A');

      expect(logs.length, 1);
      expect(logs.first.bookId, 'book_A');
    });

    test('filters by date range', () async {
      // We'll insert logs then filter by time range
      await logger.log(event: AuditEvent.appLaunched);
      final afterFirst = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 10));
      await logger.log(event: AuditEvent.databaseOpened);

      final logs = await logger.getLogs(startDate: afterFirst);

      expect(logs.length, 1);
      expect(logs.first.event, AuditEvent.databaseOpened);
    });

    test('respects limit parameter', () async {
      for (int i = 0; i < 5; i++) {
        await logger.log(event: AuditEvent.appLaunched);
      }

      final logs = await logger.getLogs(limit: 3);

      expect(logs.length, 3);
    });

    test('respects offset parameter', () async {
      for (int i = 0; i < 5; i++) {
        await logger.log(event: AuditEvent.appLaunched);
        await Future.delayed(const Duration(milliseconds: 5));
      }

      final allLogs = await logger.getLogs();
      final offsetLogs = await logger.getLogs(offset: 2, limit: 2);

      expect(offsetLogs.length, 2);
      expect(offsetLogs.first.id, allLogs[2].id);
    });
  });

  group('getLogCount', () {
    test('returns total count', () async {
      await logger.log(event: AuditEvent.appLaunched);
      await logger.log(event: AuditEvent.databaseOpened);
      await logger.log(event: AuditEvent.biometricAuthSuccess);

      final count = await logger.getLogCount();

      expect(count, 3);
    });

    test('returns filtered count', () async {
      await logger.log(event: AuditEvent.biometricAuthSuccess);
      await logger.log(event: AuditEvent.biometricAuthFailed);
      await logger.log(event: AuditEvent.biometricAuthFailed);

      final count = await logger.getLogCount(
        eventType: AuditEvent.biometricAuthFailed,
      );

      expect(count, 2);
    });
  });

  group('exportToCSV', () {
    test('generates valid CSV with headers', () async {
      await logger.log(
        event: AuditEvent.keyGenerated,
        details: '{"algorithm": "Ed25519"}',
      );

      final csv = await logger.exportToCSV();

      expect(csv, contains('id,event,deviceId,bookId,transactionId,details,timestamp'));
      expect(csv, contains('keyGenerated'));
      expect(csv, contains('test_device_id'));
      expect(csv, contains('Ed25519'));
    });

    test('escapes commas and quotes in details', () async {
      await logger.log(
        event: AuditEvent.appLaunched,
        details: 'value,with,"quotes"',
      );

      final csv = await logger.exportToCSV();

      // CSV escaping: wrap in quotes, double-escape inner quotes
      expect(csv, contains('"value,with,""quotes"""'));
    });

    test('filters by bookId', () async {
      await logger.log(event: AuditEvent.chainVerified, bookId: 'book_A');
      await logger.log(event: AuditEvent.chainVerified, bookId: 'book_B');

      final csv = await logger.exportToCSV(bookId: 'book_A');

      expect(csv, contains('book_A'));
      expect(csv, isNot(contains('book_B')));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/security/audit_logger_test.dart`
Expected: FAIL — `AuditLogger` class not defined.

**Step 3: Write minimal implementation**

Create `lib/infrastructure/security/audit_logger.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:ulid/ulid.dart';

import '../../data/app_database.dart';
import 'models/audit_log_entry.dart';
import 'secure_storage_service.dart';

/// Security event audit logger.
///
/// Records structured audit events to the `audit_logs` Drift table.
/// Provides query, filtering, and CSV export capabilities.
///
/// Security rules for the `details` field:
/// - ALLOWED: algorithm names, transaction IDs, counts, error types
/// - FORBIDDEN: encryption keys, plaintext amounts, PINs, mnemonics
class AuditLogger {
  AuditLogger({
    required AppDatabase database,
    required SecureStorageService storageService,
  })  : _database = database,
        _storageService = storageService;

  final AppDatabase _database;
  final SecureStorageService _storageService;

  /// Record an audit event.
  ///
  /// Automatically fills [id] (ULID), [deviceId], and [timestamp].
  Future<void> log({
    required AuditEvent event,
    String? bookId,
    String? transactionId,
    String? details,
  }) async {
    final deviceId = await _storageService.getDeviceId() ?? 'unknown';

    await _database.into(_database.auditLogs).insert(
          AuditLogsCompanion.insert(
            id: Ulid().toString(),
            event: event.name,
            deviceId: deviceId,
            bookId: Value(bookId),
            transactionId: Value(transactionId),
            details: Value(details),
            timestamp: DateTime.now(),
          ),
        );
  }

  /// Query audit logs with optional filters.
  ///
  /// Results are ordered newest-first. All filter parameters
  /// are AND-combined.
  Future<List<AuditLogEntry>> getLogs({
    String? bookId,
    AuditEvent? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final query = _database.select(_database.auditLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit, offset: offset);

    if (bookId != null) {
      query.where((t) => t.bookId.equals(bookId));
    }
    if (eventType != null) {
      query.where((t) => t.event.equals(eventType.name));
    }
    if (startDate != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.timestamp.isSmallerOrEqualValue(endDate));
    }

    final rows = await query.get();
    return rows.map(_rowToEntry).toList();
  }

  /// Count logs matching the given filters.
  Future<int> getLogCount({
    String? bookId,
    AuditEvent? eventType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final countExp = _database.auditLogs.id.count();
    final query = _database.selectOnly(_database.auditLogs)
      ..addColumns([countExp]);

    if (bookId != null) {
      query.where(_database.auditLogs.bookId.equals(bookId));
    }
    if (eventType != null) {
      query.where(_database.auditLogs.event.equals(eventType.name));
    }
    if (startDate != null) {
      query.where(_database.auditLogs.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(_database.auditLogs.timestamp.isSmallerOrEqualValue(endDate));
    }

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Export logs to CSV string.
  ///
  /// Returns the CSV content. The caller is responsible for writing
  /// to a file if needed.
  Future<String> exportToCSV({String? bookId}) async {
    final logs = await getLogs(bookId: bookId, limit: 999999);

    final buffer = StringBuffer();
    buffer.writeln('id,event,deviceId,bookId,transactionId,details,timestamp');

    for (final log in logs) {
      buffer.writeln([
        log.id,
        log.event.name,
        log.deviceId,
        log.bookId ?? '',
        log.transactionId ?? '',
        _escapeCSV(log.details ?? ''),
        log.timestamp.toIso8601String(),
      ].join(','));
    }

    return buffer.toString();
  }

  AuditLogEntry _rowToEntry(AuditLog row) {
    return AuditLogEntry(
      id: row.id,
      event: AuditEvent.values.firstWhere(
        (e) => e.name == row.event,
        orElse: () => AuditEvent.appLaunched,
      ),
      deviceId: row.deviceId,
      bookId: row.bookId,
      transactionId: row.transactionId,
      details: row.details,
      timestamp: row.timestamp,
    );
  }

  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/security/audit_logger_test.dart`
Expected: All 13 tests PASS.

**Step 5: Run analyzer**

Run: `flutter analyze lib/infrastructure/security/audit_logger.dart`
Expected: No issues found.

**Step 6: Commit**

```bash
git add lib/infrastructure/security/audit_logger.dart test/infrastructure/security/audit_logger_test.dart
git commit -m "feat: implement AuditLogger with TDD (13 tests)"
```

---

## Task 9: Create Riverpod Providers

**Files:**
- Create: `lib/infrastructure/security/providers.dart`

**Step 1: Create provider definitions**

Create `lib/infrastructure/security/providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'biometric_service.dart';
import 'secure_storage_service.dart';
import 'audit_logger.dart';
import '../../data/app_database.dart';

part 'providers.g.dart';

/// Biometric authentication service.
///
/// Uses `keepAlive: true` to ensure the service persists across
/// widget rebuilds, preserving the `_failedAttempts` counter state.
@Riverpod(keepAlive: true)
BiometricService biometricService(Ref ref) {
  return BiometricService();
}

/// Check biometric availability for the current device.
@riverpod
Future<BiometricAvailability> biometricAvailability(Ref ref) async {
  final service = ref.watch(biometricServiceProvider);
  return service.checkAvailability();
}

/// Secure storage service — iOS Keychain / Android Keystore wrapper.
@riverpod
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService();
}

/// Audit logger — depends on AppDatabase and SecureStorageService.
///
/// NOTE: This provider requires [appDatabaseProvider] to be defined
/// elsewhere (e.g. in app initialization). For now, it uses
/// constructor injection and should be wired during app startup.
@riverpod
AuditLogger auditLogger(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuditLogger(database: database, storageService: storageService);
}

/// AppDatabase provider - PLACEHOLDER.
///
/// This provider MUST be overridden during app initialization.
/// The placeholder throws to ensure it's properly configured before use.
///
/// ## How to Replace
///
/// In your `AppInitializer` or `main.dart`, override this provider:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // 1. Get master key repository
///   final masterKeyRepo = MasterKeyRepositoryImpl(secureStorage: secureStorage);
///
///   // 2. Initialize master key if needed  
///   if (!await masterKeyRepo.hasMasterKey()) {
///     await masterKeyRepo.initializeMasterKey();
///   }
///
///   // 3. Create encrypted database executor
///   final executor = await createEncryptedExecutor(masterKeyRepo);
///   final database = AppDatabase(executor);
///
///   // 4. Override the provider
///   runApp(
///     ProviderScope(
///       overrides: [appDatabaseProvider.overrideWithValue(database)],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
///
/// ## Dependencies
///
/// - `MasterKeyRepository` from `lib/infrastructure/crypto/repositories/`
/// - `createEncryptedExecutor` from `lib/infrastructure/crypto/database/`
@riverpod
AppDatabase appDatabase(Ref ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden during app initialization.\n'
    'See AppInitializer pattern in lib/main.dart or the docstring above.',
  );
}
```

**Step 2: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `providers.g.dart` generated successfully.

**Step 3: Run analyzer**

Run: `flutter analyze lib/infrastructure/security/providers.dart`
Expected: No issues found.

**Step 4: Commit**

```bash
git add lib/infrastructure/security/providers.dart
git commit -m "feat: add Riverpod providers for security infrastructure"
```

---

## Task 10: Final Verification and Cleanup

**Files:**
- All files in `lib/infrastructure/security/` and `test/infrastructure/security/`

**Step 1: Run all security infrastructure tests**

Run: `flutter test test/infrastructure/security/`
Expected: All tests PASS (7 + 11 + 14 + 5 + 13 = ~50 tests).

**Step 2: Run full project tests**

Run: `flutter test`
Expected: All existing crypto tests (65) + new security tests (~50) = ~115 tests PASS.

**Step 3: Run analyzer on entire project**

Run: `flutter analyze`
Expected: No issues found.

**Step 4: Format code**

Run: `dart format lib/infrastructure/security/ test/infrastructure/security/ lib/data/`
Expected: All files formatted.

**Step 5: Verify directory structure**

Run: `find lib/infrastructure/security -type f -name '*.dart' | sort`
Expected:
```
lib/infrastructure/security/audit_logger.dart
lib/infrastructure/security/biometric_service.dart
lib/infrastructure/security/models/auth_result.dart
lib/infrastructure/security/models/audit_log_entry.dart
lib/infrastructure/security/providers.dart
lib/infrastructure/security/secure_storage_service.dart
```

Run: `find lib/data -type f -name '*.dart' | sort`
Expected:
```
lib/data/app_database.dart
lib/data/tables/audit_logs_table.dart
```

**Step 6: Final commit**

```bash
git add -A
git commit -m "chore: format and verify security infrastructure (BASIC-002)"
```

---

## Summary

| Task | Component | Tests | Estimated Time |
|------|-----------|-------|---------------|
| 1 | Add dependencies | 0 | 2 min |
| 2 | AuthResult Freezed model | 7 | 5 min |
| 3 | Enums + StorageKeys | 0 | 3 min |
| 4 | SecureStorageService | 11 | 10 min |
| 5 | BiometricService | 14 | 15 min |
| 6 | AuditLogEntry model | 5 | 5 min |
| 7 | AuditLogs table + AppDatabase | 0 | 5 min |
| 8 | AuditLogger | 13 | 15 min |
| 9 | Riverpod providers | 0 | 5 min |
| 10 | Verification & cleanup | 0 | 5 min |
| **Total** | | **~50** | **~70 min** |

## Post-Implementation Notes

After BASIC-002 is complete, the following future tasks remain:

1. **Migrate crypto providers to use SecureStorageService** — Replace direct `FlutterSecureStorage` usage in `lib/infrastructure/crypto/providers.dart` with `SecureStorageService`
2. **Wire AppDatabase with encrypted executor** — Replace the placeholder `appDatabaseProvider` with real encrypted database initialization
3. **Add audit_logs table indices** — Add `TableIndex` definitions once Drift codegen supports them in the current setup
4. **Integrate AuditLogger into existing services** — Add `logger.log()` calls to KeyManager, BiometricService, etc.
