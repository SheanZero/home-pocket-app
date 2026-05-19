// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_time_window.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-scoped AnalyticsScreen time-window selection (D-12: HomeHero is NOT
/// a consumer). Default = current calendar month per ADR-016 §3 ring semantics
/// consistency.

@ProviderFor(SelectedTimeWindow)
final selectedTimeWindowProvider = SelectedTimeWindowProvider._();

/// Session-scoped AnalyticsScreen time-window selection (D-12: HomeHero is NOT
/// a consumer). Default = current calendar month per ADR-016 §3 ring semantics
/// consistency.
final class SelectedTimeWindowProvider
    extends $NotifierProvider<SelectedTimeWindow, TimeWindow> {
  /// Session-scoped AnalyticsScreen time-window selection (D-12: HomeHero is NOT
  /// a consumer). Default = current calendar month per ADR-016 §3 ring semantics
  /// consistency.
  SelectedTimeWindowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTimeWindowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTimeWindowHash();

  @$internal
  @override
  SelectedTimeWindow create() => SelectedTimeWindow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimeWindow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimeWindow>(value),
    );
  }
}

String _$selectedTimeWindowHash() =>
    r'0a45d88369f9d7cb4db377b4743194eb8c6b41ae';

/// Session-scoped AnalyticsScreen time-window selection (D-12: HomeHero is NOT
/// a consumer). Default = current calendar month per ADR-016 §3 ring semantics
/// consistency.

abstract class _$SelectedTimeWindow extends $Notifier<TimeWindow> {
  TimeWindow build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TimeWindow, TimeWindow>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimeWindow, TimeWindow>,
              TimeWindow,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
