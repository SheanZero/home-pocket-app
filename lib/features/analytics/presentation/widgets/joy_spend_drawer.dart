import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/joy_warm_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../providers/state_analytics.dart';
import '../providers/state_donut_dimension.dart';
import '../providers/state_joy_metric_variant.dart';
import 'analytics_card_error_state.dart';
import 'joy_spend_drawer_body.dart';
import 'joy_spend_stacked_bar.dart';

/// The nested 悦己 joybar drawer (round-5 r5 mock §2b → 260622-d5i D1/D2/D3).
/// Lives INSIDE `CategoryDonutCard`'s hero.
///
/// D1 (260622-d5i): borderless. A 1px `palette.borderDivider` line separates the
/// 悦己 part from the donut/legend above; the old pink-bordered `Container` is
/// gone. A small ♡悦び chip (`joyLight` bg / `joyText`) + count + ¥total sit on
/// one label row.
///
/// D2 (260622-d5i): the drawer reads `donutDimensionStateProvider` (via the
/// passed [donutView]) so the member filter (`memberFilterDeviceId`) narrows the
/// 悦己 part using the SAME `tx.deviceId == deviceId` rule the overall donut uses.
///
/// D3 (260622-d5i): the drawer mirrors the top dimension toggle —
///   • `category` → by-category joy split (`joyCategoryAmountsProvider`, deviceId
///     applied), rendered via the shared [JoySpendDrawerBody].
///   • `member` → by-member joy split (`joyMemberAmountsProvider`, in-widget
///     filtered by `memberFilterDeviceId`), rendered via [JoySpendStackedBar]
///     with member names/emojis + a generic person icon.
///
/// All text routes through `S.of(context)`; every color resolves via
/// `palette` / `JoyWarmPalette` (no 裸 hex). ADR-012-neutral: just where joy
/// spend went, no ranking/target/cross-period.
class JoySpendDrawer extends ConsumerWidget {
  const JoySpendDrawer({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.joyMetricVariant,
    required this.donutView,
    required this.memberNames,
    required this.memberEmojis,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final JoyMetricVariant joyMetricVariant;

  /// 260622-d5i / D2/D3: the active donut dimension + global member filter,
  /// supplied by `CategoryDonutCard` (which already watches it).
  final DonutDimensionView donutView;

  /// 260622-d5i / D3: deviceId → display name (resolved by `CategoryDonutCard`,
  /// self overridden with the profile name) for the member-dimension labels.
  final Map<String, String> memberNames;

  /// 260622-d5i / D3: deviceId → avatar emoji (currently unused for the joy
  /// segment icon — members render with a generic person icon — but threaded for
  /// parity with the donut hero / future use).
  final Map<String, String> memberEmojis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final isMemberDim = donutView.dimension == DonutDimension.member;

    final Widget body = isMemberDim
        ? _buildMemberDimension(context, ref, palette)
        : _buildCategoryDimension(context, ref, palette);

    return body;
  }

  /// The shared chrome (D1): a top divider, then the label row
  /// (♡悦び chip — count — ¥total), then the bar/body. [activeBar] is the active
  /// dimension's rendered bar/body (category body or member stacked bar).
  Widget _chrome({
    required BuildContext context,
    required AppPalette palette,
    required Locale locale,
    required int total,
    required String countText,
    required Widget activeBar,
  }) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // D1: 1px divider separates 悦己 from the donut/legend above.
        Container(
          height: 1,
          color: palette.borderDivider,
          margin: const EdgeInsets.only(top: 16, bottom: 14),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // D1 label row: ♡悦び chip — count — ¥total (total right-aligned).
              Row(
                children: [
                  _JoyChip(palette: palette, label: l10n.analyticsJoySpendHeaderLabel),
                  const SizedBox(width: 7),
                  // Count takes the remaining space (left-aligned) so the ¥total
                  // stays pinned to the row end; ellipsizes if cramped.
                  Expanded(
                    child: Text(
                      countText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: palette.joyText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    NumberFormatter.formatCurrency(total, 'JPY', locale),
                    style: AppTextStyles.amountSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: palette.joyText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              activeBar,
            ],
          ),
        ),
      ],
    );
  }

  // ── 分类 dimension (D2: deviceId-filtered) ────────────────────────────────
  Widget _buildCategoryDimension(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
  ) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final amountsAsync = ref.watch(
      joyCategoryAmountsProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
        deviceId: donutView.memberFilterDeviceId,
      ),
    );

    return amountsAsync.when(
      data: (amounts) {
        final total = amounts.fold<int>(0, (sum, a) => sum + a.amount);
        return _chrome(
          context: context,
          palette: palette,
          locale: locale,
          total: total,
          countText: l10n.analyticsJoyDrawerCount(amounts.length),
          activeBar: JoySpendDrawerBody(
            amounts: amounts,
            showTotalHeader: false,
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
              deviceId: donutView.memberFilterDeviceId,
            ),
          ),
        ),
      ),
    );
  }

  // ── 成员 dimension (D3: by-member joy split, in-widget filtered) ───────────
  Widget _buildMemberDimension(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
  ) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final membersAsync = ref.watch(
      joyMemberAmountsProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );

    return membersAsync.when(
      data: (allMembers) {
        // In-widget member filter — same rule as CategoryDonutCard's member path.
        final filter = donutView.memberFilterDeviceId;
        final members = filter == null
            ? allMembers
            : allMembers.where((m) => m.deviceId == filter).toList();
        final total = members.fold<int>(0, (sum, m) => sum + m.amount);

        // Build segments directly from the (filtered) MemberSpendBreakdown list.
        final segments = <JoySpendSegment>[
          for (final entry in members.asMap().entries)
            JoySpendSegment(
              label: memberNames[entry.value.deviceId] ?? entry.value.deviceId,
              amount: entry.value.amount,
              formattedAmount: NumberFormatter.formatCurrency(
                entry.value.amount,
                'JPY',
                locale,
              ),
              percent: total > 0
                  ? (entry.value.amount / total * 100).round()
                  : 0,
              color: JoyWarmPalette.colorAt(entry.key),
              // Members have no IconData — use a generic person icon (D3).
              icon: Icons.person_outline,
            ),
        ];

        final Widget bar = segments.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.analyticsJoySpendEmpty,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              )
            : JoySpendStackedBar(segments: segments);

        return _chrome(
          context: context,
          palette: palette,
          locale: locale,
          total: total,
          countText: l10n.analyticsJoyDrawerMemberCount(segments.length),
          activeBar: bar,
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AnalyticsCardErrorState(
          onRetry: () => ref.invalidate(
            joyMemberAmountsProvider(
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

/// The small ♡悦び pill that keeps the joy identity (D1). `joyLight` bg /
/// `joyText` fg; a heart glyph via [Icons.favorite_border] (NO 裸 hex, no
/// hardcoded CJK — the label is localized).
class _JoyChip extends StatelessWidget {
  const _JoyChip({required this.palette, required this.label});

  final AppPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: palette.joyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 11, color: palette.joyText),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: palette.joyText,
            ),
          ),
        ],
      ),
    );
  }
}
