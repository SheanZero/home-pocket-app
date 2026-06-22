import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Quick task 260622-nhs / 260623-0cj: the 「语音记录」 voice-record key that sits
/// ABOVE the SmartKeyboard on the single-page entry screen.
///
/// 260623-0cj: redesigned from a flush full-width strip into a centered,
/// edge-inset **capsule** (椭圆/Stadium) that floats on the screen background
/// above the keypad card — it no longer touches the left/right edges. The
/// capsule is the tap target (the surrounding inset area is not); a single
/// [onTap] raises the inline voice panel (no press-and-hold).
///
/// Stateless about recording — the host owns the session state. The mic is a
/// line-style [Icons.mic_none] (not filled). All colors via [AppPalette]; the
/// label via [S].
class VoiceRecordBar extends StatelessWidget {
  const VoiceRecordBar({super.key, required this.onTap});

  final VoidCallback onTap;

  /// 260623-0cj: approved A/B midpoint width for the voice capsule.
  static const double _pillWidth = 200.0;
  static const double _pillHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    return Container(
      key: const ValueKey('voice-record-bar'),
      // Vertical breathing room so the capsule floats clear of the form above
      // and the keypad card below (不顶边).
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Material(
        color: palette.joyLight,
        elevation: 1,
        shadowColor: palette.joyText.withValues(alpha: 0.25),
        shape: StadiumBorder(
          side: BorderSide(color: palette.joyText.withValues(alpha: 0.18)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            key: const ValueKey('voice-record-pill'),
            width: _pillWidth,
            height: _pillHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_none, size: 18, color: palette.joyText),
                const SizedBox(width: 8),
                Text(
                  l10n.voiceRecordBar,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: palette.joyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
