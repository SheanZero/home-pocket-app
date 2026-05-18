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
