import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../domain/models/tagged_transaction.dart';
import '../../../../shared/constants/sort_config.dart';

/// Day section header rendered above each day's tile group in the [ListView].
///
/// Layout per C-02 (UI-SPEC): 32dp height, [AppPalette.backgroundMuted] background,
/// date formatted via [DateFormatter.formatDate] at [AppTextStyles.caption] style.
class ListDayGroupHeader extends StatelessWidget {
  const ListDayGroupHeader({
    super.key,
    required this.date,
    required this.locale,
  });

  final DateTime date;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // v15 `.list-day-header`: 28dp, no background, muted small caps-ish label.
    return Container(
      height: 28,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          DateFormatter.formatFullDateCjk(date, locale),
          style: AppTextStyles.labelSmall.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Grouped-by-day flat-list helpers ─────────────────────────────────────────

/// Sealed discriminated union for items in the transaction flat list.
///
/// Used by [buildFlatList] to interleave [DayHeaderItem] (day-group headers)
/// and [TransactionRowItem] (transaction tiles) in a single [ListView.builder].
sealed class ListItem {}

/// Represents a day-group header row in the flat list (renders [ListDayGroupHeader]).
class DayHeaderItem extends ListItem {
  DayHeaderItem(this.date);
  final DateTime date;
}

/// Represents a transaction tile row in the flat list (renders [ListTransactionTile]).
class TransactionRowItem extends ListItem {
  TransactionRowItem(this.tx);
  final TaggedTransaction tx;
}

/// Groups [txs] by calendar day and flattens to a mixed [ListItem] list.
///
/// Day groups are sorted by [direction]:
/// - [SortDirection.desc] → newest day first (default calendar view)
/// - [SortDirection.asc] → oldest day first
///
/// Within-day transaction order comes from [listTransactionsProvider] SQL ORDER BY
/// and is NOT re-sorted here (Pitfall 4: day-key order must mirror sortDirection).
List<ListItem> buildFlatList(
  List<TaggedTransaction> txs,
  SortDirection direction,
) {
  final map = <DateTime, List<TaggedTransaction>>{};
  for (final t in txs) {
    final key = DateTime(
      t.transaction.timestamp.year,
      t.transaction.timestamp.month,
      t.transaction.timestamp.day,
    );
    map.putIfAbsent(key, () => []).add(t);
  }
  final sortedKeys = map.keys.toList()
    ..sort(
      (a, b) => direction == SortDirection.desc
          ? b.compareTo(a)
          : a.compareTo(b),
    );
  return [
    for (final k in sortedKeys) ...[
      DayHeaderItem(k),
      for (final tx in map[k]!) TransactionRowItem(tx),
    ],
  ];
}
