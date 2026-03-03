import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    required this.isOwner,
    this.size = 40,
  });

  final String name;
  final bool isOwner;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final backgroundColor = isOwner
        ? AppColors.survival
        : const Color(0xFFEEF4FA);
    final textColor = isOwner ? Colors.white : AppColors.survival;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
