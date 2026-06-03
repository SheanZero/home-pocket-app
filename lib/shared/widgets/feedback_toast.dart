import 'package:flutter/material.dart';

import 'soft_toast.dart';

/// Default visible duration for a feedback toast.
const Duration _kDefaultFeedbackDuration = Duration(seconds: 3);

/// Unified top-of-screen feedback entry point for success / error toasts.
///
/// This is the SINGLE entry for both success and error feedback app-wide
/// (260603-nr1 #1; promoted to lib/shared in the follow-up sweep). It mirrors
/// the overlay pattern of `showVoiceRecognitionErrorToast`
/// (voice_error_toast.dart): a top-anchored [SoftToast] inserted as an
/// [OverlayEntry] that removes itself on dismissal.
///
/// Prefer [showSuccessFeedback] / [showErrorFeedback]; both delegate here.
///
/// [actionLabel] + [onAction] render an optional inline link (e.g. "退出记账").
void showFeedbackToast(
  BuildContext context,
  String message, {
  required FeedbackTone tone,
  Duration duration = _kDefaultFeedbackDuration,
  String? actionLabel,
  VoidCallback? onAction,
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
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}

/// Show a green success toast sliding down from the top.
///
/// Supports an optional inline action link and a custom [duration] (the
/// continuous-accounting "可以继续记账 / 退出记账" toast uses a longer duration).
void showSuccessFeedback(
  BuildContext context,
  String message, {
  Duration duration = _kDefaultFeedbackDuration,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showFeedbackToast(
    context,
    message,
    tone: FeedbackTone.success,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

/// Show a red error toast sliding down from the top.
void showErrorFeedback(
  BuildContext context,
  String message, {
  Duration duration = _kDefaultFeedbackDuration,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showFeedbackToast(
    context,
    message,
    tone: FeedbackTone.error,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
