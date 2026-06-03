import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Flat header row with month navigation (prev/next chevrons + label tap),
/// mode badge, and settings icon.
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
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final int year;
  final int month;
  final bool isGroupMode;
  final VoidCallback onSettingsTap;

  /// Tapping the month label opens the month-year picker dialog.
  final VoidCallback onDateTap;

  /// Tapping the left chevron navigates to the previous month.
  final VoidCallback onPrevMonth;

  /// Tapping the right chevron navigates to the next month.
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Row(
      children: [
        // Left: prev-month chevron
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 20,
            color: context.palette.textSecondary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onPrevMonth,
        ),

        // Centre: month label tap → dialog
        GestureDetector(
          onTap: onDateTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.homeMonthFormat(year, month),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: context.palette.textSecondary,
              ),
            ],
          ),
        ),

        // Right: next-month chevron
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            size: 20,
            color: context.palette.textSecondary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onNextMonth,
        ),

        const Spacer(),

        // Mode badge (near settings)
        _ModeBadge(isGroupMode: isGroupMode, l10n: l10n),
        const SizedBox(width: 8),

        // Settings icon
        GestureDetector(
          onTap: onSettingsTap,
          child: Icon(
            Icons.settings_outlined,
            size: 22,
            color: context.palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Badge showing either family mode (coral) or personal mode (blue).
class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.isGroupMode, required this.l10n});

  final bool isGroupMode;
  final S l10n;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isGroupMode
        ? context.palette.familyBadgeBg
        : context.palette.dailyLight;
    final foregroundColor = isGroupMode
        ? context.palette.accentPrimary
        : context.palette.daily;
    final label = isGroupMode ? l10n.homeFamilyMode : l10n.homePersonalMode;
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
