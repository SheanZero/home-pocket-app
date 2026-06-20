import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/analytics_category_palette.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/analytics_aggregate.dart';

/// STATSUI-02: 1-10 joy fullness distribution histogram.
///
/// round-5 r5 (`.histo` / `.histo .b` / `.bar` / `.cnt` / `.x` / `.b.med`):
/// custom flex bars replacing fl_chart for pixel control. 10 bars (scores 1–10)
/// grow from a shared baseline, height ∝ count. Each non-zero bar carries a count
/// label above it; count==0 renders a 3px [AppPalette.backgroundMuted] stub with
/// NO label. Every bar uses ONE uniform pink vertical gradient
/// (`palette.joy` → [AnalyticsCategoryPalette.histoBarBottom]) — NOT a per-score
/// ramp. The data-derived weighted-median bucket gets a 2px outline (descriptive,
/// not a target; the mock's literal「7」is NEVER hardcoded).
class SatisfactionDistributionHistogram extends StatelessWidget {
  const SatisfactionDistributionHistogram({super.key, required this.buckets});

  final List<SatisfactionScoreBucket> buckets;

  /// Chart plot height (count labels + bars).
  static const double _chartHeight = 140;

  /// Tallest a non-zero bar can grow (leaves headroom above for the count label).
  static const double _maxBarHeight = 110;

  /// Fixed height reserved for the count-label row above each bar so all bar tops
  /// share one baseline (placeholder height for count==0 columns).
  static const double _countLabelHeight = 14;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final normalized = _normalize();
    final total = normalized.fold<int>(0, (sum, item) => sum + item.count);
    final maxCount = normalized.fold<int>(
      0,
      (maxValue, item) => item.count > maxValue ? item.count : maxValue,
    );
    // Pitfall-7 / D4: the median pill/outline are DERIVED from buckets (weighted
    // median — the score whose cumulative count first crosses 50% of total),
    // NEVER the mock's literal「7」. `null` when there is no data.
    final medianScore = _weightedMedian(normalized, total);
    final medianBorderColor = Color.lerp(palette.joy, palette.joyLight, 0.55)!;

    return Semantics(
      container: true,
      label: _semanticLabel(normalized, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bucket in normalized)
                  Expanded(
                    child: _BarColumn(
                      score: bucket.score,
                      count: bucket.count,
                      maxCount: maxCount,
                      isMedian: bucket.score == medianScore,
                      palette: palette,
                      medianBorderColor: medianBorderColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Score labels (`.x`), one per column, aligned with the bars above.
          Row(
            children: [
              for (final bucket in normalized)
                Expanded(
                  child: Text(
                    '${bucket.score}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // round-5 r5 `.histo-foot`: left = data-derived count footer, right =
          // data-derived median pill (Pitfall-7 / D4). Both come from `buckets`
          // (no new provider) — descriptive, ADR-012-safe.
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.analyticsHistogramCountFooter(total),
                  style: AppTextStyles.caption.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              if (medianScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.joyLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    l10n.analyticsHistogramMedianPill(medianScore),
                    style: AppTextStyles.caption.copyWith(
                      color: palette.joyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          // round-5 r5 `.histo-cap`: warm descriptive caption (new key, §3).
          Text(
            l10n.analyticsHistogramJoyCaption,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              height: 1.55,
              color: palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Weighted median of the 1–10 satisfaction buckets: the score whose CUMULATIVE
  /// count first reaches/crosses 50% of [total]. Returns `null` when there is no
  /// data. Descriptive (Pitfall-7 / D4) — never a target.
  int? _weightedMedian(List<SatisfactionScoreBucket> normalized, int total) {
    if (total <= 0) return null;
    final half = total / 2;
    var cumulative = 0;
    for (final bucket in normalized) {
      cumulative += bucket.count;
      if (cumulative >= half) return bucket.score;
    }
    return normalized.isNotEmpty ? normalized.last.score : null;
  }

  List<SatisfactionScoreBucket> _normalize() {
    final byScore = {for (final bucket in buckets) bucket.score: bucket.count};
    return [
      for (var score = 1; score <= 10; score += 1)
        SatisfactionScoreBucket(score: score, count: byScore[score] ?? 0),
    ];
  }

  String _semanticLabel(List<SatisfactionScoreBucket> normalized, int total) {
    return normalized
        .map(
          (bucket) =>
              'score ${bucket.score} of 10, ${bucket.count} entries of $total',
        )
        .join('. ');
  }
}

/// One score column: count label (or placeholder) above a single flex bar.
class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.score,
    required this.count,
    required this.maxCount,
    required this.isMedian,
    required this.palette,
    required this.medianBorderColor,
  });

  final int score;
  final int count;
  final int maxCount;
  final bool isMedian;
  final AppPalette palette;
  final Color medianBorderColor;

  static const BorderRadius _barRadius = BorderRadius.only(
    topLeft: Radius.circular(5),
    topRight: Radius.circular(5),
    bottomLeft: Radius.circular(2),
    bottomRight: Radius.circular(2),
  );

  @override
  Widget build(BuildContext context) {
    final hasCount = count > 0;
    final double barHeight;
    if (!hasCount) {
      barHeight = 3;
    } else {
      final ratio = maxCount > 0 ? count / maxCount : 0.0;
      barHeight = math.max(
        8,
        ratio * SatisfactionDistributionHistogram._maxBarHeight,
      );
    }

    final bar = Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: hasCount ? null : palette.backgroundMuted,
        gradient: hasCount
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.joy, AnalyticsCategoryPalette.histoBarBottom],
              )
            : null,
        borderRadius: _barRadius,
      ),
    );

    // round-5 r5 `.b.med .bar{outline}` — outline the data-derived median bucket.
    final outlinedBar = isMedian
        ? Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: medianBorderColor, width: 2),
              borderRadius: _barRadius,
            ),
            child: bar,
          )
        : bar;

    return Padding(
      // max-width 22 per bar (mock `.bar{max-width:22px}`); the Expanded column is
      // wider on small screens, so cap the bar and center it.
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Count label above the bar (count==0 → fixed-height placeholder so all
          // bar tops share one baseline).
          SizedBox(
            height: SatisfactionDistributionHistogram._countLabelHeight,
            child: hasCount
                ? Center(
                    child: Text(
                      '$count',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: palette.joyText,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 22),
            child: SizedBox(width: double.infinity, child: outlinedBar),
          ),
        ],
      ),
    );
  }
}
