import 'package:speech_to_text/speech_recognition_result.dart';

import '../../infrastructure/speech/speech_recognition_service.dart';

/// Application-layer use case wrapping [SpeechRecognitionService] for screens
/// that need speech recognition without importing infrastructure/ directly.
///
/// Exposes the underlying callback-based API of [SpeechRecognitionService]
/// as a thin wrapper following constructor-injection + delegation pattern.
class StartSpeechRecognitionUseCase {
  StartSpeechRecognitionUseCase({required SpeechRecognitionService service})
      : _service = service;

  final SpeechRecognitionService _service;

  /// Initialize speech recognition.
  ///
  /// Returns [true] if available and initialized.
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) =>
      _service.initialize(onStatus: onStatus, onError: onError);

  /// Start listening for speech with [localeId].
  ///
  /// Results arrive via [onResult]; sound level via [onSoundLevel].
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) =>
      _service.startListening(
        onResult: onResult,
        onSoundLevel: onSoundLevel,
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
      );

  /// Stop listening and finalize the transcription result.
  Future<void> stop() => _service.stopListening();

  /// Cancel listening without processing result.
  Future<void> cancel() => _service.cancelListening();

  /// Whether speech recognition is currently active.
  bool get isListening => _service.isListening;

  /// Whether speech recognition is available on this device.
  bool get isAvailable => _service.isAvailable;
}
