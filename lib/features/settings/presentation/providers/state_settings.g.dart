// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current app settings (async because SharedPreferences is async).

@ProviderFor(appSettings)
final appSettingsProvider = AppSettingsProvider._();

/// Current app settings (async because SharedPreferences is async).

final class AppSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppSettings>,
          AppSettings,
          FutureOr<AppSettings>
        >
    with $FutureModifier<AppSettings>, $FutureProvider<AppSettings> {
  /// Current app settings (async because SharedPreferences is async).
  AppSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsHash();

  @$internal
  @override
  $FutureProviderElement<AppSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppSettings> create(Ref ref) {
    return appSettings(ref);
  }
}

String _$appSettingsHash() => r'cd72da6eb5573d2cf05ceef45cce3cd51dacab7d';

/// The BCP-47 locale ID to use for voice recognition.
///
/// Reads from persisted [AppSettings.voiceLanguage] and converts to
/// the format expected by speech_to_text (e.g. 'zh-CN').

@ProviderFor(voiceLocaleId)
final voiceLocaleIdProvider = VoiceLocaleIdProvider._();

/// The BCP-47 locale ID to use for voice recognition.
///
/// Reads from persisted [AppSettings.voiceLanguage] and converts to
/// the format expected by speech_to_text (e.g. 'zh-CN').

final class VoiceLocaleIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The BCP-47 locale ID to use for voice recognition.
  ///
  /// Reads from persisted [AppSettings.voiceLanguage] and converts to
  /// the format expected by speech_to_text (e.g. 'zh-CN').
  VoiceLocaleIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceLocaleIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceLocaleIdHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return voiceLocaleId(ref);
  }
}

String _$voiceLocaleIdHash() => r'b4e918a993cff98ccb3f6311f41bd4b483983b80';
