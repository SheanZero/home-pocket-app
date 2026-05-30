// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_list_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the complete filter + sort state for the transaction list view.
///
/// Kept alive across IndexedStack tab switches (D-01/D-02, SC#2) so that all
/// filter fields — month, day, sort, search, ledger, category, member — persist
/// when the user navigates away from the List tab and returns. Under IndexedStack
/// widgets are never unmounted, so subscriptions never drop; the keepAlive
/// annotation makes the intent explicit and guards against future refactors.

@ProviderFor(ListFilter)
final listFilterProvider = ListFilterProvider._();

/// Holds the complete filter + sort state for the transaction list view.
///
/// Kept alive across IndexedStack tab switches (D-01/D-02, SC#2) so that all
/// filter fields — month, day, sort, search, ledger, category, member — persist
/// when the user navigates away from the List tab and returns. Under IndexedStack
/// widgets are never unmounted, so subscriptions never drop; the keepAlive
/// annotation makes the intent explicit and guards against future refactors.
final class ListFilterProvider
    extends $NotifierProvider<ListFilter, ListFilterState> {
  /// Holds the complete filter + sort state for the transaction list view.
  ///
  /// Kept alive across IndexedStack tab switches (D-01/D-02, SC#2) so that all
  /// filter fields — month, day, sort, search, ledger, category, member — persist
  /// when the user navigates away from the List tab and returns. Under IndexedStack
  /// widgets are never unmounted, so subscriptions never drop; the keepAlive
  /// annotation makes the intent explicit and guards against future refactors.
  ListFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listFilterHash();

  @$internal
  @override
  ListFilter create() => ListFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListFilterState>(value),
    );
  }
}

String _$listFilterHash() => r'cf441242129f814f1970316a54d3ebc2969bf80b';

/// Holds the complete filter + sort state for the transaction list view.
///
/// Kept alive across IndexedStack tab switches (D-01/D-02, SC#2) so that all
/// filter fields — month, day, sort, search, ledger, category, member — persist
/// when the user navigates away from the List tab and returns. Under IndexedStack
/// widgets are never unmounted, so subscriptions never drop; the keepAlive
/// annotation makes the intent explicit and guards against future refactors.

abstract class _$ListFilter extends $Notifier<ListFilterState> {
  ListFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ListFilterState, ListFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ListFilterState, ListFilterState>,
              ListFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
