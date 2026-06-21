import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/analytics_category_palette.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/presentation/utils/category_display_utils.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/category_l1_rollup.dart';
import '../../domain/models/member_spend_breakdown.dart';
import '../../domain/models/monthly_report.dart';
import '../screens/category_drill_down_screen.dart';

/// Donut chart + count-up center total + tappable L1-rollup legend rows
/// (round-5 r5 §1, 260620-lfp R2). Extracted out of `cards/category_donut_card.dart`
/// to keep that wrapper under the REDES-01 400-LOC cap; the card composes this
/// hero + the nested 悦己 joy drawer.
///
/// §1d colour algorithm (mock-exact): walk rows amount-descending; a joy-ledger
/// L1 → 樱粉 [AnalyticsCategoryPalette.joy]; otherwise the next survival-sequence
/// colour; the long-tail 「其他」 rollup → neutral 藕灰. The arc colour MUST equal
/// its legend-row swatch colour — both read from the same parallel colour list.
class DonutHero extends ConsumerWidget {
  const DonutHero({
    super.key,
    required this.breakdowns,
    required this.total,
    required this.entryCount,
    required this.month,
    required this.joyL1Ids,
    required this.categoryMap,
    required this.bookId,
    this.members,
    this.memberNames,
    this.memberEmojis,
    this.controls,
  });

  final List<CategoryBreakdown> breakdowns;
  final int total;

  /// 260621-son Bug 3: the 分类/成员 toggle + member-filter row, rendered between
  /// the donut Stack and the legend rows (both category and member mode). Null =
  /// not shown. Injected by `CategoryDonutCard` so the card-level Column no
  /// longer owns it (it used to sit above the hero).
  final Widget? controls;

  /// Total expense entry count for the window (hero-top pill + center 3rd line).
  final int entryCount;

  /// Display-anchor month (hero-top pill).
  final int month;

  /// L1 category ids that belong to the 悦己 (joy) ledger — coloured 樱粉.
  final Set<String> joyL1Ids;

  final Map<String, Category> categoryMap;
  final String bookId;

  /// §D2 member mode (260620-v2m): when non-null, the hero renders per-member
  /// slices + member legend rows instead of the category breakdown. Each entry is
  /// `(deviceId, amount, transactionCount)`.
  final List<MemberSpendBreakdown>? members;

  /// deviceId → resolved display name (via activeGroupMembers). Falls back to a
  /// truncated deviceId when absent.
  final Map<String, String>? memberNames;

  /// deviceId → avatar emoji (via activeGroupMembers).
  final Map<String, String>? memberEmojis;

  /// §D3: on-ring % is suppressed below this share so small/long-tail slices
  /// don't overlap (legend still shows the %). Recorded in SUMMARY.
  static const double _onRingPctThreshold = 0.05;

  /// A deliberately-suppressed on-ring label (D3: small slices / long-tail
  /// 「其他」 stay legend-only — no on-ring %). Held as a named const empty
  /// string so no value slice carries a bare empty title literal; the
  /// suppression intent stays explicit and grep-clean.
  static const String _suppressedRingTitle = '';

  /// Max width (px) for the donut center total. The hole is
  /// `centerSpaceRadius: 54` → ~108px inner ø; this keeps the count-up amount
  /// inside the ring with margin. Paired with `FittedBox.scaleDown` so large
  /// (7+ digit JPY) totals shrink to fit instead of overflowing the donut.
  static const double _centerTotalMaxWidth = 96;

  /// On-ring % label for a slice, or the suppressed label when below the
  /// threshold (small slice → legend-only, D3).
  static String _onRingPctTitle(int amount, int total) {
    if (total <= 0) return _suppressedRingTitle;
    final share = amount / total;
    if (share < _onRingPctThreshold) return _suppressedRingTitle;
    return '${(share * 100).round()}%';
  }

  bool get _memberMode => members != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    if (_memberMode) {
      return _buildMemberMode(context, palette, l10n, locale);
    }

    // D-11 single source: roll the L2-grain breakdowns up to <=10 L1 rows,
    // amount-descending. NEVER a second rollup loop.
    final rows = rollupCategoryBreakdownsToL1(
      breakdowns,
      categoryMap,
      topN: 10,
    );

    final donutTotal = rows.fold<int>(0, (sum, r) => sum + r.amount);

    // WR-02 / D-03: when the L1 rollup is truncated to topN (>10 categories had
    // spend), the donut keeps only the top 10 (donutTotal < true total). The
    // residual long-tail is shown as a single neutral, non-tappable "Other"
    // slice/row of (total - donutTotal), so slices + legend percentages
    // reconcile to the TRUE center total (monthly.totalExpenses).
    final otherAmount = total - donutTotal;
    final hasOther = otherAmount > 0;

