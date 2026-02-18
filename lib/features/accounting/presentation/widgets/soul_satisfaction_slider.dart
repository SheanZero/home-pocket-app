import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 10-segment green slider for soul satisfaction (1-10).
///
/// Each segment fills from light to dark green as the value increases.
/// Shows the percentage label on the right.
class SoulSatisfactionSlider extends StatelessWidget {
  const SoulSatisfactionSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  /// Current satisfaction value (1-10).
  final int value;

  /// Called with new value when user taps a segment.
  final ValueChanged<int> onChanged;

  /// Label displayed above the slider (e.g. "灵魂充盈度").
  final String label;

  static const _segmentColors = [
    Color(0xFFC8E2D3),
    Color(0xFFBBDCC9),
    Color(0xFFAED6BF),
    Color(0xFFA1D0B5),
    Color(0xFF94CAAB),
    Color(0xFF87C4A1),
    Color(0xFF7ABE97),
    Color(0xFF6DB88D),
    Color(0xFF60B283),
    Color(0xFF53AC79),
  ];

  static const _inactiveColor = Color(0xFFE8EFF5);

  @override
  Widget build(BuildContext context) {
    final percent = (value * 10).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: AppTextStyles.amountMedium.copyWith(
                color: AppColors.soul,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(10, (index) {
            final segmentValue = index + 1;
            final isActive = segmentValue <= value;
            final isFirst = index == 0;
            final isLast = index == 9;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(segmentValue),
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(
                    left: isFirst ? 0 : 1.5,
                    right: isLast ? 0 : 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _segmentColors[index]
                        : _inactiveColor,
                    borderRadius: BorderRadius.horizontal(
                      left: isFirst
                          ? const Radius.circular(5)
                          : Radius.zero,
                      right: isLast
                          ? const Radius.circular(5)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
