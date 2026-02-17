import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Custom bottom navigation bar with 4 tabs and a floating action button.
///
/// Pure UI component -- callbacks provided by parent.
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

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tabs = [
      _Tab(Icons.home_outlined, Icons.home, l10n.homeTabHome),
      _Tab(Icons.list_outlined, Icons.list, l10n.homeTabList),
      _Tab(Icons.schedule, Icons.schedule, l10n.homeTabChart),
      _Tab(Icons.checklist, Icons.checklist, l10n.homeTabTodo),
    ];

    return Container(
      height: 90,
      color: AppColors.tabBarBackground,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tab items
          Padding(
            padding: const EdgeInsets.only(
              top: 8,
              left: 12,
              right: 80,
              bottom: 24,
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isActive = i == currentIndex;
                final color = isActive
                    ? AppColors.survival
                    : AppColors.inactiveTab;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          size: 24,
                          color: color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: AppTextStyles.tabLabel.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // FAB
          Positioned(
            right: 20,
            top: -5,
            child: GestureDetector(
              onTap: onFabTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.fabGradientStart,
                      AppColors.fabGradientEnd,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.fabShadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
