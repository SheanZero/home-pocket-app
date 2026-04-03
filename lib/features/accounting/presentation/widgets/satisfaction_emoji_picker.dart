import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SatisfactionEmojiPicker extends StatelessWidget {
  const SatisfactionEmojiPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.levelLabels,
    required this.bottomLabels,
  });

  static const _faceValues = [2, 4, 6, 8, 10];
  static const _icons = [
    Icons.sentiment_very_dissatisfied_outlined,
    Icons.sentiment_dissatisfied_outlined,
    Icons.sentiment_neutral_outlined,
    Icons.sentiment_satisfied_alt_outlined,
    Icons.favorite_border,
  ];

  final int value;
  final ValueChanged<int> onChanged;
  final String title;
  final List<String> levelLabels;
  final List<String> bottomLabels;

  int get _selectedIndex {
    if (value <= 2) return 0;
    if (value <= 4) return 1;
    if (value <= 6) return 2;
    if (value <= 8) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _selectedIndex;
    final baseTileColor = isDark
        ? AppColorsDark.backgroundMuted
        : AppColors.backgroundMuted;
    final labelColor = isDark
        ? AppColorsDark.textTertiary
        : AppColors.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 13,
                color: isDark
                    ? AppColorsDark.textPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              levelLabels[selectedIndex],
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.soul,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_icons.length, (index) {
            final isSelected = index == selectedIndex;
            return GestureDetector(
              key: ValueKey('face_$index'),
              onTap: () => onChanged(_faceValues[index]),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColorsDark.tagGreen : AppColors.tagGreen)
                      : baseTileColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.soul : Colors.transparent,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  _icons[index],
                  size: 24,
                  color: isSelected
                      ? AppColors.soul
                      : (isDark
                            ? AppColorsDark.textSecondary
                            : AppColors.textSecondary),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                bottomLabels[0],
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                bottomLabels[1],
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                bottomLabels[2],
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
