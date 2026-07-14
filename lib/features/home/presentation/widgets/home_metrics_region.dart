import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';
import '../../../analytics/domain/models/family_happiness.dart';
import '../../../analytics/domain/models/metric_result.dart';

/// v15 `faithfulMetrics()` — the ときめき度 metrics grid.
///
/// SOLO layout (mockup-faithful): a 100px 悦己 goal ring (conic fill =
/// joyContribution ÷ activeMonthlyJoyTarget) paired with a support stack of a
/// 満足度 scale bar (avgSatisfaction / 10) over a 小確幸 count.
///
/// GROUP layout: there is NO family-level joy target in the presentation layer,
/// so a faithful family goal-ring cannot be drawn. Instead the existing family
/// metric triple is restyled into the same ring + support-stack shape:
///   - ring slot  → medianSatisfaction as a /10 ring
///   - support ①  → familyHighlightsSum count (小確幸)
///   - support ②  → sharedJoyInsight presence (共に好き ✓)
/// No family joy target is fabricated.
class HomeMetricsRegion extends StatelessWidget {
  const HomeMetricsRegion({
    required this.isGroupMode,
    required this.joyContribution,
    required this.avgSatisfaction,
    required this.highlightsCount,
    required this.activeMonthlyJoyTarget,
    required this.currencyCode,
    required this.family,
    super.key,
  });

  final bool isGroupMode;
  final MetricResult<double> joyContribution;
  final MetricResult<double> avgSatisfaction;
  final MetricResult<int> highlightsCount;
  final int activeMonthlyJoyTarget;
  final String currencyCode;
  final FamilyHappiness? family;

