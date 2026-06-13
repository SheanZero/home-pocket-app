import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_currency_provider.g.dart';

/// Common-zone foreign currencies shown by default in [CurrencySelectorSheet],
/// in their canonical (un-reordered) order. JPY is NOT in this list — it is
/// always pinned first by the sheet and does NOT participate in recent-use
/// reordering (Open Question 1, UI-SPEC).
const List<String> kCommonZoneCurrencies = <String>[
  'USD',
  'EUR',
  'CNY',
  'HKD',
  'GBP',
];

/// Session-only recent-use currency state (CURR-02/CURR-03).
///
/// Holds an in-session LRU list of recently-selected foreign ISO codes. This
/// is **non-persisted** — it lives only for the lifetime of the Riverpod
/// container and resets to its empty (JPY-default) baseline on app restart
/// (UI-SPEC; threat T-42-14). It MUST NOT write to Drift or secure storage.
///
/// JPY is intentionally absent from the LRU: it is always pinned first by the
/// sheet and never reorders (Open Question 1 resolution).
@riverpod
class RecentCurrency extends _$RecentCurrency {
  /// Most-recent-first list of foreign ISO codes selected this session.
  @override
  List<String> build() => const <String>[];

  /// The last-used foreign currency this session, or null when none has been
  /// selected yet (the entry default is JPY). Used as the suggested default
  /// when reopening the entry screen within the same session.
  String? get lastUsed => state.isEmpty ? null : state.first;

  /// Record [isoCode] as just-used, moving it to the front of the LRU list.
  ///
  /// JPY is ignored — it never participates in recent-use reordering. A code
  /// already present is promoted to the front (deduplicated, immutable update).
  void recordUse(String isoCode) {
    final code = isoCode.toUpperCase();
    if (code == 'JPY') return;
    state = <String>[code, ...state.where((c) => c != code)];
  }

  /// Returns the common zone ([kCommonZoneCurrencies]) re-ordered so that
  /// recently-used codes come first (most-recent-first), followed by the
  /// remaining common-zone codes in their canonical order. JPY is never part
  /// of this list (the sheet pins it first separately).
  List<String> orderedCommonZone() {
    final recentCommon =
        state.where(kCommonZoneCurrencies.contains).toList(growable: false);
    final rest = kCommonZoneCurrencies
        .where((c) => !recentCommon.contains(c))
        .toList(growable: false);
    return <String>[...recentCommon, ...rest];
  }
}
