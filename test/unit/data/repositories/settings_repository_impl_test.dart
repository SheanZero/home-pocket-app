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
      expect(settings.language, 'system');
      expect(settings.notificationsEnabled, true);
      expect(settings.biometricLockEnabled, true);
      // D-01/LOCK-01/LOCK-06: new lock toggles default OFF when keys absent.
      expect(settings.appLockEnabled, false);
      expect(settings.biometricUnlockEnabled, false);
      expect(settings.monthlyJoyTarget, isNull);
    });

    test('returns stored settings', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'language': 'en',
        'notifications_enabled': false,
        'biometric_lock_enabled': false,
        'monthly_joy_target': 75,
      });
      final prefs = await SharedPreferences.getInstance();
      repository = SettingsRepositoryImpl(prefs: prefs);

      final settings = await repository.getSettings();

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.language, 'en');
      expect(settings.notificationsEnabled, false);
      expect(settings.biometricLockEnabled, false);
      expect(settings.monthlyJoyTarget, 75);
    });
  });

  group('updateSettings', () {
    test('persists all fields', () async {
      const settings = AppSettings(
        themeMode: AppThemeMode.light,
        language: 'zh',
        notificationsEnabled: false,
        biometricLockEnabled: false,
        monthlyJoyTarget: 60,
      );

      await repository.updateSettings(settings);
      final restored = await repository.getSettings();

      expect(restored, settings);
    });

    test('removes monthlyJoyTarget when updated to null', () async {
      await repository.setMonthlyJoyTarget(75);

      await repository.updateSettings(const AppSettings());
      final restored = await repository.getSettings();

      expect(restored.monthlyJoyTarget, isNull);
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

  group('appLockEnabled (D-01/LOCK-01)', () {
    test('defaults to false when key absent', () async {
      expect((await repository.getSettings()).appLockEnabled, false);
    });

    test('setAppLockEnabled round-trips both directions', () async {
      await repository.setAppLockEnabled(true);
      expect((await repository.getSettings()).appLockEnabled, true);

      await repository.setAppLockEnabled(false);
      expect((await repository.getSettings()).appLockEnabled, false);
    });

    test('reads stored app_lock_enabled key', () async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final prefs = await SharedPreferences.getInstance();
      repository = SettingsRepositoryImpl(prefs: prefs);

      expect((await repository.getSettings()).appLockEnabled, true);
    });

    test('updateSettings persists appLockEnabled', () async {
      await repository.updateSettings(
        const AppSettings(appLockEnabled: true),
      );
      expect((await repository.getSettings()).appLockEnabled, true);
    });
  });

  group('biometricUnlockEnabled (D-01/LOCK-06)', () {
    test('defaults to false when key absent', () async {
      expect((await repository.getSettings()).biometricUnlockEnabled, false);
    });

    test('setBiometricUnlockEnabled round-trips both directions', () async {
      await repository.setBiometricUnlockEnabled(true);
      expect((await repository.getSettings()).biometricUnlockEnabled, true);

      await repository.setBiometricUnlockEnabled(false);
      expect((await repository.getSettings()).biometricUnlockEnabled, false);
    });

    test('reads stored biometric_unlock_enabled key', () async {
      SharedPreferences.setMockInitialValues({'biometric_unlock_enabled': true});
      final prefs = await SharedPreferences.getInstance();
      repository = SettingsRepositoryImpl(prefs: prefs);

      expect((await repository.getSettings()).biometricUnlockEnabled, true);
    });

    test('updateSettings persists biometricUnlockEnabled', () async {
      await repository.updateSettings(
        const AppSettings(biometricUnlockEnabled: true),
      );
      expect((await repository.getSettings()).biometricUnlockEnabled, true);
    });
  });

  group('onboardingComplete', () {
    test('defaults to false when key absent', () async {
      final settings = await repository.getSettings();

      expect(settings.onboardingComplete, false);
    });

    test('const AppSettings() has onboardingComplete false', () {
      expect(const AppSettings().onboardingComplete, false);
    });

    test('setOnboardingComplete round-trips both directions', () async {
      await repository.setOnboardingComplete(true);
      expect((await repository.getSettings()).onboardingComplete, true);

      await repository.setOnboardingComplete(false);
      expect((await repository.getSettings()).onboardingComplete, false);
    });

    test('updateSettings persists onboardingComplete', () async {
      await repository.updateSettings(
        const AppSettings(onboardingComplete: true),
      );

      expect((await repository.getSettings()).onboardingComplete, true);
    });
  });

  group('setNotificationsEnabled', () {
    test('persists notifications enabled', () async {
      await repository.setNotificationsEnabled(false);

      final settings = await repository.getSettings();
      expect(settings.notificationsEnabled, false);
    });
  });

  group('monthlyJoyTarget', () {
    test('getMonthlyJoyTarget returns null when key absent', () async {
      expect(await repository.getMonthlyJoyTarget(), isNull);
    });

    test(
      'setMonthlyJoyTarget persists and getSettings reflects change',
      () async {
        await repository.setMonthlyJoyTarget(75);

        final settings = await repository.getSettings();

        expect(settings.monthlyJoyTarget, 75);
        expect(await repository.getMonthlyJoyTarget(), 75);
      },
    );

    test('setMonthlyJoyTarget(null) removes the key', () async {
      await repository.setMonthlyJoyTarget(75);

      await repository.setMonthlyJoyTarget(null);
      final settings = await repository.getSettings();

      expect(settings.monthlyJoyTarget, isNull);
      expect(await repository.getMonthlyJoyTarget(), isNull);
    });
  });
}
