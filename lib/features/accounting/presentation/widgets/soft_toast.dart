import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// Visual tone of a [SoftToast] — drives surface/border/shadow/foreground
/// colour family and the default leading icon.
enum FeedbackTone {
  /// Red error family (`palette.error*`). Default — keeps existing inline
  /// error-toast call sites unchanged.
  error,

  /// Green success family (`palette.success` / `palette.successLight`).
  success,
}

/// A floating capsule-style soft toast for inline success/error feedback.
///
/// Displays a pill-shaped message with icon, text, and optional close button.
/// Auto-dismisses after [duration] and supports manual dismissal via close tap.
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
  });

  final String message;

  /// Colour family + default icon selector.
  final FeedbackTone tone;

  /// Optional explicit leading icon. When null, derives from [tone]
  /// (success → check_circle_outline, error → error_outline).
  final IconData? icon;

  final Duration duration;
  final VoidCallback? onDismissed;

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

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isSuccess = widget.tone == FeedbackTone.success;

    // Tone-resolved colour family. Success derives a soft border/shadow from
    // [success] via alpha so no extra palette tokens are required; error keeps
    // its dedicated error* tints for pixel-stable existing call sites.
    final Color foreground = isSuccess ? palette.success : palette.error;
    final Color surface =
        isSuccess ? palette.successLight : palette.errorSurface;
    final Color border = isSuccess
        ? palette.success.withValues(alpha: 0.35)
        : palette.errorBorder;
    final Color shadow = isSuccess
        ? palette.success.withValues(alpha: 0.12)
        : palette.errorShadow;
    final Color closeBg = isSuccess
        ? palette.success.withValues(alpha: 0.18)
        : palette.errorBorder;
    final IconData leadingIcon = widget.icon ??
        (isSuccess ? Icons.check_circle_outline : Icons.error_outline);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(leadingIcon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: closeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
