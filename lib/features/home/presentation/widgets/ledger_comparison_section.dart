import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/models/ledger_row_data.dart';

/// Displays a vertical list of ledger row cards.
///
/// Solo mode shows 2 rows (survival + soul), group mode adds a 3rd shared row.
/// Each row shows a colored tag, title, optional subtitle, formatted amount,
/// and a navigation chevron.
class LedgerComparisonSection extends StatelessWidget {
  const LedgerComparisonSection({required this.rows, this.onRowTap, super.key});

  final List<LedgerRowData> rows;

  /// Called when a row is tapped, with the row index.
  final ValueChanged<int>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _LedgerRow(
            data: rows[i],
            onTap: onRowTap != null ? () => onRowTap!(i) : null,
          ),
        ],
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.data, this.onTap});

  final LedgerRowData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.wmCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: data.borderColor ?? context.wmBorderDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: tag + title | amount + chevron
            Row(
              children: [
                _buildTag(),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: data.titleColor,
                    ),
                  ),
                ),
                Text(
                  data.formattedAmount,
                  style: AppTextStyles.amountMedium.copyWith(
                    color: data.amountColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 14, color: data.chevronColor),
              ],
            ),
            // Line 2: subtitle
            if (data.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                style: AppTextStyles.overline.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.wmTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: data.tagBgColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        data.tagText,
        style: AppTextStyles.micro.copyWith(color: data.tagTextColor),
      ),
    );
  }
}
