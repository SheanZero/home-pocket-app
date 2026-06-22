import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../screens/voice_ptt_session_mixin.dart' show PttListenStatus;
import 'voice_waveform.dart';

/// Quick task 260622-nhs R3 (BUG 3): inline auto-fill voice panel that REPLACES
/// the keypad in place — NO scrim, NO overlay, NO bottom-sheet chrome. The host
/// renders it in the same bottom slot the keypad normally occupies, so the form
/// above stays fully visible (un-dimmed) and keeps auto-filling live while the
/// user speaks.
///
/// Tap the panel's blank area = EXIT (stop + dismiss, keep the already-filled
/// content, stay on the page — D-2 no auto-save).
///
/// 260622-nhs R7: the central square is a DUAL-STATE button driven by [status]
/// (the bottom 「重置·恢复账目」 button is GONE):
///   - listening/processing → grey square + line mic ([Icons.mic_none]); PASSIVE
///     (no onTap — a tap on it bubbles to the panel's exit handler).
///   - stopped → red (recording-gradient) square + reset icon ([Icons.restore],
///     white); TAPPABLE → [onReset] (restore the pre-speech snapshot + re-record).
/// The tap does NOT bubble to the exit handler when stopped.
///
/// Both states are EQUAL HEIGHT: the stopped-only 「点击重置重新录入」 hint keeps a
/// reserved (invisible, maintained) placeholder while listening so 「轻点空白处
/// 退出」 aligns at the same vertical position in both states (no jump on
/// transition).
///
/// Replaces R2's `VoiceListeningModal` (a Positioned.fill scrim + rounded
/// bottom-sheet). Content top→bottom: status title (pulsing status dot) → live
/// transcript → 16-bar [VoiceWaveform] → dual-state square → 「点击重置重新录入」
/// hint (reserved while listening) → 「轻点空白处退出」 hint.
///
/// All text via [S]; all colors via [AppPalette] (zero raw hex). Stateless —
/// the host passes the live [transcript] / [soundLevel] and the [onExit] /
/// [onReset] handlers from the session mixin.
class VoiceRecordPanel extends StatelessWidget {
  const VoiceRecordPanel({
    super.key,
    required this.transcript,
    required this.soundLevel,
    required this.onExit,
    required this.onReset,
    this.status = PttListenStatus.listening,
  });

  /// Live transcript (partial-or-final) rendered under the listening title.
  final String transcript;

  /// Normalized 0.0–1.0 sound level driving the waveform bars.
  final double soundLevel;

  /// 260622-nhs R4 (BUG C): the live recognizer status driving the panel title
  /// + pulse-dot colour (listening → red 「正在聆听…」, processing → amber
  /// 「正在解析…」, stopped → grey 「停止聆听」). Defaults to listening so callers
  /// that don't yet thread status see the prior behaviour.
  final PttListenStatus status;

  /// Tap-on-blank-area exit: stop listening + dismiss, keep the filled content.
  final VoidCallback onExit;

  /// 260622-nhs R7: triggered by tapping the RED central square in the stopped
  /// state — clears the transcript, restores the pre-speech snapshot, and
  /// re-arms a fresh listening session. Passive while listening (no trigger).
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    // 260622-nhs R4 (BUG C): title + pulse-dot colour reflect the live status.
    final (statusTitle, statusColor) = switch (status) {
      PttListenStatus.listening => (
          l10n.listeningTitle,
          palette.recordingGradientStart,
        ),
      PttListenStatus.processing => (
          l10n.voiceStatusProcessing,
          palette.warning,
        ),
      PttListenStatus.stopped => (
          l10n.voiceStatusStopped,
          palette.textTertiary,
        ),
    };

    // 260622-nhs R6 (BUG 1): in the one-shot model the recognizer stops after a
    // single listen. When stopped the mic drops to a non-recording (grey, no
    // pulse) look and a 「点击重置重新录入」 hint tells the user to tap 重置 to
    // record again. listening/processing keep the recording-red pulsing mic.
    final isStopped = status == PttListenStatus.stopped;

