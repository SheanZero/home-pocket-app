import 'package:flutter/material.dart';

import 'soft_toast.dart';

/// Unified top-of-screen feedback entry point for success / error toasts.
///
/// This is the SINGLE entry for both success and error feedback across the
/// accounting flows (260603-nr1 #1). It mirrors the overlay pattern of
/// `showVoiceRecognitionErrorToast` (voice_error_toast.dart): a top-anchored
/// [SoftToast] inserted as an [OverlayEntry] that removes itself on dismissal.
///
/// Prefer [showSuccessFeedback] / [showErrorFeedback]; both delegate here.
void showFeedbackToast(
  BuildContext context,
  String message, {
  required FeedbackTone tone,
}) {
  final overlay = Overlay.of(context);
  final topInset = MediaQuery.of(context).padding.top + 16;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: topInset,
      left: 0,
      right: 0,
      child: SoftToast(
        message: message,
        tone: tone,
        onDismissed: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}

/// Show a green success toast sliding down from the top.
void showSuccessFeedback(BuildContext context, String message) {
  showFeedbackToast(context, message, tone: FeedbackTone.success);
}

/// Show a red error toast sliding down from the top.
void showErrorFeedback(BuildContext context, String message) {
  showFeedbackToast(context, message, tone: FeedbackTone.error);
}
