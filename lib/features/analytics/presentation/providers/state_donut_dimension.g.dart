// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_donut_dimension.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the donut card's in-screen interaction state — split dimension +
/// member filter.
///
/// Plain `@riverpod` (NOT keepAlive) — analytics cards are auto-dispose and this
/// is a per-screen interaction state, consistent with the other analytics
/// providers and the trend card's local `_TrendBody` state.

@ProviderFor(DonutDimensionState)
final donutDimensionStateProvider = DonutDimensionStateProvider._();

/// Holds the donut card's in-screen interaction state — split dimension +
/// member filter.
///
/// Plain `@riverpod` (NOT keepAlive) — analytics cards are auto-dispose and this
/// is a per-screen interaction state, consistent with the other analytics
/// providers and the trend card's local `_TrendBody` state.
final class DonutDimensionStateProvider
    extends $NotifierProvider<DonutDimensionState, DonutDimensionView> {
  /// Holds the donut card's in-screen interaction state — split dimension +
  /// member filter.
  ///
  /// Plain `@riverpod` (NOT keepAlive) — analytics cards are auto-dispose and this
  /// is a per-screen interaction state, consistent with the other analytics
  /// providers and the trend card's local `_TrendBody` state.
  DonutDimensionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'donutDimensionStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$donutDimensionStateHash();

  @$internal
  @override
  DonutDimensionState create() => DonutDimensionState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DonutDimensionView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DonutDimensionView>(value),
    );
  }
}

String _$donutDimensionStateHash() =>
    r'6186ae0f513232bf1c838a5f68f68bb214e1c08a';

/// Holds the donut card's in-screen interaction state — split dimension +
/// member filter.
///
/// Plain `@riverpod` (NOT keepAlive) — analytics cards are auto-dispose and this
/// is a per-screen interaction state, consistent with the other analytics
/// providers and the trend card's local `_TrendBody` state.

abstract class _$DonutDimensionState extends $Notifier<DonutDimensionView> {
  DonutDimensionView build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DonutDimensionView, DonutDimensionView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DonutDimensionView, DonutDimensionView>,
              DonutDimensionView,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
