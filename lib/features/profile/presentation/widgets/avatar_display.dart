import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

class AvatarDisplay extends StatelessWidget {
  const AvatarDisplay({
    super.key,
    required this.emoji,
    this.imagePath,
    this.size = 110,
    this.gradientColors,
    this.onTap,
  });

  final String emoji;
  final String? imagePath;
  final double size;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = gradientColors ?? [
      palette.avatarGradientStart,
      palette.avatarGradientMid,
      palette.avatarGradientEnd,
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          border: Border.all(color: palette.avatarBorderAlpha, width: 2),
          boxShadow: [
            BoxShadow(
              color: palette.accentPrimary.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: imagePath != null
              ? Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _EmojiContent(emoji: emoji, size: size),
                )
              : _EmojiContent(emoji: emoji, size: size),
        ),
      ),
    );
  }
}

class _EmojiContent extends StatelessWidget {
  const _EmojiContent({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(emoji, style: TextStyle(fontSize: size * 0.47, height: 1)),
    );
  }
}
