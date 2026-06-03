import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_palette.dart';
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
  static const _chipSize = 56.0;

  /// Satisfaction faces (cat set), ordered low → high satisfaction.
  /// Monochrome SVGs — tinted via [ColorFilter] to match the picker state.
  static const _icons = [
    'assets/satisfaction/sat_01.svg',
    'assets/satisfaction/sat_02.svg',
    'assets/satisfaction/sat_03.svg',
    'assets/satisfaction/sat_04.svg',
    'assets/satisfaction/sat_05.svg',
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
    final palette = context.palette;
    final selectedIndex = _selectedIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 13,
                color: palette.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              levelLabels[selectedIndex],
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.joy,
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
                width: _chipSize,
                height: _chipSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? palette.joyLight : palette.backgroundMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? palette.joy : Colors.transparent,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: SvgPicture.asset(
                  _icons[index],
                  width: 34,
                  height: 34,
                  colorFilter: ColorFilter.mode(
                    isSelected ? palette.joy : palette.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Labels sit in fixed-width columns matching the icon row (same
        // spaceBetween), so 平和/不错/最爱 center under icons 1 / 3 / 5
        // instead of hugging the card edges.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_icons.length, (index) {
            final String label;
            if (index == 0) {
              label = bottomLabels[0];
            } else if (index == 2) {
              label = bottomLabels[1];
            } else if (index == _icons.length - 1) {
              label = bottomLabels[2];
            } else {
              label = '';
            }
            return SizedBox(
              width: _chipSize,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: palette.textTertiary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
