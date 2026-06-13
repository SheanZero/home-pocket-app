// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_recent_currency.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-only recent-use currency state (CURR-02/CURR-03).
///
/// Holds an in-session LRU list of recently-selected foreign ISO codes. This
/// is **non-persisted** — it lives only for the lifetime of the Riverpod
/// container and resets to its empty (JPY-default) baseline on app restart
/// (UI-SPEC; threat T-42-14). It MUST NOT write to Drift or secure storage.
///
/// JPY is intentionally absent from the LRU: it is always pinned first by the
/// sheet and never reorders (Open Question 1 resolution).

@ProviderFor(RecentCurrency)
final recentCurrencyProvider = RecentCurrencyProvider._();

/// Session-only recent-use currency state (CURR-02/CURR-03).
///
/// Holds an in-session LRU list of recently-selected foreign ISO codes. This
/// is **non-persisted** — it lives only for the lifetime of the Riverpod
/// container and resets to its empty (JPY-default) baseline on app restart
/// (UI-SPEC; threat T-42-14). It MUST NOT write to Drift or secure storage.
///
/// JPY is intentionally absent from the LRU: it is always pinned first by the
/// sheet and never reorders (Open Question 1 resolution).
final class RecentCurrencyProvider
    extends $NotifierProvider<RecentCurrency, List<String>> {
  /// Session-only recent-use currency state (CURR-02/CURR-03).
  ///
  /// Holds an in-session LRU list of recently-selected foreign ISO codes. This
  /// is **non-persisted** — it lives only for the lifetime of the Riverpod
  /// container and resets to its empty (JPY-default) baseline on app restart
  /// (UI-SPEC; threat T-42-14). It MUST NOT write to Drift or secure storage.
  ///
  /// JPY is intentionally absent from the LRU: it is always pinned first by the
  /// sheet and never reorders (Open Question 1 resolution).
  RecentCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentCurrencyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentCurrencyHash();

  @$internal
  @override
  RecentCurrency create() => RecentCurrency();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$recentCurrencyHash() => r'7166ecc71f293d0d627aa75060bb86ac165c92d8';

/// Session-only recent-use currency state (CURR-02/CURR-03).
///
/// Holds an in-session LRU list of recently-selected foreign ISO codes. This
/// is **non-persisted** — it lives only for the lifetime of the Riverpod
/// container and resets to its empty (JPY-default) baseline on app restart
/// (UI-SPEC; threat T-42-14). It MUST NOT write to Drift or secure storage.
///
/// JPY is intentionally absent from the LRU: it is always pinned first by the
/// sheet and never reorders (Open Question 1 resolution).

abstract class _$RecentCurrency extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
