import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../providers/state_analytics.dart';
import '../providers/state_joy_metric_variant.dart';
import 'analytics_card_error_state.dart';
import 'joy_spend_drawer_body.dart';

/// The nested 悦己 joybar drawer (round-5 r5 mock §2b, D2). Lives INSIDE
/// `CategoryDonutCard`'s hero. Watches [joyCategoryAmountsProvider] with the SAME
/// key tuple the de-registered `JoySpendCard` used, and renders a connector chip
/// («▾ 把悦己这一块放大看看») followed by a pink-bordered drawer: drawer-top
/// (data-derived ¥ total + category count) + subtitle + the shared
/// [JoySpendDrawerBody] (count-up header + joybar + legend) + neutral caption.
///
/// The drawer's own error branch invalidates `joyCategoryAmountsProvider` (the
/// donut's error branch owns the monthlyReport target — the two are folded into
/// `categoryDonutRefreshTargets` so pull-to-refresh keeps invalidating both,
/// Pitfall-3). Pink chrome resolves via `Color.lerp(palette.joy, palette.joyLight,
/// …)` — NO 裸hex (RESEARCH A5). ADR-012-neutral: just where joy spend went, no
/// ranking/target/cross-period.
class JoySpendDrawer extends ConsumerWidget {
  const JoySpendDrawer({
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
    final palette = context.palette;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    final amountsAsync = ref.watch(
      joyCategoryAmountsProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return amountsAsync.when(
      data: (amounts) {
        final total = amounts.fold<int>(0, (sum, a) => sum + a.amount);
        // Pink drawer border, derived (no joyBorder token exists) — RESEARCH A5.
        final drawerBorderColor = Color.lerp(
          palette.joy,
          palette.joyLight,
          0.55,
        )!;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connector: dashed stem + pink chip.
              _JoyConnector(
                label: l10n.analyticsJoyDrawerConnector,
                stemColor: drawerBorderColor,
                chipBg: palette.joyLight,
                chipBorder: drawerBorderColor,
                chipText: palette.joyText,
              ),
              const SizedBox(height: 10),
              // The pink-bordered drawer card.
              Container(
                decoration: BoxDecoration(
                  color: palette.card,
                  border: Border.all(color: drawerBorderColor),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.analyticsJoyDrawerTitle(
                              NumberFormatter.formatCurrency(
                                total,
                                'JPY',
                                locale,
                              ),
                            ),
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: palette.joyText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.analyticsJoyDrawerCount(amounts.length),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.joyText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.analyticsJoyDrawerSubtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 13),
                    JoySpendDrawerBody(amounts: amounts),
                    const SizedBox(height: 12),
                    Text(
                      l10n.analyticsJoyDrawerCaption,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textTertiary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AnalyticsCardErrorState(
          onRetry: () => ref.invalidate(
            joyCategoryAmountsProvider(
              bookId: bookId,
              startDate: startDate,
              endDate: endDate,
              joyMetricVariant: joyMetricVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// The connector between the donut hero and the joy drawer: a centered dashed
/// vertical stem + a pink pill chip with a ▾ arrow (round-5 r5 mock `.joy-connector`).
class _JoyConnector extends StatelessWidget {
  const _JoyConnector({
    required this.label,
    required this.stemColor,
    required this.chipBg,
    required this.chipBorder,
    required this.chipText,
  });

  final String label;
  final Color stemColor;
  final Color chipBg;
  final Color chipBorder;
  final Color chipText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dashed 2px stem (three short dashes).
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: SizedBox(
              width: 2,
              height: 4,
              child: DecoratedBox(decoration: BoxDecoration(color: stemColor)),
            ),
          ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
          decoration: BoxDecoration(
            color: chipBg,
            border: Border.all(color: chipBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_down, size: 14, color: chipText),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: chipText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
