import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DetailInfoRow {
  const DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showChevron = false,
    this.onTap,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showChevron;
  final VoidCallback? onTap;
  final TextStyle? valueStyle;
}

class DetailInfoCard extends StatelessWidget {
  const DetailInfoCard({super.key, required this.rows, this.trailing});

  final List<DetailInfoRow> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColorsDark.borderDefault
        : AppColors.borderDefault;
    final dividerColor = isDark
        ? AppColorsDark.backgroundDivider
        : AppColors.backgroundDivider;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.card : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _DetailInfoCardRow(row: rows[index], isDark: isDark),
            if (index < rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  key: ValueKey('detail_info_divider_$index'),
                  height: 1,
                  color: dividerColor,
                ),
              ),
          ],
          if (trailing != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(height: 1, color: dividerColor),
            ),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _DetailInfoCardRow extends StatelessWidget {
  const _DetailInfoCardRow({required this.row, required this.isDark});

  final DetailInfoRow row;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;
    final valueColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;
    final iconColor = isDark
        ? AppColorsDark.textTertiary
        : AppColors.textTertiary;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(row.icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            row.label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    row.value,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: row.valueStyle?.copyWith(color: valueColor) ??
                        AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: valueColor,
                        ),
                  ),
                ),
                if (row.showChevron) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: labelColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (row.onTap == null) {
      return content;
    }

    return InkWell(
      onTap: row.onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}
