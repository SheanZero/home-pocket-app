import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_list_filter.dart';

/// Three render variants for [ListEmptyState] (Phase 30, D-04/D-05).
enum ListEmptyVariant {
  /// No transactions in the selected month, no filters active.
  noData,

  /// Only a calendar day-filter active and no results on that day.
  dayEmpty,

  /// Any ledger/category/search/member filter active (regardless of day).
  filtered,
}

/// Empty-state placeholder for the transaction list.
///
/// Three distinct render paths driven by [ListEmptyVariant]:
/// - [ListEmptyVariant.noData]    → receipt icon, no action (show all-month copy).
/// - [ListEmptyVariant.dayEmpty]  → event-busy icon + day-clear TextButton (selectDay(null)).
/// - [ListEmptyVariant.filtered]  → search-off icon + clearAll TextButton.
///
/// D-05 CRITICAL: dayEmpty uses selectDay(null) (day-only clear), NOT clearAll().
/// clearAll() resets the month anchor; selectDay(null) only clears activeDayFilter.
class ListEmptyState extends ConsumerWidget {
  const ListEmptyState({super.key, required this.variant});

  final ListEmptyVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, message, actionLabel, onAction) = switch (variant) {
      ListEmptyVariant.noData => (
          Icons.receipt_long_outlined,
          S.of(context).listEmptyMonth,
          null as String?,
          null as VoidCallback?,
        ),
      ListEmptyVariant.dayEmpty => (
          Icons.event_busy_outlined,
          S.of(context).listEmptyDay,
          S.of(context).listEmptyDayClear as String?,
          // D-05 CRITICAL: selectDay(null) clears ONLY the day filter
          (() => ref.read(listFilterProvider.notifier).selectDay(null))
              as VoidCallback?,
        ),
      ListEmptyVariant.filtered => (
          Icons.search_off_outlined,
          S.of(context).listEmptyFiltered,
          S.of(context).listEmptyFilteredClear as String?,
          (() => ref.read(listFilterProvider.notifier).clearAll())
              as VoidCallback?,
        ),
    };

    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: palette.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: palette.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: palette.accentPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
