import 'package:freezed_annotation/freezed_annotation.dart';

part 'ocr_parse_draft.freezed.dart';

/// Result of parsing a scanned receipt via OCR.
///
/// Holds extracted fields as nullable primitives. MOD-005 populates these
/// when the real OCR writer ships; until then [OcrParseDraft.empty] is the
/// only construction path Phase 18 exercises.
///
/// Symmetric with [VoiceParseResult] — same mental model for downstream agents.
@freezed
sealed class OcrParseDraft with _$OcrParseDraft {
  const OcrParseDraft._();

  /// Draft with explicitly provided OCR-extracted fields.
  const factory OcrParseDraft({
    int? amount,
    String? merchant,
    DateTime? date,
    String? rawOcrText,
    String? imagePath,
  }) = _OcrParseDraft;

  /// Empty draft — all fields null. Used by Phase 18's OCR slot wire-up
  /// (the camera stub passes this; user fills the form manually).
  const factory OcrParseDraft.empty() = _Empty;

  /// True when no OCR field was populated — drives the banner in OcrReviewScreen.
  bool get isEmpty => switch (this) {
    _OcrParseDraft(:final amount, :final merchant, :final date, :final rawOcrText, :final imagePath) =>
      amount == null && merchant == null && date == null && rawOcrText == null && imagePath == null,
    _Empty() => true,
  };
}
