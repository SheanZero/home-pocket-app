import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../infrastructure/i18n/models/locale_settings.dart';
import 'repository_providers.dart';

part 'locale_provider.g.dart';

/// Manages the current locale settings for the app.
///
/// Reads persisted language from [SettingsRepository] on startup.
/// Persists changes via [SettingsRepository.setLanguage()].
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Future<LocaleSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    final language = settings.language;

    if (language == 'system') {
      final systemLocale = PlatformDispatcher.instance.locale;
      return LocaleSettings.fromSystem(systemLocale);
    }

    return LocaleSettings(
      locale: Locale(language),
      isSystemDefault: false,
    );
  }

  /// Set the locale explicitly (not system default). Persists the choice.
  Future<void> setLocale(Locale locale) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setLanguage(locale.languageCode);
    state = AsyncData(
      LocaleSettings(locale: locale, isSystemDefault: false),
    );
  }

  /// Use the system locale. Persists 'system' as the language value.
  Future<void> setSystemDefault() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setLanguage('system');
    final systemLocale = PlatformDispatcher.instance.locale;
    state = AsyncData(LocaleSettings.fromSystem(systemLocale));
  }
}

/// Convenience provider that extracts just the [Locale] from [LocaleNotifier].
@riverpod
Future<Locale> currentLocale(Ref ref) async {
  final settings = await ref.watch(localeNotifierProvider.future);
  return settings.locale;
}
