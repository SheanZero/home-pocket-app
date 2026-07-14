import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../../../features/home/presentation/widgets/month_picker_dialog.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../domain/models/time_window.dart';
import '../analytics_card_registry.dart';
import '../providers/state_time_window.dart';
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
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);

    // ONE canonical context drives BOTH the card map and `_refresh` so build
    // and invalidation keys cannot drift (D-A1 / D-B2).
    final ctx = buildAnalyticsCardContext(context, ref, bookId: bookId);

    // v15 header (260714): month-only. The AppBar title is the selected month
    // (joy-tinted per mock `.analytics-month-title`) and opens the same
    // month-grid picker the home/list headers use. The multi-granularity
    // TimeWindowChip + its sheet were removed — the UI exposes ONLY month
    // selection, though the underlying TimeWindow type is kept intact (the data
    // pipeline is month-keyed already).
    final window = ref.watch(selectedTimeWindowProvider);
    final anchorMonth = DateTime(
      window.range.end.year,
      window.range.end.month,
    );

    // Display-only home-feature read (NOT an invalidation target — never in the
    // `_refresh` union, D-B3). Resolved here and injected into the one
    // FamilyInsightDataCard the registry leaves with a null placeholder.
    final shadowBooksAsync = ctx.isGroupMode
        ? ref
              .watch(shadowBooksProvider)
              .whenData<List<Object>?>((value) => value)
        : const AsyncValue<List<Object>?>.data(null);

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
      appBar: AppBar(
        centerTitle: false,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: openMonthPicker,
          child: Text(
            DateFormatter.formatMonthYear(anchorMonth, ctx.locale),
            style: TextStyle(color: context.palette.joyText),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: l10n.analyticsTimeWindowChipTooltip,
            onPressed: openMonthPicker,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(bookId: bookId),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref, ctx),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // v15 `.analytics-screen`: horizontal 20 (was 16).
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildCardChildren(l10n, ctx, shadowBooksAsync),
          ),
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
      if (!spec.isVisible(ctx)) continue;

      final header = spec.sectionHeader;
      if (header != null) {
        if (!isFirst) {
          children.add(const SizedBox(height: 26));
        }
        children.add(
          AnalyticsSectionHeader(
            title: header.title(l10n),
            tone: header.tone,
          ),
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
        .where((spec) => spec.isVisible(ctx))
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