    // §1d colour algorithm (mock-exact, do NOT change).
    final rowColors = <Color>[];
    var survivalIdx = 0;
    for (final row in rows) {
      if (joyL1Ids.contains(row.categoryId)) {
        rowColors.add(AnalyticsCategoryPalette.joy);
      } else {
        rowColors.add(AnalyticsCategoryPalette.survivalAt(survivalIdx++));
      }
    }
    const otherColor = AnalyticsCategoryPalette.other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // §1b hero-top: caption (left) + entry-count·month pill (right).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.analyticsDonutHeroCap,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: palette.dailyLight,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                l10n.analyticsDonutHeroTag(entryCount, month),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.dailyText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (rows.isNotEmpty)
                PieChart(
                  PieChartData(
                    sections: [
                      for (final entry in rows.asMap().entries)
                        PieChartSectionData(
                          value: entry.value.amount.toDouble(),
                          // §D3: on-ring % label (28.9% → 29%). Small slices below
                          // [_onRingPctThreshold] are suppressed (legend-only) so
                          // 8–10 categories don't overlap. % uses the SAME口径 as
                          // the legend rows (amount / true total).
                          title: _onRingPctTitle(entry.value.amount, total),
                          color: rowColors[entry.key],
                          // §1c→D3: slightly thicker ring + smaller hole so the
                          // on-ring % is legible; label centered on the band.
                          radius: 30,
                          cornerRadius: 0,
                          titlePositionPercentageOffset: 0.5,
                          titleStyle: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: palette.card,
                          ),
                          // TI1-ICON-01: L1 category icon overlaid above the
                          // on-ring %, but ONLY when the % is shown (same露出 rule
                          // as the title — suppressed small slices get no badge so
                          // the band doesn't crowd). badge sits slightly inward of
                          // the title (offset < 0.5) → lands above the % text.
                          badgeWidget:
                              _onRingPctTitle(entry.value.amount, total) ==
                                  _suppressedRingTitle
                              ? null
                              : Icon(
                                  parentCategoryIconFromId(
                                    entry.value.categoryId,
                                  ),
                                  size: 11,
                                  color: palette.card,
                                ),
                          badgePositionPercentageOffset: 0.35,
                        ),
                      // WR-02: neutral long-tail "Other" slice, sorted last — its
                      // on-ring % is suppressed (D3: long-tail Other stays
                      // legend-only) regardless of size.
                      if (hasOther)
                        PieChartSectionData(
                          value: otherAmount.toDouble(),
                          title: _suppressedRingTitle,
                          color: otherColor,
                          radius: 30,
                          cornerRadius: 0,
                        ),
                    ],
                    sectionsSpace: 0,
                    centerSpaceRadius: 54,
                  ),
                ),
              // §1e center: 3 lines (label / count-up total / entry-count).
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.analyticsDonutCenterLabel,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                  // Center total: smaller base size + auto-shrink so large
                  // amounts (7+ digit JPY like ¥2,041,856) never overflow the
                  // donut hole. FittedBox.scaleDown only shrinks past the base
                  // size — short amounts keep the full 24px.
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: total),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => SizedBox(
                      width: _centerTotalMaxWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          NumberFormatter.formatCurrency(value, 'JPY', locale),
                          maxLines: 1,
                          style: AppTextStyles.amountMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.analyticsDonutCenterCount(entryCount),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 260621-son Bug 3: 分类/成员 toggle + filter row between donut & legend.
        ?controls,
        // §1f: L1-rollup legend ROWS — each fully tappable → drill push (D-B1).
        // The last row owns no bottom divider (mock `.hl:last-child`).
        for (final entry in rows.asMap().entries)
          LegendRow(
            key: ValueKey('donut_legend_row_${entry.value.categoryId}'),
            color: rowColors[entry.key],
            // TI1-ICON-01: L1 (top-level) category icon before the name.
            leadingIcon: parentCategoryIconFromId(entry.value.categoryId),
            name: CategoryLocalizationService.resolveFromId(
              entry.value.categoryId,
              locale,
            ),
            amount: NumberFormatter.formatCurrency(
              entry.value.amount,
              'JPY',
              locale,
            ),
            // WR-02 reconciliation: percentages divide by the TRUE total (NOT
            // donutTotal), so all rows incl. Other reconcile to the center.
            percent: total > 0 ? (entry.value.amount / total * 100).round() : 0,
            showDivider: !(entry.key == rows.length - 1 && !hasOther),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CategoryDrillDownScreen(
                  bookId: bookId,
                  l1CategoryId: entry.value.categoryId,
                ),
              ),
            ),
          ),
        // WR-02: the long-tail "Other" legend row — neutral swatch, sorted last,
        // NON-tappable (no L1 ancestor to drill into → null onTap, no chevron),
        // and last → no bottom divider.
        if (hasOther)
          LegendRow(
            key: const ValueKey('donut_legend_row_other'),
            color: otherColor,
            name: l10n.analyticsCategoryDonutOther,
            amount: NumberFormatter.formatCurrency(otherAmount, 'JPY', locale),
            percent: total > 0 ? (otherAmount / total * 100).round() : 0,
            showDivider: false,
            onTap: null,
          ),
      ],
    );
  }

  /// §D2 member-mode render: per-member donut slices (on-ring % per member) +
  /// member legend rows (emoji + display name + ¥amount + %), center keeps the
  /// 本月支出 + filtered total. Single-device degrades to ONE slice (100%).
  Widget _buildMemberMode(
    BuildContext context,
    AppPalette palette,
    S l10n,
    Locale locale,
  ) {
    final memberRows = members!;
    final memberColors = <Color>[
      for (final m in memberRows)
        AnalyticsCategoryPalette.memberColorFor(m.deviceId),
    ];

    String nameFor(String deviceId) {
      final resolved = memberNames?[deviceId];
      if (resolved != null && resolved.isNotEmpty) return resolved;
      // Fallback: truncated deviceId (never leak the full id beyond a short head).
      return deviceId.length <= 6 ? deviceId : '${deviceId.substring(0, 6)}…';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // §1b hero-top reused (same caption + entry-count·month pill).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.analyticsDonutHeroCap,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: palette.dailyLight,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                l10n.analyticsDonutHeroTag(entryCount, month),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.dailyText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (memberRows.isNotEmpty)
                PieChart(
                  PieChartData(
                    sections: [
                      for (final entry in memberRows.asMap().entries)
                        PieChartSectionData(
                          value: entry.value.amount.toDouble(),
                          title: _onRingPctTitle(entry.value.amount, total),
                          color: memberColors[entry.key],
                          radius: 30,
                          cornerRadius: 0,
                          titlePositionPercentageOffset: 0.5,
                          titleStyle: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: palette.card,
                          ),
                        ),
                    ],
                    sectionsSpace: 0,
                    centerSpaceRadius: 54,
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.analyticsDonutCenterLabel,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                  // Center total: smaller base size + auto-shrink so large
                  // amounts (7+ digit JPY like ¥2,041,856) never overflow the
                  // donut hole. FittedBox.scaleDown only shrinks past the base
                  // size — short amounts keep the full 24px.
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: total),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => SizedBox(
                      width: _centerTotalMaxWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          NumberFormatter.formatCurrency(value, 'JPY', locale),
                          maxLines: 1,
                          style: AppTextStyles.amountMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.analyticsDonutCenterCount(entryCount),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 260621-son Bug 3: 分类/成员 toggle + filter row between donut & legend.
        ?controls,
        // §D2 member legend rows: emoji + display name + ¥amount + %. Not tappable
        // (this round does not drill into a member).
        for (final entry in memberRows.asMap().entries)
          LegendRow(
            key: ValueKey('donut_member_row_${entry.value.deviceId}'),
            color: memberColors[entry.key],
            leadingEmoji: memberEmojis?[entry.value.deviceId],
            name: nameFor(entry.value.deviceId),
            amount: NumberFormatter.formatCurrency(
              entry.value.amount,
              'JPY',
              locale,
            ),
            percent: total > 0
                ? (entry.value.amount / total * 100).round()
                : 0,
            showDivider: entry.key != memberRows.length - 1,
            onTap: null,
          ),
      ],
    );
  }
}

