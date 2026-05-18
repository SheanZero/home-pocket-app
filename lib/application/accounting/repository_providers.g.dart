// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer re-export of [AppDatabase].
///
/// Feature accounting presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).

@ProviderFor(appAppDatabase)
final appAppDatabaseProvider = AppAppDatabaseProvider._();

/// Application-layer re-export of [AppDatabase].
///
/// Feature accounting presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).

final class AppAppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Application-layer re-export of [AppDatabase].
  ///
  /// Feature accounting presentation imports this instead of
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
/// Deduplicates the two-hop import via accounting feature's
/// infrastructure/crypto/providers.dart dependency.

@ProviderFor(appKeyManager)
final appKeyManagerProvider = AppKeyManagerProvider._();

/// Application-layer re-export of [KeyManager].
///
/// Deduplicates the two-hop import via accounting feature's
/// infrastructure/crypto/providers.dart dependency.

final class AppKeyManagerProvider
    extends $FunctionalProvider<KeyManager, KeyManager, KeyManager>
    with $Provider<KeyManager> {
  /// Application-layer re-export of [KeyManager].
  ///
  /// Deduplicates the two-hop import via accounting feature's
  /// infrastructure/crypto/providers.dart dependency.
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

/// Application-layer re-export of [FieldEncryptionService].
///
/// Feature accounting presentation uses this for TransactionRepository
/// construction without importing infrastructure/crypto directly (HIGH-02).

@ProviderFor(appFieldEncryptionService)
final appFieldEncryptionServiceProvider = AppFieldEncryptionServiceProvider._();

/// Application-layer re-export of [FieldEncryptionService].
///
/// Feature accounting presentation uses this for TransactionRepository
/// construction without importing infrastructure/crypto directly (HIGH-02).

final class AppFieldEncryptionServiceProvider
    extends
        $FunctionalProvider<
          FieldEncryptionService,
          FieldEncryptionService,
          FieldEncryptionService
        >
    with $Provider<FieldEncryptionService> {
  /// Application-layer re-export of [FieldEncryptionService].
  ///
  /// Feature accounting presentation uses this for TransactionRepository
  /// construction without importing infrastructure/crypto directly (HIGH-02).
  AppFieldEncryptionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appFieldEncryptionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appFieldEncryptionServiceHash();

  @$internal
  @override
  $ProviderElement<FieldEncryptionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FieldEncryptionService create(Ref ref) {
    return appFieldEncryptionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FieldEncryptionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FieldEncryptionService>(value),
    );
  }
}

String _$appFieldEncryptionServiceHash() =>
    r'd5e91a2f79f87e46a93b99522fe57770d9a8835a';

/// Application-layer re-export of [HashChainService].
///
/// Feature accounting presentation uses this for CreateTransactionUseCase
/// construction without importing infrastructure/crypto directly (HIGH-02).

@ProviderFor(appHashChainService)
final appHashChainServiceProvider = AppHashChainServiceProvider._();

/// Application-layer re-export of [HashChainService].
///
/// Feature accounting presentation uses this for CreateTransactionUseCase
/// construction without importing infrastructure/crypto directly (HIGH-02).

final class AppHashChainServiceProvider
    extends
        $FunctionalProvider<
          HashChainService,
          HashChainService,
          HashChainService
        >
    with $Provider<HashChainService> {
  /// Application-layer re-export of [HashChainService].
  ///
  /// Feature accounting presentation uses this for CreateTransactionUseCase
  /// construction without importing infrastructure/crypto directly (HIGH-02).
  AppHashChainServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appHashChainServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appHashChainServiceHash();

  @$internal
  @override
  $ProviderElement<HashChainService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HashChainService create(Ref ref) {
    return appHashChainService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HashChainService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HashChainService>(value),
    );
  }
}

String _$appHashChainServiceHash() =>
    r'8209945120a703e3120745e3997689817e7127ac';
