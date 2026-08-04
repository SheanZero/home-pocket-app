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

/// Unified top-of-screen feedback entry point for all transient status pills.
///
/// This is the SINGLE entry for success, error, and informational feedback
/// (260603-nr1 #1; promoted to lib/shared in the follow-up sweep). It mirrors
/// the overlay pattern of `showVoiceRecognitionErrorToast`
/// (voice_error_toast.dart): a top-anchored [SoftToast] inserted as an
/// [OverlayEntry] that removes itself on dismissal.
///
/// Only ONE feedback toast is visible at a time — showing a new one instantly
/// replaces the previous (no stacking). Prefer [showSuccessFeedback] /
/// [showErrorFeedback]; both delegate here.
///
/// [actionLabel] + [onAction] render an optional inline action (e.g. "退出记账").
void showFeedbackToast(
  BuildContext context,
  String message, {
  required FeedbackTone tone,
  IconData? icon,
  Duration duration = _kDefaultFeedbackDuration,
  String? actionLabel,
  VoidCallback? onAction,
  Key? actionKey,
}) {
  // Singleton: drop any toast still on screen before inserting the new one.
  _dismissActiveToast();

  final overlay = Overlay.of(context);
  // Read the platform view directly: a caller nested below SafeArea sees a
  // MediaQuery whose top padding has already been consumed (usually zero).
  // View.padding remains the authoritative system inset for the current
  // window, keeping every shared toast below notches and Dynamic Island.
  final view = View.of(context);
  final topInset = view.padding.top / view.devicePixelRatio + 16;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: topInset,
      left: 0,
      right: 0,
      child: SoftToast(
        message: message,
        tone: tone,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        actionKey: actionKey,
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
  IconData? icon,
  Duration duration = _kDefaultFeedbackDuration,
  String? actionLabel,
  VoidCallback? onAction,
  Key? actionKey,
}) {
  showFeedbackToast(
    context,
    message,
    tone: FeedbackTone.success,
    icon: icon,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
    actionKey: actionKey,
  );
}

/// Show a red error toast sliding down from the top.
void showErrorFeedback(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration duration = _kDefaultFeedbackDuration,
  String? actionLabel,
  VoidCallback? onAction,
  Key? actionKey,
}) {
  showFeedbackToast(
    context,
    message,
    tone: FeedbackTone.error,
    icon: icon,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
    actionKey: actionKey,
  );
}

/// Show a neutral informational status pill.
void showInfoFeedback(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration duration = _kDefaultFeedbackDuration,
  String? actionLabel,
  VoidCallback? onAction,
  Key? actionKey,
}) {
  showFeedbackToast(
    context,
    message,
    tone: FeedbackTone.info,
    icon: icon,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
    actionKey: actionKey,
  );
}
