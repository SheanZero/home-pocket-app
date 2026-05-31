import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../features/accounting/presentation/screens/transaction_edit_screen.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/constants/sort_config.dart';
import '../../domain/models/list_filter_state.dart';
import '../../domain/models/tagged_transaction.dart';
import '../providers/state_calendar_totals.dart';
import '../providers/state_list_filter.dart';
import '../providers/state_list_transactions.dart';
import '../widgets/list_calendar_header.dart';
import '../widgets/list_day_group_header.dart';
import '../widgets/list_empty_state.dart';
import '../widgets/list_sort_filter_bar.dart';
import '../widgets/list_transaction_tile.dart';

/// List screen for Phase 28 — grouped-by-day transaction list with pinned sort/filter bar.
///
/// Replaces the Phase 27 CircularProgressIndicator placeholder with:
/// - [ListSortFilterBar]: pinned 44dp chip bar
/// - Grouped-by-day [ListView.builder] via [buildFlatList]
class ListScreen extends ConsumerWidget {
  const ListScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod 3: .value is the nullable accessor (not .valueOrNull, which was removed)
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    // Phase 29: resolve currencyCode from bookByIdProvider
    const currencyCode = 'JPY';
    final filter = ref.watch(listFilterProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: S.of(context).listCalNavPrev,
          onPressed: () {
            final prev = DateTime(
              filter.selectedYear,
              filter.selectedMonth - 1,
            );
            ref
                .read(listFilterProvider.notifier)
                .selectMonth(prev.year, prev.month);
          },
        ),
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final now = DateTime.now();
            ref
                .read(listFilterProvider.notifier)
                .selectMonth(now.year, now.month);
          },
          child: Text(
            DateFormatter.formatMonthYear(
              DateTime(filter.selectedYear, filter.selectedMonth),
              locale,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: S.of(context).listCalNavNext,
            onPressed: () {
              final next = DateTime(
                filter.selectedYear,
                filter.selectedMonth + 1,
              );
              ref
                  .read(listFilterProvider.notifier)
                  .selectMonth(next.year, next.month);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CalendarHeaderWidget(
            bookId: bookId,
            currencyCode: currencyCode,
            locale: locale,
          ),
          ListSortFilterBar(bookId: bookId),
          Expanded(child: _buildList(context, ref, filter, locale)),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    ListFilterState filter,
    Locale locale,
  ) {
    final txsAsync = ref.watch(listTransactionsProvider(bookId: bookId));
    return RefreshIndicator(
      color: AppColors.accentPrimary,
      onRefresh: () async {
        ref.invalidate(listTransactionsProvider(bookId: bookId));
        ref.invalidate(
          calendarDailyTotalsProvider(
            bookId: bookId,
            year: filter.selectedYear,
            month: filter.selectedMonth,
          ),
        );
        // Await re-settlement so spinner dismisses honestly (Pitfall F)
        await ref
            .read(listTransactionsProvider(bookId: bookId).future)
            .catchError((_) => <TaggedTransaction>[]);
      },
      child: txsAsync.when(
        loading: () => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: const CircularProgressIndicator(
              color: AppColors.accentPrimary,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (err, st) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).listLoadError,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (txs) {
          // D-05: "other" filters = non-day filters; anyOtherFilter takes priority over day filter
          final anyOtherFilter =
              filter.ledgerType != null ||
              filter.categoryIds.isNotEmpty ||
              filter.searchQuery.isNotEmpty ||
              filter.memberBookId != null;

          final variant = anyOtherFilter
              ? ListEmptyVariant.filtered
              : (filter.activeDayFilter != null
                    ? ListEmptyVariant.dayEmpty
                    : ListEmptyVariant.noData);

          if (txs.isEmpty) {
            // Wrap in scrollable so pull-to-refresh gesture fires when empty (Pitfall E)
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Breathing room below the sort/filter bar when there are no records.
              padding: const EdgeInsets.only(top: 80),
              child: ListEmptyState(variant: variant),
            );
          }

          // D-01 flat mode: amount sort renders a globally-sorted flat list with
          // no day-group headers. The transactions are already sorted by the
          // provider; skip buildFlatList entirely.
          if (filter.sortConfig.sortField == SortField.amount) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: txs.length,
              itemBuilder: (context, i) => _buildTile(
                context,
                ref,
                txs[i],
                filter,
                locale,
                txs,
                i,
                showDate: true,
              ),
            );
          }

          // Default: timestamp sort — grouped-by-day with day headers (unchanged).
          final items = buildFlatList(txs, filter.sortConfig.sortDirection);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            // Clear the floating bottom navigation bar so the last row is not obscured.
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return switch (item) {
                DayHeaderItem() => ListDayGroupHeader(
                  date: item.date,
                  locale: locale,
                ),
                TransactionRowItem() => _buildTile(
                  context,
                  ref,
                  item.tx,
                  filter,
                  locale,
                  items,
                  i,
                ),
              };
            },
          );
        },
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    WidgetRef ref,
    TaggedTransaction tx,
    ListFilterState filter,
    Locale locale,
    // Either List<ListItem> (timestamp mode) or List<TaggedTransaction> (amount mode).
    // Only used for divider lookahead; length is all that matters in amount mode.
    List<dynamic> items,
    int index, {
    bool showDate = false,
  }) {
    final transaction = tx.transaction;
    final ledgerType = transaction.ledgerType;

    // Ledger tag colors (AppColors constants — never hardcoded hex)
    final tagText = ledgerType == LedgerType.survival
        ? S.of(context).listLedgerSurvival
        : S.of(context).listLedgerSoul;
    final tagBgColor = ledgerType == LedgerType.survival
        ? AppColors.survivalLight
        : AppColors.soulLight;
    final tagTextColor = ledgerType == LedgerType.survival
        ? AppColors.survival
        : AppColors.soul;
    // Category label uses same color as ledger tag per UI-SPEC Typography table
    final categoryColor = tagTextColor;

    // Locale-resolved category name (FILTER-01 / D-04 — NEVER raw categoryId)
    final category = CategoryLocalizationService.resolveFromId(
      transaction.categoryId,
      locale,
    );

    // Formatted amount with currency symbol (SC#1 — amountSmall tabular figures applied by tile)
    final formattedAmount = NumberFormatter.formatCurrency(
      transaction.amount,
      'JPY',
      locale,
    );

    // L1 icon resolved from category ID
    final l1Icon = _resolveL1IconForCategory(transaction.categoryId);

    // Satisfaction icon: soul transactions only (ADR-014 mapping from home_screen.dart)
    final satisfactionIcon = _satisfactionIcon(transaction);

    // Invalidate list + calendar totals together. Both the edit-save and the
    // swipe-delete paths must refresh the calendar header (CR-01 / UI-SPEC C-04
    // step 5) — the calendar reads calendarDailyTotalsProvider, which the tile
    // cannot invalidate itself because it lacks the active year/month.
    void invalidateAfterMutation() {
      ref.invalidate(listTransactionsProvider(bookId: bookId));
      ref.invalidate(
        calendarDailyTotalsProvider(
          bookId: bookId,
          year: filter.selectedYear,
          month: filter.selectedMonth,
        ),
      );
    }

    // Tap handler: push TransactionEditScreen; on save (result == true), refresh.
    Future<void> onTap() async {
      try {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (ctx) => TransactionEditScreen(transaction: transaction),
          ),
        );
        if (result == true) {
          invalidateAfterMutation();
        }
      } catch (e, st) {
        // Surface rather than silently dropping the unhandled Future (WR-03).
        FlutterError.reportError(
          FlutterErrorDetails(exception: e, stack: st, library: 'list_screen'),
        );
      }
    }

    final tile = ListTransactionTile(
      taggedTx: tx,
      bookId: bookId,
      onTap: onTap,
      onDeleted: invalidateAfterMutation,
      tagText: tagText,
      tagBgColor: tagBgColor,
      tagTextColor: tagTextColor,
      category: category,
      categoryColor: categoryColor,
      formattedAmount: formattedAmount,
      l1Icon: l1Icon,
      locale: locale,
      merchant: transaction.merchant,
      satisfactionIcon: satisfactionIcon,
      showDate: showDate,
    );

    // Divider between consecutive tiles.
    // In amount-sort flat mode (showDate == true): always show divider except
    // after the last row. In timestamp grouped mode: show only between
    // consecutive transaction rows (not between a row and a day-group header).
    final nextItem = index + 1 < items.length ? items[index + 1] : null;
    final showDivider = showDate
        ? nextItem != null
        : nextItem is TransactionRowItem;

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile,
          const Divider(height: 1, thickness: 1, color: AppColors.borderList),
        ],
      );
    }
    return tile;
  }

  /// ADR-014 satisfaction icon mapping for soul-ledger transactions.
  ///
  /// Returns null for survival transactions (ledgerType != soul).
  /// Mirrors the mapping in [HomeScreen._satisfactionIcon].
  static IconData? _satisfactionIcon(Transaction tx) {
    if (tx.ledgerType != LedgerType.soul) return null;
    final v = tx.soulSatisfaction;
    if (v <= 2) return Icons.sentiment_neutral_outlined;
    if (v <= 4) return Icons.sentiment_satisfied_outlined;
    if (v <= 6) return Icons.sentiment_satisfied_alt_outlined;
    if (v <= 8) return Icons.sentiment_very_satisfied_outlined;
    return Icons.favorite_border;
  }

  /// Resolves the L1 category icon from a category ID string.
  ///
  /// Category IDs follow the pattern 'cat_{l1key}' (L1) or
  /// 'cat_{l1key}_{l2key}' (L2). For L2 IDs the last segment is stripped
  /// to get the L1 prefix, which is then looked up in the static icon map.
  static IconData _resolveL1IconForCategory(String categoryId) {
    const iconMap = <String, IconData>{
      'cat_food': Icons.restaurant,
      'cat_daily': Icons.local_mall,
      'cat_transport': Icons.directions_bus,
      'cat_hobbies': Icons.sports_esports,
      'cat_clothing': Icons.checkroom,
      'cat_social': Icons.people,
      'cat_health': Icons.local_hospital,
      'cat_education': Icons.school,
      'cat_utilities': Icons.flash_on,
      'cat_communication': Icons.phone_iphone,
      'cat_housing': Icons.home,
      'cat_car': Icons.directions_car,
      'cat_tax': Icons.account_balance,
      'cat_insurance': Icons.security,
      'cat_special': Icons.star,
      'cat_savings': Icons.savings,
      'cat_other': Icons.more_horiz,
    };

    if (!categoryId.startsWith('cat_')) return Icons.category;

    // Strip 'cat_' prefix, split remainder on '_', take first segment
    final withoutPrefix = categoryId.substring(4); // remove 'cat_'
    final parts = withoutPrefix.split('_');
    final l1Key = 'cat_${parts.first}';
    return iconMap[l1Key] ?? Icons.category;
  }
}
