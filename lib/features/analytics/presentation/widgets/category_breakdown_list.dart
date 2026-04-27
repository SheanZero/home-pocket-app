import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/monthly_report.dart';

/// Sortable list of all categories with amounts and percentages.
class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList({super.key, required this.breakdowns});

  final List<CategoryBreakdown> breakdowns;

  @override
  Widget build(BuildContext context) {
    if (breakdowns.isEmpty) return const SizedBox.shrink();

    final l10n = S.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsCategoryDetails,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...breakdowns.map((b) => _CategoryItem(breakdown: b)),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.breakdown});

  final CategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context);
    const formatter = FormatterService();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(breakdown.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breakdown.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.analyticsTransactionCount(breakdown.transactionCount),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.formatCurrency(breakdown.amount, 'JPY', locale),
                style: AppTextStyles.amountSmall.copyWith(color: Colors.black),
              ),
              Text(
                '${breakdown.percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
