import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/accounting/domain/models/transaction.dart';

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
    final palette = context.palette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          context: context,
          label: dailyLabel,
          icon: Icons.shield_outlined,
          type: LedgerType.daily,
          key: const ValueKey('ledger_type_daily_chip'),
          palette: palette,
          activeColor: palette.daily,
          activeBg: palette.dailyLight,
        ),
        const SizedBox(width: 10),
        _chip(
          context: context,
          label: joyLabel,
          icon: Icons.auto_awesome,
          type: LedgerType.joy,
          key: const ValueKey('ledger_type_joy_chip'),
          palette: palette,
          activeColor: palette.joy,
          activeBg: palette.joyLight,
        ),
      ],
    );
  }

  Widget _chip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required LedgerType type,
    required Key key,
    required AppPalette palette,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isActive = selected == type;

    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        key: key,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeBg : palette.backgroundMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : palette.borderDefault,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? activeColor : palette.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: isActive ? activeColor : palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
