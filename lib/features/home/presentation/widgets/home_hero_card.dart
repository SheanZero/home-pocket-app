import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/joy_density_formatter.dart';
import '../../../analytics/domain/models/best_joy_moment_row.dart';
import '../../../analytics/domain/models/family_happiness.dart';
import '../../../analytics/domain/models/happiness_report.dart';
import '../../../analytics/domain/models/metric_result.dart';
import '../../../analytics/domain/models/monthly_report.dart';
import '../providers/state_shadow_books.dart';
import 'painter/happiness_rings_painter.dart';

/// Integrated hero card replacing MonthOverviewCard + LedgerComparisonSection +
/// SoulFullnessCard (Phase 10). Pure StatelessWidget — parent resolves
/// AsyncValue.when() and passes Freezed aggregates (UI-SPEC line 277).
///
/// Hard contracts (CONTEXT D-01..D-13):
/// - Amounts via `AppTextStyles.amount*`; currency via FormatterService (no JPY literal).
/// - `MetricResult<T>` consumed via sealed `switch` only.
/// - Exactly 2 info-icon placeholders (HOMEUI-04).
/// - Whole-card single onTap; ⓘ icons absorb taps in 10-07b (Pitfall #3).
/// - 魂/生存 split bar shows ABSOLUTE amounts (D-02).
/// - No gamification chips of any kind (ADR-012).
///
/// Plan 10-07a delivers Regions 1-5 (hero header → split bar → divider → ring
/// section → divider). Regions 6 (Best Joy) and 8 (members) are intentional
/// `SizedBox.shrink()` placeholders pending Plan 10-07b — constructor signature
/// is locked here.
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
  final VoidCallback onTap;

  static const FormatterService _fmt = FormatterService();

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final showMembers = isGroupMode && (shadowBooks?.isNotEmpty ?? false);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.wmCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.wmBorderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(context, l10n),
            const SizedBox(height: 16),
            _splitBar(context, l10n),
            const SizedBox(height: 12),
            _divider(context),
            const SizedBox(height: 12),
            _ringSection(context, l10n),
            const SizedBox(height: 12),
            _divider(context),
            const SizedBox(height: 12),
            // Region 6: Best Joy strip — Plan 10-07b fills this.
            _buildBestJoyStripPlaceholder(),
            if (showMembers) ...[
              const SizedBox(height: 12),
              _divider(context),
              const SizedBox(height: 12),
              // Region 8: Members section — Plan 10-07b fills this.
              _buildMembersSectionPlaceholder(),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Region 1: Hero header ─────────────────────────────────────────────────
  Widget _hero(BuildContext context, S l10n) {
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
            color: context.wmTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                _fmt.formatCurrency(total, currencyCode, locale),
                style: AppTextStyles.amountLarge.copyWith(
                  color: context.wmTextPrimary,
                ),
              ),
            ),
            if (hasAny) _trendChip(trend),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.homeHeroPreviousMonthSubline(
            _fmt.formatCurrency(prev, currencyCode, locale),
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: context.wmTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _trendChip(int trend) {
    final text = trend <= 0 ? '$trend%' : '+$trend%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.oliveLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend <= 0 ? Icons.trending_down : Icons.trending_up,
            size: 14,
            color: AppColors.olive,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.olive,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Region 2: 魂/生存 split bar (ABSOLUTE amounts only — D-02) ────────────
  Widget _splitBar(BuildContext context, S l10n) {
    final soul = report.soulTotal;
    final survival = report.survivalTotal;
    final combined = soul + survival;
    final ratio = combined > 0 ? (soul / combined).clamp(0.0, 1.0) : 0.0;
    final soulText = _fmt.formatCurrency(soul, currencyCode, locale);
    final survivalText = _fmt.formatCurrency(survival, currencyCode, locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _splitLabel(
              context,
              AppColors.soul,
              l10n.soulLedger,
              soulText,
              leading: true,
            ),
            _splitLabel(
              context,
              AppColors.survival,
              l10n.survivalLedger,
              survivalText,
              leading: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 6, color: context.wmBackgroundDivider),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.soul.withValues(alpha: 0.6),
                        AppColors.soul,
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
    BuildContext context,
    Color color,
    String label,
    String amount, {
    required bool leading,
  }) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final labelText = Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(color: context.wmTextSecondary),
    );
    final amountText = Text(
      amount,
      style: AppTextStyles.amountSmall.copyWith(color: color),
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
  Widget _divider(BuildContext context) =>
      Container(height: 1, color: context.wmBackgroundDivider);

  // ─── Region 4: Ring section ───────────────────────────────────────────────
  Widget _ringSection(BuildContext context, S l10n) {
    final title = isGroupMode
        ? l10n.homeRingSectionTitleGroup
        : l10n.homeRingSectionTitleSingle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: AppColors.soul),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.wmTextPrimary,
              ),
            ),
            const SizedBox(width: 4),
            // TODO(plan-10-07b): promote to _InfoIcon (joy-index tooltip).
            Icon(Icons.info_outline, size: 16, color: context.wmTextSecondary),
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
                      painter: _painter(context),
                    ),
                    Text(
                      _centerText(),
                      style: AppTextStyles.amountMedium.copyWith(
                        color: context.wmTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _legend(context, l10n)),
          ],
        ),
      ],
    );
  }

  HappinessRingsPainter _painter(BuildContext context) {
    final track = context.wmBackgroundDivider;
    if (isGroupMode) {
      final f = family;
      return HappinessRingsPainter(
        outerSweepRatio: f == null ? null : _outerGroup(f.familyHighlightsSum),
        middleSweepRatio: f == null ? null : _middleGroup(f.sharedJoyInsight),
        innerSweepRatio: f == null ? null : _innerGroup(f.medianSatisfaction),
        outerGradient: const SweepGradient(
          colors: [AppColors.sharedLight, AppColors.shared],
        ),
        middleGradient: const SweepGradient(
          colors: [AppColors.accentPrimaryLight, AppColors.accentPrimary],
        ),
        innerGradient: const SweepGradient(
          colors: [AppColors.oliveLight, AppColors.olive],
        ),
        trackColor: track,
      );
    }
    return HappinessRingsPainter(
      outerSweepRatio: _outerSingle(happiness.joyPerYen),
      middleSweepRatio: _middleSingle(happiness.avgSatisfaction),
      innerSweepRatio: _innerSingle(
        happiness.highlightsCount,
        happiness.totalSoulTx,
      ),
      outerGradient: SweepGradient(
        colors: [AppColors.soul.withValues(alpha: 0.6), AppColors.soul],
      ),
      middleGradient: const SweepGradient(
        colors: [AppColors.oliveLight, AppColors.olive],
      ),
      innerGradient: const SweepGradient(
        colors: [AppColors.accentPrimaryLight, AppColors.accentPrimary],
      ),
      trackColor: track,
    );
  }

  double? _outerSingle(MetricResult<double> r) => switch (r) {
    Empty() => null,
    Value(:final data) => (data / 2.0).clamp(0.0, 1.0),
  };
  double? _middleSingle(MetricResult<double> r) => switch (r) {
    Empty() => null,
    Value(:final data) => (data / 10.0).clamp(0.0, 1.0),
  };
  double? _innerSingle(MetricResult<int> r, int total) => switch (r) {
    Empty() => null,
    Value(:final data) => total > 0 ? (data / total).clamp(0.0, 1.0) : null,
  };
  double? _outerGroup(MetricResult<int> r) => switch (r) {
    Empty() => null,
    Value(:final data) => (data / 30.0).clamp(0.0, 1.0),
  };
  double? _middleGroup(MetricResult<Object> r) => switch (r) {
    Empty() => null,
    Value() => 1.0,
  };
  double? _innerGroup(MetricResult<double> r) => switch (r) {
    Empty() => null,
    Value(:final data) => (data / 10.0).clamp(0.0, 1.0),
  };

  String _centerText() {
    if (isGroupMode) {
      final f = family;
      if (f == null) return '—';
      return switch (f.familyHighlightsSum) {
        Empty() => '—',
        Value(:final data) => '$data',
      };
    }
    return switch (happiness.avgSatisfaction) {
      Empty() => '—',
      Value(:final data) => data.toStringAsFixed(1),
    };
  }

  Widget _legend(BuildContext context, S l10n) {
    if (isGroupMode) return _legendGroup(context, l10n);
    return _legendSingle(context, l10n);
  }

  Widget _legendGroup(BuildContext context, S l10n) {
    final f = family;
    final empty = l10n.homeNoSoulDataLegend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legendRow(
          context,
          AppColors.shared,
          l10n.homeFamilyHighlightsLegend,
          switch (f?.familyHighlightsSum) {
            null || Empty() => empty,
            Value(:final data) => '$data',
          },
        ),
        const SizedBox(height: 6),
        _legendRow(
          context,
          AppColors.accentPrimary,
          l10n.homeSharedJoyLegend,
          switch (f?.sharedJoyInsight) {
            null || Empty() => empty,
            Value() => '✓',
          },
        ),
        const SizedBox(height: 6),
        _legendRow(
          context,
          AppColors.olive,
          l10n.homeMedianSatisfactionLegend,
          switch (f?.medianSatisfaction) {
            null || Empty() => empty,
            Value(:final data) => data.toStringAsFixed(1),
          },
        ),
      ],
    );
  }

  Widget _legendSingle(BuildContext context, S l10n) {
    final empty = l10n.homeNoSoulDataLegend;
    final highlights = switch (happiness.highlightsCount) {
      Empty() => 0,
      Value(:final data) => data,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legendRow(
          context,
          AppColors.soul,
          l10n.homeJoyPerYenLegend,
          switch (happiness.joyPerYen) {
            Empty() => empty,
            Value(:final data) => formatJoyDensity(data, currencyCode),
          },
          // TODO(plan-10-07b): promote to _InfoIcon (joy/¥ tooltip).
          trailing: Icon(
            Icons.info_outline,
            size: 16,
            color: context.wmTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        _legendRow(
          context,
          AppColors.olive,
          l10n.homeAvgSatisfactionLegend,
          switch (happiness.avgSatisfaction) {
            Empty() => empty,
            Value(:final data) => data.toStringAsFixed(1),
          },
        ),
        const SizedBox(height: 6),
        _legendRow(
          context,
          AppColors.accentPrimary,
          l10n.homeHighlightsCountLegend(highlights),
          '',
        ),
        if (happiness.totalSoulTx > 0) ...[
          const SizedBox(height: 6),
          Text(
            l10n.homeCoverageCaption(_rated(happiness), happiness.totalSoulTx),
            style: AppTextStyles.bodySmall.copyWith(
              color: context.wmTextSecondary,
            ),
          ),
        ],
      ],
    );
  }

  int _rated(HappinessReport h) => switch (h.avgSatisfaction) {
    Empty() => 0,
    Value(sampleSize: final n) => n,
  };

  Widget _legendRow(
    BuildContext context,
    Color dot,
    String label,
    String value, {
    Widget? trailing,
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
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.wmTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.wmTextPrimary,
            ),
          ),
        if (trailing != null) ...[const SizedBox(width: 4), trailing],
      ],
    );
  }

  // ─── Region 6+8 stubs — Plan 10-07b owns these. ───────────────────────────
  // TODO(plan-10-07b): replace with full Best Joy strip (Empty / Value / all-neutral CTAs).
  Widget _buildBestJoyStripPlaceholder() => const SizedBox.shrink();
  // TODO(plan-10-07b): replace with full members list rendering ShadowBookInfo rows.
  Widget _buildMembersSectionPlaceholder() => const SizedBox.shrink();
}
