import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../shared/constants/voice_tuning.dart';

/// Voice recognition service wrapping the speech_to_text plugin.
///
/// Provides a unified interface for speech recognition and handles
/// platform differences (sound level normalization).
class SpeechRecognitionService {
  SpeechRecognitionService({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _isInitialized = false;

  /// voice-consolidation P0-6 / offline Tier 0 (quick 260706-tm6): latched
  /// true when an on-device listen attempt failed and the session degraded to
  /// default (network-permitted) recognition. Scoped to this service instance
  /// — a fresh service (new session) retries on-device first.
  bool _onDeviceFallbackActive = false;

  /// Exposed for unit testing only. Do not read in production code.
  @visibleForTesting
  bool get onDeviceFallbackActive => _onDeviceFallbackActive;

  /// Captures the last [startListening] arguments so [restartListen] can
  /// replay them without the caller having to remember 5 params.
  ///
  /// Per Pitfall 3 (RESEARCH.md): the merger calls restartListen() between
  /// finalResult emissions. This field is the single source of truth for
  /// the cached config — there is no other state to drift from it.
  ({
    void Function(SpeechRecognitionResult result) onResult,
    void Function(double normalizedLevel) onSoundLevel,
    String localeId,
    Duration listenFor,
    Duration pauseFor,
  })? _lastConfig;

  /// Initialize speech recognition.
  ///
  /// Returns true if speech recognition is available and initialized.
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async {
    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onStatus: (status) => onStatus?.call(status),
      onError: (error) => onError?.call(error.errorMsg, error.permanent),
      debugLogging: false,
    );

    return _isInitialized;
  }

  /// Start listening for speech.
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = VoiceTuning.listenFor,
    Duration pauseFor = VoiceTuning.pauseFor,
  }) async {
    // Cache config BEFORE the _isInitialized guard so restartListen can
    // still find config even if a startListening attempt no-ops on uninitialised state.
    // The init check below preserves the existing no-op semantics.
    _lastConfig = (
      onResult: onResult,
      onSoundLevel: onSoundLevel,
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
    );

    if (!_isInitialized) return;

    // voice-consolidation P0-6 / offline Tier 0: prefer on-device recognition
    // unless this session already degraded. Single listen site — restartListen
    // replays through here, so the fallback needs no second implementation.
    final wantOnDevice =
        VoiceTuning.preferOnDeviceRecognition && !_onDeviceFallbackActive;
    try {
      await _listen(
        onResult: onResult,
        onSoundLevel: onSoundLevel,
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        onDevice: wantOnDevice,
      );
    } on Exception {
      // Only an on-device attempt is retried (once, same args, degraded).
      // A failure on the already-degraded path propagates unchanged — no loop.
      if (!wantOnDevice) rethrow;
      _onDeviceFallbackActive = true;
      if (kDebugMode) {
        // Degrade event only — never transcript content.
        debugPrint(
          'SpeechRecognitionService: on-device recognition unavailable, '
          'session degraded to default recognition',
        );
      }
      await _listen(
        onResult: onResult,
        onSoundLevel: onSoundLevel,
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        onDevice: false,
      );
    }
  }

  /// Single plugin-listen call site shared by the on-device attempt and the
  /// degraded retry. All non-onDevice options are byte-identical to the
  /// pre-P0-6 configuration.
  Future<void> _listen({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
    required bool onDevice,
  }) {
    return _speech.listen(
      onResult: onResult,
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      onSoundLevelChange: (double level) {
        onSoundLevel(_normalizeSoundLevel(level));
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        autoPunctuation: true,
        cancelOnError: false,
        partialResults: true,
        onDevice: onDevice,
      ),
    );
  }

  /// Restart listening using the most recently used [startListening] configuration.
  ///
  /// Used by the voice chunk merger (Phase 20 / VOICE-02) to reopen
  /// recognition between final results within a continued-listening window.
  ///
  /// Behavior:
  ///   - If [initialize] has not been called OR no prior [startListening]
  ///     call was made, returns false and does nothing.
  ///   - If the recognizer is currently listening, cancels first then
  ///     re-invokes [startListening] with the cached config (per
  ///     speech_to_text Pitfall 3 — calling listen() mid-session can throw).
  ///   - Otherwise, calls [startListening] directly with cached config.
  ///
  /// Errors from [cancel] or [listen] propagate to the caller — the
  /// merger should display an error in the voice screen rather than
  /// silently dropping the user's continued speech.
  Future<bool> restartListen() async {
    final cfg = _lastConfig;
    if (cfg == null || !_isInitialized) {
      return false;
    }
    if (_speech.isListening) {
      await _speech.cancel();
    }
    await startListening(
      onResult: cfg.onResult,
      onSoundLevel: cfg.onSoundLevel,
      localeId: cfg.localeId,
      listenFor: cfg.listenFor,
      pauseFor: cfg.pauseFor,
    );
    return true;
  }

  /// Stop listening and get the final result.
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancel listening without getting a result.
  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Get the list of available locales for speech recognition.
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) return [];
    return _speech.locales();
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;

  /// Normalize raw sound level to 0.0–1.0 range.
  ///
  /// Android: RMS-based, approximately 0~10
  /// iOS: dB scale, approximately -50~0
  /// Output: 0.0 (silent) ~ 1.0 (maximum)
  double _normalizeSoundLevel(double rawLevel) {
    if (Platform.isAndroid) {
      return (rawLevel / 10.0).clamp(0.0, 1.0);
    } else if (Platform.isIOS) {
      return ((rawLevel + 50.0) / 50.0).clamp(0.0, 1.0);
    }
    return rawLevel.clamp(0.0, 1.0);
  }

  /// Exposed for unit testing only. Do not call in production code.
  ///
  /// Tests cannot call [_normalizeSoundLevel] directly (it uses Platform).
  /// This method accepts an explicit [isAndroid] flag for test isolation.
  @visibleForTesting
  double normalizeSoundLevelForTest(
    double rawLevel, {
    required bool isAndroid,
  }) {
    if (isAndroid) {
      return (rawLevel / 10.0).clamp(0.0, 1.0);
    } else {
      return ((rawLevel + 50.0) / 50.0).clamp(0.0, 1.0);
    }
  }
}
