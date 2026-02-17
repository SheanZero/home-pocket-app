import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_settings.freezed.dart';

@freezed
abstract class LocaleSettings with _$LocaleSettings {
  const factory LocaleSettings({
    required Locale locale,
    required bool isSystemDefault,
  }) = _LocaleSettings;

  factory LocaleSettings.defaultSettings() => const LocaleSettings(
        locale: Locale('ja'),
        isSystemDefault: false,
      );

  factory LocaleSettings.fromSystem(Locale systemLocale) {
    const supportedCodes = ['ja', 'zh', 'en'];
    final normalizedCode = supportedCodes.contains(systemLocale.languageCode)
        ? systemLocale.languageCode
        : 'ja';
    return LocaleSettings(
      locale: Locale(normalizedCode),
      isSystemDefault: true,
    );
  }
}
