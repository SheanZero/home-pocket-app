// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedPreferencesHash() => r'dc403fbb1d968c7d5ab4ae1721a29ffe173701c7';

/// SharedPreferences instance provider.
///
/// Copied from [sharedPreferences].
@ProviderFor(sharedPreferences)
final sharedPreferencesProvider =
    AutoDisposeFutureProvider<SharedPreferences>.internal(
      sharedPreferences,
      name: r'sharedPreferencesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sharedPreferencesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPreferencesRef = AutoDisposeFutureProviderRef<SharedPreferences>;
String _$settingsRepositoryHash() =>
    r'7df289791566178daca2460ffd2566bc518f611c';

/// SettingsRepository provider (single source of truth).
///
/// Copied from [settingsRepository].
@ProviderFor(settingsRepository)
final settingsRepositoryProvider =
    AutoDisposeProvider<SettingsRepository>.internal(
      settingsRepository,
      name: r'settingsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsRepositoryRef = AutoDisposeProviderRef<SettingsRepository>;
String _$exportBackupUseCaseHash() =>
    r'fd98e79c362dc0339dbb9a3b3aa9e77c9c7dbf70';

/// See also [exportBackupUseCase].
@ProviderFor(exportBackupUseCase)
final exportBackupUseCaseProvider =
    AutoDisposeProvider<ExportBackupUseCase>.internal(
      exportBackupUseCase,
      name: r'exportBackupUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$exportBackupUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExportBackupUseCaseRef = AutoDisposeProviderRef<ExportBackupUseCase>;
String _$importBackupUseCaseHash() =>
    r'86ca32281747bd6dfd27fa3f55e9689f9eefe8b6';

/// See also [importBackupUseCase].
@ProviderFor(importBackupUseCase)
final importBackupUseCaseProvider =
    AutoDisposeProvider<ImportBackupUseCase>.internal(
      importBackupUseCase,
      name: r'importBackupUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$importBackupUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ImportBackupUseCaseRef = AutoDisposeProviderRef<ImportBackupUseCase>;
String _$clearAllDataUseCaseHash() =>
    r'5e425df54e4533fadafb053bd4241a6c9560d8d5';

/// See also [clearAllDataUseCase].
@ProviderFor(clearAllDataUseCase)
final clearAllDataUseCaseProvider =
    AutoDisposeProvider<ClearAllDataUseCase>.internal(
      clearAllDataUseCase,
      name: r'clearAllDataUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$clearAllDataUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClearAllDataUseCaseRef = AutoDisposeProviderRef<ClearAllDataUseCase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
