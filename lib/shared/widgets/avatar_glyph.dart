import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/avatar_icon_ids.dart';

/// Renders either a current icon-library avatar or a legacy emoji avatar.
///
/// Keeping this translation in one widget lets stored icon IDs display
/// consistently in onboarding, profile, family, and analytics surfaces.
class AvatarGlyph extends StatelessWidget {
  const AvatarGlyph({
    super.key,
    required this.value,
    required this.size,
    this.color,
  });

  final String value;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = _avatarIconData[value];
    if (icon != null) {
      return Icon(icon, key: ValueKey(value), size: size, color: color);
    }

    return Text(value, style: TextStyle(fontSize: size, height: 1));
  }
}

final Map<String, IconData> _avatarIconData = {
  avatarIconIds[0]: LucideIcons.userRound,
  avatarIconIds[1]: LucideIcons.cat,
  avatarIconIds[2]: LucideIcons.dog,
  avatarIconIds[3]: LucideIcons.rabbit,
  avatarIconIds[4]: LucideIcons.bird,
  avatarIconIds[5]: LucideIcons.flower2,
  avatarIconIds[6]: LucideIcons.leaf,
  avatarIconIds[7]: LucideIcons.sprout,
  avatarIconIds[8]: LucideIcons.heart,
  avatarIconIds[9]: LucideIcons.smile,
  avatarIconIds[10]: LucideIcons.coffee,
  avatarIconIds[11]: LucideIcons.bookOpen,
  avatarIconIds[12]: LucideIcons.house,
  avatarIconIds[13]: LucideIcons.star,
};
