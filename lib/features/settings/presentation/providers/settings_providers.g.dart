// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appSettingsHash() => r'cd72da6eb5573d2cf05ceef45cce3cd51dacab7d';

/// Current app settings (async because SharedPreferences is async).
///
/// Copied from [appSettings].
@ProviderFor(appSettings)
final appSettingsProvider = AutoDisposeFutureProvider<AppSettings>.internal(
  appSettings,
  name: r'appSettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppSettingsRef = AutoDisposeFutureProviderRef<AppSettings>;
String _$voiceLocaleIdHash() => r'b4e918a993cff98ccb3f6311f41bd4b483983b80';

/// The BCP-47 locale ID to use for voice recognition.
///
/// Reads from persisted [AppSettings.voiceLanguage] and converts to
/// the format expected by speech_to_text (e.g. 'zh-CN').
///
/// Copied from [voiceLocaleId].
@ProviderFor(voiceLocaleId)
final voiceLocaleIdProvider = AutoDisposeFutureProvider<String>.internal(
  voiceLocaleId,
  name: r'voiceLocaleIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$voiceLocaleIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VoiceLocaleIdRef = AutoDisposeFutureProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
