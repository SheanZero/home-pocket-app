import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infrastructure/speech/speech_recognition_service.dart';
import '../../infrastructure/voice/chinese_numeral_state_machine.dart';
import '../../infrastructure/voice/japanese_numeral_state_machine.dart';
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

// ─── Voice numeral state machines (Phase 20) ───────────────────────────────

/// Chinese numeral state machine — stateless, const constructor.
///
/// Provides ChineseNumeralStateMachine for injection into VoiceChunkMerger.
/// The merger itself is per-recording-session and constructed inline in
/// VoiceInputScreen (Plan 20-09) — only the stateless machines are provided here.
@riverpod
ChineseNumeralStateMachine chineseNumeralStateMachine(Ref ref) =>
    const ChineseNumeralStateMachine();

/// Japanese numeral state machine — stateless but non-const due to static
/// sorted-keys initialization at first use.
@riverpod
JapaneseNumeralStateMachine japaneseNumeralStateMachine(Ref ref) =>
    JapaneseNumeralStateMachine();
