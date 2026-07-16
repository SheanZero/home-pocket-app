import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/main_surface_header.dart';

/// Flat V15 header row with a tappable month title, compact mode badge, calendar
/// action and settings action.
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

  /// Tapping the month label opens the month picker dialog.
  final VoidCallback onMonthTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return MainSurfaceHeader(
      key: const Key('home-main-header'),
      title: l10n.homeMonthFormat(year, month),
      titleKey: const Key('home-main-title'),
      titleColor: context.palette.accentPrimary,
      onTitleTap: onMonthTap,
      titleTooltip: l10n.listMonthPickerLabel,
      trailing: _ModeBadge(isGroupMode: isGroupMode, l10n: l10n),
      actions: [
        MainSurfaceHeaderAction(
          key: const Key('home-calendar-hit-area'),
          icon: Icons.calendar_month_outlined,
          tooltip: l10n.listMonthPickerLabel,
          onPressed: onMonthTap,
        ),
        MainSurfaceHeaderAction(
          key: const Key('home-settings-hit-area'),
          icon: Icons.settings_outlined,
          tooltip: l10n.settings,
          onPressed: onSettingsTap,
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
      constraints: const BoxConstraints(minHeight: 27),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.compact.copyWith(
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
