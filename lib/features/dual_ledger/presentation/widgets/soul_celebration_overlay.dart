import 'dart:math';

import 'package:flutter/material.dart';

/// A purple-themed celebration overlay shown when a soul transaction is saved.
///
/// Displays animated sparkle icons that scale up and fade out over 1.5 seconds,
/// then auto-dismisses by calling [onDismissed].
class SoulCelebrationOverlay extends StatefulWidget {
  const SoulCelebrationOverlay({super.key, this.onDismissed});

  final VoidCallback? onDismissed;

  @override
  State<SoulCelebrationOverlay> createState() =>
      _SoulCelebrationOverlayState();
}

class _SoulCelebrationOverlayState extends State<SoulCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final List<_SparkleData> _sparkles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    final rng = Random(42);
    _sparkles = List.generate(
      7,
      (_) => _SparkleData(
        dx: rng.nextDouble() * 0.8 + 0.1,
        dy: rng.nextDouble() * 0.6 + 0.2,
        size: rng.nextDouble() * 16 + 16,
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Stack(
            children: [
              // Purple gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.purple.withValues(alpha: 0.3),
                      Colors.deepPurple.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
              // Sparkle icons
              ..._sparkles.map((sparkle) {
                return Positioned(
                  left: MediaQuery.of(context).size.width * sparkle.dx -
                      sparkle.size / 2,
                  top: MediaQuery.of(context).size.height * sparkle.dy -
                      sparkle.size / 2,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(
                      Icons.auto_awesome,
                      size: sparkle.size,
                      color: Colors.purple.shade300,
                    ),
                  ),
                );
              }),
              // Center text
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 48,
                        color: Colors.purple,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Soul!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SparkleData {
  final double dx;
  final double dy;
  final double size;

  const _SparkleData({
    required this.dx,
    required this.dy,
    required this.size,
  });
}
