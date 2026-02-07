import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/domain/models/app_settings.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';

/// SharedPreferences-backed implementation of [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _biometricLockKey = 'biometric_lock_enabled';

  @override
  Future<AppSettings> getSettings() async {
    return AppSettings(
      themeMode: _getThemeMode(),
      language: _prefs.getString(_languageKey) ?? 'ja',
      notificationsEnabled: _prefs.getBool(_notificationsKey) ?? true,
      biometricLockEnabled: _prefs.getBool(_biometricLockKey) ?? true,
    );
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await _prefs.setString(_themeModeKey, settings.themeMode.name);
    await _prefs.setString(_languageKey, settings.language);
    await _prefs.setBool(_notificationsKey, settings.notificationsEnabled);
    await _prefs.setBool(_biometricLockKey, settings.biometricLockEnabled);
  }

  @override
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    await _prefs.setString(_themeModeKey, themeMode.name);
  }

  @override
  Future<void> setLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  @override
  Future<void> setBiometricLock(bool enabled) async {
    await _prefs.setBool(_biometricLockKey, enabled);
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsKey, enabled);
  }

  AppThemeMode _getThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}