    // Inline panel occupying the keypad footprint. Tap the blank area to exit;
    // the reset button (below) has its own non-bubbling onTap.
    return GestureDetector(
      key: const ValueKey('voice-record-panel'),
      behavior: HitTestBehavior.opaque,
      onTap: onExit,
      child: Container(
        width: double.infinity,
        // Match the keypad block's top border so the swap is seamless — the
        // form above keeps its same visible footprint (no reflow/jump).
        decoration: BoxDecoration(
          color: palette.card,
          border: Border(
            top: BorderSide(color: palette.borderDefault),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status title with a pulsing status-coloured dot (BUG C).
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stopped: a static dot (no pulse) — the recognizer is idle.
                _PulsingDot(color: statusColor, pulsing: !isStopped),
                const SizedBox(width: 6),
                Text(
                  statusTitle,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live transcript.
            SizedBox(
              key: const ValueKey('voice-panel-transcript'),
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

            // 260622-nhs R7: dual-state central square (~74dp, radius ~22).
            //  - listening/processing → grey ([backgroundMuted]) + line mic
            //    ([Icons.mic_none], [textTertiary]); PASSIVE (no onTap, so a tap
            //    bubbles to the panel's exit handler).
            //  - stopped → red (recording-gradient) + reset icon
            //    ([Icons.restore], white); TAPPABLE → [onReset] (re-record). Its
            //    tap must NOT bubble to the exit handler.
            _CentralSquare(
              isStopped: isStopped,
              palette: palette,
              onReset: onReset,
            ),
            const SizedBox(height: 8),

            // 260622-nhs R7: the stopped-only 「点击重置重新录入」 hint keeps a
            // RESERVED placeholder while listening (maintainSize) so the panel
            // height — and the 「轻点空白处退出」 below — is identical in both
            // states (no jump on transition).
            Visibility(
              visible: isStopped,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.voiceTapResetToRerecord,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Tap-to-exit hint — always present, aligned in both states.
            Text(
              l10n.voiceTapToExit,
              style: AppTextStyles.bodySmall.copyWith(
                color: palette.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 260622-nhs R7: the dual-state central square. Stateless visual: grey/mic when
/// listening (passive — taps bubble up to the panel exit) and red/reset when
/// stopped (a tappable [GestureDetector] wired to [onReset] whose tap does NOT
/// bubble to the panel exit handler).
class _CentralSquare extends StatelessWidget {
  const _CentralSquare({
    required this.isStopped,
    required this.palette,
    required this.onReset,
  });

  final bool isStopped;
  final AppPalette palette;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final square = Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // Stopped → red recording gradient; listening → flat grey (muted).
        color: isStopped ? null : palette.backgroundMuted,
        gradient: isStopped
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.recordingGradientStart,
                  palette.recordingGradientEnd,
                ],
              )
            : null,
        border: isStopped ? null : Border.all(color: palette.borderDefault),
        boxShadow: isStopped
            ? [
                BoxShadow(
                  color: palette.actionShadow,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(
        // Stopped → reset (re-record) icon; listening → passive line mic.
        isStopped ? Icons.restore : Icons.mic_none,
        color: isStopped ? Colors.white : palette.textTertiary,
        size: 32,
      ),
    );

    // Listening/processing: passive — no GestureDetector, so a tap on the grey
    // square falls through to the panel's exit handler.
    if (!isStopped) return square;

    // Stopped: tappable red square → onReset; must NOT bubble to exit.
    return GestureDetector(
      key: const ValueKey('voice-square-reset'),
      behavior: HitTestBehavior.opaque,
      onTap: onReset,
      child: square,
    );
  }
}

/// Recording-red dot that pulses opacity 1.0 → 0.3 → 1.0 (mock `@keyframes
/// pulse`). 260622-nhs R6 (BUG 1): when [pulsing] is false (stopped state) the
/// dot is static so the panel reads as idle, not actively listening.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, this.pulsing = true});
  final Color color;
  final bool pulsing;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

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
