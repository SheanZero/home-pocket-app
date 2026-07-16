import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/home_v15_visual_tokens.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../shared/widgets/satisfaction_face_icon.dart';
import '../../../analytics/domain/models/best_joy_moment_row.dart';
import '../../../analytics/domain/models/family_happiness.dart';
import '../../../analytics/domain/models/happiness_report.dart';
import '../../../analytics/domain/models/metric_result.dart';
import '../../../analytics/domain/models/monthly_report.dart';
import '../providers/state_shadow_books.dart';
import 'home_metrics_region.dart';

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
          // v15 `.faithful-hero`: surface tinted ~10% toward primary-soft,
          // radius 22, primary-tinted border, soft ambient shadow.
          color: Color.lerp(palette.card, palette.accentPrimaryLight, 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Color.lerp(
              palette.borderDefault,
              palette.accentPrimary,
              0.18,
            )!,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.navShadow,
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(context, l10n, palette),
            const SizedBox(height: 16),
            _splitBar(context, l10n, palette),
            const SizedBox(height: 12),
            _divider(context),
            const SizedBox(height: 12),
            _ringSection(context, l10n, palette),
            const SizedBox(height: 12),
            _divider(context),
            const SizedBox(height: 12),
            // Region 6: Best Joy strip.
            _buildBestJoyStrip(context, l10n, palette),
            if (showMembers) ...[
              const SizedBox(height: 12),
              _divider(context),
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
          style: AppTextStyles.label.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _fmt.formatCurrency(total, currencyCode, locale),
                style: AppTextStyles.amountHero.copyWith(
                  letterSpacing: -0.4,
                  color: palette.textPrimary,
                ),
              ),
            ),
            if (hasAny) _trendChip(palette, trend),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          l10n.homeHeroPreviousMonthSubline(
            _fmt.formatCurrency(prev, currencyCode, locale),
          ),
          style: AppTextStyles.supporting.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _trendChip(AppPalette palette, int trend) {
    final text = trend <= 0 ? '$trend%' : '+$trend%';
    // v15 `.faithful-trend`: calm primary-soft pill with primary-text content
    // regardless of direction; the arrow icon carries the up/down signal.
    final chipColor = palette.accentPrimaryLight;
    final contentColor = palette.accentPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend <= 0 ? Icons.trending_down : Icons.trending_up,
            size: 13,
            color: contentColor,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: AppTextStyles.compact.copyWith(
              fontWeight: FontWeight.w700,
              color: contentColor,
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
                // 260603-nr1 #3: solid joy fill (no gradient) to match the
                // daily segment's flat colour.
                child: Container(height: 6, color: palette.joy),
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
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
    final labelText = Text(
      label,
      style: AppTextStyles.compact.copyWith(color: palette.textSecondary),
    );
    final amountText = Text(
      amount,
      style: AppTextStyles.label.copyWith(
        fontWeight: FontWeight.w700,
        color: amountColor,
      ),
    );
    return Row(
      children: leading
          ? [
              dot,
              const SizedBox(width: 5),
              labelText,
              const SizedBox(width: 5),
              amountText,
            ]
          : [
              amountText,
              const SizedBox(width: 5),
              labelText,
              const SizedBox(width: 5),
              dot,
            ],
    );
  }

  // ─── Region 3+5+7: Divider ────────────────────────────────────────────────
  Widget _divider(BuildContext context) => Container(
    height: 1,
    color: HomeV15VisualTokens.of(context).metricDivider,
  );

  // ─── Region 4: ときめき度 metrics section (v15 faithfulMetrics) ───────────────
  Widget _ringSection(BuildContext context, S l10n, AppPalette palette) {
    final homeColors = HomeV15VisualTokens.of(context);
    final title = isGroupMode
        ? l10n.homeRingSectionTitleGroup
        : l10n.homeRingSectionTitleSingle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  // v15 region-title accent: rose leaf glyph for the ときめき region.
                  Icon(Icons.eco, size: 16, color: homeColors.metricAccent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const _InfoIcon(tooltipKey: _TooltipKey.joyIndex),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // "今月の分析を見る ›" — no own gesture; the tap falls through to the
            // whole-card onTap (hero → analytics), matching the mockup.
            _analysisLink(l10n, palette),
          ],
        ),
        const SizedBox(height: 12),
        HomeMetricsRegion(
          isGroupMode: isGroupMode,
          joyContribution: happiness.joyContribution,
          avgSatisfaction: happiness.avgSatisfaction,
          highlightsCount: happiness.highlightsCount,
          activeMonthlyJoyTarget: activeMonthlyJoyTarget,
          currencyCode: currencyCode,
          family: family,
        ),
      ],
    );
  }

  Widget _analysisLink(S l10n, AppPalette palette) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.homeViewMonthlyAnalysis,
          style: AppTextStyles.compact.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.accentPrimary,
          ),
        ),
        Icon(Icons.chevron_right, size: 14, color: palette.accentPrimary),
      ],
    );
  }

  // ─── Region 6: Best Joy strip (ticket × calendar fusion — quick 260602-u5x) ─
  //
  // Reverses the s9g flat-strip decision (user-approved): the VALUE state is now
  // a ticket card (票根) — a full-height 6px joy accent bar down the left edge, a
  // tinted joy body with a thin uniform joy border (radius 14). Inside: a left
  // calendar tile carrying the date (joy month band / big tabular day number /
  // weekday) as a visual anchor, a middle column with the parent (L1)
  // category-icon + L2 category name over the amount (joyText), and a right
  // frameless satisfaction seal (icon over tier word) separated by a dashed
  // vertical perforation (撕口). Empty / all-neutral states reuse the same ticket
  // chrome with a muted "—" calendar placeholder and no seal.
  // ARCH-002: primary line is category name only — no merchant/note. ADR-014
  // tier mapping reused via _satisfactionPillIcon/_satisfactionPillLabel.
  // homeBestJoyEmptyBig/AllNeutralBig ARB keys unused since Variant A.
  Widget _buildBestJoyStrip(BuildContext context, S l10n, AppPalette palette) {
    final titleText = isGroupMode
        ? l10n.homeBestJoyTagGroup
        : l10n.homeBestJoyTagSingle;
    return switch (bestJoy) {
      Empty() => _bestJoyEmpty(
        context,
        palette,
        titleText,
        l10n.homeBestJoyEmptySmall,
      ),
      Value(:final data) when data.joyFullness <= 2 => _bestJoyEmpty(
        context,
        palette,
        titleText,
        l10n.homeBestJoyAllNeutralSmall,
      ),
      Value(:final data) => _bestJoyValue(
        context,
        l10n,
        palette,
        titleText,
        data,
      ),
    };
  }

  /// Shared flat-strip chrome for both value + empty states (quick 260602-s9g).
  ///
  /// No tinted box or border — the strip renders directly on the card surface
  /// and relies on the parent card's padding, matching the ring section. The
  /// header mirrors `_ringSection`'s header (workspace_premium + textPrimary
  /// title) minus the info icon (the strip has no tooltip).
  Widget _bestJoyStripContainer({
    required BuildContext context,
    required AppPalette palette,
    required String title,
    required Widget row,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 260603-nr1 #2: medal icon for the 本月最爱 (best joy) header.
            Icon(
              Icons.workspace_premium,
              size: 16,
              color: HomeV15VisualTokens.of(context).metricAccent,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        row,
      ],
    );
  }

  /// Ticket chrome (票根) shared by the Best Joy value + empty states
  /// (quick 260602-u5x). A full-height 6px joy accent bar down the left edge,
  /// a tinted joy body with a thin uniform joy border, rounded to radius 14.
  ///
  /// Flutter forbids combining `borderRadius` with a non-uniform `Border`, so
  /// the rounding is done by an outer ClipRRect while the body keeps a uniform
  /// border only. IntrinsicHeight + Row(stretch) lets the accent bar match the
  /// content height.
  Widget _bestJoyTicket({
    required BuildContext context,
    required AppPalette palette,
    required Widget calendar,
    required Widget copy,
    Widget? seal,
  }) {
    final colors = HomeV15VisualTokens.of(context);
    final heroSurface = Color.lerp(
      palette.card,
      palette.accentPrimaryLight,
      0.10,
    )!;
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      decoration: BoxDecoration(
        color: colors.ticketSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.ticketBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: colors.ticketAccent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13),
                ),
              ),
            ),
            SizedBox(
              width: 58,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Align(alignment: Alignment.centerLeft, child: calendar),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Align(alignment: Alignment.centerLeft, child: copy),
              ),
            ),
            if (seal != null)
              SizedBox(
                key: const Key('best-joy-seal-panel'),
                width: 72,
                child: _TicketSealChrome(
                  borderColor: colors.ticketBorder,
                  cutoutColor: heroSurface,
                  child: seal,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Calendar tile (日历瓦片) carrying the Best Joy date as a visual anchor
  /// (quick 260602-u5x). ~48px wide, joyLight body, radius 11, soft joy shadow.
  /// A joy month band sits on top, a big tabular day number in the middle, and
  /// a muted weekday at the bottom. For the empty-state placeholder, pass
  /// [day] "—" with [month]/[weekday] null → a single centered muted glyph with
  /// no month band, keeping the tile size stable.
  Widget _bestJoyCalendarTile({
    required BuildContext context,
    required AppPalette palette,
    String? month,
    String? day,
    String? weekday,
  }) {
    // Month-band text reads as the page background sitting on the joy band:
    // near-white in light, near-black in dark — both supplied by palette.background.
    final colors = HomeV15VisualTokens.of(context);
    final monthBandText = palette.background;
    final isPlaceholder = month == null && weekday == null;
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: palette.joy.withValues(alpha: 0.18),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isPlaceholder
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    day ?? '—',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: AppTextStyles.itemTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    color: colors.ticketCalendar,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    alignment: Alignment.center,
                    child: Text(
                      month ?? '',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: AppTextStyles.micro.copyWith(
                        fontWeight: FontWeight.w700,
                        color: monthBandText,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day ?? '',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: AppTextStyles.itemTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.ticketText,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    weekday ?? '',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: AppTextStyles.micro.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
      ),
    );
  }

  Widget _bestJoyEmpty(
    BuildContext context,
    AppPalette palette,
    String title,
    String mutedLine,
  ) {
    return _bestJoyStripContainer(
      context: context,
      palette: palette,
      title: title,
      row: _bestJoyTicket(
        context: context,
        palette: palette,
        calendar: _bestJoyCalendarTile(
          context: context,
          palette: palette,
          day: '—',
        ),
        copy: Text(
          mutedLine,
          softWrap: true,
          style: AppTextStyles.supporting.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _bestJoyValue(
    BuildContext context,
    S l10n,
    AppPalette palette,
    String title,
    BestJoyMomentRow row,
  ) {
    final colors = HomeV15VisualTokens.of(context);
    final category = CategoryLocalizationService.resolveFromId(
      row.categoryId,
      locale,
    );
    final month = DateFormatter.formatCalendarMonth(row.timestamp, locale);
    final day = DateFormatter.formatCalendarDay(row.timestamp, locale);
    final weekday = DateFormat('E', locale.toString()).format(row.timestamp);
    final amount = _fmt.formatCurrency(row.amount, currencyCode, locale);

    final calendar = _bestJoyCalendarTile(
      context: context,
      palette: palette,
      month: month,
      day: day,
      weekday: weekday,
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.supporting.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          amount,
          style: AppTextStyles.amountSmall.copyWith(color: colors.ticketText),
        ),
      ],
    );
    final seal = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SatisfactionFaceIcon(
          value: row.joyFullness,
          size: 32,
          color: colors.ticketText,
        ),
        const SizedBox(height: 4),
        Text(
          _satisfactionPillLabel(l10n, row.joyFullness),
          style: AppTextStyles.supporting.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.ticketText,
          ),
        ),
      ],
    );

    return _bestJoyStripContainer(
      context: context,
      palette: palette,
      title: title,
      row: _bestJoyTicket(
        context: context,
        palette: palette,
        calendar: calendar,
        copy: copy,
        seal: seal,
      ),
    );
  }

  /// ADR-014 satisfaction value → tier label mapping (Variant A pill).
  String _satisfactionPillLabel(S l10n, int sat) {
    if (sat <= 2) return l10n.satisfactionLabelNeutral;
    if (sat <= 4) return l10n.satisfactionLabelOK;
    if (sat <= 6) return l10n.satisfactionLabelGood;
    if (sat <= 8) return l10n.satisfactionLabelGreat;
    return l10n.satisfactionLabelAmazing;
  }

  // ─── Region 8: Members section (group mode + non-empty shadowBooks) ───────
  Widget _buildMembersSection(
    BuildContext context,
    S l10n,
    AppPalette palette,
  ) {
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
  // v15 faithfulHero exposes a single ⓘ affordance in the ときめき region title.
  const _InfoIcon({required this.tooltipKey});

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
        child: Icon(Icons.info_outline, size: 16, color: palette.textSecondary),
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

/// V15 ticket seal: a full-height dashed tear line with semicircular cut-outs at
/// the top and bottom edge.
class _TicketSealChrome extends StatelessWidget {
  const _TicketSealChrome({
    required this.borderColor,
    required this.cutoutColor,
    required this.child,
  });

  final Color borderColor;
  final Color cutoutColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 2,
          child: CustomPaint(painter: _DashedVLinePainter(color: borderColor)),
        ),
        Center(child: child),
        Positioned(
          key: const Key('best-joy-notch-top'),
          left: -6,
          top: -1,
          child: _TicketNotch(
            color: cutoutColor,
            borderColor: borderColor,
            top: true,
          ),
        ),
        Positioned(
          key: const Key('best-joy-notch-bottom'),
          left: -6,
          bottom: -1,
          child: _TicketNotch(
            color: cutoutColor,
            borderColor: borderColor,
            top: false,
          ),
        ),
      ],
    );
  }
}

class _TicketNotch extends StatelessWidget {
  const _TicketNotch({
    required this.color,
    required this.borderColor,
    required this.top,
  });

  final Color color;
  final Color borderColor;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: borderColor);
    return Container(
      width: 12,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          left: side,
          top: top ? BorderSide.none : side,
          right: side,
          bottom: top ? side : BorderSide.none,
        ),
        borderRadius: top
            ? const BorderRadius.vertical(bottom: Radius.circular(7))
            : const BorderRadius.vertical(top: Radius.circular(7)),
      ),
    );
  }
}

class _DashedVLinePainter extends CustomPainter {
  const _DashedVLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0;
    const gap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedVLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
