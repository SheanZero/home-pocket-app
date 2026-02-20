import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Displays the current amount with currency badge and clear button.
///
/// Shows "¥ JPY" badge on the left, the formatted amount in the center,
/// and an "x" clear button on the right when amount is non-empty.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amount,
    this.onClear,
  });

  /// Raw amount string (digits only, e.g. "3280").
  final String amount;

  /// Called when the clear button is tapped.
  final VoidCallback? onClear;

  String get _formatted {
    if (amount.isEmpty) return '0';
    final value = int.tryParse(amount);
    if (value == null) return amount;
    // Format with comma separators
    final str = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Currency badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¥',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.survival,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'JPY',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.survival,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.expand_more,
                  size: 20,
                  color: AppColors.survival,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Amount value
          Text(
            _formatted,
            style: AppTextStyles.amountLarge.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          // Clear button
          if (amount.isNotEmpty && onClear != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E8EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
