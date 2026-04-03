import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Floating pill-style bottom navigation bar with 4 tabs and a FAB.
///
/// The pill has rounded corners (32px radius), a subtle shadow, and the active
/// tab is highlighted with a coral-coloured pill (14px radius). The FAB sits
/// to the right of the pill with a coral gradient.
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  static const _icons = [
    Icons.home_outlined,
    Icons.list,
    Icons.bar_chart,
    Icons.check_box_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final labels = [
      l10n.homeTabHome,
      l10n.homeTabList,
      l10n.homeTabChart,
      l10n.homeTabTodo,
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
                color: context.wmCard,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: context.wmBorderDefault),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                    color: context.wmNavShadow,
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
          _buildFab(),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, String label) {
    final isActive = index == currentIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.accentPrimary,
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[index],
              size: 20,
              color: isActive ? Colors.white : context.wmTextTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isActive
                  ? AppTextStyles.navLabelActive
                  : AppTextStyles.navLabel.copyWith(
                      color: context.wmTextTertiary,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: onFabTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.fabGradientStart, AppColors.fabGradientEnd],
          ),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 14,
              color: AppColors.fabShadow,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
