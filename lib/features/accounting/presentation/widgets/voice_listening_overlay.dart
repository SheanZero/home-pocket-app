import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import 'voice_waveform.dart';

/// Quick task 260622-nhs (D-1): listening overlay shown WHILE the user holds the
/// [HoldToTalkBar]. Scrim + rounded-top sheet with: grab handle, 「正在聆听…」
/// (pulsing recording-red dot), the live transcript, a 16-bar [VoiceWaveform],
/// a recording-red rounded mic, and the 「松开后自动填入表单」 release hint.
///
/// V2 mock `.ptt` block. All text via [S]; all colors via [AppPalette]
/// (zero raw hex). Stateless — the host passes the live [transcript] and
/// [soundLevel] from the session mixin.
class VoiceListeningOverlay extends StatelessWidget {
  const VoiceListeningOverlay({
    super.key,
    required this.transcript,
    required this.soundLevel,
  });

  /// Live transcript (partial-or-final) rendered under the listening title.
  final String transcript;

  /// Normalized 0.0–1.0 sound level driving the waveform bars.
  final double soundLevel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    return Positioned.fill(
      key: const ValueKey('voice-listening-overlay'),
      child: Stack(
        children: [
          // Scrim.
          ModalBarrier(
            color: palette.textPrimary.withValues(alpha: 0.30),
            dismissible: false,
          ),
          // Bottom sheet.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.actionShadow,
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grab handle.
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.borderDefault,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 11),

                  // Listening title with a pulsing recording-red dot.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(color: palette.recordingGradientStart),
                      const SizedBox(width: 6),
                      Text(
                        l10n.listeningTitle,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: palette.recordingGradientStart,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),

                  // Live transcript.
                  SizedBox(
                    key: const ValueKey('voice-overlay-transcript'),
                    height: 22,
                    child: Center(
                      child: Text(
                        transcript,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),

                  VoiceWaveform(
                    soundLevel: soundLevel,
                    isActive: true,
                    color: palette.daily,
                  ),
                  const SizedBox(height: 11),

                  // Recording-red rounded mic.
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.recordingGradientStart,
                          palette.recordingGradientEnd,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.actionShadow,
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 11),

                  Text(
                    l10n.releaseToFill,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recording-red dot that pulses opacity 1.0 → 0.3 → 1.0 (V2 `@keyframes pulse`).
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.3).animate(_controller),
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
