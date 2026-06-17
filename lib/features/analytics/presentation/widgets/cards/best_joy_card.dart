import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../analytics_card_registry.dart';
import '../../providers/state_happiness.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../best_joy_story_strip.dart';

/// Best joy-moment "story" strip for the Stories group.
///
/// Phase 45: promoted verbatim from the private `_BestJoyCard` inline in
/// `analytics_screen.dart` (D-A1 byte-faithful move — class name de-privatised,
/// `super.key` added, error-retry now invalidates the single-source
/// `bestJoyRefreshTargets` element instead of a literal). Renders the leaf
/// [BestJoyStoryStrip] DIRECTLY — no shared title/caption shell.
///
/// `bestJoyRefreshTargets` is the single source (D-B2) for the registry
/// `_refresh` union (Plan 03/04) and this card's error-retry.
class BestJoyCard extends ConsumerWidget {
  const BestJoyCard({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.locale,
    required this.joyMetricVariant,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final Locale locale;
  final JoyMetricVariant joyMetricVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = bestJoyRefreshTargets(_ctx());

    final joyAsync = ref.watch(
      bestJoyMomentProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );
    return joyAsync.when(
      data: (joy) => BestJoyStoryStrip(
        bestJoy: joy,
        currencyCode: currencyCode,
        locale: locale,
      ),
      loading: () => const SizedBox(height: 120),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.single),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's single target. `trendAnchor`
  /// and `isGroupMode` are unused by `bestJoyRefreshTargets`.
  AnalyticsCardContext _ctx() => AnalyticsCardContext(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    currencyCode: currencyCode,
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: locale,
  );
}

/// Single-source refresh targets for [BestJoyCard] (D-B2), reused by the
/// registry `_refresh` union and this card's error-retry.
List<ProviderBase<Object?>> bestJoyRefreshTargets(AnalyticsCardContext ctx) => [
  bestJoyMomentProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];
