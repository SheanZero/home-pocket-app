import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// A floating capsule-style soft toast for inline error/warning feedback.
///
/// Displays a pill-shaped message with icon, text, and optional close button.
/// Auto-dismisses after [duration] and supports manual dismissal via close tap.
class SoftToast extends StatefulWidget {
  const SoftToast({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
  });

  final String message;
  final IconData icon;
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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: palette.errorSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.errorBorder),
              boxShadow: [
                BoxShadow(
                  color: palette.errorShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: palette.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: palette.error,
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
                      color: palette.errorBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: palette.error,
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
