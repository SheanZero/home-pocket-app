import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper to create a ProviderContainer with real SharedPreferences.
Future<ProviderContainer> createTestContainer({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
      settingsRepositoryProvider.overrideWith(
        (_) => SettingsRepositoryImpl(prefs: prefs),
      ),
    ],
  );
}

void main() {
  group('LocaleNotifier', () {
    test('initial state reads persisted language from settings', () async {
      final container = await createTestContainer(
        initialValues: {'language': 'en'},
      );
      addTearDown(container.dispose);

      final settings = await container.read(localeNotifierProvider.future);
      expect(settings.locale, const Locale('en'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('initial state defaults to ja when no persisted value', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      final settings = await container.read(localeNotifierProvider.future);
      // Default is 'ja' (current AppSettings default)
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('initial state handles system value', () async {
      final container = await createTestContainer(
        initialValues: {'language': 'system'},
      );
      addTearDown(container.dispose);

      final settings = await container.read(localeNotifierProvider.future);
      expect(settings.isSystemDefault, isTrue);
    });

    test('setLocale persists language and updates state', () async {
      final container = await createTestContainer(
        initialValues: {'language': 'ja'},
      );
      addTearDown(container.dispose);

      await container.read(localeNotifierProvider.future);
      await container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('zh'));

      final settings = await container.read(localeNotifierProvider.future);
      expect(settings.locale, const Locale('zh'));
      expect(settings.isSystemDefault, isFalse);

      // Verify persistence
      final prefs = await container.read(sharedPreferencesProvider.future);
      expect(prefs.getString('language'), 'zh');
    });

    test('setSystemDefault persists system and updates state', () async {
      final container = await createTestContainer(
        initialValues: {'language': 'ja'},
      );
      addTearDown(container.dispose);

      await container.read(localeNotifierProvider.future);
      await container
          .read(localeNotifierProvider.notifier)
          .setSystemDefault();

      final settings = await container.read(localeNotifierProvider.future);
      expect(settings.isSystemDefault, isTrue);

      // Verify persistence
      final prefs = await container.read(sharedPreferencesProvider.future);
      expect(prefs.getString('language'), 'system');
    });
  });

  group('currentLocaleProvider', () {
    test('returns locale from LocaleNotifier', () async {
      final container = await createTestContainer(
        initialValues: {'language': 'en'},
      );
      addTearDown(container.dispose);

      final locale = await container.read(currentLocaleProvider.future);
      expect(locale, const Locale('en'));
    });
  });
}
