import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = SettingsRepositoryImpl(prefs: prefs);
  });

  group('getSettings', () {
    test('returns default settings when no values stored', () async {
      final settings = await repository.getSettings();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.language, 'ja');
      expect(settings.notificationsEnabled, true);
      expect(settings.biometricLockEnabled, true);
    });

    test('returns stored settings', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'language': 'en',
        'notifications_enabled': false,
        'biometric_lock_enabled': false,
      });
      final prefs = await SharedPreferences.getInstance();
      repository = SettingsRepositoryImpl(prefs: prefs);

      final settings = await repository.getSettings();

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.language, 'en');
      expect(settings.notificationsEnabled, false);
      expect(settings.biometricLockEnabled, false);
    });
  });

  group('updateSettings', () {
    test('persists all fields', () async {
      const settings = AppSettings(
        themeMode: AppThemeMode.light,
        language: 'zh',
        notificationsEnabled: false,
        biometricLockEnabled: false,
      );

      await repository.updateSettings(settings);
      final restored = await repository.getSettings();

      expect(restored, settings);
    });
  });

  group('setThemeMode', () {
    test('persists theme mode', () async {
      await repository.setThemeMode(AppThemeMode.dark);

      final settings = await repository.getSettings();
      expect(settings.themeMode, AppThemeMode.dark);
    });
  });

  group('setLanguage', () {
    test('persists language', () async {
      await repository.setLanguage('en');

      final settings = await repository.getSettings();
      expect(settings.language, 'en');
    });
  });

  group('setBiometricLock', () {
    test('persists biometric lock', () async {
      await repository.setBiometricLock(false);

      final settings = await repository.getSettings();
      expect(settings.biometricLockEnabled, false);
    });
  });

  group('setNotificationsEnabled', () {
    test('persists notifications enabled', () async {
      await repository.setNotificationsEnabled(false);

      final settings = await repository.getSettings();
      expect(settings.notificationsEnabled, false);
    });
  });
}
