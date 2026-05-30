import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/state_list_filter.dart';

/// Empty-state placeholder for the transaction list.
///
/// Two distinct render paths:
/// - [isFilterActive] == false: no transactions in month (receipt icon, no action).
/// - [isFilterActive] == true: filters active but 0 results (search-off icon + clearAll button).
class ListEmptyState extends ConsumerWidget {
  const ListEmptyState({super.key, required this.isFilterActive});

  final bool isFilterActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFilterActive
                  ? Icons.search_off_outlined
                  : Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isFilterActive
                  ? '絞り込み条件に一致する記録がありません'
                  : 'この月の記録はまだありません',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFilterActive) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(listFilterProvider.notifier).clearAll(),
                child: Text(
                  '絞り込みをクリア',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentPrimary,
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
