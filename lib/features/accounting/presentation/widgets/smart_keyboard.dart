import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Custom numpad with 4 digit rows + action row for transaction entry.
///
/// Layout (matches Pencil design 1XUUv):
///   Row 1: 1, 2, 3
///   Row 2: 4, 5, 6
///   Row 3: 7, 8, 9
///   Row 4: 00, 0, .
///   Action: ⌫, ¥JPY, Next  (equal width)
class SmartKeyboard extends StatelessWidget {
  const SmartKeyboard({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onNext,
    this.onDoubleZero,
    this.onDot,
    this.nextLabel = 'Next',
    this.currencyLabel = 'JPY',
    this.currencySymbol = '¥',
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onNext;
  final VoidCallback? onDoubleZero;
  final VoidCallback? onDot;
  final String nextLabel;
  final String currencyLabel;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E8EF)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDigitRow(['1', '2', '3']),
          const SizedBox(height: 8),
          _buildDigitRow(['4', '5', '6']),
          const SizedBox(height: 8),
          _buildDigitRow(['7', '8', '9']),
          const SizedBox(height: 8),
          _buildExtraRow(),
          const SizedBox(height: 8),
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildDigitRow(List<String> keys) {
    return Row(
      children: keys
          .map((key) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _DigitKey(
                    label: key,
                    onTap: () => onDigit(key),
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// Row 4: 00, 0, .
  Widget _buildExtraRow() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DigitKey(
              label: '00',
              onTap: () => onDoubleZero?.call(),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DigitKey(
              label: '0',
              onTap: () => onDigit('0'),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DigitKey(
              label: '.',
              onTap: () => onDot?.call(),
            ),
          ),
        ),
      ],
    );
  }

  /// Action Row: ⌫ (delete), ¥JPY (currency), Next — all equal width
  Widget _buildActionRow() {
    return Row(
      children: [
        // Delete key
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ActionKey(
              color: const Color(0xFFEAF2F8),
              height: 50,
              onTap: onDelete,
              child: const Icon(
                Icons.backspace_outlined,
                color: AppColors.survival,
                size: 22,
              ),
            ),
          ),
        ),
        // Currency label (display only, no tap action)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CurrencyKey(
              symbol: currencySymbol,
              label: currencyLabel,
            ),
          ),
        ),
        // Next key
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _GradientKey(
              label: nextLabel,
              onTap: onNext,
            ),
          ),
        ),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F9FD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.amountLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.child,
    required this.color,
    required this.onTap,
    this.height = 48,
  });

  final Widget child;
  final Color color;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _CurrencyKey extends StatelessWidget {
  const _CurrencyKey({
    required this.symbol,
    required this.label,
  });

  final String symbol;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F8),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: AppTextStyles.amountMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.survival,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.survival,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientKey extends StatelessWidget {
  const _GradientKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.fabGradientStart, AppColors.fabGradientEnd],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x405A9CC8),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
