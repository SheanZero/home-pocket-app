import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';
import '../../../analytics/domain/models/best_joy_moment_row.dart';
import '../../../analytics/domain/models/family_happiness.dart';
import '../../../analytics/domain/models/happiness_report.dart';
import '../../../analytics/domain/models/metric_result.dart';
import '../../../analytics/domain/models/monthly_report.dart';
import '../providers/state_shadow_books.dart';
import 'painter/happiness_rings_painter.dart';

/// D-05: Lerps daily → joy to produce the progress indicator color on the
/// inner ring. Replaces the old hardcoded start/end gradient constants
/// (COLOR-03 duplicate removal).
Color joyTargetProgressColor(double ratio, AppPalette palette) {
  final clamped = ratio.clamp(0.0, 1.0).toDouble();
  return Color.lerp(palette.daily, palette.joy, clamped)!;
}

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
          style: AppTextStyles.bodySmall.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _trendChip(AppPalette palette, int trend) {
    final text = trend <= 0 ? '$trend%' : '+$trend%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.successLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend <= 0 ? Icons.trending_down : Icons.trending_up,
            size: 14,
            color: palette.success,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.success,
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
                      colors: [
                        palette.joy.withValues(alpha: 0.6),
                        palette.joy,
                      ],
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
                      painter: _painter(palette),
                    ),
                    _centerContent(context, l10n, palette),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _legend(context, l10n, palette)),
          ],
        ),
      ],
    );
  }

  HappinessRingsPainter _painter(AppPalette palette) {
    final track = palette.backgroundDivider;
    if (isGroupMode) {
      final f = family;
      return HappinessRingsPainter(
        outerSweepRatio: f == null ? null : _familyHighlightsRatio(f.familyHighlightsSum),
        middleSweepRatio: f == null ? null : _sharedJoyRatio(f.sharedJoyInsight),
        innerSweepRatio: f == null ? null : _medianSatisfactionRatio(f.medianSatisfaction),
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
    return HappinessRingsPainter(
      outerSweepRatio: _highlightsRatio(happiness.highlightsCount),
      middleSweepRatio: _avgSatisfactionRatio(happiness.avgSatisfaction),
      innerSweepRatio: _joyContributionRatio(happiness.joyContribution),
      outerGradient: SweepGradient(
        colors: [palette.accentPrimary, palette.accentPrimary],
      ),
      middleGradient: SweepGradient(
        colors: [palette.success, palette.success],
      ),
      innerGradient: SweepGradient(
        colors: [_singleProgressColor(palette), _singleProgressColor(palette)],
      ),
      trackColor: track,
    );
  }

  double? _joyContributionRatio(MetricResult<double> r) => switch (r) {
    Empty() => null,
    Value(:final data) =>
      activeMonthlyJoyTarget > 0
          ? (data / activeMonthlyJoyTarget).clamp(0.0, 1.0)
          : null,
  };
  double _singleProgressRatioForColor() => switch (happiness.joyContribution) {
    Empty() => 0.0,
    Value(:final data) =>
      activeMonthlyJoyTarget > 0
          ? (data / activeMonthlyJoyTarget).clamp(0.0, 1.0)
          : 0.0,
  };
  Color _singleProgressColor(AppPalette palette) =>
      joyTargetProgressColor(_singleProgressRatioForColor(), palette);
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

  Widget _centerContent(BuildContext context, S l10n, AppPalette palette) {
    if (isGroupMode) {
      return Text(
        _groupCenterText(),
        style: AppTextStyles.amountMedium.copyWith(
          color: palette.textPrimary,
        ),
      );
    }
    final valueText = switch (happiness.joyContribution) {
      Empty() => '—',
      Value(:final data) => formatJoyCumulative(data, currencyCode),
    };
    final valueColor = switch (happiness.joyContribution) {
      Empty() => palette.textPrimary,
      Value() => _singleProgressColor(palette),
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

  Widget _legend(BuildContext context, S l10n, AppPalette palette) {
    if (isGroupMode) return _legendGroup(context, l10n, palette);
    return _legendSingle(context, l10n, palette);
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

  Widget _legendSingle(BuildContext context, S l10n, AppPalette palette) {
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
          palette.joy,
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
          palette.success,
          l10n.homeAvgSatisfactionLegend,
          switch (happiness.avgSatisfaction) {
            Empty() => empty,
            Value(:final data) => data.toStringAsFixed(1),
          },
        ),
        const SizedBox(height: 6),
        _legendRow(
          palette,
          palette.accentPrimary,
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

  // ─── Region 6: Best Joy strip (Variant A — Pencil mock n6VVd) ────────────
  //
  // 3-row cream card: Row 1 = title + satisfaction pill; Row 2 = hero amount;
  // Row 3 = merchant/category + date. Replaces old 3-line text layout.
  // homeBestJoyEmptyBig/AllNeutralBig ARB keys unused after Variant A — see v4v worklog.
  Widget _buildBestJoyStrip(BuildContext context, S l10n, AppPalette palette) {
    final titleText = isGroupMode
        ? l10n.homeBestJoyTagGroup
        : l10n.homeBestJoyTagSingle;
    return switch (bestJoy) {
      Empty() => _bestJoyEmpty(palette, titleText, l10n.homeBestJoyEmptySmall),
      Value(:final data) when data.joyFullness <= 2 => _bestJoyEmpty(
        palette,
        titleText,
        l10n.homeBestJoyAllNeutralSmall,
      ),
      Value(:final data) => _bestJoyValue(context, l10n, palette, titleText, data),
    };
  }

  Widget _bestJoyEmpty(AppPalette palette, String title, String mutedLine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bestJoyTitleRow(palette, title),
        const SizedBox(height: 12),
        Text(
          mutedLine,
          style: AppTextStyles.bodyMedium.copyWith(
            color: palette.textMutedGold,
          ),
        ),
      ],
    );
  }

  /// Section title row matching `_ringSection` style: icon + bodyLarge text,
  /// left-aligned, transparent background (no card chrome).
  Widget _bestJoyTitleRow(AppPalette palette, String title) {
    return Row(
      children: [
        Icon(Icons.favorite, size: 16, color: palette.joy),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(color: palette.textPrimary),
        ),
      ],
    );
  }

  Widget _bestJoyValue(
    BuildContext context,
    S l10n,
    AppPalette palette,
    String title,
    BestJoyMomentRow row,
  ) {
    final formatted = _fmt.formatCurrency(row.amount, currencyCode, locale);
    final splitResult = _splitCurrencySymbol(formatted);
    final category = CategoryLocalizationService.resolveFromId(
      row.categoryId,
      locale,
    );
    final dateShort = DateFormatter.formatShortMonthDay(row.timestamp, locale);
    final dayOfWeek = DateFormat('E', locale.toString()).format(row.timestamp);
    final dateLabel = '$dateShort · $dayOfWeek';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: title only — left-aligned (pill moved to amount row)
        _bestJoyTitleRow(palette, title),
        const SizedBox(height: 12),
        // Row 2: hero amount left + enlarged satisfaction pill right
        // (pill vertically centered on amount center line per user 260518-v4v r2)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  splitResult.$1,
                  style: AppTextStyles.amountSmall.copyWith(
                    fontSize: 20,
                    color: palette.joyText,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  splitResult.$2,
                  style: AppTextStyles.amountLarge.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: palette.joyText,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            _satisfactionPill(l10n, palette, row.joyFullness),
          ],
        ),
        const SizedBox(height: 10),
        // Row 3: category/merchant left + date right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                category,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textMutedGold,
                ),
              ),
            ),
            Text(
              dateLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.textMutedGold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Satisfaction pill widget (Variant A — pill with icon + tier label).
  /// Enlarged per user 260518-v4v r2: icon 16→20, text 11→14, padding (8,4)→(12,7).
  Widget _satisfactionPill(S l10n, AppPalette palette, int sat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.satisfactionPillBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _satisfactionPillIcon(sat),
            size: 20,
            color: palette.satisfactionPillRose,
          ),
          const SizedBox(width: 6),
          Text(
            _satisfactionPillLabel(l10n, sat),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.satisfactionPillRose,
            ),
          ),
        ],
      ),
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

  /// Splits a formatted currency string into (symbol, number) pair.
  /// e.g. "¥4,200" → ("¥", "4,200"), "$4.20" → ("$", "4.20")
  (String, String) _splitCurrencySymbol(String formatted) {
    final idx = formatted.indexOf(RegExp(r'\d'));
    if (idx <= 0) return ('', formatted);
    return (formatted.substring(0, idx), formatted.substring(idx));
  }

  // ─── Region 8: Members section (group mode + non-empty shadowBooks) ───────
  Widget _buildMembersSection(BuildContext context, S l10n, AppPalette palette) {
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
        child: Icon(
          Icons.info_outline,
          size: 16,
          color: palette.textSecondary,
        ),
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
