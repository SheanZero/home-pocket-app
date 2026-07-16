import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

enum AmountDisplayLayout { legacy, v16 }

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
    this.layout = AmountDisplayLayout.legacy,
    this.onCurrencyTap,
  });

  /// Raw amount string (digits only, e.g. "3280").
  final String amount;

  /// Called when the clear button is tapped.
  final VoidCallback? onClear;

  /// Currency symbol (e.g. "¥", "$", "€").
  final String currencySymbol;

  /// Currency code label (e.g. "JPY", "USD", "CNY").
  final String currencyLabel;

  /// v16 places the amount on the left and the compact currency action on the
  /// right. The legacy layout stays the default for OCR/voice review surfaces.
  final AmountDisplayLayout layout;

  /// Optional currency selector action used by the unified-entry header.
  final VoidCallback? onCurrencyTap;

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
    final palette = context.palette;

    if (layout == AmountDisplayLayout.v16) {
      return SizedBox(
        height: 88,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(
                currencySymbol,
                style: AppTextStyles.amountHero.copyWith(
                  color: palette.textPrimary,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatted,
                    style: AppTextStyles.amountHero.copyWith(
                      color: palette.textPrimary,
                      fontSize: 44,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              if (amount.isNotEmpty && onClear != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  key: const ValueKey('amount_clear_button'),
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: palette.textSecondary,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Material(
                key: const ValueKey('amount_currency_badge'),
                color: palette.dailyLight,
                shape: const StadiumBorder(),
                child: InkWell(
                  onTap: onCurrencyTap,
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    width: 67,
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currencyLabel,
                          style: AppTextStyles.label.copyWith(
                            color: palette.dailyText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (onCurrencyTap != null) ...[
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: palette.dailyText,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            key: const ValueKey('amount_currency_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: palette.dailyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencySymbol,
                  style: AppTextStyles.amountMedium.copyWith(
                    color: palette.dailyText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currencyLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: palette.dailyText,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
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
                  color: palette.textPrimary,
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
                  color: palette.backgroundMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
