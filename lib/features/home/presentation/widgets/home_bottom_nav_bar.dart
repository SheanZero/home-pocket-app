import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Floating pill-style bottom navigation bar with 4 tabs and a FAB.
///
/// The pill has rounded corners (32px radius) and a subtle shadow. The active
/// tab has no background — its icon and label are tinted with the primary
/// accent colour and slightly bolded; inactive tabs are tertiary grey. The FAB
/// sits to the right of the pill with a coral gradient.
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.onFabLongPress,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  /// 260614-iww: long-press the add-entry FAB to open the add screen in
  /// continuous mode. Nullable — when null the FAB only responds to taps.
  final VoidCallback? onFabLongPress;

  static const _icons = [
    Icons.home_outlined,
    Icons.list,
    Icons.bar_chart,
    Icons.shopping_bag_outlined,
  ];

  static const _activeIcons = [
    Icons.home,
    Icons.list,
    Icons.bar_chart,
    Icons.shopping_bag,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final labels = [
      l10n.homeTabHome,
      l10n.homeTabList,
      l10n.homeTabChart,
      l10n.homeTabShopping,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(21, 16, 21, 21),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Pill nav bar
          Expanded(
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: context.palette.card,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: context.palette.borderDefault),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                    color: context.palette.navShadow,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  4,
                  (i) => _buildTab(context, i, labels[i]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // FAB
          _buildFab(context),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, String label) {
    final isActive = index == currentIndex;

    final activeColor = context.palette.accentPrimary;
    // Pure neutral grey from the palette (light #BDBDBD / dark #8A8A8A) —
    // resolved per-brightness by the theme extension (COLOR-01).
    final inactiveColor = context.palette.navInactive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? _activeIcons[index] : _icons[index],
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isActive
                  ? AppTextStyles.navLabelActive.copyWith(color: activeColor)
                  : AppTextStyles.navLabel.copyWith(color: inactiveColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onFabTap,
      onLongPress: onFabLongPress,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.fabGradientStart, palette.fabGradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 14,
              color: palette.fabShadow,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
