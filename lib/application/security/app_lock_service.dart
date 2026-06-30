import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../infrastructure/security/biometric_service.dart';
import '../../infrastructure/security/models/auth_result.dart';
import '../../infrastructure/security/pin_kdf.dart' as pin_kdf;
import '../../infrastructure/security/secure_storage_service.dart';

/// Application-layer single source of truth for the app-lock business logic
/// (LOCK-01 / LOCK-06).
///
/// The cold-start gate (Plan 11), lifecycle observer, lock screen (Plan 09), and
/// Settings security section (Plan 10) ALL route their lock decisions and PIN
/// operations through this one service so they can never diverge.
///
/// Plain constructor-injected service (mirrors [BiometricService]) — no Riverpod
/// inside. The PIN secret (Argon2id PHC string) lives ONLY in the keychain slot
/// via [SecureStorageService]; the boolean toggles live in [SettingsRepository]
/// (SharedPreferences). Plaintext PINs are never stored, logged, or compared.
class AppLockService {
  AppLockService({
    required SettingsRepository settingsRepository,
    required SecureStorageService secureStorage,
    required BiometricService biometricService,
  })  : _settings = settingsRepository,
        _secureStorage = secureStorage,
        _biometric = biometricService;

  final SettingsRepository _settings;
  final SecureStorageService _secureStorage;
  final BiometricService _biometric;

  /// D-01 single source of truth: the lock is effective ONLY when the master
  /// toggle is on AND a PIN hash exists. No PIN => never lock (T-55-15), so a
  /// half-configured state can never strand the user behind a lock they cannot
  /// satisfy.
  Future<bool> isLockEffective() async {
    final settings = await _settings.getSettings();
    if (!settings.appLockEnabled) return false;
    final pinHash = await _secureStorage.getPinHash();
    return pinHash != null;
  }

  /// LOCK-06: derive a fresh salted Argon2id PHC for [pin] off-isolate and
  /// persist it to the keychain slot. Overwrites any prior hash.
  Future<void> setPin(String pin) async {
    final phc = await pin_kdf.derivePinPhc(pin);
    await _secureStorage.setPinHash(phc);
  }

  /// LOCK-06: verify [pin] against the stored PHC by re-deriving with the stored
  /// salt and comparing in constant time (delegated to [pin_kdf.verifyPin]).
  /// Returns false — never throws — when no PIN is stored or the hash is garbage.
  Future<bool> verifyPin(String pin) async {
    final phc = await _secureStorage.getPinHash();
    if (phc == null) return false;
    return pin_kdf.verifyPin(pin, phc);
  }

  /// D-05 re-auth primitive used before disabling / changing the PIN (Plan 10).
  ///
  /// Tries biometric ONLY when the user has enabled biometric unlock; any
  /// non-success outcome (fallback, failure, lockout) returns false so the
  /// caller falls back to explicit PIN entry. When biometric unlock is off,
  /// returns false WITHOUT invoking the platform dialog.
  Future<bool> reauth() async {
    final settings = await _settings.getSettings();
    if (!settings.biometricUnlockEnabled) return false;
    final result = await _biometric.authenticate(
      reason: 'Confirm it\'s you to change app lock settings',
    );
    return result is AuthResultSuccess;
  }

  /// Disable the lock: persist the master toggle off AND delete the stored PIN
  /// hash so a stale hash can never silently re-arm the lock (T-55-16).
  Future<void> disableLock() async {
    await _settings.setAppLockEnabled(false);
    await _secureStorage.deletePinHash();
  }

  /// Enable the lock. Called ONLY after [setPin] succeeds — Plan 10 enforces the
  /// "never enable without a PIN" ordering (LOCK-06).
  Future<void> enableLock() async {
    await _settings.setAppLockEnabled(true);
  }
}
