import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/joy_warm_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../accounting/presentation/utils/category_display_utils.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/joy_category_amount.dart';
import '../providers/state_analytics.dart';
import 'joy_spend_stacked_bar.dart';

/// Shared 悦己花在哪 body — the count-up「悦己 ¥…」header + the custom
/// [JoySpendStackedBar] (j1–j7 warm palette) + single-column legend.
///
/// SINGLE SOURCE for the joy-spend visual rendered by the nested
/// [JoySpendDrawer] inside `CategoryDonutCard` (round-5 r5 mock §2b). The caller
/// supplies the resolved [amounts]; this widget pre-formats each segment's
/// localized name, ¥, %, and warm hue.
///
/// Ambient celebrate-past: amounts only — zero target/streak/ranking/cross-period
/// (ADR-012). Empty amounts → a neutral empty copy (no throw).
class JoySpendDrawerBody extends ConsumerWidget {
  const JoySpendDrawerBody({super.key, required this.amounts});

  final List<JoyCategoryAmount> amounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final categoryMap =
        ref.watch(analyticsCategoriesMapProvider).value ?? const {};

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
          label: categoryNameForDisplay(
            categoryId: entry.value.categoryId,
            category: categoryMap[entry.value.categoryId],
            locale: locale,
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
          icon: categoryMap[entry.value.categoryId] == null
              ? parentCategoryIconFromId(entry.value.categoryId)
              : parentCategoryIconForCategory(
                  categoryMap[entry.value.categoryId]!,
                ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [JoySpendStackedBar(segments: segments)],
    );
  }
}
