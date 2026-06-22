import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../../generated/app_localizations.dart';
import '../../../../family_sync/domain/models/group_member.dart';
import '../../../../family_sync/presentation/providers/state_sync.dart';
import '../../../../profile/presentation/providers/state_user_profile.dart';
import '../../analytics_card_registry.dart';
import '../../providers/state_analytics.dart';
import '../../providers/state_donut_dimension.dart';
import '../../providers/state_joy_metric_variant.dart';
import '../analytics_card_error_state.dart';
import '../donut_dimension_member_controls.dart';
import '../donut_hero.dart';
import '../joy_spend_drawer.dart';
import 'analytics_data_card.dart';

/// Category-spend donut HERO card (round-5 B card #2, Phase 46).
///
/// Rebuilt from the Phase-45 verbatim move: the legend is now 10 L1-rollup rows
/// (via the single-source `rollupCategoryBreakdownsToL1` helper, D-11), each
/// row is fully tappable to `Navigator.push` the read-only
/// [CategoryDrillDownScreen] for that L1 (D-B1 — the ROW, never a pie slice),
/// and the donut center "本月支出" total animates with a `TweenAnimationBuilder`
/// count-up (~480ms, D-D2 anchor #1).
///
/// Still watches `monthlyReportProvider` with the SAME key tuple (the shell
/// `.toSet()` dedupes the shared instance), and `categoryDonutRefreshTargets`
/// remains the single source (D-B2) for the registry `_refresh` union and this
/// card's error-retry. Adds a read of `analyticsCategoriesMapProvider` for the
/// {id -> Category} map the L1 rollup needs.
class CategoryDonutCard extends ConsumerWidget {
  const CategoryDonutCard({
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
    final monthlyAsync = ref.watch(
      monthlyReportProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );
    final categoryMapAsync = ref.watch(analyticsCategoriesMapProvider);
    // round-5 r5 §1d: joy-aware donut colours. `JoyCategoryAmount.categoryId` is
    // ALREADY L1 (confirmed) — build the L1-id set directly, no rollup. The same
    // provider key the nested `JoySpendDrawer` watches → Riverpod dedupes.
    final joyAmountsAsync = ref.watch(
      joyCategoryAmountsProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        joyMetricVariant: joyMetricVariant,
      ),
    );
    final joyL1Ids = <String>{
      for (final a in joyAmountsAsync.value ?? const []) a.categoryId,
    };

    // §D2 (260620-v2m): donut dimension + global member filter.
    final donutView = ref.watch(donutDimensionStateProvider);
    // TD-1 / D-01: build the refresh targets from the LIVE member filter so the
    // self-derived error-retry target list (and the registry union via _ctx)
    // appends memberFilteredCategoryBreakdownProvider when a filter is active.
    final targets = categoryDonutRefreshTargets(
      _ctx(donutView.memberFilterDeviceId),
    );
    final members =
        ref.watch(activeGroupMembersProvider).value ?? const <GroupMember>[];
    // 260621-son Bug 1: self name single source = userProfileProvider (watched,
    // not snapshotted) so renaming in 设置 invalidates and re-renders here.
    final profile = ref.watch(userProfileProvider).value;
    final selfDeviceId = ref.watch(currentDeviceIdProvider).value;
    final memberNames = <String, String>{
      for (final m in members)
        m.deviceId: m.displayName.isNotEmpty
            ? m.displayName
            : (m.deviceName.isNotEmpty ? m.deviceName : m.deviceId),
    };
    final memberEmojis = <String, String>{
      for (final m in members) m.deviceId: m.avatarEmoji,
    };
    // 260621-son Bug 1: override the self record with the profile name/avatar so
    // 「自己」 shows "Shean" (设置 → 编辑个人资料), never a truncated deviceId.
    if (selfDeviceId != null && profile != null) {
      if (profile.displayName.isNotEmpty) {
        memberNames[selfDeviceId] = profile.displayName;
      }
      if (profile.avatarEmoji.isNotEmpty) {
        memberEmojis[selfDeviceId] = profile.avatarEmoji;
      }
    }

    final controls = const DonutDimensionMemberControls();

    Widget wrap(Widget hero) => AnalyticsDataCard(
      title: S.of(context).analyticsCardTitleCategoryDonut,
      caption: S.of(context).analyticsCardCaptionCategoryDonut,
      // round-5 r5 §1a: drop the in-card 「分类支出」 title/caption — the section
      // header already labels it (same handling as the trend card).
      showHeader: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 260621-son Bug 3: the 分类/成员 toggle + filter row is no longer a
          // card-level child here — it is injected into DonutHero (between the
          // donut and the legend) via `controls:` so it renders BELOW the donut.
          hero,
          // round-5 r5 §2b (D2) → 260622-d5i (D1/D2/D3): the 悦己 joybar is nested
          // INSIDE the donut hero, borderless + divider-separated, dimension-aware
          // and member-filtered. The drawer reads the same donutView the card does.
          JoySpendDrawer(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            joyMetricVariant: joyMetricVariant,
            donutView: donutView,
            memberNames: memberNames,
            memberEmojis: memberEmojis,
          ),
        ],
      ),
    );

    // ── 成员 dimension ──────────────────────────────────────────────────────
    if (donutView.dimension == DonutDimension.member) {
      final memberAsync = ref.watch(
        memberSpendBreakdownProvider(
          bookId: bookId,
          startDate: startDate,
          endDate: endDate,
          joyMetricVariant: joyMetricVariant,
        ),
      );
      return memberAsync.when(
        data: (allMembers) {
          // Global filter: narrow to one member when set.
          final filtered = donutView.memberFilterDeviceId == null
              ? allMembers
              : allMembers
                    .where(
                      (m) => m.deviceId == donutView.memberFilterDeviceId,
                    )
                    .toList();
          final memberTotal = filtered.fold<int>(0, (s, m) => s + m.amount);
          final memberCount = filtered.fold<int>(
            0,
            (s, m) => s + m.transactionCount,
          );
          return wrap(
            DonutHero(
              breakdowns: const [],
              total: memberTotal,
              entryCount: memberCount,
              month: monthlyAsync.value?.month ?? endDate.month,
              joyL1Ids: joyL1Ids,
              categoryMap: categoryMapAsync.value ?? const {},
              bookId: bookId,
              members: filtered,
              memberNames: memberNames,
              memberEmojis: memberEmojis,
              controls: controls,
            ),
          );
        },
        loading: () => const SizedBox(height: 280),
        error: (_, _) => AnalyticsCardErrorState(
          onRetry: () => ref.invalidate(
            memberSpendBreakdownProvider(
              bookId: bookId,
              startDate: startDate,
              endDate: endDate,
              joyMetricVariant: joyMetricVariant,
            ),
          ),
        ),
      );
    }

    // ── 分类 dimension + active member filter (global narrowing) ─────────────
    if (donutView.memberFilterDeviceId != null) {
      final filteredAsync = ref.watch(
        memberFilteredCategoryBreakdownProvider(
          bookId: bookId,
          startDate: startDate,
          endDate: endDate,
          deviceId: donutView.memberFilterDeviceId!,
          joyMetricVariant: joyMetricVariant,
        ),
      );
      return filteredAsync.when(
        data: (fc) => wrap(
          DonutHero(
            breakdowns: fc.breakdowns,
            total: fc.total,
            entryCount: fc.entryCount,
            month: monthlyAsync.value?.month ?? endDate.month,
            joyL1Ids: joyL1Ids,
            categoryMap: categoryMapAsync.value ?? const {},
            bookId: bookId,
            controls: controls,
          ),
        ),
        loading: () => const SizedBox(height: 280),
        error: (_, _) => AnalyticsCardErrorState(
          onRetry: () => ref.invalidate(
            memberFilteredCategoryBreakdownProvider(
              bookId: bookId,
              startDate: startDate,
              endDate: endDate,
              deviceId: donutView.memberFilterDeviceId!,
              joyMetricVariant: joyMetricVariant,
            ),
          ),
        ),
      );
    }

    // ── 分类 dimension, no filter (unchanged monthlyReport path) ─────────────
    return monthlyAsync.when(
      data: (monthly) => wrap(
        DonutHero(
          breakdowns: monthly.categoryBreakdowns,
          total: monthly.totalExpenses,
          // §1b: hero-top + center third line need the total entry count and
          // the display-anchor month.
          entryCount: monthly.categoryBreakdowns.fold<int>(
            0,
            (s, b) => s + b.transactionCount,
          ),
          month: monthly.month,
          joyL1Ids: joyL1Ids,
          // The legend's L1 rollup needs the category map; while it loads,
          // fall back to an empty map (the donut + center total still render).
          categoryMap: categoryMapAsync.value ?? const {},
          bookId: bookId,
          controls: controls,
        ),
      ),
      loading: () => const SizedBox(height: 280),
      // `targets` now folds in joyCategoryAmountsProvider (Pitfall-3); the donut's
      // own error branch owns the monthlyReport target — invalidate `.first`.
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(targets.first),
      ),
    );
  }

  /// Minimal [AnalyticsCardContext] for this card's targets. `trendAnchor` is
  /// derived from `endDate`; `isGroupMode` is unused by the targets.
  /// TD-1 / D-01: [memberFilterDeviceId] (the LIVE `donutView` filter) is
  /// threaded in so `categoryDonutRefreshTargets` appends the filtered breakdown
  /// target when a member filter is active.
  AnalyticsCardContext _ctx(String? memberFilterDeviceId) =>
      AnalyticsCardContext(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        trendAnchor: DateTime(endDate.year, endDate.month),
        joyMetricVariant: joyMetricVariant,
        isGroupMode: false,
        locale: const Locale('ja'),
        memberFilterDeviceId: memberFilterDeviceId,
      );
}

