import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Wa-Modern section divider: label ─── thin line
/// Used between content sections on the home screen.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.dividerLabel),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: AppColors.borderDivider),
        ),
      ],
    );
  }
}
