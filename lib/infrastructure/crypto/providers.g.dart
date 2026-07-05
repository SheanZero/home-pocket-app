// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Master key repository - manages 256-bit master key and HKDF derivation

@ProviderFor(masterKeyRepository)
final masterKeyRepositoryProvider = MasterKeyRepositoryProvider._();

/// Master key repository - manages 256-bit master key and HKDF derivation

final class MasterKeyRepositoryProvider
    extends
        $FunctionalProvider<
          MasterKeyRepository,
          MasterKeyRepository,
          MasterKeyRepository
        >
    with $Provider<MasterKeyRepository> {
  /// Master key repository - manages 256-bit master key and HKDF derivation
  MasterKeyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'masterKeyRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$masterKeyRepositoryHash();

  @$internal
  @override
  $ProviderElement<MasterKeyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MasterKeyRepository create(Ref ref) {
    return masterKeyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MasterKeyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MasterKeyRepository>(value),
    );
  }
}

String _$masterKeyRepositoryHash() =>
    r'4c3ad8f67393d7368904e1c501d396690b6b672a';

/// Key repository - manages Ed25519 key pairs

@ProviderFor(keyRepository)
final keyRepositoryProvider = KeyRepositoryProvider._();

/// Key repository - manages Ed25519 key pairs

final class KeyRepositoryProvider
    extends $FunctionalProvider<KeyRepository, KeyRepository, KeyRepository>
    with $Provider<KeyRepository> {
  /// Key repository - manages Ed25519 key pairs
  KeyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keyRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keyRepositoryHash();

  @$internal
  @override
  $ProviderElement<KeyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeyRepository create(Ref ref) {
    return keyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyRepository>(value),
    );
  }
}

String _$keyRepositoryHash() => r'6ad4d390457589e7474880eba16e6dd7d8e8e02b';

/// Key manager - high-level key operations

@ProviderFor(keyManager)
final keyManagerProvider = KeyManagerProvider._();

/// Key manager - high-level key operations

final class KeyManagerProvider
    extends $FunctionalProvider<KeyManager, KeyManager, KeyManager>
    with $Provider<KeyManager> {
  /// Key manager - high-level key operations
  KeyManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keyManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keyManagerHash();

  @$internal
  @override
  $ProviderElement<KeyManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeyManager create(Ref ref) {
    return keyManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyManager>(value),
    );
  }
}

String _$keyManagerHash() => r'40e2e0f9bd63d2f17e56c42d82636d643d0407b1';

/// Check if device has a key pair

@ProviderFor(hasKeyPair)
final hasKeyPairProvider = HasKeyPairProvider._();

/// Check if device has a key pair

final class HasKeyPairProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Check if device has a key pair
  HasKeyPairProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasKeyPairProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasKeyPairHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasKeyPair(ref);
  }
}

String _$hasKeyPairHash() => r'72d0fbb0036045faf3fbbadf5224c35ffe3ea6a4';

/// Encryption repository - ChaCha20-Poly1305 field encryption

@ProviderFor(encryptionRepository)
final encryptionRepositoryProvider = EncryptionRepositoryProvider._();

/// Encryption repository - ChaCha20-Poly1305 field encryption

final class EncryptionRepositoryProvider
    extends
        $FunctionalProvider<
          EncryptionRepository,
          EncryptionRepository,
          EncryptionRepository
        >
    with $Provider<EncryptionRepository> {
  /// Encryption repository - ChaCha20-Poly1305 field encryption
  EncryptionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'encryptionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$encryptionRepositoryHash();

  @$internal
  @override
  $ProviderElement<EncryptionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EncryptionRepository create(Ref ref) {
    return encryptionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EncryptionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EncryptionRepository>(value),
    );
  }
}

String _$encryptionRepositoryHash() =>
    r'c6056282201dec9addce49947d7dd578f5fc9e19';

/// Field encryption service - high-level encryption operations

@ProviderFor(fieldEncryptionService)
final fieldEncryptionServiceProvider = FieldEncryptionServiceProvider._();

/// Field encryption service - high-level encryption operations

final class FieldEncryptionServiceProvider
    extends
        $FunctionalProvider<
          FieldEncryptionService,
          FieldEncryptionService,
          FieldEncryptionService
        >
    with $Provider<FieldEncryptionService> {
  /// Field encryption service - high-level encryption operations
  FieldEncryptionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fieldEncryptionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fieldEncryptionServiceHash();

  @$internal
  @override
  $ProviderElement<FieldEncryptionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FieldEncryptionService create(Ref ref) {
    return fieldEncryptionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FieldEncryptionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FieldEncryptionService>(value),
    );
  }
}

String _$fieldEncryptionServiceHash() =>
    r'e5a06708eee529bd7d89c4772eb3c01c4805a08f';

/// Hash chain service - SHA-256 transaction integrity

@ProviderFor(hashChainService)
final hashChainServiceProvider = HashChainServiceProvider._();

/// Hash chain service - SHA-256 transaction integrity

final class HashChainServiceProvider
    extends
        $FunctionalProvider<
          HashChainService,
          HashChainService,
          HashChainService
        >
    with $Provider<HashChainService> {
  /// Hash chain service - SHA-256 transaction integrity
  HashChainServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hashChainServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hashChainServiceHash();

  @$internal
  @override
  $ProviderElement<HashChainService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HashChainService create(Ref ref) {
    return hashChainService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HashChainService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HashChainService>(value),
    );
  }
}

String _$hashChainServiceHash() => r'bae731c484fb95a977585d5349b209c78f91c66d';

/// Backup crypto service - password-based .hpb encryption (Argon2id + AES-GCM)

@ProviderFor(backupCryptoService)
final backupCryptoServiceProvider = BackupCryptoServiceProvider._();

/// Backup crypto service - password-based .hpb encryption (Argon2id + AES-GCM)

final class BackupCryptoServiceProvider
    extends
        $FunctionalProvider<
          BackupCryptoService,
          BackupCryptoService,
          BackupCryptoService
        >
    with $Provider<BackupCryptoService> {
  /// Backup crypto service - password-based .hpb encryption (Argon2id + AES-GCM)
  BackupCryptoServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupCryptoServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupCryptoServiceHash();

  @$internal
  @override
  $ProviderElement<BackupCryptoService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackupCryptoService create(Ref ref) {
    return backupCryptoService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupCryptoService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupCryptoService>(value),
    );
  }
}

String _$backupCryptoServiceHash() =>
    r'e12ccc9734307ae0a945c9f013ad9bad02488035';
