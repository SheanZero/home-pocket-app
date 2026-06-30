// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  themeMode:
      $enumDecodeNullable(_$AppThemeModeEnumMap, json['themeMode']) ??
      AppThemeMode.system,
  language: json['language'] as String? ?? 'system',
  notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
  biometricLockEnabled: json['biometricLockEnabled'] as bool? ?? true,
  appLockEnabled: json['appLockEnabled'] as bool? ?? false,
  biometricUnlockEnabled: json['biometricUnlockEnabled'] as bool? ?? false,
  onboardingComplete: json['onboardingComplete'] as bool? ?? false,
  voiceLanguage: json['voiceLanguage'] as String? ?? 'zh',
  monthlyJoyTarget: (json['monthlyJoyTarget'] as num?)?.toInt(),
  weekStartDay:
      $enumDecodeNullable(_$WeekStartDayEnumMap, json['weekStartDay']) ??
      WeekStartDay.monday,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'language': instance.language,
      'notificationsEnabled': instance.notificationsEnabled,
      'biometricLockEnabled': instance.biometricLockEnabled,
      'appLockEnabled': instance.appLockEnabled,
      'biometricUnlockEnabled': instance.biometricUnlockEnabled,
      'onboardingComplete': instance.onboardingComplete,
      'voiceLanguage': instance.voiceLanguage,
      'monthlyJoyTarget': instance.monthlyJoyTarget,
      'weekStartDay': _$WeekStartDayEnumMap[instance.weekStartDay]!,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.system: 'system',
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
};

const _$WeekStartDayEnumMap = {
  WeekStartDay.monday: 'monday',
  WeekStartDay.sunday: 'sunday',
};
