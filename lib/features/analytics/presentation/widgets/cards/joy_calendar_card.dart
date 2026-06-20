import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../application/accounting/category_localization_service.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../generated/app_localizations.dart';
import '../../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../../shared/utils/currency_conversion.dart';
import '../../../../accounting/domain/models/transaction.dart';
import '../../../../list/domain/models/tagged_transaction.dart';
import '../../../../list/presentation/widgets/list_transaction_tile.dart';
import '../../../../settings/presentation/providers/state_locale.dart';
import '../../../domain/models/per_day_joy_count.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../joy_calendar_heatmap.dart';
import 'analytics_data_card.dart';

/// 小确幸日历 card (round-5 B card #4, Phase 46 — D-C1).
///
/// Mirrors `category_donut_card.dart`'s single-source `ConsumerWidget` +
/// `*RefreshTargets` contract: watches exactly ONE provider family
/// ([perDayJoyCountsProvider], MONTH-anchored, D-12) and routes its error-retry
/// through the single-source [joyCalendarRefreshTargets].
///
/// On data: an `AnalyticsDataCard` with the custom [JoyCalendarHeatmap] (R-2 —
/// NOT fl_chart) and, BELOW it, an INLINE expandable panel (the card grows in
/// place via `AnimatedSize` — D-C1, NOT a sheet/route). The tapped day is held
/// in local state by [_JoyCalendarBody]; the day's joy一刻 list is read on demand
/// from [joyDayTransactionsProvider] (a day-scoped `findByBookIds(joy)` window —
/// the count model stays count-only). Ambient celebrate-past — the cell depth is
/// f(count), explicitly NOT a streak (ADR-016 §5).
class JoyCalendarCard extends ConsumerWidget {
  const JoyCalendarCard({
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
    final ctx = _ctx();
    final targets = joyCalendarRefreshTargets(ctx);

    final countsAsync = ref.watch(
      perDayJoyCountsProvider(
        bookId: bookId,
        anchor: ctx.trendAnchor,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return countsAsync.when(
      data: (counts) => AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleJoyCalendar,
        caption: S.of(context).analyticsCardCaptionJoyCalendar,
        // round-5 r5 §2a: drop the in-card title/caption — the section header
        // already labels it (same handling as the donut + trend cards).
        showHeader: false,
        child: _JoyCalendarBody(
          bookId: bookId,
          anchor: ctx.trendAnchor,
          counts: counts,
          joyMetricVariant: joyMetricVariant,
        ),
      ),
      loading: () => const SizedBox(height: 280),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.single),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext]. `trendAnchor` is the MONTH-anchored key the
  /// per-day-joy provider is keyed on (D-12); `isGroupMode`/`locale` unused here.
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

/// Single-source refresh targets for [JoyCalendarCard] (D-B2) — keyed on the
/// MONTH-anchored `ctx.trendAnchor` (D-12). The shell `_refresh` union and this
/// card's error-retry both draw from this one list.
List<ProviderBase<Object?>> joyCalendarRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  perDayJoyCountsProvider(
    bookId: ctx.bookId,
    anchor: ctx.trendAnchor,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];

/// Holds the tapped day in local state and renders the heatmap + the inline
/// expandable panel. A tap on a day updates local state (no Navigator route, no
/// bottom sheet — D-C1); the panel grows in place via [AnimatedSize].
class _JoyCalendarBody extends StatefulWidget {
  const _JoyCalendarBody({
    required this.bookId,
    required this.anchor,
    required this.counts,
    required this.joyMetricVariant,
  });

  final String bookId;
  final DateTime anchor;
  final List<PerDayJoyCount> counts;
  final JoyMetricVariant joyMetricVariant;

  @override
  State<_JoyCalendarBody> createState() => _JoyCalendarBodyState();
}

class _JoyCalendarBodyState extends State<_JoyCalendarBody> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final countByDay = <int, int>{
      for (final c in widget.counts)
        if (c.date.year == widget.anchor.year &&
            c.date.month == widget.anchor.month)
          c.date.day: c.count,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JoyCalendarHeatmap(
          anchor: widget.anchor,
          countByDay: countByDay,
          selectedDay: _selectedDay,
          onDayTap: (day) => setState(() => _selectedDay = day),
        ),
        // Inline expansion: grow in place (D-C1). AnimatedSize gives a calm
        // one-shot grow (D-D1 — no loop/glow/pulse).
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _selectedDay == null
              ? const SizedBox(width: double.infinity)
              : _InlineDayPanel(
                  key: const ValueKey('joy_calendar_inline_panel'),
                  bookId: widget.bookId,
                  anchor: widget.anchor,
                  day: _selectedDay!,
                  joyMetricVariant: widget.joyMetricVariant,
                ),
        ),
      ],
    );
  }
}

/// The inline-expanded panel for one tapped day: reads the day's joy一刻 list and
/// renders read-only [ListTransactionTile]s (D-B3 reuse). Empty day → neutral
/// copy. Reads [joyDayTransactionsProvider] — a day-scoped `findByBookIds(joy)`
/// window (the count model stays count-only, D-C1).
class _InlineDayPanel extends ConsumerWidget {
  const _InlineDayPanel({
    super.key,
    required this.bookId,
    required this.anchor,
    required this.day,
    required this.joyMetricVariant,
  });

