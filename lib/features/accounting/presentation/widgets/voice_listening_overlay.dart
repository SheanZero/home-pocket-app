import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import 'voice_waveform.dart';

/// Quick task 260622-nhs R2: auto-fill listening modal. Tap-anywhere on the
/// modal body OR the scrim = EXIT (stop + close, keep the already-filled
/// content, stay on the page — D-2 no auto-save). The ONLY button is
/// 「重置·恢复账目」 which clears the transcript and restores the form to the
/// pre-speech snapshot; its tap does NOT bubble to the exit handler.
///
/// Replaces R1's `VoiceListeningOverlay` (which had 完成/取消 and a release
/// hint). Content top→bottom: grab handle → 「正在聆听…」 (pulsing recording-red
/// dot) → live transcript → 16-bar [VoiceWaveform] → recording-red rounded mic
/// (line-style [Icons.mic_none], white) → 「轻点空白处退出」 hint (directly below
/// the mic) → single line-style reset button.
///
/// All text via [S]; all colors via [AppPalette] (zero raw hex). Stateless —
/// the host passes the live [transcript] / [soundLevel] and the [onExit] /
/// [onReset] handlers from the session mixin.
class VoiceListeningModal extends StatelessWidget {
  const VoiceListeningModal({
    super.key,
    required this.transcript,
    required this.soundLevel,
    required this.onExit,
    required this.onReset,
  });

  /// Live transcript (partial-or-final) rendered under the listening title.
  final String transcript;

  /// Normalized 0.0–1.0 sound level driving the waveform bars.
  final double soundLevel;

  /// Tap-anywhere exit: stop listening + close, keep the filled content.
  final VoidCallback onExit;

  /// Reset button: clear the transcript and restore the pre-speech snapshot.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    return Positioned.fill(
      key: const ValueKey('voice-listening-modal'),
      child: Stack(
        children: [
          // Scrim — tap to exit.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExit,
              child: ColoredBox(
                color: palette.textPrimary.withValues(alpha: 0.34),
              ),
            ),
          ),
          // Bottom sheet — tap anywhere (except the reset button) to exit.
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExit,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.actionShadow,
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                child: SafeArea(
                  top: false,
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
                      const SizedBox(height: 12),

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
                      const SizedBox(height: 12),

                      // Live transcript.
                      SizedBox(
                        key: const ValueKey('voice-modal-transcript'),
                        height: 24,
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
                      const SizedBox(height: 12),

                      VoiceWaveform(
                        soundLevel: soundLevel,
                        isActive: true,
                        color: palette.daily,
                      ),
                      const SizedBox(height: 12),

                      // Recording-red rounded mic (line-style glyph).
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
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
                        child: const Icon(
                          Icons.mic_none,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tap-to-exit hint directly below the mic.
                      Text(
                        l10n.voiceTapToExit,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: palette.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Single reset button — restores the pre-speech snapshot.
                      // Its tap must NOT bubble to the modal's exit handler.
                      GestureDetector(
                        key: const ValueKey('voice-modal-reset'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onReset,
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          decoration: BoxDecoration(
                            color: palette.backgroundMuted,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: palette.borderDefault),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.restore,
                                size: 18,
                                color: palette.textSecondary,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                l10n.voiceResetRestore,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: palette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.voiceResetRestoreSub,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recording-red dot that pulses opacity 1.0 → 0.3 → 1.0 (mock `@keyframes
/// pulse`).
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
