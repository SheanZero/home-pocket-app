// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-layer app-lock service — single source of truth for the lock
/// decision (D-01) and all PIN operations (LOCK-01/06).
///
/// Consumed by the cold-start gate (Plan 11), lock screen (Plan 09), and the
/// Settings security section (Plan 10). Wires the keychain (pinHash slot), the
/// biometric service (re-auth, D-05), and the settings repository (toggles).
///
/// Lives in the applock composition root (not infrastructure/security) — an
/// infrastructure provider watching a feature's settingsRepositoryProvider is
/// a reverse layer dependency (quality report P1-2).

@ProviderFor(appLockService)
final appLockServiceProvider = AppLockServiceProvider._();

/// Application-layer app-lock service — single source of truth for the lock
/// decision (D-01) and all PIN operations (LOCK-01/06).
///
/// Consumed by the cold-start gate (Plan 11), lock screen (Plan 09), and the
/// Settings security section (Plan 10). Wires the keychain (pinHash slot), the
/// biometric service (re-auth, D-05), and the settings repository (toggles).
///
/// Lives in the applock composition root (not infrastructure/security) — an
/// infrastructure provider watching a feature's settingsRepositoryProvider is
/// a reverse layer dependency (quality report P1-2).

final class AppLockServiceProvider
    extends $FunctionalProvider<AppLockService, AppLockService, AppLockService>
    with $Provider<AppLockService> {
  /// Application-layer app-lock service — single source of truth for the lock
  /// decision (D-01) and all PIN operations (LOCK-01/06).
  ///
  /// Consumed by the cold-start gate (Plan 11), lock screen (Plan 09), and the
  /// Settings security section (Plan 10). Wires the keychain (pinHash slot), the
  /// biometric service (re-auth, D-05), and the settings repository (toggles).
  ///
  /// Lives in the applock composition root (not infrastructure/security) — an
  /// infrastructure provider watching a feature's settingsRepositoryProvider is
  /// a reverse layer dependency (quality report P1-2).
  AppLockServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockServiceHash();

  @$internal
  @override
  $ProviderElement<AppLockService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLockService create(Ref ref) {
    return appLockService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLockService>(value),
    );
  }
}

String _$appLockServiceHash() => r'2170e8bfbef63e945e084abbeaf0e755ae63a0a2';
