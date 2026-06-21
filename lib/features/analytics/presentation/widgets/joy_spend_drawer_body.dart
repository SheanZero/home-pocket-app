import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/joy_warm_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../accounting/presentation/utils/category_display_utils.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/joy_category_amount.dart';
import 'joy_spend_stacked_bar.dart';

/// Shared 悦己花在哪 body — the count-up「悦己 ¥…」header + the custom
/// [JoySpendStackedBar] (j1–j7 warm palette) + single-column legend.
///
/// SINGLE SOURCE for the joy-spend visual: rendered both by the standalone
/// `JoySpendCard` wrapper (retained for its golden/anti-toxicity tests) AND by
/// the nested `_JoyDrawer` inside `CategoryDonutCard` (round-5 r5 mock §2b). The
/// caller supplies the resolved [amounts]; this widget pre-formats each
/// segment's localized name, ¥, %, and warm hue.
///
/// Ambient celebrate-past: amounts only — zero target/streak/ranking/cross-period
/// (ADR-012). Empty amounts → a neutral empty copy (no throw).
class JoySpendDrawerBody extends ConsumerWidget {
  const JoySpendDrawerBody({
    super.key,
    required this.amounts,
    this.showTotalHeader = true,
  });

  final List<JoyCategoryAmount> amounts;

  /// Whether to render the「悦己花销」label + count-up total above the joybar.
  /// The nested [JoySpendDrawer] passes `false` (drawer-top already shows the
  /// ¥ total — the count-up here would be a duplicate). The standalone
  /// `JoySpendCard` wrapper keeps the default `true`.
  final bool showTotalHeader;

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
          percent: total > 0 ? (entry.value.amount / total * 100).round() : 0,
          // D5: the joybar uses the mock's 7-color warm palette (j1–j7), wrapping
          // deterministically past 7 categories — NOT a single joy-family lerp.
          color: JoyWarmPalette.colorAt(entry.key),
          // TI1-ICON-01: L1 icon via the shared helper (categoryId is already L1).
          icon: parentCategoryIconFromId(entry.value.categoryId),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // D-D2 anchor #2: count-up the 悦己 header total. Skipped inside the
        // nested drawer (showTotalHeader == false) where drawer-top already
        // shows the ¥ total — rendering it here would duplicate it.
        if (showTotalHeader) ...[
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
        ],
        JoySpendStackedBar(segments: segments),
      ],
    );
  }
}
