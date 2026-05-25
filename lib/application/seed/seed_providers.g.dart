// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seed_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Phase 23 D-14: Riverpod provider for [SeedAllUseCase].
///
/// Composes the two existing leaf providers via [ref.watch] so the ordering
/// contract is owned by [SeedAllUseCase.execute()], not by call-site comments.

@ProviderFor(seedAllUseCase)
final seedAllUseCaseProvider = SeedAllUseCaseProvider._();

/// Phase 23 D-14: Riverpod provider for [SeedAllUseCase].
///
/// Composes the two existing leaf providers via [ref.watch] so the ordering
/// contract is owned by [SeedAllUseCase.execute()], not by call-site comments.

final class SeedAllUseCaseProvider
    extends $FunctionalProvider<SeedAllUseCase, SeedAllUseCase, SeedAllUseCase>
    with $Provider<SeedAllUseCase> {
  /// Phase 23 D-14: Riverpod provider for [SeedAllUseCase].
  ///
  /// Composes the two existing leaf providers via [ref.watch] so the ordering
  /// contract is owned by [SeedAllUseCase.execute()], not by call-site comments.
  SeedAllUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seedAllUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seedAllUseCaseHash();

  @$internal
  @override
  $ProviderElement<SeedAllUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SeedAllUseCase create(Ref ref) {
    return seedAllUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeedAllUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeedAllUseCase>(value),
    );
  }
}

String _$seedAllUseCaseHash() => r'bcebc34cabacc512bba1ad28cf271cd6fb3a1445';
