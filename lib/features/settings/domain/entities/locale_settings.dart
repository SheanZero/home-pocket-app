import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_settings.freezed.dart';

/// Locale settings for the application
///
/// Manages user's language preference with support for:
/// - Japanese (default)
/// - Chinese
/// - English
/// - System default locale detection
@freezed
class LocaleSettings with _$LocaleSettings {
  const factory LocaleSettings({
    /// The selected locale (ja, zh, en)
    required Locale locale,

    /// Whether to use system default locale
    required bool isSystemDefault,
  }) = _LocaleSettings;

  /// Default settings with Japanese locale
  factory LocaleSettings.defaultSettings() => const LocaleSettings(
        locale: Locale('ja'),
        isSystemDefault: false,
      );

  /// Create settings from system locale
  factory LocaleSettings.fromSystem(Locale systemLocale) {
    // Normalize system locale to supported locales
    final supportedCodes = ['ja', 'zh', 'en'];
    final normalizedCode = supportedCodes.contains(systemLocale.languageCode)
        ? systemLocale.languageCode
        : 'ja'; // Fallback to Japanese

    return LocaleSettings(
      locale: Locale(normalizedCode),
      isSystemDefault: true,
    );
  }
}
