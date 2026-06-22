import 'package:flutter/gestures.dart' show LongPressGestureRecognizer;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Quick task 260622-nhs (D-1): full-width 「按住说话」 push-to-talk bar that sits
/// below the SmartKeyboard on the single-page entry screen.
///
/// Stateless about recording — the host owns the session state. Press-and-hold
/// fires [onHoldStart]; release fires [onHoldEnd]; a slide-off fires
/// [onHoldCancel]. Uses a [LongPressGestureRecognizer] with `duration:
/// Duration.zero` (the same wiring as the legacy voice mic button) so press-down
/// begins immediately and the hit area is the whole bar.
///
/// V2 visual: 樱粉浅底 (`palette.joyLight`) + `joyText` label + a small joy dot +
/// mic glyph. All colors via [AppPalette]; the label via [S].
class HoldToTalkBar extends StatelessWidget {
  const HoldToTalkBar({
    super.key,
    required this.onHoldStart,
    required this.onHoldEnd,
    this.onHoldCancel,
  });

  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback? onHoldCancel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: Duration.zero,
                debugOwner: this,
              ),
              (LongPressGestureRecognizer instance) {
                instance
                  ..onLongPressStart = ((_) => onHoldStart())
                  ..onLongPressEnd = ((_) => onHoldEnd())
                  ..onLongPressCancel = (() => onHoldCancel?.call());
              },
            ),
      },
      child: Container(
        key: const ValueKey('hold-to-talk-bar'),
        height: 48,
        decoration: BoxDecoration(
          color: palette.joyLight,
          border: Border(
            top: BorderSide(color: palette.borderDivider),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.joy,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.mic, size: 18, color: palette.joyText),
            const SizedBox(width: 6),
            Text(
              l10n.holdToTalkBar,
              style: AppTextStyles.labelMedium.copyWith(
                color: palette.joyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
