import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Theme mode for the app (domain-layer enum, no Flutter dependency).
enum AppThemeMode { system, light, dark }

/// Application settings model.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default('ja') String language,
    @Default(true) bool notificationsEnabled,
    @Default(true) bool biometricLockEnabled,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
