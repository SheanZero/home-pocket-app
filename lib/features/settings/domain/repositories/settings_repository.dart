import '../models/app_settings.dart';

/// Abstract repository interface for app settings.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> setThemeMode(AppThemeMode themeMode);
  Future<void> setLanguage(String language);
  Future<void> setBiometricLock(bool enabled);

  /// Persists the app-lock master toggle (D-01/LOCK-01, default false).
  ///
  /// The new app lock reads ONLY this flag — never the legacy
  /// [setBiometricLock]/`biometricLockEnabled` (retired per D-02). Plaintext
  /// SharedPreferences key, no Drift migration.
  Future<void> setAppLockEnabled(bool enabled);

  /// Persists the biometric-unlock sub-toggle (D-01/LOCK-06, default false).
  ///
  /// Only meaningful while [setAppLockEnabled] is on. Plaintext
  /// SharedPreferences key, no Drift migration.
  Future<void> setBiometricUnlockEnabled(bool enabled);

  /// Persists the onboarding-completion flag (single source of truth for the
  /// onboarding gate). Plaintext SharedPreferences key, no Drift migration.
  Future<void> setOnboardingComplete(bool enabled);
  Future<void> setNotificationsEnabled(bool enabled);
  Future<void> setVoiceLanguage(String languageCode);

  /// Persists the on-device recognition auto-degradation policy (default true =
  /// auto-degrade allowed, current behavior).
  ///
  /// When false, an on-device recognition failure is surfaced instead of
  /// silently retrying with cloud recognition (privacy control, T-kfb-01).
  /// Plaintext SharedPreferences key, no Drift migration (mirror
  /// [setVoiceLanguage]).
  Future<void> setVoiceAllowOnDeviceFallback(bool enabled);

  /// Reads the configured monthly Joy target.
  ///
  /// Null means unconfigured and is encoded as key absence in persistence.
  Future<int?> getMonthlyJoyTarget();

  /// Persists the monthly Joy target consumed by recommendation UI/use cases.
  ///
  /// Passing null clears the persisted key rather than storing a sentinel.
  Future<void> setMonthlyJoyTarget(int? value);

  /// Reads the configured week start day (default: monday).
  Future<WeekStartDay> getWeekStartDay();

  /// Persists the week start day selection.
  Future<void> setWeekStartDay(WeekStartDay day);
}

/// Applies an old settings snapshot after a cross-store operation fails.
///
/// Settings persistence is not transactional with Drift. This journal-style
/// compensation therefore attempts every setting independently instead of
/// stopping at the first failed preference write. A caller must surface
/// [SettingsRestorationException] because the database may already have rolled
/// back while one or more preferences remain restored only partially.
extension SettingsRepositoryRestoreJournal on SettingsRepository {
  Future<void> restoreSettingsBestEffort(AppSettings settings) async {
    final failures = <Object>[];

    Future<void> restore(Future<void> Function() write) async {
      try {
        await write();
      } catch (error) {
        failures.add(error);
      }
    }

    await restore(() => setThemeMode(settings.themeMode));
    await restore(() => setLanguage(settings.language));
    await restore(() => setNotificationsEnabled(settings.notificationsEnabled));
    await restore(() => setBiometricLock(settings.biometricLockEnabled));
    await restore(() => setAppLockEnabled(settings.appLockEnabled));
    await restore(
      () => setBiometricUnlockEnabled(settings.biometricUnlockEnabled),
    );
    await restore(() => setOnboardingComplete(settings.onboardingComplete));
    await restore(() => setVoiceLanguage(settings.voiceLanguage));
    await restore(
      () => setVoiceAllowOnDeviceFallback(settings.voiceAllowOnDeviceFallback),
    );
    await restore(() => setMonthlyJoyTarget(settings.monthlyJoyTarget));
    await restore(() => setWeekStartDay(settings.weekStartDay));

    if (failures.isNotEmpty) {
      throw SettingsRestorationException(failures);
    }
  }
}

/// Signals that a settings compensation was attempted for every key but at
/// least one preference write still failed.
class SettingsRestorationException implements Exception {
  SettingsRestorationException(this.failures);

  final List<Object> failures;

  @override
  String toString() =>
      'Settings restoration failed for ${failures.length} preference write(s).';
}
