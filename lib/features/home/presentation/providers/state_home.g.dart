// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_home.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global bottom navigation tab index state.
///
/// Defaults to 0 (Home tab). Kept alive so the tab selection
/// persists across navigation events within the shell.

@ProviderFor(SelectedTabIndex)
final selectedTabIndexProvider = SelectedTabIndexProvider._();

/// Global bottom navigation tab index state.
///
/// Defaults to 0 (Home tab). Kept alive so the tab selection
/// persists across navigation events within the shell.
final class SelectedTabIndexProvider
    extends $NotifierProvider<SelectedTabIndex, int> {
  /// Global bottom navigation tab index state.
  ///
  /// Defaults to 0 (Home tab). Kept alive so the tab selection
  /// persists across navigation events within the shell.
  SelectedTabIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTabIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTabIndexHash();

  @$internal
  @override
  SelectedTabIndex create() => SelectedTabIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$selectedTabIndexHash() => r'f53863ea10a26a883f6e835fa78f66eb7997249d';

/// Global bottom navigation tab index state.
///
/// Defaults to 0 (Home tab). Kept alive so the tab selection
/// persists across navigation events within the shell.

abstract class _$SelectedTabIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Selected month/year for the home dashboard.
///
/// Defaults to the current month. Kept alive so the selected month
/// persists across tab switches. State is a named record
/// `({int year, int month})` so callers use `state.year` / `state.month`.

@ProviderFor(HomeSelectedMonth)
final homeSelectedMonthProvider = HomeSelectedMonthProvider._();

/// Selected month/year for the home dashboard.
///
/// Defaults to the current month. Kept alive so the selected month
/// persists across tab switches. State is a named record
/// `({int year, int month})` so callers use `state.year` / `state.month`.
final class HomeSelectedMonthProvider
    extends $NotifierProvider<HomeSelectedMonth, ({int month, int year})> {
  /// Selected month/year for the home dashboard.
  ///
  /// Defaults to the current month. Kept alive so the selected month
  /// persists across tab switches. State is a named record
  /// `({int year, int month})` so callers use `state.year` / `state.month`.
  HomeSelectedMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeSelectedMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeSelectedMonthHash();

  @$internal
  @override
  HomeSelectedMonth create() => HomeSelectedMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int month, int year}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int month, int year})>(value),
    );
  }
}

String _$homeSelectedMonthHash() => r'74681ee3335eb69f5442a3f184f2dd9319725a1b';

/// Selected month/year for the home dashboard.
///
/// Defaults to the current month. Kept alive so the selected month
/// persists across tab switches. State is a named record
/// `({int year, int month})` so callers use `state.year` / `state.month`.

abstract class _$HomeSelectedMonth extends $Notifier<({int month, int year})> {
  ({int month, int year}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<({int month, int year}), ({int month, int year})>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<({int month, int year}), ({int month, int year})>,
              ({int month, int year}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
