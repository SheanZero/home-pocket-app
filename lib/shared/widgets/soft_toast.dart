import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

const double _kCompactToastHeight = 44;
const double _kToastVerticalPadding = 4;
const double _kToastActionHeight = 44;

/// Visual tone of a [SoftToast] — drives surface/border/shadow/foreground
/// colour family and the default leading icon.
enum FeedbackTone {
  /// Red error family (`palette.error*`). Default — keeps existing inline
  /// error-feedback call sites unchanged.
  error,

  /// Green success family (`palette.success` / `palette.successLight`).
  success,

  /// Blue information family (`palette.info`).
  info,
}

/// A compact floating status pill for success, error, and informational
/// feedback.
///
/// Displays an intrinsic-width message with a semantic icon and optional action.
/// Short copy stays compact; longer localized copy expands up to 360 logical
/// pixels and wraps. The pill auto-dismisses after [duration].
///
/// The [tone] selects the colour family (success = green, error = red) and the
/// default leading icon. Defaults to [FeedbackTone.error] for backward
/// compatibility with the original error-only call sites.
class SoftToast extends StatefulWidget {
  const SoftToast({
    super.key,
    required this.message,
    this.tone = FeedbackTone.error,
    this.icon,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final String message;

  /// Colour family + default icon selector.
  final FeedbackTone tone;

  /// Optional explicit leading icon. When null, derives from [tone]
  /// (success → check_circle_outline, error → error_outline).
  final IconData? icon;

  final Duration duration;
  final VoidCallback? onDismissed;

  /// Optional inline action (e.g. "退出记账"). Tapping it dismisses the pill and
  /// then invokes [onAction] (260603-nr1 follow-up Ask 2).
  final String? actionLabel;

  /// Invoked after the toast dismisses when the [actionLabel] link is tapped.
  final VoidCallback? onAction;

  /// Optional stable key for an inline action used by behavior tests and
  /// callers that need to target a specific undo affordance.
  final Key? actionKey;

  @override
  State<SoftToast> createState() => _SoftToastState();
}

class _SoftToastState extends State<SoftToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _startAutoHide();
  }

  void _startAutoHide() {
    _autoHideTimer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  /// Tapping the inline action link: stop the auto-hide, invoke the action
  /// (e.g. navigate away), then animate the toast out / remove its overlay.
  void _handleAction() {
    _autoHideTimer?.cancel();
    widget.onAction?.call();
    _dismiss();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (
      foreground,
      badgeSurface,
      badgeForeground,
      leadingIcon,
    ) = switch (widget.tone) {
      FeedbackTone.success => (
        palette.success,
        isDark ? palette.accentPrimary : palette.accentPrimaryLight,
        isDark ? palette.background : palette.accentPrimary,
        widget.icon ?? Icons.check_rounded,
      ),
      FeedbackTone.error => (
        palette.error,
        palette.errorSurface,
        palette.error,
        widget.icon ?? Icons.priority_high_rounded,
      ),
      FeedbackTone.info => (
        palette.info,
        palette.info.withValues(alpha: 0.16),
        palette.info,
        widget.icon ?? Icons.info_outline_rounded,
      ),
    };
    final Color shadow = palette.textPrimary.withValues(alpha: 0.08);
    final maxWidth = (MediaQuery.sizeOf(context).width - 40).clamp(0.0, 360.0);
    final messageStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );
    const actionStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.none,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final messagePainter = TextPainter(
      text: TextSpan(text: widget.message, style: messageStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout();
    var desiredWidth = 20 + 28 + 8 + messagePainter.width;
    if (widget.actionLabel != null) {
      final actionPainter = TextPainter(
        text: TextSpan(text: widget.actionLabel, style: actionStyle),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout();
      desiredWidth += 6 + (actionPainter.width + 16).clamp(44.0, maxWidth);
    }
    final needsVerticalPadding =
        widget.actionLabel == null ||
        messagePainter.didExceedMaxLines ||
        desiredWidth > maxWidth;
    desiredWidth = desiredWidth.clamp(0.0, maxWidth);

    return Semantics(
      container: true,
      liveRegion: true,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: desiredWidth,
                child: Container(
                  key: const Key('feedback-toast-surface'),
                  constraints: const BoxConstraints(
                    minHeight: _kCompactToastHeight,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: needsVerticalPadding ? _kToastVerticalPadding : 0,
                  ),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: shadow,
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        key: const Key('feedback-toast-icon-badge'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: badgeSurface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          leadingIcon,
                          key: const Key('feedback-toast-leading-icon'),
                          size: 18,
                          color: badgeForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.message,
                          maxLines: 3,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: messageStyle,
                        ),
                      ),
                      if (widget.actionLabel != null) ...[
                        const SizedBox(width: 6),
                        TextButton(
                          key:
                              widget.actionKey ??
                              const Key('feedback-toast-action'),
                          onPressed: _handleAction,
                          style: TextButton.styleFrom(
                            foregroundColor: foreground,
                            minimumSize: const Size(44, _kToastActionHeight),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: const StadiumBorder(),
                            textStyle: actionStyle,
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: foreground,
                              decoration: TextDecoration.none,
                              decorationColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
