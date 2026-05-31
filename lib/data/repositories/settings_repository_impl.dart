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
  static const String _voiceLanguageKey = 'voice_language';
  static const String _monthlyJoyTargetKey = 'monthly_joy_target';
  static const String _weekStartDayKey = 'week_start_day';

  @override
  Future<AppSettings> getSettings() async {
    return AppSettings(
      themeMode: _getThemeMode(),
      language: _prefs.getString(_languageKey) ?? 'system',
      notificationsEnabled: _prefs.getBool(_notificationsKey) ?? true,
      biometricLockEnabled: _prefs.getBool(_biometricLockKey) ?? true,
      voiceLanguage: _prefs.getString(_voiceLanguageKey) ?? 'zh',
      monthlyJoyTarget: _prefs.getInt(_monthlyJoyTargetKey),
      weekStartDay: _getWeekStartDay(),
    );
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await _prefs.setString(_themeModeKey, settings.themeMode.name);
    await _prefs.setString(_languageKey, settings.language);
    await _prefs.setBool(_notificationsKey, settings.notificationsEnabled);
    await _prefs.setBool(_biometricLockKey, settings.biometricLockEnabled);
    await _prefs.setString(_voiceLanguageKey, settings.voiceLanguage);
    await _prefs.setString(_weekStartDayKey, settings.weekStartDay.name);
    if (settings.monthlyJoyTarget == null) {
      await _prefs.remove(_monthlyJoyTargetKey);
    } else {
      await _prefs.setInt(_monthlyJoyTargetKey, settings.monthlyJoyTarget!);
    }
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

  @override
  Future<void> setVoiceLanguage(String languageCode) async {
    await _prefs.setString(_voiceLanguageKey, languageCode);
  }

  @override
  Future<int?> getMonthlyJoyTarget() async {
    return _prefs.getInt(_monthlyJoyTargetKey);
  }

  @override
  Future<void> setMonthlyJoyTarget(int? value) async {
    if (value == null) {
      await _prefs.remove(_monthlyJoyTargetKey);
    } else {
      await _prefs.setInt(_monthlyJoyTargetKey, value);
    }
  }

  @override
  Future<WeekStartDay> getWeekStartDay() async {
    return _getWeekStartDay();
  }

  @override
  Future<void> setWeekStartDay(WeekStartDay day) async {
    await _prefs.setString(_weekStartDayKey, day.name);
  }

  AppThemeMode _getThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  /// T-oqn-01 mitigation: malformed persisted value falls back to monday default.
  WeekStartDay _getWeekStartDay() {
    final v = _prefs.getString(_weekStartDayKey);
    return WeekStartDay.values.firstWhere(
      (d) => d.name == v,
      orElse: () => WeekStartDay.monday,
    );
  }
}
