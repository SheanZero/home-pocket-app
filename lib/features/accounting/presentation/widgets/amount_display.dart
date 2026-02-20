import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Displays the current amount with currency label and clear button.
///
/// Shows "¥ JPY" as plain text on the left, the formatted amount in the center,
/// and an "x" clear button on the right when amount is non-empty.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amount,
    this.onClear,
    this.currencySymbol = '¥',
    this.currencyLabel = 'JPY',
  });

  /// Raw amount string (digits only, e.g. "3280").
  final String amount;

  /// Called when the clear button is tapped.
  final VoidCallback? onClear;

  /// Currency symbol (e.g. "¥", "$", "€").
  final String currencySymbol;

  /// Currency code label (e.g. "JPY", "USD", "CNY").
  final String currencyLabel;

  String get _formatted {
    if (amount.isEmpty) return '0';

    // Split integer and decimal parts
    final parts = amount.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final value = int.tryParse(intPart);
    if (value == null) return amount;

    // Format integer part with comma separators
    final str = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }

    // Append decimal part if present
    if (parts.length > 1) {
      buffer.write('.');
      buffer.write(parts[1]);
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Currency label (plain text)
          Text(
            '$currencySymbol $currencyLabel',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.survival,
            ),
          ),
          const SizedBox(width: 12),
          // Amount value — shrinks to fit when digits exceed 7
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _formatted,
                style: AppTextStyles.amountLarge.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
              ),
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
