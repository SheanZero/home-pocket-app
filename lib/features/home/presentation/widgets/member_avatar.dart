import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

/// Circular member avatar with a single-character initial.
///
/// Used in the group bar and transaction tags to represent family members.
/// The overlap layout (gap -6px) is handled by the parent widget.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.initial,
    required this.color,
    this.size = 24,
    this.strokeWidth = 2,
    this.strokeColor = const Color(0xFFFFFFFF),
  });

  /// Single character displayed in the centre of the avatar.
  final String initial;

  /// Fill colour of the circle.
  final Color color;

  /// Inner diameter of the avatar (excluding stroke).
  final double size;

  /// Width of the outer white stroke.
  final double strokeWidth;

  /// Colour of the outer stroke.
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    final totalSize = size + strokeWidth * 2;
    return Container(
      width: totalSize,
      height: totalSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: strokeColor, width: strokeWidth),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
