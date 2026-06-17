import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import '../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import '../domain/models/time_window.dart';
import 'providers/state_analytics.dart';
import 'providers/state_joy_metric_variant.dart';
import 'providers/state_time_window.dart';

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

/// A single analytics card entry in the [analyticsCardRegistry] — the typed
/// spec that is the SINGLE SOURCE OF TRUTH for both (a) the shell's card render
/// order and (b) the `_refresh` invalidation union (D-B1).
///
/// Spec-list pattern (RESEARCH Pattern 1): each card stays a dumb
/// `ConsumerWidget`; the registry holds closures over [AnalyticsCardContext]:
/// - [build] constructs the card from the ctx.
/// - [refreshTargets] delegates to the per-card `<card>RefreshTargets(ctx)`
///   function from Plans 01/02 (no second list — D-B2).
/// - [isVisible] gates conditional cards (D-B4); defaults to always-true.
/// - [sectionHeaderKey] lets Plan 04's shell interleave the section headers
///   1:1 with today's render order.
@immutable
class AnalyticsCardSpec {
  const AnalyticsCardSpec({
    required this.build,
    required this.refreshTargets,
    this.isVisible = _always,
    this.sectionHeaderKey,
  });

  /// Builds the card widget from the shared [AnalyticsCardContext].
  final Widget Function(AnalyticsCardContext ctx) build;

  /// The keyed analytics provider instances this card watches — the physical
  /// source of the `_refresh` union (D-B2). MUST contain only analytics
  /// providers (D-B3); never a `home/*` provider.
  final List<ProviderBase<Object?>> Function(AnalyticsCardContext ctx)
  refreshTargets;

  /// Visibility predicate (D-B4). Only the two family specs override this with
  /// `(ctx) => ctx.isGroupMode`; all others are always-visible.
  final bool Function(AnalyticsCardContext ctx) isVisible;

  /// Optional section-header key (one of the three `analyticsGroupHeader*`
  /// l10n keys) the shell renders ABOVE this card. `null` = no header (the
  /// KPI hero sits above all section headers).
  final String? sectionHeaderKey;

  static bool _always(AnalyticsCardContext _) => true;
}

/// Builds the canonical [AnalyticsCardContext] ONCE from the same providers the
/// shell's `build` reads (analytics_screen.dart:42–67 verbatim), so Plan 04's
/// shell card map and `_refresh` share one source — no build/invalidation
/// drift (D-A1/D-B2).
AnalyticsCardContext buildAnalyticsCardContext(
  BuildContext context,
  WidgetRef ref, {
  required String bookId,
}) {
  final window = ref.watch(selectedTimeWindowProvider);
  final range = window.range;
  final startDate = range.start;
  final endDate = range.end;
  final trendAnchor = DateTime(endDate.year, endDate.month);
  final currencyCode =
      ref
          .watch(accounting_providers.bookByIdProvider(bookId: bookId))
          .value
          ?.currency ??
      'JPY';
  final joyMetricVariant = ref.watch(selectedJoyMetricVariantProvider);
  final isGroupMode = ref.watch(isGroupModeProvider);
  final locale =
      ref.watch(locale_providers.currentLocaleProvider).value ??
      Localizations.localeOf(context);

  return AnalyticsCardContext(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    trendAnchor: trendAnchor,
    currencyCode: currencyCode,
    joyMetricVariant: joyMetricVariant,
    isGroupMode: isGroupMode,
    locale: locale,
  );
}

/// The one shell-level, non-card refresh target: the AppBar's
/// `TimeWindowChip` reads `earliestTransactionMonthProvider` (NOT owned by any
/// card). It is an analytics provider, so the union ⊆ analytics still holds
/// (D-B3).
List<ProviderBase<Object?>> shellRefreshTargets(AnalyticsCardContext ctx) => [
  earliestTransactionMonthProvider(bookId: ctx.bookId),
];
