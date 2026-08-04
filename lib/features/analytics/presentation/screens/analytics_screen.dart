import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../../../features/home/presentation/widgets/month_picker_dialog.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/widgets/main_surface_header.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import '../../domain/models/time_window.dart';
import '../analytics_card_registry.dart';
import '../providers/state_analytics.dart';
import '../providers/state_time_window.dart';
import '../widgets/analytics_primary_tabs.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/cards/family_insight_data_card.dart';

/// Round-5 r5 analytics dashboard (260620-lfp / D2).
///
/// A THIN SHELL (Phase 45 D-A1 / REDES-01). The body is built by mapping
/// [analyticsCardRegistry] (the single source of render order AND the
/// `_refresh` invalidation union — D-B1) into a SECTIONED [Column]: each spec
/// carrying a provider-free `sectionHeader` descriptor renders an
/// [AnalyticsSectionHeader] before its card (round-5 r5 reverses Phase-46 D-F2's
/// flat no-header lineup). `_refresh` is derived from the registry (no
/// hand-listed providers, and headers carry none) so HomeHero isolation is
/// guaranteed by construction (GUARD-01): the registry imports zero `home/*`
/// providers.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPrimaryTab _selectedTab = AnalyticsPrimaryTab.joy;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    // ONE canonical context drives BOTH the card map and `_refresh` so build
    // and invalidation keys cannot drift (D-A1 / D-B2).
    final ctx = buildAnalyticsCardContext(context, ref, bookId: widget.bookId);

    // v15 header (260714): month-only. The header title is the selected month
    // (joy-tinted per mock `.analytics-month-title`) and opens the same
    // month-grid picker the home/list headers use. The multi-granularity
    // TimeWindowChip + its sheet were removed — the UI exposes ONLY month
    // selection, though the underlying TimeWindow type is kept intact (the data
    // pipeline is month-keyed already).
    final window = ref.watch(selectedTimeWindowProvider);
    final anchorMonth = DateTime(window.range.end.year, window.range.end.month);

    // Display-only home-feature read (NOT an invalidation target — never in the
    // `_refresh` union, D-B3). Resolved here and injected into the one
    // FamilyInsightDataCard the registry leaves with a null placeholder.
    final shadowBooksAsync =
        ctx.isGroupMode && _selectedTab == AnalyticsPrimaryTab.spending
        ? ref
              .watch(shadowBooksProvider)
              .whenData<List<Object>?>((value) => value)
        : const AsyncValue<List<Object>?>.data(null);

    final spendingAsync = ref.watch(
      monthlyReportProvider(
        bookId: widget.bookId,
        startDate: ctx.startDate,
        endDate: ctx.endDate,
        joyMetricVariant: ctx.joyMetricVariant,
        includeFamily: true,
      ),
    );
    final joyCountsAsync = ref.watch(
      perDayJoyCountsProvider(
        bookId: widget.bookId,
        anchor: ctx.trendAnchor,
        joyMetricVariant: ctx.joyMetricVariant,
        includeFamily: false,
      ),
    );
    final bookAsync = ref.watch(
      accounting_providers.bookByIdProvider(bookId: widget.bookId),
    );
    final currencyCode = bookAsync.value?.currency ?? 'JPY';
    final spendingReport = spendingAsync.value;
    final spendingSummary = spendingReport == null
        ? '—'
        : NumberFormatter.formatCurrency(
            spendingReport.totalExpenses,
            currencyCode,
            ctx.locale,
          );
    final joyCounts = joyCountsAsync.value;
    final joyCount = joyCounts?.fold<int>(0, (sum, row) => sum + row.count);
    final joySummary = joyCount == null
        ? '—'
        : l10n.analyticsTabJoyCount(joyCount);
    final spendingLabel = ctx.isGroupMode
        ? l10n.analyticsTabFamilySpending
        : l10n.analyticsTabSpending;
    final joyLabel = ctx.isGroupMode
        ? l10n.analyticsTabMyJoy
        : l10n.analyticsTabJoy;

    // Opens the shared month-grid picker (same widget home/list use) and applies
    // the choice to the analytics time window as a MonthWindow. Future months are
    // disabled by the picker itself.
    Future<void> openMonthPicker() async {
      final picked = await showMonthPickerDialog(
        context,
        selectedYear: anchorMonth.year,
        selectedMonth: anchorMonth.month,
      );
      if (picked == null || !context.mounted) return;
      ref
          .read(selectedTimeWindowProvider.notifier)
          .setWindow(TimeWindow.month(year: picked.year, month: picked.month));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: MainSurfaceHeader.screenPadding,
              child: MainSurfaceHeader(
                key: const Key('analytics-main-header'),
                title: DateFormatter.formatMonthYear(anchorMonth, ctx.locale),
                titleKey: const Key('analytics-main-title'),
                titleColor: context.palette.joyText,
                onTitleTap: openMonthPicker,
                titleTooltip: l10n.listMonthPickerLabel,
                actions: [
                  MainSurfaceHeaderAction(
                    key: const Key('analytics-month-picker-button'),
                    icon: Icons.calendar_month_outlined,
                    tooltip: l10n.listMonthPickerLabel,
                    onPressed: openMonthPicker,
                  ),
                  MainSurfaceHeaderAction(
                    key: const Key('analytics-settings-button'),
                    icon: Icons.settings_outlined,
                    tooltip: l10n.settings,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(bookId: widget.bookId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MainSurfaceHeader.contentSpacing),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refresh(ref, ctx),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    MainSurfaceHeader.horizontalInset,
                    0,
                    MainSurfaceHeader.horizontalInset,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnalyticsPrimaryTabs(
                        selected: _selectedTab,
                        spendingLabel: spendingLabel,
                        joyLabel: joyLabel,
                        spendingSummary: spendingSummary,
                        joySummary: joySummary,
                        onChanged: (tab) {
                          if (tab == _selectedTab) return;
                          setState(() => _selectedTab = tab);
                        },
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeOut,
                        child: Column(
                          key: ValueKey(_selectedTab),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildCardChildren(
                            l10n,
                            ctx,
                            shadowBooksAsync,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps [analyticsCardRegistry] into a SECTIONED [Column] (round-5 r5 / D2 —
  /// reverses Phase-46 D-F2's flat no-header lineup). For each visible spec:
  ///   - if it carries a `sectionHeader` descriptor, an [AnalyticsSectionHeader]
  ///     is rendered first (with a leading `SizedBox(26)` except before the very
  ///     first widget, matching the mock `.sect-h` `margin:26px 4px 10px`), then
  ///     a `SizedBox(10)` gap, then the card.
  ///   - otherwise (the family card) a plain inter-card `SizedBox(8)` precedes it.
  /// A trailing `SizedBox(64)` closes the list. Section headers carry NO
  /// providers, so `_refresh` is untouched (GUARD-01).
  List<Widget> _buildCardChildren(
    S l10n,
    AnalyticsCardContext ctx,
    AsyncValue<List<Object>?> shadowBooksAsync,
  ) {
    final children = <Widget>[];
    var isFirst = true;

    for (final spec in analyticsCardRegistry) {
      if (spec.primaryTab != _selectedTab) continue;
      if (!spec.isVisible(ctx)) continue;

      final header = spec.sectionHeader;
      if (header != null) {
        if (!isFirst) {
          children.add(const SizedBox(height: 26));
        }
        children.add(
          AnalyticsSectionHeader(title: header.title(l10n), tone: header.tone),
        );
        children.add(const SizedBox(height: 10));
      } else if (!isFirst) {
        children.add(const SizedBox(height: 8));
      }

      children.add(_buildCard(spec, ctx, shadowBooksAsync));
      isFirst = false;
    }

    children.add(const SizedBox(height: 64));
    return children;
  }

  /// Builds a card from its spec. The FamilyInsightDataCard's display-only
  /// `shadowBooksAsync` is a shell-injected prop (the registry passes a null
  /// placeholder so it imports zero `home/*` providers — D-B3); the shell
  /// rebuilds that one card with the real shell-resolved value.
  Widget _buildCard(
    AnalyticsCardSpec spec,
    AnalyticsCardContext ctx,
    AsyncValue<List<Object>?> shadowBooksAsync,
  ) {
    final built = spec.build(ctx);
    if (built is FamilyInsightDataCard) {
      return FamilyInsightDataCard(
        bookId: ctx.bookId,
        startDate: ctx.startDate,
        endDate: ctx.endDate,
        isGroupMode: ctx.isGroupMode,
        shadowBooksAsync: shadowBooksAsync,
        locale: ctx.locale,
        joyMetricVariant: ctx.joyMetricVariant,
      );
    }
    return built;
  }

  /// Pull-to-refresh invalidation, derived ENTIRELY from the registry + the one
  /// shell-level target (D-B2/D-B4). The union is registry-derived and
  /// structurally analytics-only — it can NEVER contain a `home/*` provider
  /// because the registry imports none (D-B3; verified by the Plan-05 union
  /// test + home_screen_isolation_test). No provider is hand-listed here.
  ///
  /// `where(isVisible)` filters BEFORE `expand(refreshTargets)` so solo mode
  /// never invalidates family providers (D-B4). `.toSet()` dedupes the
  /// monthlyReport/happinessReport instances shared across cards.
  void _refresh(WidgetRef ref, AnalyticsCardContext ctx) {
    final targets = analyticsCardRegistry
        .where((spec) => spec.primaryTab == _selectedTab && spec.isVisible(ctx))
        .expand((spec) => spec.refreshTargets(ctx))
        .toSet();
    for (final ProviderBase<Object?> p in targets) {
      ref.invalidate(p);
    }
    for (final ProviderBase<Object?> p in shellRefreshTargets(ctx)) {
      ref.invalidate(p);
    }
  }
}
