import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Size variant for [CategoryReorderRow].
enum CategoryReorderRowVariant { l1, l2 }

/// A single draggable category row used inside a [ReorderableListView] in
/// edit mode. Pure presentation — no tap handlers, no Riverpod deps.
class CategoryReorderRow extends StatelessWidget {
  const CategoryReorderRow({
    super.key,
    required this.label,
    required this.iconData,
    required this.color,
    required this.variant,
    this.dragHandle,
    this.onDelete,
    this.deleteTooltip,
  });

  final String label;
  final IconData iconData;
  final Color color;
  final CategoryReorderRowVariant variant;
  final Widget? dragHandle;
  final VoidCallback? onDelete;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isL1 = variant == CategoryReorderRowVariant.l1;
    final rowHeight = isL1 ? 60.0 : 46.0;
    final iconBoxSize = isL1 ? 32.0 : 0.0;
    final innerIconSize = isL1 ? 18.0 : 0.0;
    final labelSize = isL1 ? 15.0 : 14.0;

    return Container(
      height: rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(isL1 ? 14 : 10),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Row(
        children: [
          dragHandle ??
              Icon(
                Icons.drag_indicator,
                size: 22,
                color: palette.textSecondary,
              ),
          const SizedBox(width: 10),
          if (isL1) ...[
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, size: innerIconSize, color: color),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              tooltip: deleteTooltip,
              icon: Icon(
                Icons.delete_outline,
                color: palette.textSecondary,
                size: 21,
              ),
            ),
        ],
      ),
    );
  }
}
