import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Maps a 1–10 satisfaction value to its face SVG asset (`sat_01`..`sat_05`,
/// low → high). Single source of truth shared by the add-transaction picker,
/// the home hero "best joy" seal, and the home/list transaction tiles. Mirrors
/// the threshold boundaries used by `SatisfactionEmojiPicker`.
String satisfactionFaceAsset(int value) {
  if (value <= 2) return 'assets/satisfaction/sat_01.svg';
  if (value <= 4) return 'assets/satisfaction/sat_02.svg';
  if (value <= 6) return 'assets/satisfaction/sat_03.svg';
  if (value <= 8) return 'assets/satisfaction/sat_04.svg';
  return 'assets/satisfaction/sat_05.svg';
}

/// Renders the satisfaction face for [value] as a monochrome SVG tinted to
/// [color] (via `srcIn`), sized to a [size]×[size] box.
class SatisfactionFaceIcon extends StatelessWidget {
  const SatisfactionFaceIcon({
    super.key,
    required this.value,
    required this.size,
    required this.color,
  });

  final int value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      satisfactionFaceAsset(value),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
