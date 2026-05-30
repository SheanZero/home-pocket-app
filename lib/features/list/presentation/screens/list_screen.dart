import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../../domain/models/list_filter_state.dart';
import '../../domain/models/tagged_transaction.dart';
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
    final locale =
        ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    // Phase 29: resolve currencyCode from bookByIdProvider
    const currencyCode = 'JPY';
    final filter = ref.watch(listFilterProvider);

    return Column(
      children: [
        CalendarHeaderWidget(
          bookId: bookId,
          currencyCode: currencyCode,
          locale: locale,
        ),
        ListSortFilterBar(bookId: bookId),
        Expanded(
          child: _buildList(context, ref, filter, locale),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    ListFilterState filter,
    Locale locale,
  ) {
    final txsAsync = ref.watch(listTransactionsProvider(bookId: bookId));
    return txsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.accentPrimary,
          strokeWidth: 2,
        ),
      ),
      error: (err, st) => Center(
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
              '[data load error]',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      data: (txs) {
        final anyFilterActive = filter.activeDayFilter != null ||
            filter.ledgerType != null ||
            filter.categoryIds.isNotEmpty ||
            filter.searchQuery.isNotEmpty;

        if (txs.isEmpty) {
          return ListEmptyState(isFilterActive: anyFilterActive);
        }

        final items = buildFlatList(txs, filter.sortConfig.sortDirection);
        return ListView.builder(
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
    );
  }

  Widget _buildTile(
    BuildContext context,
    WidgetRef ref,
    TaggedTransaction tx,
    ListFilterState filter,
    Locale locale,
    List<ListItem> items,
    int index,
  ) {
    // Stub: display values will be computed in Task 1b
    final tile = ListTransactionTile(
      taggedTx: tx,
      bookId: bookId,
      onTap: buildTileTapHandler(
        context: context,
        ref: ref,
        taggedTx: tx,
        bookId: bookId,
      ),
      tagText: '',
      tagBgColor: AppColors.survivalLight,
      tagTextColor: AppColors.survival,
      category: '',
      categoryColor: AppColors.survival,
      formattedAmount: '',
      formattedTime: '',
    );

    // Divider between consecutive tiles in the same day group
    final nextItem = index + 1 < items.length ? items[index + 1] : null;
    final showDivider = nextItem is TransactionRowItem;

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile,
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderList,
          ),
        ],
      );
    }
    return tile;
  }
}
