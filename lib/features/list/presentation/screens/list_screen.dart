import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../features/accounting/presentation/screens/transaction_edit_screen.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/utils/currency_conversion.dart';
import '../../../../shared/constants/sort_config.dart';
import '../../../../shared/utils/invalidate_transaction_dependents.dart';
import '../../domain/models/list_filter_state.dart';
import '../../domain/models/tagged_transaction.dart';
import '../providers/state_calendar_totals.dart';
import '../providers/state_list_filter.dart';
import '../providers/state_list_transactions.dart';
import '../widgets/list_calendar_header.dart';
import '../widgets/list_day_group_header.dart';
import '../widgets/list_empty_state.dart';
import '../widgets/list_ledger_segments.dart';
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
    final now = DateTime.now();
    final isCurrentMonth =
        filter.selectedYear == now.year && filter.selectedMonth == now.month;

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
          if (!isCurrentMonth)
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
          // v15 order: ledger segments → calendar → filter bar → list.
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ListLedgerSegments(),
          ),
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
    final palette = context.palette;
    final txsAsync = ref.watch(listTransactionsProvider(bookId: bookId));
    return RefreshIndicator(
      color: palette.accentPrimary,
      onRefresh: () async {
        // Refresh re-fetches data → invalidate the SQL base (P2-1); the search
        // layer [listTransactionsProvider] cascades because it watches the base.
        ref.invalidate(listTransactionsBaseProvider(bookId: bookId));
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
            child: CircularProgressIndicator(
              color: palette.accentPrimary,
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
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: palette.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).listLoadError,
                  style: AppTextStyles.caption.copyWith(
                    color: palette.textSecondary,
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
          // no day-group headers, inside a single v15 `.list-transactions` card.
          // The transactions are already sorted by the provider; skip
          // buildFlatList entirely.
          if (filter.sortConfig.sortField == SortField.amount) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _transactionCard(
                  context,
                  ref,
                  txs,
                  filter,
                  locale,
                  showDate: true,
                ),
              ],
            );
          }

          // Default: timestamp sort — grouped-by-day; each day is a day-header
          // followed by a `.list-transactions` card (v15 layout).
          final items = buildFlatList(txs, filter.sortConfig.sortDirection);
          final children = <Widget>[];
          var currentRows = <TaggedTransaction>[];
          DateTime? currentDate;

          void flushGroup() {
            if (currentDate != null && currentRows.isNotEmpty) {
              children.add(
                ListDayGroupHeader(date: currentDate, locale: locale),
              );
              children.add(
                _transactionCard(context, ref, currentRows, filter, locale),
              );
              children.add(const SizedBox(height: 6));
            }
            currentRows = <TaggedTransaction>[];
          }

          for (final item in items) {
            switch (item) {
              case DayHeaderItem():
                flushGroup();
                currentDate = item.date;
              case TransactionRowItem():
                currentRows.add(item.tx);
            }
          }
          flushGroup();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Clear the floating bottom navigation bar so the last row is not
            // obscured.
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: children,
          );
        },
      ),
    );
  }

  /// Builds a single v15 `.list-transactions` card wrapping [rows] with
  /// interior 1dp dividers between consecutive rows (no divider after the last).
  Widget _transactionCard(
    BuildContext context,
    WidgetRef ref,
    List<TaggedTransaction> rows,
    ListFilterState filter,
    Locale locale, {
    bool showDate = false,
  }) {
    final palette = context.palette;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(
        _buildTile(context, ref, rows[i], filter, locale, showDate: showDate),
      );
      if (i < rows.length - 1) {
        children.add(
          Divider(height: 1, thickness: 1, color: palette.borderList),
        );
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderDefault, width: 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildTile(
    BuildContext context,
    WidgetRef ref,
    TaggedTransaction tx,
    ListFilterState filter,
    Locale locale, {
    bool showDate = false,
  }) {
    final palette = context.palette;
    final transaction = tx.transaction;
    final ledgerType = transaction.ledgerType;

    // Ledger tag colors resolved via palette (COLOR-02 / D-07 dark-mode support).
    // v15 `.list-transaction-tag`/`-icon` use the darker *Text variants for AA
    // contrast on the soft tag background.
    final tagText = ledgerType == LedgerType.daily
        ? S.of(context).listLedgerDaily
        : S.of(context).listLedgerJoy;
    final tagBgColor = ledgerType == LedgerType.daily
        ? palette.dailyLight
        : palette.joyLight;
    final tagTextColor = ledgerType == LedgerType.daily
        ? palette.dailyText
        : palette.joyText;
    // Leading category icon uses the same ledger-text colour as the tag (v15).
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

    // DISP-02 / CURR-04: original-currency annotation for FOREIGN rows only.
    // Computed here (pure-UI tile contract — the tile never fetches/formats).
    // Null for JPY/domestic rows → the tile renders the amount block
    // byte-identically (CURR-04 regression protection). The annotation amount is
    // the stored original MINOR units rendered via NumberFormatter with
    // trimWholeFraction (260614-dx1): whole amounts drop ".00" ($12,211), real
    // fractions keep their decimals (USD 5050 minor → "$50.50").
    final originalCurrency = transaction.originalCurrency;
    final originalAmount = transaction.originalAmount;
    final String? foreignAnnotation =
        (originalCurrency != null &&
            originalCurrency.toUpperCase() != 'JPY' &&
            originalAmount != null)
        ? NumberFormatter.formatCurrency(
            originalAmount / subunitToUnitFor(originalCurrency),
            originalCurrency,
            locale,
            // 260614-dx1: whole foreign amounts drop ".00" ($12,211.00 → $12,211);
            // real fractions (kr12.50) keep their decimals.
            trimWholeFraction: true,
          )
        : null;

    // L1 icon resolved from category ID
    final l1Icon = _resolveL1IconForCategory(transaction.categoryId);

    // Satisfaction face: joy transactions only (ADR-014 mapping)
    final satisfactionValue = transaction.ledgerType == LedgerType.joy
        ? transaction.joyFullness
        : null;

    // 260603-nr1 #5: refresh every transaction-dependent provider after an
    // edit-save or swipe-delete — list + calendar (keyed) AND the Home today
    // summary + Analytics reports (whole families). Previously only list +
    // calendar were invalidated, leaving Home/Analytics stale in solo mode.
    void invalidateAfterMutation() {
      invalidateTransactionDependents(
        ref,
        bookId: bookId,
        year: filter.selectedYear,
        month: filter.selectedMonth,
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
      satisfactionValue: satisfactionValue,
      showDate: showDate,
      foreignAnnotation: foreignAnnotation,
    );

    // Dividers between rows are owned by [_transactionCard]; the tile renders
    // bare.
    return tile;
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
