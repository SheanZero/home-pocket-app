import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Blue top header with month display and settings button.
///
/// Pure UI component -- no providers, no navigation.
/// [bottomOverlap] adds extra blue space below the header row so that the
/// card beneath can visually overlap into the blue area via a Stack.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.year,
    required this.month,
    required this.onSettingsTap,
    required this.onDateTap,
    this.bottomOverlap = 0,
  });

  final int year;
  final int month;
  final VoidCallback onSettingsTap;
  final VoidCallback onDateTap;

  /// Extra blue height below the header content for card overlap.
  final double bottomOverlap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.heroBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(left: 24, right: 24, bottom: bottomOverlap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onDateTap,
                    child: Row(
                      children: [
                        Text(
                          l10n.homeMonthFormat(year, month),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textOnPrimary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textOnPrimary,
                      size: 24,
                    ),
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
