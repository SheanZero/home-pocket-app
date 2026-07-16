import 'package:flutter/material.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Shared title/caption/child Card shell for analytics data cards.
///
/// Phase 45: promoted verbatim from the private `_AnalyticsDataCard` inline in
/// `analytics_screen.dart` (D-A1 byte-faithful move — only the class name lost
/// its leading underscore and the constructor gained `super.key`). Consumed by
/// `CategoryDonutCard` and `SatisfactionHistogramCard` (the `TotalSixMonthCard`
/// consumer was removed with the 6-month trend stack in 46-01, D-E2).
///
/// V15 uses a 16px radius and a very light warm shadow. Most cards keep 14px
/// padding; content-heavy cards can opt into their mock-specific inset.
class AnalyticsDataCard extends StatelessWidget {
  const AnalyticsDataCard({
    super.key,
    required this.title,
    required this.caption,
    required this.child,
    this.showHeader = true,
    this.padding = const EdgeInsets.all(14),
  });

  final String title;
  final String caption;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When `false`, the card's own [title]/[caption] header row is suppressed —
  /// used by the within-month trend card (round-5 r5 / D2), whose section header
  /// 「支出趋势」already labels it and whose mock body has no separate card title
  /// (pills sit at the top). All other cards keep `showHeader: true` (the section
  /// header is the section label; the card title is light, accepted redundancy).
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        key: const ValueKey('analytics_data_card'),
        decoration: BoxDecoration(
          color: palette.card,
          border: Border.all(color: palette.borderDefault),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.navShadow.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          key: const ValueKey('analytics_data_card_padding'),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                Text(
                  title,
                  style: AppTextStyles.itemTitle.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: AppTextStyles.supporting.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
