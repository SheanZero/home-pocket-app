import 'package:flutter/material.dart';

/// 悦己 7-color warm palette for the joy-spend horizontal stacked bar (joybar).
///
/// The joybar segments need DISTINCT, hue-separated warm colors (NOT a single
/// joy-family lerp) so each joy category reads as its own slice — mirroring the
/// round-5 r5 mock's 悦己暖色调色板. The seven hues are deliberately chosen to
/// be hue-separated AND to AVOID the green (日常/daily) and blue (shared) ledger
/// semantic families, so the bar never visually collides with a ledger color.
///
/// This is a joybar-专属 palette defined in `lib/core/theme/` rather than as inline
/// `Color(0x…)` literals inside a `lib/features/...` widget. That placement is
/// deliberate: `color_literal_scan_test` forbids raw hex in
/// `lib/features/` / `lib/application/` / `lib/shared/`, and this is the ONE
/// sanctioned hex carve-out (D5). Do NOT inline these constants into a feature
/// widget.
///
/// Order = mock j1..j7 (largest→smallest joy category, anchored on sakura):
///   j1 樱粉   #D98CA0 (anchor) · j2 琥珀金 #E2A23B · j3 珊瑚赤陶 #E0664B ·
///   j4 梅紫藕 #9B5DA6 · j5 桃沙 #EBB87A · j6 暖灰褐 #B08363 · j7 藕灰玫 #C7A7AE
@immutable
class JoyWarmPalette {
  const JoyWarmPalette();

  /// j1 樱粉 (anchor) — same hue as the ADR-019 joy token.
  static const Color j1 = Color(0xFFD98CA0);

  /// j2 琥珀金.
  static const Color j2 = Color(0xFFE2A23B);

  /// j3 珊瑚赤陶.
  static const Color j3 = Color(0xFFE0664B);

  /// j4 梅紫藕.
  static const Color j4 = Color(0xFF9B5DA6);

  /// j5 桃沙.
  static const Color j5 = Color(0xFFEBB87A);

  /// j6 暖灰褐.
  static const Color j6 = Color(0xFFB08363);

  /// j7 藕灰玫.
  static const Color j7 = Color(0xFFC7A7AE);

  /// 段间 2px 分隔 / 条底色（mock --cream）。
  static const Color cream = Color(0xFFFFFAF6);

  /// The ordered j1..j7 segment colors (largest→smallest joy category).
  static const List<Color> segments = <Color>[j1, j2, j3, j4, j5, j6, j7];

  /// Color for the [index]-th joy segment, wrapping deterministically when there
  /// are MORE than 7 joy categories (`index % segments.length`) so the palette
  /// cycles without ever falling back to an undefined/transparent color.
  static Color colorAt(int index) => segments[index % segments.length];
}
