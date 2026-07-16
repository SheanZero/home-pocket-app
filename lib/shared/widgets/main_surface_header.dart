import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Shared title bar for the four primary navigation surfaces.
///
/// The screen owns its body and scrolling behavior; this widget owns the title
/// and action geometry so Home, List, Analytics, and Shopping cannot drift.
class MainSurfaceHeader extends StatelessWidget {
  const MainSurfaceHeader({
    super.key,
    required this.title,
    this.titleKey,
    this.titleColor,
    this.onTitleTap,
    this.titleTooltip,
    this.trailing,
    this.actions = const [],
  });

  static const double height = 46;
  static const double horizontalInset = 20;
  static const double topInset = 11;
  static const double contentSpacing = 13;
  static const double trailingActionSpacing = 9;
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(
    horizontalInset,
    topInset,
    horizontalInset,
    0,
  );

  final String title;
  final Key? titleKey;
  final Color? titleColor;
  final VoidCallback? onTitleTap;
  final String? titleTooltip;
  final Widget? trailing;
  final List<MainSurfaceHeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    Widget titleWidget = Text(
      title,
      key: titleKey,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.pageTitle.copyWith(
        color: titleColor ?? context.palette.textPrimary,
      ),
    );

    if (onTitleTap != null) {
      titleWidget = InkWell(
        onTap: onTitleTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: titleWidget,
        ),
      );
      if (titleTooltip != null) {
        titleWidget = Tooltip(message: titleTooltip!, child: titleWidget);
      }
    }

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: titleWidget),
          ),
          ?trailing,
          if (trailing != null && actions.isNotEmpty)
            const SizedBox(width: trailingActionSpacing),
          ...actions,
        ],
      ),
    );
  }
}

/// A standard 40dp action target with a 24dp icon for [MainSurfaceHeader].
class MainSurfaceHeaderAction extends StatelessWidget {
  const MainSurfaceHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  static const double size = 40;
  static const double iconSize = 24;

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: size, height: size),
        iconSize: iconSize,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: color ?? context.palette.textPrimary),
      ),
    );
  }
}
