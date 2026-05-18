// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer re-export of [AppDatabase].
///
/// Profile feature presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).

@ProviderFor(appAppDatabase)
final appAppDatabaseProvider = AppAppDatabaseProvider._();

/// Application-layer re-export of [AppDatabase].
///
/// Profile feature presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).

final class AppAppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Application-layer re-export of [AppDatabase].
  ///
  /// Profile feature presentation imports this instead of
  /// infrastructure/security/providers.dart (HIGH-02 compliance).
  AppAppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appAppDatabaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appAppDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appAppDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appAppDatabaseHash() => r'a93923f0b7e30eae84d8cfca4e7b57a0bd619890';

/// Application-layer re-export of [KeyManager].
///
/// Profile feature presentation imports this instead of
/// infrastructure/crypto/providers.dart (HIGH-02 compliance).

@ProviderFor(appKeyManager)
final appKeyManagerProvider = AppKeyManagerProvider._();

/// Application-layer re-export of [KeyManager].
///
/// Profile feature presentation imports this instead of
/// infrastructure/crypto/providers.dart (HIGH-02 compliance).

final class AppKeyManagerProvider
    extends $FunctionalProvider<KeyManager, KeyManager, KeyManager>
    with $Provider<KeyManager> {
  /// Application-layer re-export of [KeyManager].
  ///
  /// Profile feature presentation imports this instead of
  /// infrastructure/crypto/providers.dart (HIGH-02 compliance).
  AppKeyManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appKeyManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appKeyManagerHash();

  @$internal
  @override
  $ProviderElement<KeyManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeyManager create(Ref ref) {
    return appKeyManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyManager>(value),
    );
  }
}

String _$appKeyManagerHash() => r'7b966b214841d1660d895e3b0836417191a65671';
