import '../models/app_settings.dart';

/// Abstract repository interface for app settings.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> setThemeMode(AppThemeMode themeMode);
  Future<void> setLanguage(String language);
  Future<void> setBiometricLock(bool enabled);
  Future<void> setNotificationsEnabled(bool enabled);
}
