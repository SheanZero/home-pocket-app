import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/transaction.dart';

/// Toggle chips for selecting Survival or Soul ledger type.
class LedgerTypeSelector extends StatelessWidget {
  const LedgerTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.survivalLabel,
    required this.soulLabel,
  });

  final LedgerType selected;
  final ValueChanged<LedgerType> onChanged;
  final String survivalLabel;
  final String soulLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(
          label: survivalLabel,
          icon: Icons.shield_outlined,
          type: LedgerType.survival,
          activeColor: AppColors.survival,
          activeBg: const Color(0xFFEEF4FA),
        ),
        const SizedBox(width: 10),
        _chip(
          label: soulLabel,
          icon: Icons.auto_awesome,
          type: LedgerType.soul,
          activeColor: AppColors.soul,
          activeBg: AppColors.soulLight,
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required LedgerType type,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isActive = selected == type;

    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeBg : const Color(0xFFF5F9FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFE0E8EF),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
