/// Compile-time feature flags for reversibly toggling in-progress features.
///
/// Each flag is a top-level `const bool` so the Dart compiler tree-shakes the
/// disabled branch out of release builds.
library;

/// Whether the user-visible OCR / scan add-entry tab is shown.
///
/// Temporarily `false` while the OCR capture/review flow is being completed.
/// The OCR infrastructure (`lib/infrastructure/ml/`, `lib/application/ocr/`) and
/// the OCR screen files (`ocr_scanner_screen.dart`, `ocr_review_screen.dart`)
/// are intentionally RETAINED, not deleted — flipping this single flag to `true`
/// fully restores the OCR tab and its navigation with no other edits.
const bool kOcrEntryEnabled = false;
