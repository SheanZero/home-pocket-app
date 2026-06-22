import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Quick task 260622-nhs R2: full-width 「语音记录」 voice-record bar that sits
/// ABOVE the SmartKeyboard on the single-page entry screen (R1 placed it below
/// the keypad, in the iOS up-swipe gesture zone — moved above + the screen adds
/// a bottom SafeArea inset so the keypad clears the home indicator).
///
/// Stateless about recording — the host owns the session state. A single
/// [onTap] raises the auto-fill listening modal (no press-and-hold). The mic is
/// a line-style [Icons.mic_none] (not filled). All colors via [AppPalette]; the
/// label via [S].
class VoiceRecordBar extends StatelessWidget {
  const VoiceRecordBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    return GestureDetector(
      key: const ValueKey('voice-record-bar'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: palette.joyLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.joy),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none, size: 20, color: palette.joyText),
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
    );
  }
}
