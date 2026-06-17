import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../../../generated/app_localizations.dart';
import '../analytics_card_registry.dart';
import '../providers/state_analytics.dart';
import '../widgets/analytics_screen_section_header.dart';
import '../widgets/cards/family_insight_data_card.dart';
import '../widgets/joy_metric_variant_chip.dart';
import '../widgets/time_window_chip.dart';

/// Phase 11 Variant delta unified analytics dashboard.
///
/// Phase 45 (D-A1 / REDES-01): a THIN SHELL. The body is built by mapping
/// [analyticsCardRegistry] (the single source of render order AND the
/// `_refresh` invalidation union — D-B1) into the [Column] children,
/// interleaving the section headers + spacers 1:1 with the previous
/// hand-written tree. The 7 inline `_*Card` widgets + the shared
/// `_AnalyticsDataCard` now live under `widgets/cards/`. `_refresh` is derived
/// from the registry (no hand-listed providers) so HomeHero isolation is
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

    // AppBar-only read: the TimeWindowChip surfaces the earliest data month.
    final earliestMonthAsync = ref.watch(
      earliestTransactionMonthProvider(bookId: bookId),
    );

    // Display-only home-feature read (NOT an invalidation target — never in the
    // `_refresh` union, D-B3). Resolved here and injected into the one
    // FamilyInsightDataCard the registry leaves with a null placeholder.
    final shadowBooksAsync = ctx.isGroupMode
        ? ref
              .watch(shadowBooksProvider)
              .whenData<List<Object>?>((value) => value)
        : const AsyncValue<List<Object>?>.data(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyticsTitle),
        actions: [
          TimeWindowChip(
            locale: ctx.locale,
            earliestData: earliestMonthAsync.value,
          ),
          JoyMetricVariantChip(locale: ctx.locale),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref, ctx),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildCardChildren(l10n, ctx, shadowBooksAsync),
          ),
        ),
      ),
    );
  }

  /// Maps [analyticsCardRegistry] into the [Column] children 1:1 with the
  /// previous hand-written tree (D-A1): for each visible spec, a
  /// [sectionHeaderKey] opens a section with `SizedBox(32)` + section header +
  /// `SizedBox(8)`; otherwise an inter-card `SizedBox(8)` precedes it (the very
  /// first card — the KPI hero — has no leading spacer). A trailing
  /// `SizedBox(64)` closes the list.
  List<Widget> _buildCardChildren(
    S l10n,
    AnalyticsCardContext ctx,
    AsyncValue<List<Object>?> shadowBooksAsync,
  ) {
    final children = <Widget>[];
    var isFirst = true;

    for (final spec in analyticsCardRegistry) {
      if (!spec.isVisible(ctx)) continue;

      if (spec.sectionHeaderKey != null) {
        // A new themed section: 32px gap, header, 8px gap. The first card never
        // gets a leading section gap before its header in the legacy tree — but
        // the first card (KPI hero) has no sectionHeaderKey, so the first
        // header always follows the KPI hero (preceded by SizedBox(32)).
        children.add(const SizedBox(height: 32));
        children.add(
          AnalyticsScreenSectionHeader(
            label: _sectionLabel(l10n, spec.sectionHeaderKey!),
          ),
        );
        children.add(const SizedBox(height: 8));
      } else if (!isFirst) {
        // An inter-card gap (the legacy tree uses 8px between sibling cards).
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

  String _sectionLabel(S l10n, String key) {
    switch (key) {
      case 'analyticsGroupHeaderTime':
        return l10n.analyticsGroupHeaderTime;
      case 'analyticsGroupHeaderDistribution':
        return l10n.analyticsGroupHeaderDistribution;
      case 'analyticsGroupHeaderStories':
        return l10n.analyticsGroupHeaderStories;
      default:
        return key;
    }
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
