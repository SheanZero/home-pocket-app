// lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart
//
// Pure helpers extracted from voice_input_screen.dart to keep the screen under
// the CLAUDE.md 800-line file cap (Phase 23 gap closure Plan 09).
//
// No behavior change — these functions are byte-identical to the inlined
// versions and have no State or `this` dependency. They grew up inside the
// State class for historical reasons; their inputs are now passed explicitly.

import '../../domain/models/voice_parse_result.dart';

/// Build a [VoiceAudioFeatures] snapshot from the raw audio-sampling buffers
/// captured during a recording session. Mirrors the prior instance method
/// `_VoiceInputScreenState._buildAudioFeatures` byte-for-byte; the only
/// change is that State fields are now passed as named parameters.
VoiceAudioFeatures buildVoiceAudioFeatures({
  required List<double> soundLevels,
  required List<DateTime> timestamps,
  required DateTime? startTime,
  required int partialResultCount,
  required int wordCount,
}) {
  final now = DateTime.now();
  return VoiceAudioFeatures(
    soundLevels: List.unmodifiable(soundLevels),
    timestamps: List.unmodifiable(timestamps),
    startTime: startTime ?? now,
    endTime: now,
    partialResultCount: partialResultCount,
    wordCount: wordCount,
  );
}

/// Estimate the word count of a recognized transcript.
///
/// Japanese/Chinese: estimate by character count (2 chars ≈ 1 word).
/// English (or any string containing Latin letters): whitespace split.
int countVoiceWords(String text) {
  if (text.isEmpty) return 0;
  // Japanese/Chinese: estimate by character count (2 chars ≈ 1 word)
  // English: split by whitespace
  final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);
  if (hasLatin) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
  return (text.replaceAll(RegExp(r'\s'), '').length / 2).ceil();
}

/// Extract the "keyword" portion of a recognized voice transcript by stripping
/// the amount, the matched merchant name (if any), and common Japanese/Chinese
/// particles. Used by the voice-correction learning hook (Phase 18 D-09).
String extractVoiceKeyword(VoiceParseResult result) {
  var remaining = result.rawText;

  // Remove amount patterns
  remaining = remaining.replaceAll(
    RegExp(r'[¥￥]?\s*[\d,]+\.?\d*\s*(円|元|ドル)?'),
    '',
  );

  // Remove merchant name if matched
  if (result.merchantName != null) {
    remaining = remaining.replaceFirst(result.merchantName!, '');
  }

  // Remove Japanese particles
  remaining = remaining.replaceAll(RegExp(r'[のにでをはがもへとや]'), '');

  // Remove Chinese particles
  remaining = remaining.replaceAll(RegExp(r'[的了吗呢吧啊呀哦]'), '');

  return remaining.trim();
}