/// Single-source refresh targets for [CategoryDonutCard] (D-B2). Returns BOTH
/// the donut's `monthlyReportProvider` AND the nested joy drawer's
/// `joyCategoryAmountsProvider`, keyed on book/start/end/variant.
///
/// Pitfall-3 / GUARD-01: round-5 r5 (260620-lfp / D2) nests the 悦己 joybar inside
/// this card and de-registers the standalone `JoySpendCard`. Folding
/// `joyCategoryAmountsProvider` in here keeps the pull-to-refresh union
/// invalidating the drawer (the registry derives the union from
/// `expand(refreshTargets)`). `[0]` is the donut's own target (its error branch
/// invalidates `targets.first`); `[1]` is the drawer's (the `_JoyDrawer` error
/// branch invalidates `joyCategoryAmountsProvider` itself). Both are analytics
/// providers — the registry stays home-free.
///
/// TD-1 / D-01: when a member filter is active (`ctx.memberFilterDeviceId !=
/// null`), the donut watches `memberFilteredCategoryBreakdownProvider(deviceId:)`
/// (NOT `monthlyReportProvider`), so that filtered breakdown family is APPENDED
/// last to the union — otherwise pull-to-refresh would serve the stale cached
/// filtered data. The unfiltered union (no member filter) is byte-identical to
/// the prior four-target order. The filtered family is analytics `state_*`
/// (zero `home/*`) so GUARD-01 still holds.
List<ProviderBase<Object?>> categoryDonutRefreshTargets(
  AnalyticsCardContext ctx,
) => [
  monthlyReportProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
  joyCategoryAmountsProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
  // §D2 (260620-v2m): member dimension data — fold into the pull-to-refresh
  // union so the 成员 split refreshes alongside the category path.
  memberSpendBreakdownProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
  // 260622-d5i / D3: the 悦己 by-member joy split (UNFILTERED key — book/start/
  // end/variant, no deviceId concept here) so pull-to-refresh covers the
  // member-dim joy path too.
  joyMemberAmountsProvider(
    bookId: ctx.bookId,
    startDate: ctx.startDate,
    endDate: ctx.endDate,
    joyMetricVariant: ctx.joyMetricVariant,
  ),
  // TD-1 / D-01: the member-filtered category breakdown the donut watches when
  // a member filter is active — appended ONLY when one is set so the unfiltered
  // union stays byte-stable. Keyed identically to the card's watch (line ~192).
  if (ctx.memberFilterDeviceId != null)
    memberFilteredCategoryBreakdownProvider(
      bookId: ctx.bookId,
      startDate: ctx.startDate,
      endDate: ctx.endDate,
      deviceId: ctx.memberFilterDeviceId!,
      joyMetricVariant: ctx.joyMetricVariant,
    ),
];