  static const double _gridHeight = 100;
  static const double _ringSize = 100;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return SizedBox(
      height: _gridHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _ringSize,
            height: _ringSize,
            child: RepaintBoundary(
              child: isGroupMode
                  ? _groupRing(context, l10n, palette)
                  : _soloRing(context, l10n, palette),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: _gridHeight,
              child: isGroupMode
                  ? _groupSupport(context, l10n, palette)
                  : _soloSupport(context, l10n, palette),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Goal ring (rose) ─────────────────────────────────────────────────────
  Widget _ringShell({
    required AppPalette palette,
    required double? ratio,
    required Widget center,
    String? semanticsLabel,
  }) {
    final ring = Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(_ringSize, _ringSize),
          painter: _GoalRingPainter(
            ratio: ratio ?? 0,
            // Medium sakura rose progress fill (goal-progress in the mockup),
            // derived from the joy pair so it stays a palette token.
            progressColor: Color.lerp(palette.joy, palette.joyText, 0.4)!,
            trackColor: palette.joyLight,
          ),
        ),
        center,
      ],
    );
    if (semanticsLabel == null) return ring;
    return Semantics(label: semanticsLabel, child: ring);
  }

  Widget _soloRing(BuildContext context, S l10n, AppPalette palette) {
    final valueText = switch (joyContribution) {
      Empty() => '—',
      Value(:final data) => formatJoyCumulative(data, currencyCode),
    };
    final ratio = switch (joyContribution) {
      Empty() => null,
      Value(:final data) => activeMonthlyJoyTarget > 0
          ? (data / activeMonthlyJoyTarget).clamp(0.0, 1.0)
          : null,
    };
    return _ringShell(
      palette: palette,
      ratio: ratio,
      semanticsLabel: l10n.homeJoyTargetSemantics(
        valueText,
        activeMonthlyJoyTarget,
      ),
      center: _ringCenter(
        palette: palette,
        label: l10n.homeJoyContributionLegend,
        value: valueText,
        trailing: ' / $activeMonthlyJoyTarget',
        unit: l10n.homeMetricJoyUnit,
      ),
    );
  }

  Widget _groupRing(BuildContext context, S l10n, AppPalette palette) {
    final median = family?.medianSatisfaction;
    final valueText = switch (median) {
      null || Empty() => '—',
      Value(:final data) => data.toStringAsFixed(1),
    };
    final ratio = switch (median) {
      null || Empty() => null,
      Value(:final data) => (data / 10.0).clamp(0.0, 1.0),
    };
    return _ringShell(
      palette: palette,
      ratio: ratio,
      center: _ringCenter(
        palette: palette,
        label: l10n.homeMedianSatisfactionLegend,
        value: valueText,
        trailing: ' / 10',
        unit: null,
      ),
    );
  }

  Widget _ringCenter({
    required AppPalette palette,
    required String label,
    required String value,
    required String trailing,
    required String? unit,
  }) {
    final roseValue = palette.joyText;
    // The mockup goal ring has an ~86px inner hole (7px donut on a 100px ring);
    // keep the center copy inside a padded box and scale the value row down so
    // large numbers never overflow the ring.
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  value,
                  style: AppTextStyles.amountMedium.copyWith(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: roseValue,
                  ),
                ),
                Text(
                  trailing,
                  style: AppTextStyles.amountSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: roseValue,
                  ),
                ),
              ],
            ),
          ),
          if (unit != null) ...[
            const SizedBox(height: 4),
            Text(
              unit,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: roseValue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Support stack ────────────────────────────────────────────────────────
  Widget _supportStack(AppPalette palette, {required Widget top, required Widget bottom}) {
    return Column(
      children: [
        Expanded(child: Align(alignment: Alignment.centerLeft, child: top)),
        Container(height: 1, color: palette.backgroundDivider),
        Expanded(child: Align(alignment: Alignment.centerLeft, child: bottom)),
      ],
    );
  }

  Widget _soloSupport(BuildContext context, S l10n, AppPalette palette) {
    return _supportStack(
      palette,
      top: _satisfactionBlock(
        palette,
        label: l10n.homeAvgSatisfactionLegend,
        metric: avgSatisfaction,
      ),
      bottom: _countBlock(
        l10n,
        palette,
        label: l10n.homeHighlightsCountLegend,
        countText: switch (highlightsCount) {
          Empty() => '—',
          Value(:final data) => '$data',
        },
      ),
    );
  }

  Widget _groupSupport(BuildContext context, S l10n, AppPalette palette) {
    final highlights = family?.familyHighlightsSum;
    final shared = family?.sharedJoyInsight;
    return _supportStack(
      palette,
      top: _countBlock(
        l10n,
        palette,
        label: l10n.homeFamilyHighlightsLegend,
        countText: switch (highlights) {
          null || Empty() => '—',
          Value(:final data) => '$data',
        },
      ),
      bottom: _sharedJoyBlock(
        l10n,
        palette,
        present: shared is Value,
      ),
    );
  }

  /// 満足度の平均 — a "8.2 / 10" head over a horizontal scale bar.
  Widget _satisfactionBlock(
    AppPalette palette, {
    required String label,
    required MetricResult<double> metric,
  }) {
    final valueText = switch (metric) {
      Empty() => '—',
      Value(:final data) => data.toStringAsFixed(1),
    };
    final ratio = switch (metric) {
      Empty() => 0.0,
      Value(:final data) => (data / 10.0).clamp(0.0, 1.0),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              valueText,
              style: AppTextStyles.amountSmall.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: palette.success,
              ),
            ),
            Text(
              ' / 10',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: palette.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(height: 3, color: palette.successLight),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(height: 3, color: palette.success),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 小確幸 count — label + a big amber count with a small unit suffix.
  Widget _countBlock(
    S l10n,
    AppPalette palette, {
    required String label,
    required String countText,
  }) {
    final unit = l10n.homeMetricCountUnit;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              countText,
              style: AppTextStyles.amountSmall.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: palette.warning,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: palette.warning,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 共に好き — group-only shared-joy presence indicator.
  Widget _sharedJoyBlock(S l10n, AppPalette palette, {required bool present}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.homeSharedJoyLegend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          present ? Icons.check_circle : Icons.remove_circle_outline,
          size: 16,
          color: present ? palette.success : palette.textSecondary,
        ),
      ],
    );
  }
}

/// Donut-ring painter mirroring the mockup `conic-gradient(progress, track)`:
/// a full track circle with a progress arc sweeping clockwise from 12 o'clock.
class _GoalRingPainter extends CustomPainter {
  _GoalRingPainter({
    required this.ratio,
    required this.progressColor,
    required this.trackColor,
  });

  final double ratio;
  final Color progressColor;
  final Color trackColor;
  static const double strokeWidth = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final clamped = ratio.clamp(0.0, 1.0);
    if (clamped > 0) {
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * clamped,
        false,
        progress,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) =>
      old.ratio != ratio ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
