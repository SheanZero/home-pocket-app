// lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
//
// Phase 23 D-10: extracts _onStatus + _onError from VoiceInputScreen so the
// screen file drops under the 800-line CLAUDE.md cap. The State class must
// supply the abstract members listed below. The mixin provides handler bodies
// that drive setState through them. D-05's intra-session guard is added in
// Plan 05 — this plan only stages the surface (intraSessionThreshold constant
// + lastMergerFinalAt abstract getter).

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../widgets/voice_error_toast.dart';

/// Phase 23 D-10: mixin that bundles the G-01 (onStatus) and G-02 (onError)
/// speech-recognizer callback bodies extracted from [VoiceInputScreen].
///
/// The State class must supply the abstract contract members declared below.
/// The mixin writes state only through those abstract setters — it never
/// accesses private fields of the hosting class directly (Pitfall 2
/// single-writer rule: [isInitialized] is the one setter wrapping setState).
mixin VoiceRecognitionEventHandlerMixin<W extends StatefulWidget>
    on State<W> {
  // ── Abstract contract — State class implements these ──────────────────────

  /// Whether the recognizer is currently in a recording session.
  bool get isRecording;
  set isRecording(bool value);

  /// Most recent finger-down DateTime from _onLongPressStart, or null when
  /// no press is in flight. The mixin clears this to enforce idempotency
  /// when status-driven commit fires.
  DateTime? get pressStart;
  set pressStart(DateTime? value);

  /// Initialization flag. Mixin flips to false on permanent error.
  /// SINGLE WRITER (RESEARCH Pitfall 2): this setter wraps setState so the
  /// hosting State class must not also write _isInitialized directly in paths
  /// that pass through the mixin — only `_initSpeechService`'s own setState is
  /// permitted as a second write site (different code path, cold-start only).
  set isInitialized(bool value);

  /// Sound-level state — cleared on session end.
  set soundLevel(double value);

  /// Last-final-result timestamp from the chunk merger. Used by Phase 23
  /// D-05 intra-session guard. Null when no chunks have been seen yet.
  ///
  /// Plan 05 will compare DateTime.now().difference(lastMergerFinalAt)
  /// against [intraSessionThreshold]. This plan only declares the surface.
  DateTime? get lastMergerFinalAt;

  /// Commit driver — delegates to the screen's _stopRecordingAndCommit.
  /// The mixin never inlines commit logic (CONTEXT.md `specifics` section:
  /// "Commit-path is OFF LIMITS" inviolable).
  Future<void> stopRecordingAndCommit();

  // ── D-05 threshold — exposed for tunability ───────────────────────────────

  /// Intra-session `notListening` heuristic — Phase 23 D-05 / RESEARCH §D-19.
  ///
  /// 800 ms ≈ 3× typical iOS partial-result cadence (~100-300 ms/partial).
  /// Plan 05 uses this constant to decide whether a `notListening` status
  /// during an active press is intra-session (recognizer self-restart) or
  /// terminal (user pause → commit). Declared here so Plan 05 can reference
  /// it without importing a separate constants file.
  static const Duration intraSessionThreshold = Duration(milliseconds: 800);

  // ── G-01: status callback ─────────────────────────────────────────────────

  /// Speech-recognizer status callback — preserves Phase 22 G-01 verbatim.
  ///
  /// When the platform recognizer self-terminates (status 'done' or
  /// 'notListening' — triggered by 30s listenFor expiry, 3s pauseFor
  /// mid-press, or platform mic interruption) while the user is still
  /// holding the mic ([pressStart] != null), drives the SAME commit path
  /// as _onLongPressEnd. Without this branch, _onLongPressEnd on the
  /// eventual finger release short-circuits at its `!isRecording` guard
  /// and silently drops the transcript.
  ///
  /// NOTE: D-05 intra-session guard is NOT added in this plan — Plan 05
  /// adds it on top of this surface. Only [lastMergerFinalAt] and
  /// [intraSessionThreshold] are staged here as the dependency surface.
  void onStatus(String status) {
    if (!mounted) return;
    if (status != 'done' && status != 'notListening') return;
    if (!isRecording) return;

    if (pressStart != null) {
      pressStart = null;
      unawaited(stopRecordingAndCommit());
      return;
    }
    setState(() {
      isRecording = false;
      soundLevel = 0.0;
    });
  }

  // ── G-02: error callback ──────────────────────────────────────────────────

  /// Speech-recognizer error callback — preserves Phase 22 G-02 verbatim.
  ///
  /// Surfaces the error to the user (never silently swallows — CLAUDE.md
  /// "provide user-friendly error messages in UI-facing code"). On
  /// permanent == true, flips [isInitialized] = false so the existing
  /// _onLongPressStart guard short-circuits new presses until the
  /// recognizer is re-initialized.
  void onError(String errorMsg, bool permanent) {
    if (!mounted) return;
    setState(() {
      isRecording = false;
      soundLevel = 0.0;
      if (permanent) isInitialized = false;
    });
    showVoiceRecognitionErrorToast(context, errorMsg);
  }
}
