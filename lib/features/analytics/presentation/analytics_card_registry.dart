import 'package:flutter/material.dart';

import 'providers/state_joy_metric_variant.dart';

/// Snapshot of everything an analytics card needs to (a) be built, (b) decide
/// its visibility, and (c) compute its refresh targets — all derived from the
/// SAME providers the shell's `build` reads, so build-vs-invalidation cannot
/// drift (D-B2 / "卡就是契约").
///
/// Phase 45 contract note: this is the canonical, single-source context for
/// every `widgets/cards/*` card's `<card>RefreshTargets(ctx)` function. Plan 03
/// fills the `List<AnalyticsCardSpec>` registry and the
/// `buildAnalyticsCardContext` helper AROUND this class; do NOT duplicate the
/// context class across card files. This minimal stub exists so the Wave-1 card
/// files (Plan 01) compile independently of Plan 03.
@immutable
class AnalyticsCardContext {
  const AnalyticsCardContext({
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.trendAnchor,
    required this.currencyCode,
    required this.joyMetricVariant,
    required this.isGroupMode,
    required this.locale,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;

  /// `DateTime(endDate.year, endDate.month)` — the month-anchored key the
  /// 6-month expense-trend provider is keyed on (NOT start/end).
  final DateTime trendAnchor;

  /// `bookByIdProvider.value?.currency ?? 'JPY'`.
  final String currencyCode;

  final JoyMetricVariant joyMetricVariant;
  final bool isGroupMode;
  final Locale locale;
}
