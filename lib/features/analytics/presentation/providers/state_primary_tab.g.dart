// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_primary_tab.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-scoped primary tab for the Statistics surface.
///
/// The shell updates this before selecting the Statistics bottom-nav item so
/// the entry source is explicit: bottom navigation opens Spending, while the
/// two Joy affordances on Home open Joy. Keep this alive because Home may set
/// it before the lazy shell stack has mounted the analytics screen.

@ProviderFor(SelectedAnalyticsPrimaryTab)
final selectedAnalyticsPrimaryTabProvider =
    SelectedAnalyticsPrimaryTabProvider._();

/// Session-scoped primary tab for the Statistics surface.
///
/// The shell updates this before selecting the Statistics bottom-nav item so
/// the entry source is explicit: bottom navigation opens Spending, while the
/// two Joy affordances on Home open Joy. Keep this alive because Home may set
/// it before the lazy shell stack has mounted the analytics screen.
final class SelectedAnalyticsPrimaryTabProvider
    extends
        $NotifierProvider<SelectedAnalyticsPrimaryTab, AnalyticsPrimaryTab> {
  /// Session-scoped primary tab for the Statistics surface.
  ///
  /// The shell updates this before selecting the Statistics bottom-nav item so
  /// the entry source is explicit: bottom navigation opens Spending, while the
  /// two Joy affordances on Home open Joy. Keep this alive because Home may set
  /// it before the lazy shell stack has mounted the analytics screen.
  SelectedAnalyticsPrimaryTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedAnalyticsPrimaryTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedAnalyticsPrimaryTabHash();

  @$internal
  @override
  SelectedAnalyticsPrimaryTab create() => SelectedAnalyticsPrimaryTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsPrimaryTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsPrimaryTab>(value),
    );
  }
}

String _$selectedAnalyticsPrimaryTabHash() =>
    r'd15de009513b7b19ce86f424a877972000c2ccc1';

/// Session-scoped primary tab for the Statistics surface.
///
/// The shell updates this before selecting the Statistics bottom-nav item so
/// the entry source is explicit: bottom navigation opens Spending, while the
/// two Joy affordances on Home open Joy. Keep this alive because Home may set
/// it before the lazy shell stack has mounted the analytics screen.

abstract class _$SelectedAnalyticsPrimaryTab
    extends $Notifier<AnalyticsPrimaryTab> {
  AnalyticsPrimaryTab build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AnalyticsPrimaryTab, AnalyticsPrimaryTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnalyticsPrimaryTab, AnalyticsPrimaryTab>,
              AnalyticsPrimaryTab,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
