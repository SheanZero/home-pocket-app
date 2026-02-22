import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice recognition service wrapping the speech_to_text plugin.
///
/// Provides a unified interface for speech recognition and handles
/// platform differences (sound level normalization).
class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

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
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) return;

    await _speech.listen(
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
      ),
    );
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
  double normalizeSoundLevelForTest(double rawLevel, {required bool isAndroid}) {
    if (isAndroid) {
      return (rawLevel / 10.0).clamp(0.0, 1.0);
    } else {
      return ((rawLevel + 50.0) / 50.0).clamp(0.0, 1.0);
    }
  }
}
