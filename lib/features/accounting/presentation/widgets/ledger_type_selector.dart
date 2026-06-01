import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/transaction.dart';

/// Toggle chips for selecting Daily or Joy ledger type.
class LedgerTypeSelector extends StatelessWidget {
  const LedgerTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.dailyLabel,
    required this.joyLabel,
  });

  final LedgerType selected;
  final ValueChanged<LedgerType> onChanged;
  final String dailyLabel;
  final String joyLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          label: dailyLabel,
          icon: Icons.shield_outlined,
          type: LedgerType.daily,
          key: const ValueKey('ledger_type_daily_chip'),
          isDark: isDark,
          activeColor: AppColors.daily,
          activeBg: AppColors.dailyLight,
        ),
        const SizedBox(width: 10),
        _chip(
          label: joyLabel,
          icon: Icons.auto_awesome,
          type: LedgerType.joy,
          key: const ValueKey('ledger_type_joy_chip'),
          isDark: isDark,
          activeColor: AppColors.joy,
          activeBg: AppColors.joyLight,
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required LedgerType type,
    required Key key,
    required bool isDark,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isActive = selected == type;

    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        key: key,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeBg
              : (isDark
                    ? AppColorsDark.backgroundMuted
                    : AppColors.backgroundMuted),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor
                : (isDark
                      ? AppColorsDark.borderDefault
                      : AppColors.borderDefault),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? activeColor
                  : (isDark
                        ? AppColorsDark.textSecondary
                        : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: isActive
                    ? activeColor
                    : (isDark
                          ? AppColorsDark.textSecondary
                          : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
