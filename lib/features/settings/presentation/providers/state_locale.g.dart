// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_locale.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the current locale settings for the app.
///
/// Reads persisted language from [SettingsRepository] on startup.
/// Persists changes via [SettingsRepository.setLanguage()].

@ProviderFor(LocaleNotifier)
final localeProvider = LocaleNotifierProvider._();

/// Manages the current locale settings for the app.
///
/// Reads persisted language from [SettingsRepository] on startup.
/// Persists changes via [SettingsRepository.setLanguage()].
final class LocaleNotifierProvider
    extends $AsyncNotifierProvider<LocaleNotifier, LocaleSettings> {
  /// Manages the current locale settings for the app.
  ///
  /// Reads persisted language from [SettingsRepository] on startup.
  /// Persists changes via [SettingsRepository.setLanguage()].
  LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();
}

String _$localeNotifierHash() => r'72397db5879bab4bff692ee5e8d5e37294b8cbf2';

/// Manages the current locale settings for the app.
///
/// Reads persisted language from [SettingsRepository] on startup.
/// Persists changes via [SettingsRepository.setLanguage()].

abstract class _$LocaleNotifier extends $AsyncNotifier<LocaleSettings> {
  FutureOr<LocaleSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LocaleSettings>, LocaleSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LocaleSettings>, LocaleSettings>,
              AsyncValue<LocaleSettings>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Convenience provider that extracts just the [Locale] from [LocaleNotifier].

@ProviderFor(currentLocale)
final currentLocaleProvider = CurrentLocaleProvider._();

/// Convenience provider that extracts just the [Locale] from [LocaleNotifier].

final class CurrentLocaleProvider
    extends $FunctionalProvider<AsyncValue<Locale>, Locale, FutureOr<Locale>>
    with $FutureModifier<Locale>, $FutureProvider<Locale> {
  /// Convenience provider that extracts just the [Locale] from [LocaleNotifier].
  CurrentLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLocaleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLocaleHash();

  @$internal
  @override
  $FutureProviderElement<Locale> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Locale> create(Ref ref) {
    return currentLocale(ref);
  }
}

String _$currentLocaleHash() => r'71aedaca2269eeb5a5a44e4d10f25c7bd3ffa2e6';
