import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum ScatteredEmojiPattern { onboarding, avatarPicker, profileEdit }

class ScatteredEmojiBackground extends StatelessWidget {
  const ScatteredEmojiBackground({
    super.key,
    required this.child,
    this.pattern = ScatteredEmojiPattern.onboarding,
  });

  final Widget child;
  final ScatteredEmojiPattern pattern;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emojiColor = isDark
        ? const Color(0xFFF0F0F5)
        : AppColors.textPrimary;
    final decorations = switch (pattern) {
      ScatteredEmojiPattern.onboarding => _onboardingDecorations,
      ScatteredEmojiPattern.avatarPicker => _avatarPickerDecorations,
      ScatteredEmojiPattern.profileEdit => _profileEditDecorations,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            for (final decoration in decorations)
              Positioned(
                left: decoration.x / _baseWidth * width,
                top: decoration.y / _baseHeight * height,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: decoration.opacity,
                    child: Transform.rotate(
                      angle: decoration.rotation * math.pi / 180,
                      child: Text(
                        decoration.emoji,
                        style: TextStyle(
                          fontSize: decoration.size,
                          color: emojiColor,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            child,
          ],
        );
      },
    );
  }

  static const _baseWidth = 402.0;
  static const _baseHeight = 874.0;

  static const _onboardingDecorations = [
    _EmojiDecoration('🌸', 40, 100, 32, 0.15, 15),
    _EmojiDecoration('🌿', 320, 140, 28, 0.12, -10),
    _EmojiDecoration('⭐', 30, 350, 20, 0.10, 20),
    _EmojiDecoration('🍃', 350, 420, 24, 0.12, -15),
    _EmojiDecoration('💫', 55, 700, 18, 0.10, 10),
    _EmojiDecoration('🌷', 330, 680, 22, 0.10, -5),
    _EmojiDecoration('✨', 340, 790, 16, 0.08, 0),
  ];

  static const _avatarPickerDecorations = [
    _EmojiDecoration('🌸', 30, 110, 24, 0.12, 15),
    _EmojiDecoration('🌿', 350, 160, 20, 0.10, -10),
    _EmojiDecoration('⭐', 20, 560, 16, 0.08, 20),
    _EmojiDecoration('🍃', 355, 620, 18, 0.10, -12),
    _EmojiDecoration('💫', 40, 780, 14, 0.08, 8),
  ];

  static const _profileEditDecorations = [
    _EmojiDecoration('🌸', 35, 120, 24, 0.12, 15),
    _EmojiDecoration('🌿', 340, 180, 20, 0.10, -10),
    _EmojiDecoration('⭐', 25, 500, 16, 0.08, 20),
    _EmojiDecoration('🍃', 350, 600, 18, 0.10, -12),
    _EmojiDecoration('💫', 45, 760, 14, 0.08, 8),
  ];
}

class _EmojiDecoration {
  const _EmojiDecoration(
    this.emoji,
    this.x,
    this.y,
    this.size,
    this.opacity,
    this.rotation,
  );

  final String emoji;
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double rotation;
}
