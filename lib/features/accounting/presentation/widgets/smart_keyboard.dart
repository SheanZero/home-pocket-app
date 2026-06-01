import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Custom numpad with 4 digit rows + action row for transaction entry.
///
/// Layout (matches Pencil design 1XUUv):
///   Row 1: 1, 2, 3
///   Row 2: 4, 5, 6
///   Row 3: 7, 8, 9
///   Row 4: 00, 0, .
///   Action: backspace, currency, Save (equal width)
///
/// Height is responsive: takes ~40% of screen height / 5 rows,
/// with a non-negotiable 48 dp floor (iOS 44pt / Material 48dp safety).
/// See RESEARCH §Pitfall 1 and D-06.
class SmartKeyboard extends StatelessWidget {
  const SmartKeyboard({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onNext,
    this.onDoubleZero,
    this.onDot,
    required this.actionLabel,
    this.currencyLabel = 'JPY',
    this.currencySymbol = '¥',
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onNext;
  final VoidCallback? onDoubleZero;
  final VoidCallback? onDot;

  /// Label for the action (Save/Record) button — renamed from nextLabel.
  ///
  /// Made required with no default so the string 'Next' cannot leak from
  /// a forgotten default. Callers must supply an ARB-resolved string
  /// (e.g. S.of(context).record). See RESEARCH §Pitfall 6.
  final String actionLabel;

  final String currencyLabel;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mq = MediaQuery.of(context);

    // D-06: responsive key height — ~40% of screen height distributed over 5
    // rows and 4 inter-row gaps (12 dp each). Floor at 48 dp per RESEARCH
    // §Pitfall 1 (iPhone SE 667pt gives ~36.96 dp without the clamp).
    final available = mq.size.height * 0.40 - mq.padding.bottom - (4 * 12.0);
    final rawKeyHeight = available / 5;
    final keyHeight = math.max(48.0, rawKeyHeight); // §Pitfall 1 NON-NEGOTIABLE

    return Container(
      key: const ValueKey('smart_keyboard_root'),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(
          top: BorderSide(
            color: palette.borderDefault,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDigitRow(context, ['1', '2', '3'], keyHeight, palette),
          const SizedBox(height: 12), // D-07: 8 -> 12 dp inter-row gap
          _buildDigitRow(context, ['4', '5', '6'], keyHeight, palette),
          const SizedBox(height: 12),
          _buildDigitRow(context, ['7', '8', '9'], keyHeight, palette),
          const SizedBox(height: 12),
          _buildExtraRow(context, keyHeight, palette),
          const SizedBox(height: 12),
          _buildActionRow(context, palette, keyHeight),
        ],
      ),
    );
  }

  Widget _buildDigitRow(
    BuildContext context,
    List<String> keys,
    double keyHeight,
    AppPalette palette,
  ) {
    return Row(
      children: keys
          .map(
            (key) => Expanded(
              child: Padding(
                // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _DigitKey(
                  label: key,
                  onTap: () => onDigit(key),
                  palette: palette,
                  height: keyHeight,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Row 4: 00, 0, .
  Widget _buildExtraRow(BuildContext context, double keyHeight, AppPalette palette) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _DigitKey(
              label: '00',
              onTap: () => onDoubleZero?.call(),
              palette: palette,
              height: keyHeight,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _DigitKey(
              label: '0',
              onTap: () => onDigit('0'),
              palette: palette,
              height: keyHeight,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _DigitKey(
              label: '.',
              onTap: () => onDot?.call(),
              palette: palette,
              height: keyHeight,
            ),
          ),
        ),
      ],
    );
  }

  /// Action Row: backspace, currency label, Save — all equal width (D-08)
  Widget _buildActionRow(
    BuildContext context,
    AppPalette palette,
    double keyHeight,
  ) {
    return Row(
      children: [
        // Delete key
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _ActionKey(
              color: palette.backgroundMuted,
              height: keyHeight, // D-08: same responsive height as digit keys
              onTap: onDelete,
              child: Icon(
                Icons.backspace_outlined,
                color: palette.daily,
                size: 22,
              ),
            ),
          ),
        ),
        // Currency label (display only, no tap action)
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _CurrencyKey(
              symbol: currencySymbol,
              label: currencyLabel,
              palette: palette,
              height: keyHeight, // D-08: same responsive height as digit keys
            ),
          ),
        ),
        // Save key (renamed from Next — see RESEARCH §Pitfall 6)
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _GradientKey(
              label: actionLabel,
              onTap: onNext,
              palette: palette,
              height: keyHeight, // D-08: same responsive height as digit keys
            ),
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
    required this.palette,
    required this.height,
  });

  final String label;
  final VoidCallback onTap;
  final AppPalette palette;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.backgroundMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              // UI-SPEC Typography: tabular figures so digit glyphs align like AmountDisplay
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.textPrimary,
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
    required this.height,
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
    required this.palette,
    required this.height,
  });

  final String symbol;
  final String label;
  final AppPalette palette;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('smart_keyboard_currency_key'),
      height: height,
      decoration: BoxDecoration(
        color: palette.backgroundMuted,
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
              color: palette.daily,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.daily,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientKey extends StatelessWidget {
  const _GradientKey({
    required this.label,
    required this.onTap,
    required this.palette,
    required this.height,
  });

  final String label;
  final VoidCallback onTap;
  final AppPalette palette;
  final double height;

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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.fabGradientStart,
                palette.fabGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: palette.actionShadow,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            height: height,
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
