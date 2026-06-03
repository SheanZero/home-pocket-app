import 'package:flutter/material.dart';

import 'soft_toast.dart';

/// Default visible duration for a feedback toast.
const Duration _kDefaultFeedbackDuration = Duration(seconds: 3);

/// The single currently-visible feedback toast, app-wide. Tracked so a new
/// toast suppresses (replaces) any still-visible one instead of stacking at the
/// same top anchor (260603-nr1 follow-up: 单例 toast 抑制堆叠).
OverlayEntry? _activeToast;

/// Immediately removes the active toast (if any) without an exit animation.
/// Safe to call when none is showing or when its overlay was already disposed.
void _dismissActiveToast() {
  final prev = _activeToast;
  _activeToast = null;
  if (prev != null && prev.mounted) {
    prev.remove();
  }
}

/// Unified top-of-screen feedback entry point for success / error toasts.
///
/// This is the SINGLE entry for both success and error feedback app-wide
/// (260603-nr1 #1; promoted to lib/shared in the follow-up sweep). It mirrors
/// the overlay pattern of `showVoiceRecognitionErrorToast`
/// (voice_error_toast.dart): a top-anchored [SoftToast] inserted as an
/// [OverlayEntry] that removes itself on dismissal.
///
/// Only ONE feedback toast is visible at a time — showing a new one instantly
/// replaces the previous (no stacking). Prefer [showSuccessFeedback] /
/// [showErrorFeedback]; both delegate here.
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
  // Singleton: drop any toast still on screen before inserting the new one.
  _dismissActiveToast();

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
        onDismissed: () {
          if (entry.mounted) entry.remove();
          // Only clear the slot if this entry is still the active one — a newer
          // toast may have already claimed it.
          if (identical(_activeToast, entry)) _activeToast = null;
        },
      ),
    ),
  );
  _activeToast = entry;
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