  final String bookId;

  /// MONTH-anchored key of the heatmap-count provider this panel listens to
  /// (D-12). Used only to mirror the pull-to-refresh invalidation onto the
  /// day-keyed list provider — see the `ref.listen` in [build].
  final DateTime anchor;

  final DateTime day;
  final JoyMetricVariant joyMetricVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    // WR-04 (46-REVIEW option (a) / D-05 "失效重算"): pull-to-refresh invalidates
    // `perDayJoyCountsProvider` (it is in `joyCalendarRefreshTargets`), but the
    // expanded day's inline list reads the day-keyed `joyDayTransactionsProvider`,
    // whose `day` key is LOCAL `_JoyCalendarBody` state — unknown at registry
    // build, so the registry union cannot key it. We mirror the refresh from the
    // panel: when the month-anchored counts provider is recomputed, invalidate
    // THIS day's list provider so the inline rows re-fetch alongside the heatmap
    // count (no stale/deleted rows). GUARD-01: `joyDayTransactionsProvider` is an
    // analytics provider — no home-feature provider enters the union.
    ref.listen(
      perDayJoyCountsProvider(
        bookId: bookId,
        anchor: anchor,
        joyMetricVariant: joyMetricVariant,
      ),
      (_, _) => ref.invalidate(
        joyDayTransactionsProvider(
          bookId: bookId,
          day: day,
          joyMetricVariant: joyMetricVariant,
        ),
      ),
    );

    final dayTxnsAsync = ref.watch(
      joyDayTransactionsProvider(
        bookId: bookId,
        day: day,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: dayTxnsAsync.when(
        data: (txns) {
          if (txns.isEmpty) {
            return Padding(
              key: const ValueKey('joy_calendar_day_empty'),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.analyticsJoyCalendarDayEmpty,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tx in txns)
                _readOnlyTile(context, tx, locale, palette),
            ],
          );
        },
        loading: () => const SizedBox(height: 56),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            l10n.analyticsDrillLoadError,
            style: AppTextStyles.bodyMedium.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// READ-ONLY [ListTransactionTile] (D-B3) — mirrors the drill screen's
  /// pre-formatting contract; `readOnly: true` suppresses swipe-delete +
  /// tap-to-edit. These are joy-ledger rows only.
  Widget _readOnlyTile(
    BuildContext context,
    Transaction transaction,
    Locale locale,
    AppPalette palette,
  ) {
    final tagText = S.of(context).listLedgerJoy;
    final tagBgColor = palette.joyLight;
    final tagTextColor = palette.joy;

    final category = CategoryLocalizationService.resolveFromId(
      transaction.categoryId,
      locale,
    );
    final formattedAmount = NumberFormatter.formatCurrency(
      transaction.amount,
      'JPY',
      locale,
    );

    final originalCurrency = transaction.originalCurrency;
    final originalAmount = transaction.originalAmount;
    final String? foreignAnnotation =
        (originalCurrency != null &&
            originalCurrency.toUpperCase() != 'JPY' &&
            originalAmount != null)
        ? NumberFormatter.formatCurrency(
            originalAmount / subunitToUnitFor(originalCurrency),
            originalCurrency,
            locale,
            trimWholeFraction: true,
          )
        : null;

    return ListTransactionTile(
      taggedTx: TaggedTransaction(transaction: transaction),
      bookId: bookId,
      onTap: _noop,
      onDeleted: _noop,
      tagText: tagText,
      tagBgColor: tagBgColor,
      tagTextColor: tagTextColor,
      category: category,
      categoryColor: tagTextColor,
      formattedAmount: formattedAmount,
      l1Icon: _resolveL1IconForCategory(transaction.categoryId),
      locale: locale,
      merchant: transaction.merchant,
      satisfactionValue: transaction.joyFullness,
      showDate: false,
      foreignAnnotation: foreignAnnotation,
      readOnly: true,
    );
  }

  static void _noop() {}

  /// Mirrors `list_screen.dart` / drill screen's static L1 icon map.
  static IconData _resolveL1IconForCategory(String categoryId) {
    const iconMap = <String, IconData>{
      'cat_food': Icons.restaurant,
      'cat_daily': Icons.local_mall,
      'cat_transport': Icons.directions_bus,
      'cat_hobbies': Icons.sports_esports,
      'cat_clothing': Icons.checkroom,
      'cat_social': Icons.people,
      'cat_health': Icons.local_hospital,
      'cat_education': Icons.school,
      'cat_utilities': Icons.flash_on,
      'cat_communication': Icons.phone_iphone,
      'cat_housing': Icons.home,
      'cat_car': Icons.directions_car,
      'cat_tax': Icons.account_balance,
      'cat_insurance': Icons.security,
      'cat_special': Icons.star,
      'cat_savings': Icons.savings,
      'cat_other': Icons.more_horiz,
    };
    if (!categoryId.startsWith('cat_')) return Icons.category;
    final withoutPrefix = categoryId.substring(4);
    final parts = withoutPrefix.split('_');
    final l1Key = 'cat_${parts.first}';
    return iconMap[l1Key] ?? Icons.category;
  }
}
