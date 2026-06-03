import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';

/// G-02 / WR-05: surface a localized SoftToast for speech-recognition
/// failures reported via VoiceInputScreen._onError.
///
/// Maps the platform's English-only error code (errorMsg from
/// `speech_to_text`) to one of the 4 voiceRecognitionError* ARB strings
/// added in Plan 22-08. Mirrors VoiceInputScreen._showPermissionError's
/// overlay pattern verbatim (same positioning, same dismissal lifecycle).
///
/// Extracted to its own file to keep voice_input_screen.dart close to the
/// 800-line CLAUDE.md cap; the helper has no `_VoiceInputScreenState`
/// dependencies (uses only S.of(context), Overlay.of(context), SoftToast),
/// so a top-level function is the correct shape.
///
/// Platform speech_to_text error codes per 22-REVIEW.md WR-05:
/// - error_network / error_network_timeout → voiceRecognitionErrorNetwork
/// - error_no_match → voiceRecognitionErrorNoMatch
/// - error_audio → voiceRecognitionErrorAudio
/// - everything else (error_speech_timeout, error_client, etc.) → voiceRecognitionErrorUnknown
///
/// error_permission is intentionally not mapped here — _initSpeechService
/// surfaces voiceMicrophonePermissionRequired for the cold-start denial;
/// if a permission error reaches _onError mid-session it falls through to
/// Unknown, which is acceptable copy.
void showVoiceRecognitionErrorToast(BuildContext context, String errorMsg) {
  final l10n = S.of(context);
  final String message;
  switch (errorMsg) {
    case 'error_network':
    case 'error_network_timeout':
      message = l10n.voiceRecognitionErrorNetwork;
      break;
    case 'error_no_match':
      message = l10n.voiceRecognitionErrorNoMatch;
      break;
    case 'error_audio':
      message = l10n.voiceRecognitionErrorAudio;
      break;
    default:
      message = l10n.voiceRecognitionErrorUnknown;
      break;
  }

  // Route through the shared error-feedback entry so this participates in the
  // app-wide single-toast suppression (FeedbackTone.error already defaults to
  // Icons.error_outline, matching the previous explicit icon).
  showErrorFeedback(context, message);
}
