import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';

void main() {
  group('SettingsRepositoryImpl - voiceLanguage', () {
    late SettingsRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SettingsRepositoryImpl(prefs: prefs);
    });

    test('getSettings returns default voiceLanguage zh', () async {
      final settings = await repo.getSettings();
      expect(settings.voiceLanguage, 'zh');
    });

    test('setVoiceLanguage persists and getSettings reflects change', () async {
      await repo.setVoiceLanguage('ja');
      final settings = await repo.getSettings();
      expect(settings.voiceLanguage, 'ja');
    });

    test('updateSettings persists voiceLanguage', () async {
      await repo.updateSettings(const AppSettings(voiceLanguage: 'en'));
      final settings = await repo.getSettings();
      expect(settings.voiceLanguage, 'en');
    });
  });

  group('SettingsRepositoryImpl - voiceAllowOnDeviceFallback', () {
    late SettingsRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SettingsRepositoryImpl(prefs: prefs);
    });

    test('getSettings returns default voiceAllowOnDeviceFallback true', () async {
      final settings = await repo.getSettings();
      expect(settings.voiceAllowOnDeviceFallback, true);
    });

    test('setVoiceAllowOnDeviceFallback(false) round-trips via getSettings',
        () async {
      await repo.setVoiceAllowOnDeviceFallback(false);
      final settings = await repo.getSettings();
      expect(settings.voiceAllowOnDeviceFallback, false);
    });

    test('setVoiceAllowOnDeviceFallback(true) round-trips via getSettings',
        () async {
      await repo.setVoiceAllowOnDeviceFallback(false);
      await repo.setVoiceAllowOnDeviceFallback(true);
      final settings = await repo.getSettings();
      expect(settings.voiceAllowOnDeviceFallback, true);
    });

    test('updateSettings persists voiceAllowOnDeviceFallback', () async {
      await repo.updateSettings(
        const AppSettings(voiceAllowOnDeviceFallback: false),
      );
      final settings = await repo.getSettings();
      expect(settings.voiceAllowOnDeviceFallback, false);
    });
  });
}
