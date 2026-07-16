import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// Presentational 9-grid numeric keypad (sketch 002 tone B "清爽极简").
///
/// A standard iOS-style passcode pad: rows `1 2 3 / 4 5 6 / 7 8 9` and a final
/// row of `(blank) 0 ⌫`. It is purely presentational — it emits [onDigit] and
/// [onBackspace] callbacks and holds NO lock state. The consuming screen
/// (Plans 09/10) owns the entered digits, instant-verify and error handling.
///
/// Theming is strictly via [AppPaletteContext.palette] (ADR-019 v1.6) and the
/// platform font stack; no hardcoded theme colours. Accessibility labels use
/// the digit value and the platform delete tooltip so the scan stays CJK-free.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  /// Fired with the tapped digit (0-9).
  final ValueChanged<int> onDigit;

  /// Fired when the backspace key is tapped.
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(context, const [1, 2, 3]),
        _row(context, const [4, 5, 6]),
        _row(context, const [7, 8, 9]),
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            _digitKey(context, 0),
            _backspaceKey(context),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, List<int> digits) {
    return Row(children: [for (final d in digits) _digitKey(context, d)]);
  }

  Widget _digitKey(BuildContext context, int digit) {
    final palette = context.palette;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Semantics(
          button: true,
          label: '$digit',
          excludeSemantics: true,
          child: Material(
            color: palette.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: palette.borderDefault),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onDigit(digit),
              child: SizedBox(
                height: 64,
                child: Center(
                  child: Text(
                    '$digit',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspaceKey(BuildContext context) {
    final palette = context.palette;
    final label = MaterialLocalizations.of(context).deleteButtonTooltip;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onBackspace,
              child: SizedBox(
                height: 64,
                child: Center(
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 26,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
