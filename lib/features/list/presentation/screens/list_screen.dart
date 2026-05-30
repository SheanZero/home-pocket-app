import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../features/accounting/presentation/screens/transaction_edit_screen.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
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
    final transaction = tx.transaction;
    final ledgerType = transaction.ledgerType;

    // Ledger tag colors (AppColors constants — never hardcoded hex)
    final tagText = ledgerType == LedgerType.survival
        ? S.of(context).listLedgerSurvival
        : S.of(context).listLedgerSoul;
    final tagBgColor =
        ledgerType == LedgerType.survival
            ? AppColors.survivalLight
            : AppColors.soulLight;
    final tagTextColor =
        ledgerType == LedgerType.survival ? AppColors.survival : AppColors.soul;
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

    // Time-only string HH:mm (D-09: date is shown in ListDayGroupHeader)
    final formattedTime = formatTransactionTime(transaction.timestamp, locale);

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
      formattedTime: formattedTime,
      satisfactionIcon: satisfactionIcon,
    );

    // Divider between consecutive tiles in the same day group (not after a row
    // followed by a day-group header).
    final nextItem = index + 1 < items.length ? items[index + 1] : null;
    final showDivider = nextItem is TransactionRowItem;

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
}
