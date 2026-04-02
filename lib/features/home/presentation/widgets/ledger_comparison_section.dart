import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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

  static const _defaultBorderColor = AppColors.borderDefault;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: data.borderColor ?? _defaultBorderColor),
        ),
        child: Row(
          children: [
            Expanded(child: _buildLeftInfo()),
            const SizedBox(width: 8),
            Text(
              data.formattedAmount,
              style: AppTextStyles.amountMedium.copyWith(
                color: data.amountColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 13, color: data.chevronColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildTag(),
            const SizedBox(width: 6),
            Text(
              data.title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: data.titleColor,
              ),
            ),
          ],
        ),
        if (data.subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            style: AppTextStyles.overline.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
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
        style: AppTextStyles.micro.copyWith(
          color: data.tagTextColor,
        ),
      ),
    );
  }
}
