// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_locale.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentLocaleHash() => r'a12ccfd4e5abf45064f5b018daf044b6367e1ea0';

/// Convenience provider that extracts just the [Locale] from [LocaleNotifier].
///
/// Copied from [currentLocale].
@ProviderFor(currentLocale)
final currentLocaleProvider = AutoDisposeFutureProvider<Locale>.internal(
  currentLocale,
  name: r'currentLocaleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLocaleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentLocaleRef = AutoDisposeFutureProviderRef<Locale>;
String _$localeNotifierHash() => r'72397db5879bab4bff692ee5e8d5e37294b8cbf2';

/// Manages the current locale settings for the app.
///
/// Reads persisted language from [SettingsRepository] on startup.
/// Persists changes via [SettingsRepository.setLanguage()].
///
/// Copied from [LocaleNotifier].
@ProviderFor(LocaleNotifier)
final localeNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LocaleNotifier, LocaleSettings>.internal(
      LocaleNotifier.new,
      name: r'localeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$localeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LocaleNotifier = AutoDisposeAsyncNotifier<LocaleSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
