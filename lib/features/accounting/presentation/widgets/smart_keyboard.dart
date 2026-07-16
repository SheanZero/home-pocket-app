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
    this.onCurrencyTap,
    this.showTopBorder = true,
    this.useV16Layout = false,
    this.isActionEnabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onNext;
  final VoidCallback? onDoubleZero;
  final VoidCallback? onDot;

  /// 260623-0cj R2: when false, the keypad omits its own top border. Used by the
  /// single-page entry screen where the white [VoiceRecordBar] above already
  /// carries the assembly's top border, so the voice key + keypad read as ONE
  /// unified white surface (一体). Defaults to true so standalone callers
  /// (edit / ocr-review / amount sheet) keep their top edge.
  final bool showTopBorder;

  /// Opt-in geometry and green primary action from the v16 unified-entry mockup.
  /// Legacy callers keep their established responsive sizing and pink action.
  final bool useV16Layout;

  final bool isActionEnabled;

  /// CURR-01: tap handler for the currency key. When non-null the currency cell
  /// becomes a tappable Material+InkWell that opens the currency selector
  /// (host-owned, 42-08). When null the cell stays display-only (legacy
  /// behavior) so callers that don't support currency switching are unaffected.
  final VoidCallback? onCurrencyTap;

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
    final keyHeight = useV16Layout
        ? 48.0
        : math.max(48.0, rawKeyHeight); // §Pitfall 1 NON-NEGOTIABLE
    final rowGap = useV16Layout ? 7.0 : 12.0;

    return Container(
      key: const ValueKey('smart_keyboard_root'),
      decoration: BoxDecoration(
        color: palette.card,
        border: showTopBorder
            ? Border(top: BorderSide(color: palette.borderDefault))
            : null,
      ),
      padding: useV16Layout
          ? const EdgeInsets.fromLTRB(10.5, 7, 10.5, 10)
          : const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDigitRow(context, ['1', '2', '3'], keyHeight, palette),
          SizedBox(height: rowGap), // D-07: v16 compacts this to 7 dp.
          _buildDigitRow(context, ['4', '5', '6'], keyHeight, palette),
          SizedBox(height: rowGap),
          _buildDigitRow(context, ['7', '8', '9'], keyHeight, palette),
          SizedBox(height: rowGap),
          _buildExtraRow(context, keyHeight, palette),
          SizedBox(height: rowGap),
          _buildActionRow(
            context,
            palette,
            useV16Layout ? 48 : _actionRowHeight,
          ),
        ],
      ),
    );
  }

  /// 260623-0cj R2: the action (bottom) row is a fixed 44 dp — shorter than the
  /// digit rows (keyHeight ≥ 48 dp) and equal to the voice key's 44 dp height
  /// (HIG 44 pt touch target). User-directed: 「按键高度和最下排按键高度都改成44dp」.
  static const double _actionRowHeight = 44.0;

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
                padding: EdgeInsets.symmetric(
                  horizontal: useV16Layout ? 3.5 : 3,
                ),
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
  Widget _buildExtraRow(
    BuildContext context,
    double keyHeight,
    AppPalette palette,
  ) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: EdgeInsets.symmetric(horizontal: useV16Layout ? 3.5 : 3),
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
            padding: EdgeInsets.symmetric(horizontal: useV16Layout ? 3.5 : 3),
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
            padding: EdgeInsets.symmetric(horizontal: useV16Layout ? 3.5 : 3),
            // D-06: dot key is gated on currency minor unit. When the host
            // passes onDot == null (0-decimal currency, e.g. JPY/KRW) we render
            // a disabled blank tile of the SAME equal width + 48dp floor so the
            // row keeps its 3-cell structure and no key shifts (RESEARCH Q3 —
            // collapsing the cell would shift keys → mis-taps + golden churn).
            // For decimal currencies the dot key behaves exactly as before
            // (CURR-04: JPY path byte-identical).
            child: onDot == null
                ? _DisabledKey(
                    key: const ValueKey('smart_keyboard_dot_disabled'),
                    palette: palette,
                    height: keyHeight,
                    showGlyph: useV16Layout,
                  )
                : _DigitKey(
                    label: '.',
                    onTap: onDot!,
                    palette: palette,
                    height: keyHeight,
                  ),
          ),
        ),
      ],
    );
  }

  /// Action Row: backspace, currency label, Save — all equal width (D-08).
  /// 260623-0cj: [rowHeight] is the shortened bottom-row height (keyHeight ×
  /// 0.77, floored at 40 dp) — all three cells share it so they stay equal
  /// height to each other (D-08) while sitting lower than the digit rows.
  Widget _buildActionRow(
    BuildContext context,
    AppPalette palette,
    double rowHeight,
  ) {
    return Row(
      children: [
        // Delete key
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: EdgeInsets.symmetric(horizontal: useV16Layout ? 3.5 : 3),
            child: _ActionKey(
              color: palette.backgroundMuted,
              height: rowHeight, // 260623-0cj: shortened bottom-row height
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
            padding: EdgeInsets.symmetric(horizontal: useV16Layout ? 3.5 : 3),
            child: _CurrencyKey(
              symbol: currencySymbol,
              label: currencyLabel,
              palette: palette,
              height: rowHeight, // 260623-0cj: shortened bottom-row height
              onTap: onCurrencyTap,
            ),
          ),
        ),
        // Save key (renamed from Next — see RESEARCH §Pitfall 6)
        Expanded(
          child: Padding(
            // P19 D-07: 3 dp per side -> 6 dp total visible gap between adjacent keys.
            padding: EdgeInsets.symmetric(horizontal: useV16Layout ? 3.5 : 3),
            child: _GradientKey(
              label: actionLabel,
              onTap: isActionEnabled ? onNext : null,
              palette: palette,
              height: rowHeight, // 260623-0cj: shortened bottom-row height
              useV16Layout: useV16Layout,
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

/// D-06: blank, non-interactive placeholder for the dot cell when the active
/// currency has 0 minor-unit decimals (JPY/KRW). Occupies the SAME equal width
/// and 48dp floor as a [_DigitKey] so the extra row keeps its 3-cell structure
/// — no key shifts (RESEARCH Q3). Renders no glyph and carries no tap handler,
/// so a "." cannot be entered for 0-decimal currencies.
class _DisabledKey extends StatelessWidget {
  const _DisabledKey({
    super.key,
    required this.palette,
    required this.height,
    this.showGlyph = false,
  });

  final AppPalette palette;
  final double height;
  final bool showGlyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Muted/transparent so it reads as a non-key gap, not a tappable key.
        color: palette.backgroundMuted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: showGlyph
          ? Text(
              '.',
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 20,
                color: palette.textTertiary.withValues(alpha: 0.45),
              ),
            )
          : null,
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
    this.onTap,
  });

  final String symbol;
  final String label;
  final AppPalette palette;
  final double height;

  /// CURR-01: when non-null the cell becomes a tappable Material+InkWell
  /// (mirroring [_DigitKey]/[_ActionKey]) that opens the currency selector.
  /// When null the cell stays display-only (legacy behavior).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: height,
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

    return Material(
      key: const ValueKey('smart_keyboard_currency_key'),
      color: palette.backgroundMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
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
    this.useV16Layout = false,
  });

  final String label;
  final VoidCallback? onTap;
  final AppPalette palette;
  final double height;
  final bool useV16Layout;

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
            color: useV16Layout
                ? palette.accentPrimary.withValues(
                    alpha: onTap == null ? 0.45 : 1,
                  )
                : null,
            gradient: useV16Layout
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.fabGradientStart, palette.fabGradientEnd],
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
