import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Flat header row with month picker, mode badge, and settings icon.
///
/// Pure UI component -- no providers, no navigation.
/// Sits on the warm ivory page background (no blue container, no SafeArea).
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.year,
    required this.month,
    required this.isGroupMode,
    required this.onSettingsTap,
    required this.onDateTap,
  });

  final int year;
  final int month;
  final bool isGroupMode;
  final VoidCallback onSettingsTap;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: month picker
          GestureDetector(
            onTap: onDateTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.homeMonthFormat(year, month),
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Center: mode badge
          _ModeBadge(isGroupMode: isGroupMode, l10n: l10n),

          // Right: settings icon
          GestureDetector(
            onTap: onSettingsTap,
            child: const Icon(
              Icons.settings_outlined,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge showing either family mode (coral) or personal mode (blue).
class _ModeBadge extends StatelessWidget {
  const _ModeBadge({
    required this.isGroupMode,
    required this.l10n,
  });

  final bool isGroupMode;
  final S l10n;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isGroupMode ? AppColors.accentPrimaryLight : AppColors.survivalLight;
    final foregroundColor =
        isGroupMode ? AppColors.accentPrimary : AppColors.survival;
    final label =
        isGroupMode ? l10n.homeFamilyMode : l10n.homePersonalMode;
    final icon = isGroupMode ? Icons.people : Icons.person;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}
