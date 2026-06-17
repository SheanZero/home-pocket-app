import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../analytics_card_registry.dart';
import '../../providers/state_happiness.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../family_insight_card.dart';

/// Group-mode-only family-aggregate insight card for the Stories group.
///
/// Phase 45: promoted verbatim from the private `_FamilyCard` inline in
/// `analytics_screen.dart` (D-A1 byte-faithful move — class name de-privatised,
/// `super.key` added, error-retry now invalidates the single-source
/// `familyInsightRefreshTargets` element instead of a literal). Watches
/// `familyHappinessProvider(startDate, endDate, joyMetricVariant)` (NO bookId —
/// it derives ids internally) and renders [FamilyInsightCard] with the
/// shell-resolved `shadowBooksAsync.value` for display only.
///
/// Registry visibility (Plan 03): `isVisible: (ctx) => ctx.isGroupMode` (D-B4),
/// so `familyInsightRefreshTargets` is only ever expanded in group mode and
/// solo mode never invalidates family providers.
///
/// Home-isolation (D-B3): the `shadowBooks` display prop is typed
/// `AsyncValue<List<Object>?>` (covariantly accepts the shell's shadow-book
/// list) precisely so this card file imports NO home-feature provider — the
/// concrete shadow-book model type lives only in a home-feature provider file,
/// and `FamilyInsightCard.shadowBooks` already accepts `List<Object>?`.
class FamilyInsightDataCard extends ConsumerWidget {
  const FamilyInsightDataCard({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.isGroupMode,
    required this.shadowBooksAsync,
    required this.locale,
    required this.joyMetricVariant,
  });

  final DateTime startDate;
  final DateTime endDate;
  final bool isGroupMode;
  final AsyncValue<List<Object>?> shadowBooksAsync;
  final Locale locale;
  final JoyMetricVariant joyMetricVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = familyInsightRefreshTargets(_ctx());

    final familyAsync = ref.watch(
      familyHappinessProvider(
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );
    return familyAsync.when(
      data: (family) => FamilyInsightCard(
        family: family,
        isGroupMode: isGroupMode,
        shadowBooks: shadowBooksAsync.value,
        locale: locale,
      ),
      loading: () => const SizedBox(height: 110),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.single),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's single target. `bookId`,
  /// `currencyCode` and `trendAnchor` are unused by
  /// `familyInsightRefreshTargets`.
  AnalyticsCardContext _ctx() => AnalyticsCardContext(
    bookId: '',
    startDate: startDate,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    currencyCode: 'JPY',
    joyMetricVariant: joyMetricVariant,
    isGroupMode: isGroupMode,
    locale: locale,
  );
}

/// Single-source refresh targets for [FamilyInsightDataCard] (D-B2).
///
/// Returns ONLY `familyHappinessProvider` and DELIBERATELY DROPS the direct
/// shadow-books invalidate the old shell `_refresh` performed (D-B3 Option A /
/// Assumption A1): the shadow-books provider is a home-feature provider, and
/// `familyHappinessProvider` re-reads it transitively via its internal
/// `ref.watch(...future)`. Dropping the direct invalidate keeps the registry
/// union ⊆ analytics (zero home-feature providers) while group-mode
/// pull-to-refresh still refreshes family data transitively (verified by the
/// group-mode refresh test in Plan 05).
List<ProviderBase<Object?>> familyInsightRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  familyHappinessProvider(
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];