/// A single L1 legend row (round-5 r5 §1f mock `.hl`). By default fully tappable
/// (D-B1 — the ROW is the affordance, not the pie slice). Shows a rounded-square
/// swatch + category name + ¥ amount + % + a 1px bottom divider (except the last
/// row).
///
/// WR-02: when [onTap] is null (the "Other" long-tail rollup), the row renders
/// non-interactive — no `InkWell` — because there is no single L1 to drill into.
class LegendRow extends StatelessWidget {
  const LegendRow({
    super.key,
    required this.color,
    required this.name,
    required this.amount,
    required this.percent,
    required this.showDivider,
    required this.onTap,
    this.leadingEmoji,
    this.leadingIcon,
  });

  final Color color;
  final String name;
  final String amount;
  final int percent;

  /// §D2 member mode: optional avatar emoji shown before the name (replaces the
  /// swatch role visually but the colour swatch is still rendered for the slice
  /// link). Null for category rows.
  final String? leadingEmoji;

  /// TI1-ICON-01: optional L1 (top-level) category icon shown before the name
  /// for category-dimension rows. Null for member rows and the long-tail
  /// 「其他」 row (no single L1 ancestor).
  final IconData? leadingIcon;

  /// §1f: every row but the last carries a 1px bottom divider (mock `.hl` +
  /// `:last-child{border-bottom:0}`).
  final bool showDivider;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tappable = onTap != null;
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.borderDivider)),
            )
          : null,
      child: Row(
        children: [
          // §1f: rounded-square swatch (NOT a circle), colour = arc colour.
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 11),
          // §D2: member rows show the avatar emoji before the name.
          if (leadingEmoji != null && leadingEmoji!.isNotEmpty) ...[
            Text(leadingEmoji!, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 7),
          ],
          // TI1-ICON-01: category-dimension rows show the L1 category icon
          // before the name.
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: palette.textSecondary),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: AppTextStyles.amountSmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            child: Text(
              '$percent%',
              textAlign: TextAlign.end,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
          ),
          // §1f: no chevron icon — the whole row is still tappable (InkWell).
        ],
      ),
    );
    if (!tappable) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
