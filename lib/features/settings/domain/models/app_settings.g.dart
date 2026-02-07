// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  themeMode:
      $enumDecodeNullable(_$AppThemeModeEnumMap, json['themeMode']) ??
      AppThemeMode.system,
  language: json['language'] as String? ?? 'ja',
  notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
  biometricLockEnabled: json['biometricLockEnabled'] as bool? ?? true,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'language': instance.language,
      'notificationsEnabled': instance.notificationsEnabled,
      'biometricLockEnabled': instance.biometricLockEnabled,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.system: 'system',
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
};
