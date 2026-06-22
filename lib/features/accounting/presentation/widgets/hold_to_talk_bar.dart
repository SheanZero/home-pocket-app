import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Quick task 260622-nhs: full-width 「语音记录」 voice-record strip that sits
/// flush ABOVE the SmartKeyboard on the single-page entry screen.
///
/// R3 (BUG 1): slimmed from a 52dp rounded card to a ~38dp strip with NO outer
/// margin so it reads as the keypad's top strip rather than a floating card. The
/// background is softened to a light joy tint with a single bottom hairline (it
/// shares the keypad container's full-width footprint and the keypad's own top
/// border sits directly below this strip).
///
/// Stateless about recording — the host owns the session state. A single
/// [onTap] raises the inline voice panel (no press-and-hold). The mic is a
/// line-style [Icons.mic_none] (not filled). All colors via [AppPalette]; the
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
        height: 38,
        decoration: BoxDecoration(
          color: palette.joyLight,
          border: Border(
            bottom: BorderSide(color: palette.borderDefault),
          ),
        ),
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
    );
  }
}
