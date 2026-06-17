import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../application/accounting/category_localization_service.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../generated/app_localizations.dart';
import '../../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../settings/presentation/providers/state_locale.dart';
import '../../../domain/models/joy_category_amount.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../joy_spend_stacked_bar.dart';
import 'analytics_data_card.dart';

/// 悦己花在哪 card (round-5 B card #3, Phase 46 — D-C2).
///
/// Mirrors `category_donut_card.dart`'s single-source `ConsumerWidget` +
/// `*RefreshTargets` contract: watches exactly ONE provider family
/// ([joyCategoryAmountsProvider]) and routes its error-retry through the
/// single-source [joySpendRefreshTargets].
///
/// On data: an `AnalyticsDataCard` with a "悦己 ¥…" header total that count-ups
/// via a `TweenAnimationBuilder` (~480ms — the D-D2 anchor #2), then the custom
/// [JoySpendStackedBar] (R-1 — NOT fl_chart). Empty joy amounts → a neutral
/// empty copy (no throw). Ambient celebrate-past — zero target/streak/ranking.
class JoySpendCard extends ConsumerWidget {
  const JoySpendCard({
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
    final targets = joySpendRefreshTargets(_ctx());

    final amountsAsync = ref.watch(
      joyCategoryAmountsProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return amountsAsync.when(
      data: (amounts) => AnalyticsDataCard(
        title: S.of(context).analyticsCardTitleJoySpend,
        caption: S.of(context).analyticsCardCaptionJoySpend,
        child: _JoySpendBody(amounts: amounts),
      ),
      loading: () => const SizedBox(height: 200),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.single),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's single target. `trendAnchor`
  /// is derived from `endDate`; `isGroupMode`/`locale` are unused by the targets.
  AnalyticsCardContext _ctx() => AnalyticsCardContext(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    trendAnchor: DateTime(endDate.year, endDate.month),
    currencyCode: 'JPY',
    joyMetricVariant: joyMetricVariant,
    isGroupMode: false,
    locale: const Locale('ja'),
  );
}

/// Single-source refresh targets for [JoySpendCard] (D-B2). The shell `_refresh`
/// union and this card's error-retry both draw from this one list.
List<ProviderBase<Object?>> joySpendRefreshTargets(AnalyticsCardContext ctx) => [
  joyCategoryAmountsProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
];

/// Resolves the joy amounts into pre-formatted bar segments, renders the
/// count-up header total, then the custom stacked bar. Empty → neutral copy.
class _JoySpendBody extends ConsumerWidget {
  const _JoySpendBody({required this.amounts});

  final List<JoyCategoryAmount> amounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    if (amounts.isEmpty) {
      return Padding(
        key: const ValueKey('joy_spend_empty'),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.analyticsJoySpendEmpty,
          style: AppTextStyles.bodyMedium.copyWith(
            color: palette.textSecondary,
          ),
        ),
      );
    }

    final total = amounts.fold<int>(0, (sum, a) => sum + a.amount);

    // Pre-resolve each segment's localized name, formatted ¥, %, and a distinct
    // warm joy hue (largest→smallest order preserved from the provider).
    final segments = <JoySpendSegment>[
      for (final entry in amounts.asMap().entries)
        JoySpendSegment(
          label: CategoryLocalizationService.resolveFromId(
            entry.value.categoryId,
            locale,
          ),
          amount: entry.value.amount,
          formattedAmount: NumberFormatter.formatCurrency(
            entry.value.amount,
            'JPY',
            locale,
          ),
          percent: total > 0
              ? (entry.value.amount / total * 100).round()
              : 0,
          color: _segmentColor(entry.key, amounts.length, palette),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // D-D2 anchor #2: count-up the 悦己 header total.
        Text(
          l10n.analyticsJoySpendHeaderLabel,
          style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: 2),
        TweenAnimationBuilder<int>(
          key: const ValueKey('joy_spend_total_countup'),
          tween: IntTween(begin: 0, end: total),
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Text(
            NumberFormatter.formatCurrency(value, 'JPY', locale),
            style: AppTextStyles.amountLarge.copyWith(color: palette.joyText),
          ),
        ),
        const SizedBox(height: 16),
        JoySpendStackedBar(segments: segments),
      ],
    );
  }

  /// Distinct warm sakura-anchored hue per segment (avoids the daily-green /
  /// shared-blue families — README data-correction). Lerps within the joy
  /// family so every segment reads as 悦己 spend.
  Color _segmentColor(int index, int count, AppPalette palette) {
    if (count <= 1) return palette.joy;
    final t = index / (count - 1);
    // Lerp from the deep joy hue toward the lighter joy tint — a warm,
    // single-family ramp (not a green/blue cross-ledger gradient).
    return Color.lerp(palette.joy, palette.joyLight, t)!;
  }
}
