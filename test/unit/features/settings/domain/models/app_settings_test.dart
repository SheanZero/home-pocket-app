import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('creates with default values', () {
      const settings = AppSettings();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.language, 'system');
      expect(settings.notificationsEnabled, true);
      expect(settings.biometricLockEnabled, true);
      // D-01/LOCK-01/LOCK-06: new lock toggles default OFF.
      expect(settings.appLockEnabled, false);
      expect(settings.biometricUnlockEnabled, false);
    });

    test('appLockEnabled and biometricUnlockEnabled round-trip via copyWith', () {
      const original = AppSettings();
      final updated = original.copyWith(
        appLockEnabled: true,
        biometricUnlockEnabled: true,
      );

      expect(updated.appLockEnabled, true);
      expect(updated.biometricUnlockEnabled, true);
      // Original is unchanged (immutability).
      expect(original.appLockEnabled, false);
      expect(original.biometricUnlockEnabled, false);
    });

    test('creates with custom values', () {
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        language: 'en',
        notificationsEnabled: false,
        biometricLockEnabled: false,
      );

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.language, 'en');
      expect(settings.notificationsEnabled, false);
      expect(settings.biometricLockEnabled, false);
    });

    test('copyWith creates new instance with changed fields', () {
      const original = AppSettings();
      final updated = original.copyWith(
        themeMode: AppThemeMode.light,
        language: 'zh',
      );

      expect(updated.themeMode, AppThemeMode.light);
      expect(updated.language, 'zh');
      // Unchanged fields retain original values
      expect(updated.notificationsEnabled, true);
      expect(updated.biometricLockEnabled, true);
      // Original is unchanged
      expect(original.themeMode, AppThemeMode.system);
      expect(original.language, 'system');
    });

    test('serializes to JSON and back', () {
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        language: 'en',
        notificationsEnabled: false,
        biometricLockEnabled: true,
      );

      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored, settings);
    });

    test('equality works correctly', () {
      const a = AppSettings(themeMode: AppThemeMode.dark);
      const b = AppSettings(themeMode: AppThemeMode.dark);
      const c = AppSettings(themeMode: AppThemeMode.light);

      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('AppSettings.voiceLanguage', () {
    test('default voiceLanguage is zh', () {
      const settings = AppSettings();
      expect(settings.voiceLanguage, 'zh');
    });

    test('copyWith preserves voiceLanguage', () {
      const settings = AppSettings(voiceLanguage: 'ja');
      final updated = settings.copyWith(themeMode: AppThemeMode.dark);
      expect(updated.voiceLanguage, 'ja');
    });

    test('fromJson/toJson round-trips voiceLanguage', () {
      const settings = AppSettings(voiceLanguage: 'en');
      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored.voiceLanguage, 'en');
    });
  });

  group('AppSettings.voiceAllowOnDeviceFallback', () {
    test('defaults to true (auto-degrade allowed, backward compatible)', () {
      const settings = AppSettings();
      expect(settings.voiceAllowOnDeviceFallback, true);
    });

    test('copyWith(false) round-trips without mutating the original', () {
      const original = AppSettings();
      final updated = original.copyWith(voiceAllowOnDeviceFallback: false);

      expect(updated.voiceAllowOnDeviceFallback, false);
      // Immutability: the original is untouched.
      expect(original.voiceAllowOnDeviceFallback, true);
    });

    test('copyWith preserves voiceAllowOnDeviceFallback', () {
      const settings = AppSettings(voiceAllowOnDeviceFallback: false);
      final updated = settings.copyWith(themeMode: AppThemeMode.dark);
      expect(updated.voiceAllowOnDeviceFallback, false);
    });

    test('fromJson/toJson round-trips voiceAllowOnDeviceFallback', () {
      const settings = AppSettings(voiceAllowOnDeviceFallback: false);
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.voiceAllowOnDeviceFallback, false);
    });
  });

  group('AppThemeMode', () {
    test('has all expected values', () {
      expect(AppThemeMode.values, hasLength(3));
      expect(AppThemeMode.values, contains(AppThemeMode.system));
      expect(AppThemeMode.values, contains(AppThemeMode.light));
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
    });
  });
}
