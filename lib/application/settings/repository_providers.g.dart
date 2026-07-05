// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer re-export of [BackupCryptoService].
///
/// Feature settings presentation imports this instead of
/// infrastructure/crypto/providers.dart directly (HIGH-02 compliance,
/// mirrors application/accounting/repository_providers.dart).

@ProviderFor(appBackupCryptoService)
final appBackupCryptoServiceProvider = AppBackupCryptoServiceProvider._();

/// Application-layer re-export of [BackupCryptoService].
///
/// Feature settings presentation imports this instead of
/// infrastructure/crypto/providers.dart directly (HIGH-02 compliance,
/// mirrors application/accounting/repository_providers.dart).

final class AppBackupCryptoServiceProvider
    extends
        $FunctionalProvider<
          BackupCryptoService,
          BackupCryptoService,
          BackupCryptoService
        >
    with $Provider<BackupCryptoService> {
  /// Application-layer re-export of [BackupCryptoService].
  ///
  /// Feature settings presentation imports this instead of
  /// infrastructure/crypto/providers.dart directly (HIGH-02 compliance,
  /// mirrors application/accounting/repository_providers.dart).
  AppBackupCryptoServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appBackupCryptoServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appBackupCryptoServiceHash();

  @$internal
  @override
  $ProviderElement<BackupCryptoService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackupCryptoService create(Ref ref) {
    return appBackupCryptoService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupCryptoService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupCryptoService>(value),
    );
  }
}

String _$appBackupCryptoServiceHash() =>
    r'7e0bb33531052f8e0e6a5086c599ac8ab1c611a4';
