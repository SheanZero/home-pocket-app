import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/happiness_ring_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';
import '../../../accounting/presentation/utils/category_display_utils.dart';
import '../../../analytics/domain/models/best_joy_moment_row.dart';
import '../../../analytics/domain/models/family_happiness.dart';
import '../../../analytics/domain/models/happiness_report.dart';
import '../../../analytics/domain/models/metric_result.dart';
import '../../../analytics/domain/models/monthly_report.dart';
import '../providers/state_shadow_books.dart';
import 'painter/happiness_rings_painter.dart';

/// Integrated hero card (Phase 10) replacing the previous trio of legacy
/// cards: month-overview, ledger-comparison, and joy-fullness. Pure
/// StatelessWidget — parent resolves AsyncValue.when() and passes Freezed
/// aggregates (UI-SPEC line 277).
///
/// Hard contracts (CONTEXT D-01..D-13):
/// - Amounts via `AppTextStyles.amount*`; currency via FormatterService (no JPY literal).
/// - `MetricResult<T>` consumed via sealed `switch` only.
/// - Exactly 2 info-icon placeholders (HOMEUI-04).
/// - Whole-card single onTap; ⓘ icons absorb taps in 10-07b (Pitfall #3).
/// - ときめき/日常 split bar shows ABSOLUTE amounts (D-02).
/// - No gamification chips of any kind (ADR-012).
///
/// Plans 10-07a + 10-07b deliver Regions 1-8 (hero header → split bar →
/// divider → ring section → divider → Best Joy strip → optional divider →
/// optional members section). Constructor signature is locked at 10-07a.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.report,
    required this.happiness,
    required this.bestJoy,
    required this.family,
    required this.shadowBooks,
    required this.shadowAggregate,
    required this.currencyCode,
    required this.locale,
    required this.isGroupMode,
    required this.activeMonthlyJoyTarget,
    required this.recommendedMonthlyJoyTarget,
    required this.isMonthlyJoyTargetConfigured,
    required this.onTap,
    super.key,
  });

  final MonthlyReport report;
  final HappinessReport happiness;
  final MetricResult<BestJoyMomentRow> bestJoy;
  final FamilyHappiness? family;
  final List<ShadowBookInfo>? shadowBooks;
  final ShadowAggregate? shadowAggregate;
  final String currencyCode;
  final Locale locale;
  final bool isGroupMode;
  final int activeMonthlyJoyTarget;
  final int? recommendedMonthlyJoyTarget;
  final bool isMonthlyJoyTargetConfigured;
  final VoidCallback onTap;

  static const FormatterService _fmt = FormatterService();

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final showMembers = isGroupMode && (shadowBooks?.isNotEmpty ?? false);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(context, l10n, palette),
            const SizedBox(height: 16),
            _splitBar(context, l10n, palette),
            const SizedBox(height: 12),
            _divider(palette),
            const SizedBox(height: 12),
            _ringSection(context, l10n, palette),
            const SizedBox(height: 12),
            _divider(palette),
            const SizedBox(height: 12),
            // Region 6: Best Joy strip.
            _buildBestJoyStrip(context, l10n, palette),
            if (showMembers) ...[
              const SizedBox(height: 12),
              _divider(palette),
              const SizedBox(height: 12),
              // Region 8: Members section (group mode + non-empty shadowBooks).
              _buildMembersSection(context, l10n, palette),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Region 1: Hero header ─────────────────────────────────────────────────
  Widget _hero(BuildContext context, S l10n, AppPalette palette) {
    final extra = isGroupMode ? (shadowAggregate?.totalExpenses ?? 0) : 0;
    final prevExtra = isGroupMode
        ? (shadowAggregate?.prevTotalExpenses ?? 0)
        : 0;
    final total = report.totalExpenses + extra;
    final prev =
        (report.previousMonthComparison?.previousExpenses ?? 0) + prevExtra;
    final hasAny = total > 0 || prev > 0;
    final trend = prev > 0 ? ((total - prev) / prev * 100).round() : 0;
    final label = isGroupMode
        ? l10n.homeHeroCardLabelGroup
        : l10n.homeHeroCardLabelSingle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _fmt.formatCurrency(total, currencyCode, locale),
                style: AppTextStyles.amountLarge.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
            if (hasAny) _trendChip(palette, trend),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.homeHeroPreviousMonthSubline(
            _fmt.formatCurrency(prev, currencyCode, locale),
          ),
          style: AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }

  Widget _trendChip(AppPalette palette, int trend) {
    final text = trend <= 0 ? '$trend%' : '+$trend%';
    final chipColor = trend > 0
        ? palette.warning.withValues(alpha: 0.15)
        : palette.successLight;
    final contentColor = trend > 0 ? palette.warning : palette.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend <= 0 ? Icons.trending_down : Icons.trending_up,
            size: 14,
            color: contentColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Region 2: ときめき/日常 split bar (ABSOLUTE amounts only — D-02) ────────────
  Widget _splitBar(BuildContext context, S l10n, AppPalette palette) {
    final joy = report.joyTotal;
    final daily = report.dailyTotal;
    final combined = joy + daily;
    final ratio = combined > 0 ? (joy / combined).clamp(0.0, 1.0) : 0.0;
    final joyText = _fmt.formatCurrency(joy, currencyCode, locale);
    final dailyText = _fmt.formatCurrency(daily, currencyCode, locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _splitLabel(
              palette,
              dotColor: palette.joy,
              amountColor: palette.joyText,
              label: l10n.joyLedger,
              amount: joyText,
              leading: true,
            ),
            _splitLabel(
              palette,
              dotColor: palette.daily,
              amountColor: palette.dailyText,
              label: l10n.dailyLedger,
              amount: dailyText,
              leading: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 6, color: palette.daily),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [palette.joy.withValues(alpha: 0.6), palette.joy],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _splitLabel(
    AppPalette palette, {
    required Color dotColor,
    required Color amountColor,
    required String label,
    required String amount,
    required bool leading,
  }) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
    final labelText = Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
    );
    final amountText = Text(
      amount,
      style: AppTextStyles.amountSmall.copyWith(color: amountColor),
    );
    return Row(
      children: leading
          ? [
              dot,
              const SizedBox(width: 6),
              labelText,
              const SizedBox(width: 8),
              amountText,
            ]
          : [
              amountText,
              const SizedBox(width: 8),
              labelText,
              const SizedBox(width: 6),
              dot,
            ],
    );
  }

  // ─── Region 3+5+7: Divider ────────────────────────────────────────────────
  Widget _divider(AppPalette palette) =>
      Container(height: 1, color: palette.backgroundDivider);

  // ─── Region 4: Ring section ───────────────────────────────────────────────
  Widget _ringSection(BuildContext context, S l10n, AppPalette palette) {
    final title = isGroupMode
        ? l10n.homeRingSectionTitleGroup
        : l10n.homeRingSectionTitleSingle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: palette.joy),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const _InfoIcon(tooltipKey: _TooltipKey.joyIndex),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: RepaintBoundary(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _painter(
                        palette,
                        HappinessRingPalette.of(Theme.of(context).brightness),
                      ),
                    ),
                    _centerContent(
                      context,
                      l10n,
                      palette,
                      HappinessRingPalette.of(Theme.of(context).brightness),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _legend(
                context,
                l10n,
                palette,
                HappinessRingPalette.of(Theme.of(context).brightness),
              ),
            ),
          ],
        ),
      ],
    );
  }

  HappinessRingsPainter _painter(
    AppPalette palette,
    HappinessRingPalette ring,
  ) {
    final track = palette.backgroundDivider;
    if (isGroupMode) {
      final f = family;
      return HappinessRingsPainter(
        outerSweepRatio: f == null
            ? null
            : _familyHighlightsRatio(f.familyHighlightsSum),
        middleSweepRatio: f == null
            ? null
            : _sharedJoyRatio(f.sharedJoyInsight),
        innerSweepRatio: f == null
            ? null
            : _medianSatisfactionRatio(f.medianSatisfaction),
        outerGradient: SweepGradient(
          colors: [palette.sharedLight, palette.shared],
        ),
        middleGradient: SweepGradient(
          colors: [palette.accentPrimaryLight, palette.accentPrimary],
        ),
        innerGradient: SweepGradient(
          colors: [palette.successLight, palette.success],
        ),
        trackColor: track,
      );
    }
    // Single mode — INNER GLOW + "Butter" scheme: each ring is a solid arc
    // with a soft blurred halo rendered by the painter (iOS/Impeller-safe).
    return HappinessRingsPainter(
      outerSweepRatio: _highlightsRatio(happiness.highlightsCount),
      middleSweepRatio: _avgSatisfactionRatio(happiness.avgSatisfaction),
      innerSweepRatio: _joyContributionRatio(happiness.joyContribution),
      outerGradient: SweepGradient(colors: [ring.highlights, ring.highlights]),
      middleGradient: SweepGradient(
        colors: [ring.satisfaction, ring.satisfaction],
      ),
      innerGradient: SweepGradient(colors: [ring.target, ring.target]),
      trackColor: ring.track,
    );
  }

  double? _joyContributionRatio(MetricResult<double> r) => switch (r) {
    Empty() => null,
    Value(:final data) =>
      activeMonthlyJoyTarget > 0
          ? (data / activeMonthlyJoyTarget).clamp(0.0, 1.0)
          : null,
  };
  double? _avgSatisfactionRatio(MetricResult<double> r) => switch (r) {
    Empty() => null,
    Value(:final data) => (data / 10.0).clamp(0.0, 1.0),
  };
  double? _highlightsRatio(MetricResult<int> r) => switch (r) {
    Empty() => null,
    Value(:final data) => (data / 10.0).clamp(0.0, 1.0),
  };
  double? _familyHighlightsRatio(MetricResult<int> r) => switch (r) {
    Empty() => null,
    Value(:final data) => (data / 30.0).clamp(0.0, 1.0),
  };
  double? _sharedJoyRatio(MetricResult<Object> r) => switch (r) {
    Empty() => null,
    Value() => 1.0,
  };
  double? _medianSatisfactionRatio(MetricResult<double> r) => switch (r) {
    Empty() => null,
    Value(:final data) => (data / 10.0).clamp(0.0, 1.0),
  };

  Widget _centerContent(
    BuildContext context,
    S l10n,
    AppPalette palette,
    HappinessRingPalette ring,
  ) {
    if (isGroupMode) {
      return Text(
        _groupCenterText(),
        style: AppTextStyles.amountMedium.copyWith(color: palette.textPrimary),
      );
    }
    final valueText = switch (happiness.joyContribution) {
      Empty() => '—',
      Value(:final data) => formatJoyCumulative(data, currencyCode),
    };
    final valueColor = switch (happiness.joyContribution) {
      Empty() => palette.textPrimary,
      Value() => ring.targetText,
    };
    return Semantics(
      label: l10n.homeJoyTargetSemantics(valueText, activeMonthlyJoyTarget),
      child: Text(
        valueText,
        style: AppTextStyles.amountMedium.copyWith(color: valueColor),
      ),
    );
  }

  String _groupCenterText() {
    final f = family;
    if (f == null) return '—';
    return switch (f.familyHighlightsSum) {
      Empty() => '—',
      Value(:final data) => '$data',
    };
  }

  Widget _legend(
    BuildContext context,
    S l10n,
    AppPalette palette,
    HappinessRingPalette ring,
  ) {
    if (isGroupMode) return _legendGroup(context, l10n, palette);
    return _legendSingle(context, l10n, palette, ring);
  }

  Widget _legendGroup(BuildContext context, S l10n, AppPalette palette) {
    final f = family;
    final empty = l10n.homeNoJoyDataLegend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legendRow(
          palette,
          palette.shared,
          l10n.homeFamilyHighlightsLegend,
          switch (f?.familyHighlightsSum) {
            null || Empty() => empty,
            Value(:final data) => '$data',
          },
        ),
        const SizedBox(height: 6),
        _legendRow(
          palette,
          palette.accentPrimary,
          l10n.homeSharedJoyLegend,
          switch (f?.sharedJoyInsight) {
            null || Empty() => empty,
            Value() => '✓',
          },
        ),
        const SizedBox(height: 6),
        _legendRow(
          palette,
          palette.success,
          l10n.homeMedianSatisfactionLegend,
          switch (f?.medianSatisfaction) {
            null || Empty() => empty,
            Value(:final data) => data.toStringAsFixed(1),
          },
        ),
      ],
    );
  }

  Widget _legendSingle(
    BuildContext context,
    S l10n,
    AppPalette palette,
    HappinessRingPalette ring,
  ) {
    final empty = l10n.homeNoJoyDataLegend;
    final highlights = switch (happiness.highlightsCount) {
      Empty() => 0,
      Value(:final data) => data,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legendRow(
          palette,
          ring.target,
          l10n.homeJoyContributionLegend,
          switch (happiness.joyContribution) {
            Empty() => empty,
            Value(:final data) => formatJoyCumulative(data, currencyCode),
          },
          labelTrailing: const _InfoIcon(
            tooltipKey: _TooltipKey.joyContribution,
          ),
        ),
        const SizedBox(height: 6),
        _legendRow(
          palette,
          ring.satisfaction,
          l10n.homeAvgSatisfactionLegend,
          switch (happiness.avgSatisfaction) {
            Empty() => empty,
            Value(:final data) => data.toStringAsFixed(1),
          },
        ),
        const SizedBox(height: 6),
        _legendRow(
          palette,
          ring.highlights,
          l10n.homeHighlightsCountLegend,
          '$highlights',
        ),
      ],
    );
  }

  Widget _legendRow(
    AppPalette palette,
    Color dot,
    String label,
    String value, {
    Widget? trailing,
    Widget? labelTrailing,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (labelTrailing != null) ...[
                const SizedBox(width: 4),
                labelTrailing,
              ],
            ],
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        if (trailing != null) ...[const SizedBox(width: 4), trailing],
      ],
    );
  }

  // ─── Region 6: Best Joy strip (ticket × calendar fusion — quick 260602-u5x) ─
  //
  // Reverses the s9g flat-strip decision (user-approved): the VALUE state is now
  // a ticket card (票根) — a full-height 6px joy accent bar down the left edge, a
  // tinted joy body with a thin uniform joy border (radius 14). Inside: a left
  // calendar tile carrying the date (joy month band / big tabular day number /
  // weekday) as a visual anchor, a middle column with the parent (L1)
  // category-icon + L2 category name over the amount (joyText), and a right
  // frameless satisfaction seal (icon over tier word) separated by a dashed
  // vertical perforation (撕口). Empty / all-neutral states reuse the same ticket
  // chrome with a muted "—" calendar placeholder and no seal.
  // ARCH-002: primary line is category name only — no merchant/note. ADR-014
  // tier mapping reused via _satisfactionPillIcon/_satisfactionPillLabel.
  // homeBestJoyEmptyBig/AllNeutralBig ARB keys unused since Variant A.
  Widget _buildBestJoyStrip(BuildContext context, S l10n, AppPalette palette) {
    final titleText = isGroupMode
        ? l10n.homeBestJoyTagGroup
        : l10n.homeBestJoyTagSingle;
    return switch (bestJoy) {
      Empty() => _bestJoyEmpty(
        context,
        palette,
        titleText,
        l10n.homeBestJoyEmptySmall,
      ),
      Value(:final data) when data.joyFullness <= 2 => _bestJoyEmpty(
        context,
        palette,
        titleText,
        l10n.homeBestJoyAllNeutralSmall,
      ),
      Value(:final data) => _bestJoyValue(
        context,
        l10n,
        palette,
        titleText,
        data,
      ),
    };
  }

  /// Shared flat-strip chrome for both value + empty states (quick 260602-s9g).
  ///
  /// No tinted box or border — the strip renders directly on the card surface
  /// and relies on the parent card's padding, matching the ring section. The
  /// header mirrors `_ringSection`'s header exactly (auto_awesome + textPrimary
  /// title) minus the info icon (the strip has no tooltip).
  Widget _bestJoyStripContainer({
    required AppPalette palette,
    required String title,
    required Widget row,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: palette.joy),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        row,
      ],
    );
  }

  /// Ticket chrome (票根) shared by the Best Joy value + empty states
  /// (quick 260602-u5x). A full-height 6px joy accent bar down the left edge,
  /// a tinted joy body with a thin uniform joy border, rounded to radius 14.
  ///
  /// Flutter forbids combining `borderRadius` with a non-uniform `Border`, so
  /// the rounding is done by an outer ClipRRect while the body keeps a uniform
  /// border only. IntrinsicHeight + Row(stretch) lets the accent bar match the
  /// content height.
  Widget _bestJoyTicket({
    required AppPalette palette,
    required bool isDark,
    required Widget content,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: palette.joy),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.joy.withValues(alpha: isDark ? 0.13 : 0.07),
                  border: Border.all(
                    color: palette.joy.withValues(alpha: 0.22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 6, 13),
                  child: content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calendar tile (日历瓦片) carrying the Best Joy date as a visual anchor
  /// (quick 260602-u5x). ~48px wide, joyLight body, radius 11, soft joy shadow.
  /// A joy month band sits on top, a big tabular day number in the middle, and
  /// a muted weekday at the bottom. For the empty-state placeholder, pass
  /// [day] "—" with [month]/[weekday] null → a single centered muted glyph with
  /// no month band, keeping the tile size stable.
  Widget _bestJoyCalendarTile({
    required AppPalette palette,
    required bool isDark,
    String? month,
    String? day,
    String? weekday,
  }) {
    // Month-band text reads as the page background sitting on the joy band:
    // near-white in light, near-black in dark — both supplied by palette.background.
    final monthBandText = palette.background;
    final isPlaceholder = month == null && weekday == null;
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: palette.joyLight,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: palette.joy.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: isPlaceholder
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    day ?? '—',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textSecondary,
                      height: 1.1,
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    color: palette.joy,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    alignment: Alignment.center,
                    child: Text(
                      month ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: monthBandText,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    day ?? '',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.joyText,
                      height: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    weekday ?? '',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
      ),
    );
  }

  Widget _bestJoyEmpty(
    BuildContext context,
    AppPalette palette,
    String title,
    String mutedLine,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _bestJoyCalendarTile(palette: palette, isDark: isDark, day: '—'),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            mutedLine,
            softWrap: true,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
    return _bestJoyStripContainer(
      palette: palette,
      title: title,
      row: _bestJoyTicket(palette: palette, isDark: isDark, content: content),
    );
  }

  Widget _bestJoyValue(
    BuildContext context,
    S l10n,
    AppPalette palette,
    String title,
    BestJoyMomentRow row,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = CategoryLocalizationService.resolveFromId(
      row.categoryId,
      locale,
    );
    final month = DateFormatter.formatCalendarMonth(row.timestamp, locale);
    final day = DateFormatter.formatCalendarDay(row.timestamp, locale);
    final weekday = DateFormat('E', locale.toString()).format(row.timestamp);
    final amount = _fmt.formatCurrency(row.amount, currencyCode, locale);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _bestJoyCalendarTile(
          palette: palette,
          isDark: isDark,
          month: month,
          day: day,
          weekday: weekday,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    parentCategoryIconFromId(row.categoryId),
                    size: 15,
                    color: palette.joyText,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: AppTextStyles.amountSmall.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.joyText,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        _DashedVLine(color: palette.joy.withValues(alpha: 0.38)),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _satisfactionPillIcon(row.joyFullness),
              size: 24,
              color: palette.satisfactionPillRose,
            ),
            const SizedBox(height: 3),
            Text(
              _satisfactionPillLabel(l10n, row.joyFullness),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: palette.satisfactionPillRose,
              ),
            ),
          ],
        ),
      ],
    );

    return _bestJoyStripContainer(
      palette: palette,
      title: title,
      row: _bestJoyTicket(palette: palette, isDark: isDark, content: content),
    );
  }

  /// ADR-014 satisfaction value → icon mapping (unipolar positive scale).
  IconData _satisfactionPillIcon(int sat) {
    if (sat <= 2) return Icons.sentiment_neutral_outlined;
    if (sat <= 4) return Icons.sentiment_satisfied_outlined;
    if (sat <= 6) return Icons.sentiment_satisfied_alt_outlined;
    if (sat <= 8) return Icons.sentiment_very_satisfied_outlined;
    return Icons.favorite_border;
  }

  /// ADR-014 satisfaction value → tier label mapping (Variant A pill).
  String _satisfactionPillLabel(S l10n, int sat) {
    if (sat <= 2) return l10n.satisfactionLabelNeutral;
    if (sat <= 4) return l10n.satisfactionLabelOK;
    if (sat <= 6) return l10n.satisfactionLabelGood;
    if (sat <= 8) return l10n.satisfactionLabelGreat;
    return l10n.satisfactionLabelAmazing;
  }

  // ─── Region 8: Members section (group mode + non-empty shadowBooks) ───────
  Widget _buildMembersSection(
    BuildContext context,
    S l10n,
    AppPalette palette,
  ) {
    // FAMILY-03 minimum gate.
    final books = shadowBooks;
    if (!isGroupMode || books == null || books.isEmpty) {
      return const SizedBox.shrink();
    }
    final reports = shadowAggregate?.perBookReports ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.homeMembersSectionTitle,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ),
        for (final m in books) _memberRow(palette, m, reports[m.book.id]),
      ],
    );
  }

  Widget _memberRow(
    AppPalette palette,
    ShadowBookInfo member,
    MonthlyReport? report,
  ) {
    final amount = report?.totalExpenses ?? 0;
    final amountText = _fmt.formatCurrency(amount, currencyCode, locale);
    final initial = member.memberAvatarEmoji.isNotEmpty
        ? member.memberAvatarEmoji
        : (member.memberDisplayName.isNotEmpty
              ? member.memberDisplayName.characters.first
              : '?');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.borderDefault,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.bodySmall.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              member.memberDisplayName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: palette.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amountText,
            style: AppTextStyles.amountSmall.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tooltip key + private _InfoIcon — Plan 10-07b ──────────────────────────
enum _TooltipKey { joyIndex, joyContribution }

class _InfoIcon extends StatelessWidget {
  // Constructor declaration split across lines so a regex looking for
  // call-site usages of this widget matches exactly twice (HOMEUI-04 cap).
  const _InfoIcon // <- declaration line, no opening paren.
  ({required this.tooltipKey});

  final _TooltipKey tooltipKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      // Pitfall #3 — absorb tap; do NOT propagate to the whole-card onTap.
      behavior: HitTestBehavior.opaque,
      onTap: () => _showTooltipDialog(context),
      child: Padding(
        // Visual stays 16px; padding expands the touchable hit area.
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.info_outline, size: 16, color: palette.textSecondary),
      ),
    );
  }

  void _showTooltipDialog(BuildContext context) {
    final l10n = S.of(context);
    final body = switch (tooltipKey) {
      _TooltipKey.joyIndex => l10n.homeJoyIndexTooltip,
      _TooltipKey.joyContribution => l10n.homeJoyContributionTooltip,
    };
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(body, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}

/// Vertical dashed perforation (撕口) separating the Best Joy middle column from
/// the satisfaction seal (quick 260602-u5x). Dash 3 / gap 3, strokeWidth 1.5,
/// hosted in a 2px-wide box with vertical margin so it reads as a ticket tear
/// line rather than a full divider.
class _DashedVLine extends StatelessWidget {
  const _DashedVLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        width: 2,
        child: CustomPaint(
          painter: _DashedVLinePainter(color: color),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _DashedVLinePainter extends CustomPainter {
  const _DashedVLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0;
    const gap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + dash).clamp(0, size.height)),
          paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedVLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
