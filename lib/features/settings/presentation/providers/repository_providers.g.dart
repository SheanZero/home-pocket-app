// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SharedPreferences instance provider.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// SharedPreferences instance provider.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  /// SharedPreferences instance provider.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'dc403fbb1d968c7d5ab4ae1721a29ffe173701c7';

/// SettingsRepository provider (single source of truth).

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// SettingsRepository provider (single source of truth).

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// SettingsRepository provider (single source of truth).
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'7df289791566178daca2460ffd2566bc518f611c';

@ProviderFor(exportBackupUseCase)
final exportBackupUseCaseProvider = ExportBackupUseCaseProvider._();

final class ExportBackupUseCaseProvider
    extends
        $FunctionalProvider<
          ExportBackupUseCase,
          ExportBackupUseCase,
          ExportBackupUseCase
        >
    with $Provider<ExportBackupUseCase> {
  ExportBackupUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportBackupUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportBackupUseCaseHash();

  @$internal
  @override
  $ProviderElement<ExportBackupUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExportBackupUseCase create(Ref ref) {
    return exportBackupUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportBackupUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportBackupUseCase>(value),
    );
  }
}

String _$exportBackupUseCaseHash() =>
    r'fd98e79c362dc0339dbb9a3b3aa9e77c9c7dbf70';

@ProviderFor(importBackupUseCase)
final importBackupUseCaseProvider = ImportBackupUseCaseProvider._();

final class ImportBackupUseCaseProvider
    extends
        $FunctionalProvider<
          ImportBackupUseCase,
          ImportBackupUseCase,
          ImportBackupUseCase
        >
    with $Provider<ImportBackupUseCase> {
  ImportBackupUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importBackupUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importBackupUseCaseHash();

  @$internal
  @override
  $ProviderElement<ImportBackupUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImportBackupUseCase create(Ref ref) {
    return importBackupUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportBackupUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportBackupUseCase>(value),
    );
  }
}

String _$importBackupUseCaseHash() =>
    r'86ca32281747bd6dfd27fa3f55e9689f9eefe8b6';

@ProviderFor(clearAllDataUseCase)
final clearAllDataUseCaseProvider = ClearAllDataUseCaseProvider._();

final class ClearAllDataUseCaseProvider
    extends
        $FunctionalProvider<
          ClearAllDataUseCase,
          ClearAllDataUseCase,
          ClearAllDataUseCase
        >
    with $Provider<ClearAllDataUseCase> {
  ClearAllDataUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clearAllDataUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clearAllDataUseCaseHash();

  @$internal
  @override
  $ProviderElement<ClearAllDataUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClearAllDataUseCase create(Ref ref) {
    return clearAllDataUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClearAllDataUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClearAllDataUseCase>(value),
    );
  }
}

String _$clearAllDataUseCaseHash() =>
    r'5e425df54e4533fadafb053bd4241a6c9560d8d5';
