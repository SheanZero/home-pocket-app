import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/budget_progress.dart';

/// List of budget progress bars for all budgeted categories.
class BudgetProgressList extends StatelessWidget {
  const BudgetProgressList({super.key, required this.progressList});

  final List<BudgetProgress> progressList;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    if (progressList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.analyticsNoBudgetsSet,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsBudgetProgress,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...progressList.map((p) => _BudgetProgressItem(progress: p)),
          ],
        ),
      ),
    );
  }
}

class _BudgetProgressItem extends StatelessWidget {
  const _BudgetProgressItem({required this.progress});

  final BudgetProgress progress;

  Color get _statusColor {
    switch (progress.status) {
      case BudgetStatus.safe:
        return Colors.green;
      case BudgetStatus.warning:
        return Colors.orange;
      case BudgetStatus.exceeded:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context);
    const formatter = FormatterService();
    final spentAmount = formatter.formatCurrency(
      progress.spentAmount,
      'JPY',
      locale,
    );
    final budgetAmount = formatter.formatCurrency(
      progress.budgetAmount,
      'JPY',
      locale,
    );
    final remainingAmount = formatter.formatCurrency(
      progress.remainingAmount.abs(),
      'JPY',
      locale,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(progress.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$spentAmount / $budgetAmount',
                style: AppTextStyles.amountSmall.copyWith(
                  color: _statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress.percentage / 100).clamp(0.0, 1.5),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: _statusColor),
              ),
              Text(
                progress.remainingAmount >= 0
                    ? l10n.budgetRemainingAmount(remainingAmount)
                    : l10n.budgetExceededAmount(remainingAmount),
                style: AppTextStyles.amountSmall.copyWith(
                  fontSize: 12,
                  color: progress.remainingAmount >= 0
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
