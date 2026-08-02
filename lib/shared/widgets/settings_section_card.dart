import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Comfortable two-line settings row height for mobile surfaces.
///
/// Flutter's standard [ListTile] contract is 72 logical pixels for two lines.
/// Keep the explicit value here so a compact app/theme density cannot shrink
/// tappable settings rows below the design contract.
const double kSettingsItemMinHeight = 72;

/// Rounded settings group used by the V16 settings surfaces.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
              child: Text(
                title!,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: palette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: palette.borderDefault),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index < children.length - 1)
                      Divider(
                        height: 1,
                        indent: 72,
                        color: palette.borderDivider,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsNavigationTile extends StatelessWidget {
  const SettingsNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SettingsActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      iconColor: iconColor,
    );
  }
}

/// Standard tappable row used inside a [SettingsSectionCard].
///
/// The icon tile, typography, spacing, and disclosure affordance mirror the
/// V16 settings mockup and are shared by both preference and navigation rows.
class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      minTileHeight: kSettingsItemMinHeight,
      minVerticalPadding: 8,
      visualDensity: VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: SettingsTileIcon(icon: icon, color: iconColor),
      title: Text(
        title,
        style: AppTextStyles.itemTitle.copyWith(color: palette.textPrimary),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: AppTextStyles.supporting.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
      trailing: trailing ?? const SettingsChevron(),
      onTap: onTap,
    );
  }
}

class SettingsTileIcon extends StatelessWidget {
  const SettingsTileIcon({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.palette.accentPrimary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: resolvedColor, size: 23),
    );
  }
}

class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      color: context.palette.textTertiary,
      size: 22,
    );
  }
}
