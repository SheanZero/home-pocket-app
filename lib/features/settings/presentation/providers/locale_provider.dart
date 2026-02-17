import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../infrastructure/i18n/models/locale_settings.dart';

part 'locale_provider.g.dart';

/// Manages the current locale settings for the app.
///
/// Supports explicit locale selection, system default detection with
/// fallback, and reset to default (Japanese).
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  LocaleSettings build() {
    return LocaleSettings.defaultSettings();
  }

  /// Set the locale explicitly (not system default).
  void setLocale(Locale locale) {
    state = LocaleSettings(
      locale: locale,
      isSystemDefault: false,
    );
  }

  /// Use the system locale, falling back to Japanese if unsupported.
  void setSystemDefault(Locale systemLocale) {
    state = LocaleSettings.fromSystem(systemLocale);
  }

  /// Reset to the default locale (Japanese).
  void resetToDefault() {
    state = LocaleSettings.defaultSettings();
  }
}

/// Convenience provider that extracts just the [Locale] from [LocaleNotifier].
@riverpod
Locale currentLocale(Ref ref) {
  final settings = ref.watch(localeNotifierProvider);
  return settings.locale;
}
