import 'package:flutter/material.dart';
import 'package:home_pocket/features/settings/domain/entities/locale_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// Provider for managing locale settings with runtime switching
///
/// Supports three languages:
/// - Japanese (ja) - Default
/// - Chinese (zh)
/// - English (en)
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  LocaleSettings build() {
    // Initialize with Japanese as default
    return LocaleSettings.defaultSettings();
  }

  /// Change the application locale
  void setLocale(Locale locale) {
    state = LocaleSettings(
      locale: locale,
      isSystemDefault: false,
    );
  }

  /// Set locale to system default
  void setSystemDefault(Locale systemLocale) {
    state = LocaleSettings.fromSystem(systemLocale);
  }

  /// Reset to Japanese default
  void resetToDefault() {
    state = LocaleSettings.defaultSettings();
  }
}

/// Convenience provider to get just the Locale object
@riverpod
Locale currentLocale(CurrentLocaleRef ref) {
  final settings = ref.watch(localeNotifierProvider);
  return settings.locale;
}
