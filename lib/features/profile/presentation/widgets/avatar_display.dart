import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../shared/widgets/avatar_glyph.dart';

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
    final colors =
        gradientColors ??
        [
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
                      _AvatarContent(value: emoji, size: size),
                )
              : _AvatarContent(value: emoji, size: size),
        ),
      ),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({required this.value, required this.size});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AvatarGlyph(
        value: value,
        size: size * 0.47,
        color: context.palette.accentPrimary,
      ),
    );
  }
}
