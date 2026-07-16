import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../generated/app_localizations.dart';
import '../../../../settings/presentation/providers/state_locale.dart';
import '../../../domain/models/per_day_joy_count.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../joy_calendar_compact_transaction_row.dart';
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
/// NOT fl_chart) and, BELOW it, an INLINE expandable panel ([AnimatedSize],
/// D-C1). The tapped day is held in local state by [_JoyCalendarBody]; the day's
/// joy一刻 list is read on demand from [joyDayTransactionsProvider]. Cell depth is
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
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
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

  /// 默认选中「今天」——仅当今天落在 anchor 当月内时返回（其它月份返回 null）。
  DateTime? _defaultSelectedDay() {
    final now = DateTime.now();
    if (now.year == widget.anchor.year && now.month == widget.anchor.month) {
      return DateTime(now.year, now.month, now.day);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _defaultSelectedDay();
  }

  @override
  void didUpdateWidget(covariant _JoyCalendarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchor.year != widget.anchor.year ||
        oldWidget.anchor.month != widget.anchor.month) {
      setState(() => _selectedDay = _defaultSelectedDay());
    }
  }

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
          onDayTap: (day) => setState(() {
            final selected = _selectedDay;
            final isSameDay =
                selected != null &&
                selected.year == day.year &&
                selected.month == day.month &&
                selected.day == day.day;
            _selectedDay = isSameDay ? null : day;
          }),
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
/// renders readable compact read-only rows. Empty day → neutral
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

    // WR-04 / D-05: the day-keyed list uses LOCAL `_JoyCalendarBody` state, so the
    // registry union can't key it — mirror the refresh here (invalidate this day's
    // list when the month-anchored counts recompute). GUARD-01 still holds.
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

    return Container(
      key: const ValueKey('joy_calendar_day_panel'),
      margin: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.borderDivider)),
      ),
      child: dayTxnsAsync.when(
        data: (txns) {
          // v15 (260714 task #8): a day-panel head line
          // 「{month}月{day}日 · {count}件のときめき」above the day's records.
          final head = Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.analyticsJoyCalendarDayHead(day.month, day.day, txns.length),
              style: AppTextStyles.supporting.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.joyText,
              ),
            ),
          );
          if (txns.isEmpty) {
            return Column(
              key: const ValueKey('joy_calendar_day_empty'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                head,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.analyticsJoyCalendarDayEmpty,
                    style: AppTextStyles.body.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              head,
              for (final tx in txns)
                JoyCalendarCompactTransactionRow(
                  key: ValueKey('joy_calendar_compact_row_${tx.id}'),
                  transaction: tx,
                  locale: locale,
                ),
            ],
          );
        },
        loading: () => const SizedBox(height: 56),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            l10n.analyticsDrillLoadError,
            style: AppTextStyles.body.copyWith(color: palette.textSecondary),
          ),
        ),
      ),
    );
  }
}
