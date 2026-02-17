// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$masterKeyRepositoryHash() =>
    r'4c3ad8f67393d7368904e1c501d396690b6b672a';

/// Master key repository - manages 256-bit master key and HKDF derivation
///
/// Copied from [masterKeyRepository].
@ProviderFor(masterKeyRepository)
final masterKeyRepositoryProvider =
    AutoDisposeProvider<MasterKeyRepository>.internal(
      masterKeyRepository,
      name: r'masterKeyRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$masterKeyRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MasterKeyRepositoryRef = AutoDisposeProviderRef<MasterKeyRepository>;
String _$keyRepositoryHash() => r'6ad4d390457589e7474880eba16e6dd7d8e8e02b';

/// Key repository - manages Ed25519 key pairs
///
/// Copied from [keyRepository].
@ProviderFor(keyRepository)
final keyRepositoryProvider = AutoDisposeProvider<KeyRepository>.internal(
  keyRepository,
  name: r'keyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$keyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KeyRepositoryRef = AutoDisposeProviderRef<KeyRepository>;
String _$keyManagerHash() => r'40e2e0f9bd63d2f17e56c42d82636d643d0407b1';

/// Key manager - high-level key operations
///
/// Copied from [keyManager].
@ProviderFor(keyManager)
final keyManagerProvider = AutoDisposeProvider<KeyManager>.internal(
  keyManager,
  name: r'keyManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$keyManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KeyManagerRef = AutoDisposeProviderRef<KeyManager>;
String _$hasKeyPairHash() => r'72d0fbb0036045faf3fbbadf5224c35ffe3ea6a4';

/// Check if device has a key pair
///
/// Copied from [hasKeyPair].
@ProviderFor(hasKeyPair)
final hasKeyPairProvider = AutoDisposeFutureProvider<bool>.internal(
  hasKeyPair,
  name: r'hasKeyPairProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasKeyPairHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasKeyPairRef = AutoDisposeFutureProviderRef<bool>;
String _$encryptionRepositoryHash() =>
    r'c6056282201dec9addce49947d7dd578f5fc9e19';

/// Encryption repository - ChaCha20-Poly1305 field encryption
///
/// Copied from [encryptionRepository].
@ProviderFor(encryptionRepository)
final encryptionRepositoryProvider =
    AutoDisposeProvider<EncryptionRepository>.internal(
      encryptionRepository,
      name: r'encryptionRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$encryptionRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EncryptionRepositoryRef = AutoDisposeProviderRef<EncryptionRepository>;
String _$fieldEncryptionServiceHash() =>
    r'e5a06708eee529bd7d89c4772eb3c01c4805a08f';

/// Field encryption service - high-level encryption operations
///
/// Copied from [fieldEncryptionService].
@ProviderFor(fieldEncryptionService)
final fieldEncryptionServiceProvider =
    AutoDisposeProvider<FieldEncryptionService>.internal(
      fieldEncryptionService,
      name: r'fieldEncryptionServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fieldEncryptionServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FieldEncryptionServiceRef =
    AutoDisposeProviderRef<FieldEncryptionService>;
String _$hashChainServiceHash() => r'bae731c484fb95a977585d5349b209c78f91c66d';

/// Hash chain service - SHA-256 transaction integrity
///
/// Copied from [hashChainService].
@ProviderFor(hashChainService)
final hashChainServiceProvider = AutoDisposeProvider<HashChainService>.internal(
  hashChainService,
  name: r'hashChainServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hashChainServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HashChainServiceRef = AutoDisposeProviderRef<HashChainService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
