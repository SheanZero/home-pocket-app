import 'package:flutter/material.dart';

/// A brief, accessibility-aware transition between root application gates.
///
/// The gate remains on the same Navigator route; this widget only softens the
/// child-tree handoff between initialization, onboarding, lock, and the shell.
class AppGateTransition extends StatelessWidget {
  const AppGateTransition({super.key, required this.child});

  static const duration = Duration(milliseconds: 220);
  static const reverseDuration = Duration(milliseconds: 140);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : duration,
      reverseDuration: reduceMotion ? Duration.zero : reverseDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: child,
    );
  }
}
