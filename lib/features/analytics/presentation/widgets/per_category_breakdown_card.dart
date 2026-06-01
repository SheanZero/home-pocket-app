import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/metric_result.dart';
import '../../domain/models/per_category_joy_breakdown.dart';
import '../providers/state_joy_metric_variant.dart';
import '../providers/state_ledger_snapshot.dart';
import 'analytics_card_error_state.dart';

/// Selector for which `PerCategoryBreakdownCard` title + provider variant to render.
///
/// - [solo]: solo mode (single book) → `analyticsCardTitlePerCategorySoul`.
/// - [you]: group mode personal card (current book) →
///   `analyticsCardTitlePerCategorySoulYou`.
/// - [family]: group mode family-aggregate card (across shadow books) →
///   `analyticsCardTitlePerCategorySoulFamily`. Reads
///   `perCategoryJoyBreakdownFamilyProvider` (no `bookId` parameter — the
///   provider derives book ids from `shadowBooksProvider`).
enum PerCategoryScope { solo, you, family }

/// HAPPY-V2-01 per-category joy-ledger satisfaction breakdown card.
///
/// Renders a ranked list of joy categories within the active window
/// (`startDate`/`endDate`), folding sub-min-N categories into an aggregate
/// "Other" row (D-08). Default view is top-5; tapping the "Show all"
/// affordance expands to the full list (and toggles back to "Show less").
///
/// State matrix per UI-SPEC §State Matrix:
/// - Loading: skeleton placeholder.
/// - Empty: provider returned `Empty<PerCategoryJoyBreakdown>()` → localized
///   `analyticsPerCategoryEmpty` body, no rows.
/// - Sub-min-N only: `items` empty but `otherCount > 0` → 0 ranked rows + Other
///   fold.
/// - Value (default): top-5 ranked + Other fold (if any) + "Show all" (if >5).
/// - Value (expanded): all items + Other fold + "Show less".
/// - Error: `AnalyticsCardErrorState` with retry invalidating the provider.
class PerCategoryBreakdownCard extends ConsumerStatefulWidget {
  const PerCategoryBreakdownCard({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.locale,
    this.joyMetricVariant = JoyMetricVariant.all,
    this.scope = PerCategoryScope.solo,
  });

  /// Active book id. Unused when [scope] is [PerCategoryScope.family] (the
  /// family provider derives ids from `shadowBooksProvider`) but accepted
  /// uniformly so the widget can be instantiated the same way in every scope.
  final String bookId;

  /// Inclusive window start.
  final DateTime startDate;

  /// Exclusive window end (matches Phase 15 use-case contracts).
  final DateTime endDate;

  /// Locale threaded through `CategoryLocalizationService` for category-name
  /// resolution. Sourced from `currentLocaleProvider` at the screen level.
  final Locale locale;

  /// AnalyticsScreen entry-source variant threaded into the provider family key.
  final JoyMetricVariant joyMetricVariant;

  /// Selector for title + provider variant.
  final PerCategoryScope scope;

  @override
  ConsumerState<PerCategoryBreakdownCard> createState() =>
      _PerCategoryBreakdownCardState();
}

class _PerCategoryBreakdownCardState
    extends ConsumerState<PerCategoryBreakdownCard> {
  static const int _defaultTop = 5;

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final title = _titleFor(l10n, widget.scope);

    final asyncResult = widget.scope == PerCategoryScope.family
        ? ref.watch(
            perCategoryJoyBreakdownFamilyProvider(
              startDate: widget.startDate,
              endDate: widget.endDate,
              joyMetricVariant: widget.joyMetricVariant,
            ),
          )
        : ref.watch(
            perCategoryJoyBreakdownProvider(
              bookId: widget.bookId,
              startDate: widget.startDate,
              endDate: widget.endDate,
              joyMetricVariant: widget.joyMetricVariant,
            ),
          );

    return Card(
      color: context.palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            asyncResult.when(
              loading: () => const SizedBox(height: 200),
              error: (_, _) => AnalyticsCardErrorState(onRetry: _invalidate),
              data: _renderResult,
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(S l10n, PerCategoryScope scope) {
    switch (scope) {
      case PerCategoryScope.solo:
        return l10n.analyticsCardTitlePerCategoryJoy;
      case PerCategoryScope.you:
        return l10n.analyticsCardTitlePerCategoryJoyYou;
      case PerCategoryScope.family:
        return l10n.analyticsCardTitlePerCategoryJoyFamily;
    }
  }

  void _invalidate() {
    if (widget.scope == PerCategoryScope.family) {
      ref.invalidate(
        perCategoryJoyBreakdownFamilyProvider(
          startDate: widget.startDate,
          endDate: widget.endDate,
          joyMetricVariant: widget.joyMetricVariant,
        ),
      );
    } else {
      ref.invalidate(
        perCategoryJoyBreakdownProvider(
          bookId: widget.bookId,
          startDate: widget.startDate,
          endDate: widget.endDate,
          joyMetricVariant: widget.joyMetricVariant,
        ),
      );
    }
  }

  Widget _renderResult(MetricResult<PerCategoryJoyBreakdown> result) {
    return switch (result) {
      Empty<PerCategoryJoyBreakdown>() => Text(
        S.of(context).analyticsPerCategoryEmpty,
        style: AppTextStyles.caption.copyWith(color: context.palette.textSecondary),
      ),
      Value<PerCategoryJoyBreakdown>(:final data) => _renderValue(data),
    };
  }

  Widget _renderValue(PerCategoryJoyBreakdown data) {
    final l10n = S.of(context);
    final hasOverflow = data.items.length > _defaultTop;
    final visibleItems = _isExpanded || !hasOverflow
        ? data.items
        : data.items.take(_defaultTop).toList();

    final children = <Widget>[];

    for (var i = 0; i < visibleItems.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 8));
      children.add(_buildRow(l10n, visibleItems[i]));
    }

    if (data.otherCount > 0) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(_buildOtherRow(l10n, data));
    }

    if (hasOverflow) {
      children.add(const SizedBox(height: 8));
      children.add(_buildToggleRow(l10n));
    }

    if (children.isEmpty) {
      // Defensive: items=[], otherCount=0, otherCategoryCount=0. The use case
      // should have returned Empty in this case, but render a sensible message
      // rather than an empty card body if it slips through.
      return Text(
        l10n.analyticsPerCategoryEmpty,
        style: AppTextStyles.caption.copyWith(color: context.palette.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildRow(S l10n, PerCategoryJoyBreakdownItem item) {
    final categoryName = CategoryLocalizationService.resolveFromId(
      item.categoryId,
      widget.locale,
    );
    final avgSat = item.avgSatisfaction.toStringAsFixed(1);
    final rowText = l10n.analyticsPerCategoryRow(
      categoryName,
      avgSat,
      item.totalCount,
    );
    return Text(
      rowText,
      style: AppTextStyles.amountMedium.copyWith(color: context.palette.textPrimary),
    );
  }

  Widget _buildOtherRow(S l10n, PerCategoryJoyBreakdown data) {
    return Text(
      l10n.analyticsPerCategoryOtherFold(
        data.otherCount,
        data.otherCategoryCount,
      ),
      style: AppTextStyles.caption.copyWith(color: context.palette.textSecondary),
    );
  }

  Widget _buildToggleRow(S l10n) {
    final label = _isExpanded
        ? l10n.analyticsPerCategoryShowLess
        : l10n.analyticsPerCategoryShowAll;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        onPressed: () => setState(() {
          _isExpanded = !_isExpanded;
        }),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label),
      ),
    );
  }
}
