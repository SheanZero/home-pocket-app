import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../generated/app_localizations.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../joy_spend_drawer_body.dart';
import 'analytics_data_card.dart';

/// 悦己花在哪 card — THIN WRAPPER (round-5 r5, Phase 47-lfp — D2).
///
/// Round-5 r5 (260620-lfp / D2) nests the joybar INSIDE [CategoryDonutCard] as a
/// connector + pink drawer; the registry de-registers this card. The FILE is
/// RETAINED (not deleted) because `anti_toxicity_phase47_test.dart` and
/// `joy_spend_card_golden_test.dart` build it directly — it stays a compiling
/// thin wrapper that watches the SAME `joyCategoryAmountsProvider` family and
/// delegates its body to the shared [JoySpendDrawerBody] (single source for both
/// the standalone card and the nested donut drawer).
///
/// Mirrors the single-source `ConsumerWidget` + `*RefreshTargets` contract:
/// watches exactly ONE provider family ([joyCategoryAmountsProvider]) and routes
/// its error-retry through the single-source [joySpendRefreshTargets]. Ambient
/// celebrate-past — zero target/streak/ranking.
class JoySpendCard extends ConsumerWidget {
  const JoySpendCard({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.joyMetricVariant,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final JoyMetricVariant joyMetricVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = joySpendRefreshTargets(_ctx());

    final amountsAsync = ref.watch(
      joyCategoryAmountsProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return amountsAsync.when(
      data: (amounts) => AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleJoySpend,
        caption: S.of(context).analyticsCardCaptionJoySpend,
        child: JoySpendDrawerBody(amounts: amounts),
      ),
      loading: () => const SizedBox(height: 200),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.single),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's single target. `trendAnchor`
  /// is derived from `endDate`; `isGroupMode`/`locale` are unused by the targets.
  AnalyticsCardContext _ctx() => AnalyticsCardContext(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: const Locale('ja'),
  );
}

/// Single-source refresh targets for [JoySpendCard] (D-B2). Still referenced by
/// the retained tests; the registry folds this same `joyCategoryAmountsProvider`
/// target into `categoryDonutRefreshTargets` so the nested drawer keeps
/// refreshing after de-registration (GUARD-01 / Pitfall-3).
List<ProviderBase<Object?>> joySpendRefreshTargets(AnalyticsCardContext ctx) => [
  joyCategoryAmountsProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];
