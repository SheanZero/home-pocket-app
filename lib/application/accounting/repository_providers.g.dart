// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appAppDatabaseHash() => r'a93923f0b7e30eae84d8cfca4e7b57a0bd619890';

/// Application-layer re-export of [AppDatabase].
///
/// Feature accounting presentation imports this instead of
/// infrastructure/security/providers.dart (HIGH-02 compliance).
///
/// Copied from [appAppDatabase].
@ProviderFor(appAppDatabase)
final appAppDatabaseProvider = AutoDisposeProvider<AppDatabase>.internal(
  appAppDatabase,
  name: r'appAppDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appAppDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppAppDatabaseRef = AutoDisposeProviderRef<AppDatabase>;
String _$appKeyManagerHash() => r'7b966b214841d1660d895e3b0836417191a65671';

/// Application-layer re-export of [KeyManager].
///
/// Deduplicates the two-hop import via accounting feature's
/// infrastructure/crypto/providers.dart dependency.
///
/// Copied from [appKeyManager].
@ProviderFor(appKeyManager)
final appKeyManagerProvider = AutoDisposeProvider<KeyManager>.internal(
  appKeyManager,
  name: r'appKeyManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appKeyManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppKeyManagerRef = AutoDisposeProviderRef<KeyManager>;
String _$appFieldEncryptionServiceHash() =>
    r'd5e91a2f79f87e46a93b99522fe57770d9a8835a';

/// Application-layer re-export of [FieldEncryptionService].
///
/// Feature accounting presentation uses this for TransactionRepository
/// construction without importing infrastructure/crypto directly (HIGH-02).
///
/// Copied from [appFieldEncryptionService].
@ProviderFor(appFieldEncryptionService)
final appFieldEncryptionServiceProvider =
    AutoDisposeProvider<FieldEncryptionService>.internal(
      appFieldEncryptionService,
      name: r'appFieldEncryptionServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appFieldEncryptionServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppFieldEncryptionServiceRef =
    AutoDisposeProviderRef<FieldEncryptionService>;
String _$appHashChainServiceHash() =>
    r'8209945120a703e3120745e3997689817e7127ac';

/// Application-layer re-export of [HashChainService].
///
/// Feature accounting presentation uses this for CreateTransactionUseCase
/// construction without importing infrastructure/crypto directly (HIGH-02).
///
/// Copied from [appHashChainService].
@ProviderFor(appHashChainService)
final appHashChainServiceProvider =
    AutoDisposeProvider<HashChainService>.internal(
      appHashChainService,
      name: r'appHashChainServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appHashChainServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppHashChainServiceRef = AutoDisposeProviderRef<HashChainService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
