import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/family_sync/presentation/widgets/family_mode_badge.dart';
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
    required this.onModeTap,
  });

  final int year;
  final int month;
  final bool isGroupMode;
  final VoidCallback onSettingsTap;
  final VoidCallback onModeTap;

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
      titleStyle: AppTextStyles.numerals(AppTextStyles.pageTitle),
      onTitleTap: onMonthTap,
      titleTooltip: l10n.listMonthPickerLabel,
      trailing: FamilyModeBadge(
        key: const Key('home-mode-badge'),
        isGroupMode: isGroupMode,
        onTap: onModeTap,
      ),
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
