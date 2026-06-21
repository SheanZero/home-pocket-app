// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_donut_dimension.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current device's id — the「自己」key for the 成员 dimension (260621-son
/// Bug 1/2). Wraps `keyManager.getDeviceId()` (the same source the transaction
/// writer assigns to `transactions.deviceId`), so the self record in the member
/// breakdown can be matched and labelled with the user's profile name.
///
/// Plain auto-dispose `@riverpod`, consistent with the other analytics state in
/// this file; tests override it with a fixed deviceId.

@ProviderFor(currentDeviceId)
final currentDeviceIdProvider = CurrentDeviceIdProvider._();

/// The current device's id — the「自己」key for the 成员 dimension (260621-son
/// Bug 1/2). Wraps `keyManager.getDeviceId()` (the same source the transaction
/// writer assigns to `transactions.deviceId`), so the self record in the member
/// breakdown can be matched and labelled with the user's profile name.
///
/// Plain auto-dispose `@riverpod`, consistent with the other analytics state in
/// this file; tests override it with a fixed deviceId.

final class CurrentDeviceIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The current device's id — the「自己」key for the 成员 dimension (260621-son
  /// Bug 1/2). Wraps `keyManager.getDeviceId()` (the same source the transaction
  /// writer assigns to `transactions.deviceId`), so the self record in the member
  /// breakdown can be matched and labelled with the user's profile name.
  ///
  /// Plain auto-dispose `@riverpod`, consistent with the other analytics state in
  /// this file; tests override it with a fixed deviceId.
  CurrentDeviceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDeviceIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDeviceIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return currentDeviceId(ref);
  }
}

String _$currentDeviceIdHash() => r'5d147a597c6b2c15f585f95cf0ae2a718a495917';

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
