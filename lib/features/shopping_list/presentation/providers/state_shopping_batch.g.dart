// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_shopping_batch.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages batch-selection mode for the shopping list.
///
/// NOT keepAlive (transient, D38-03) — resets when the provider is no longer
/// watched. MUST remain at app-root scope so [MainShellScreen] can read it
/// to hide the nav bar during batch mode (Pitfall 3 — never override in a
/// local ProviderScope).
///
/// Riverpod 3 suffix-stripping: `class BatchSelectMode` → `batchSelectModeProvider`.

@ProviderFor(BatchSelectMode)
final batchSelectModeProvider = BatchSelectModeProvider._();

/// Manages batch-selection mode for the shopping list.
///
/// NOT keepAlive (transient, D38-03) — resets when the provider is no longer
/// watched. MUST remain at app-root scope so [MainShellScreen] can read it
/// to hide the nav bar during batch mode (Pitfall 3 — never override in a
/// local ProviderScope).
///
/// Riverpod 3 suffix-stripping: `class BatchSelectMode` → `batchSelectModeProvider`.
final class BatchSelectModeProvider
    extends $NotifierProvider<BatchSelectMode, BatchSelectModeState> {
  /// Manages batch-selection mode for the shopping list.
  ///
  /// NOT keepAlive (transient, D38-03) — resets when the provider is no longer
  /// watched. MUST remain at app-root scope so [MainShellScreen] can read it
  /// to hide the nav bar during batch mode (Pitfall 3 — never override in a
  /// local ProviderScope).
  ///
  /// Riverpod 3 suffix-stripping: `class BatchSelectMode` → `batchSelectModeProvider`.
  BatchSelectModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchSelectModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchSelectModeHash();

  @$internal
  @override
  BatchSelectMode create() => BatchSelectMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchSelectModeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchSelectModeState>(value),
    );
  }
}

String _$batchSelectModeHash() => r'9f3ece2bf3dca4225aa5c8fdfa57ff12e7f8d035';

/// Manages batch-selection mode for the shopping list.
///
/// NOT keepAlive (transient, D38-03) — resets when the provider is no longer
/// watched. MUST remain at app-root scope so [MainShellScreen] can read it
/// to hide the nav bar during batch mode (Pitfall 3 — never override in a
/// local ProviderScope).
///
/// Riverpod 3 suffix-stripping: `class BatchSelectMode` → `batchSelectModeProvider`.

abstract class _$BatchSelectMode extends $Notifier<BatchSelectModeState> {
  BatchSelectModeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BatchSelectModeState, BatchSelectModeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BatchSelectModeState, BatchSelectModeState>,
              BatchSelectModeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
