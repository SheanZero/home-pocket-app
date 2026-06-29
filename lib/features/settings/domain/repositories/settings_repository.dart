import '../models/app_settings.dart';

/// Abstract repository interface for app settings.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> setThemeMode(AppThemeMode themeMode);
  Future<void> setLanguage(String language);
  Future<void> setBiometricLock(bool enabled);

  /// Persists the onboarding-completion flag (single source of truth for the
  /// onboarding gate). Plaintext SharedPreferences key, no Drift migration.
  Future<void> setOnboardingComplete(bool enabled);
  Future<void> setNotificationsEnabled(bool enabled);
  Future<void> setVoiceLanguage(String languageCode);

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
