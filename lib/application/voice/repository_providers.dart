import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infrastructure/speech/speech_recognition_service.dart';
import 'start_speech_recognition_use_case.dart';

part 'repository_providers.g.dart';

/// Application-layer SpeechRecognitionService provider.
///
/// Uses `app` prefix to avoid collision with any future feature-side definition
/// during Wave 2/3 coexistence (per Warning 7 fix).
@riverpod
SpeechRecognitionService appSpeechRecognitionService(Ref ref) {
  return SpeechRecognitionService();
}

/// Application-layer StartSpeechRecognitionUseCase provider.
@riverpod
StartSpeechRecognitionUseCase startSpeechRecognitionUseCase(Ref ref) {
  return StartSpeechRecognitionUseCase(
    service: ref.watch(appSpeechRecognitionServiceProvider),
  );
}
