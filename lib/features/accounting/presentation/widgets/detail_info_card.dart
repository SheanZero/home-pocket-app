import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

class DetailInfoRow {
  const DetailInfoRow({
    this.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showChevron = false,
    this.onTap,
    this.valueStyle,
  });

  /// Optional key forwarded to the rendered row widget for testability
  /// (Phase 19 P19-W2 — downstream tests use find.byKey(ValueKey('...'))).
  final Key? key;
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
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _DetailInfoCardRow(key: rows[index].key, row: rows[index]),
            if (index < rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  key: ValueKey('detail_info_divider_$index'),
                  height: 1,
                  color: palette.backgroundDivider,
                ),
              ),
          ],
          if (trailing != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(height: 1, color: palette.backgroundDivider),
            ),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _DetailInfoCardRow extends StatelessWidget {
  const _DetailInfoCardRow({super.key, required this.row});

  final DetailInfoRow row;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final labelColor = palette.textSecondary;
    final valueColor = palette.textPrimary;
    final iconColor = palette.textTertiary;

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
                    style:
                        row.valueStyle?.copyWith(color: valueColor) ??
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
