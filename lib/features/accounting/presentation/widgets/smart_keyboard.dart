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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const ValueKey('smart_keyboard_root'),
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.card : AppColors.card,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColorsDark.borderDefault
                : AppColors.borderDefault,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDigitRow(context, ['1', '2', '3']),
          const SizedBox(height: 8),
          _buildDigitRow(context, ['4', '5', '6']),
          const SizedBox(height: 8),
          _buildDigitRow(context, ['7', '8', '9']),
          const SizedBox(height: 8),
          _buildExtraRow(context),
          const SizedBox(height: 8),
          _buildActionRow(context),
        ],
      ),
    );
  }

  Widget _buildDigitRow(BuildContext context, List<String> keys) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: keys
          .map(
            (key) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DigitKey(
                  label: key,
                  onTap: () => onDigit(key),
                  isDark: isDark,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Row 4: 00, 0, .
  Widget _buildExtraRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DigitKey(
              label: '00',
              onTap: () => onDoubleZero?.call(),
              isDark: isDark,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DigitKey(
              label: '0',
              onTap: () => onDigit('0'),
              isDark: isDark,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DigitKey(
              label: '.',
              onTap: () => onDot?.call(),
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  /// Action Row: ⌫ (delete), ¥JPY (currency), Next — all equal width
  Widget _buildActionRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Delete key
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ActionKey(
              color: isDark
                  ? AppColorsDark.backgroundMuted
                  : AppColors.backgroundMuted,
              height: 50,
              onTap: onDelete,
              child: Icon(
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
              isDark: isDark,
            ),
          ),
        ),
        // Next key
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _GradientKey(label: nextLabel, onTap: onNext),
          ),
        ),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted,
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
              color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
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
    required this.isDark,
  });

  final String symbol;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('smart_keyboard_currency_key'),
      height: 50,
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundMuted
            : AppColors.backgroundMuted,
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
              colors: [
                AppColors.actionGradientStart,
                AppColors.actionGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.actionShadow,
                blurRadius: 14,
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
