import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Flat header row with a tap-to-open month picker, mode badge, and settings
/// icon.
///
/// The month label is followed by a downward `⌄` affordance; tapping the
/// label+arrow group fires [onMonthTap], which the caller wires to open the
/// centered month-grid picker dialog (quick 260607-jrz). No prev/next chevrons.
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
    required this.onMonthTap,
  });

  final int year;
  final int month;
  final bool isGroupMode;
  final VoidCallback onSettingsTap;

  /// Tapping the month label + down-chevron opens the month picker dialog.
  final VoidCallback onMonthTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Row(
      children: [
        // Tappable month label + down-chevron — opens the month-grid picker.
        // 260607: title-size 18, non-bold w500 (was headlineMedium 24/w700).
        InkWell(
          onTap: onMonthTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // v15 `.home-month-title` — deep leaf-green month heading.
              Text(
                l10n.homeMonthFormat(year, month),
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.palette.accentPrimary,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: context.palette.textSecondary,
              ),
            ],
          ),
        ),

        const Spacer(),

        // Mode badge (near settings)
        _ModeBadge(isGroupMode: isGroupMode, l10n: l10n),
        const SizedBox(width: 8),

        // Month calendar icon — v15 mainHeader affordance; opens the same
        // month-grid picker as tapping the title.
        GestureDetector(
          onTap: onMonthTap,
          child: Icon(
            Icons.calendar_month_outlined,
            size: 22,
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(width: 14),

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
