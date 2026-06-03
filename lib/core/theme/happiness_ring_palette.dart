import 'package:flutter/material.dart';

/// Color set for the HomeHeroCard 「悦己充盈」 happiness rings (single mode).
///
/// v1.6 ring update — **COMET SWEEP + "青瓷 / 柔绿 / 樱粉" scheme** (quick 260603-lr5b).
/// The three rings show three INDEPENDENT joy metrics (NOT proportions of a
/// whole), so colors are chosen for hue + lightness separation (colorblind
/// safe). Inner [target] ring moved from butter 奶油黄 to sakura pink 樱粉
/// per user direction — Joy identity tokens now sakura across all surfaces.
/// Defined here (core/theme) rather than as `Color(0x…)` literals inside the
/// feature widget.
///
/// Ring → metric mapping (outer → inner):
///   - [highlights]   outer  · 小确幸 (highlights count) — 青瓷 teal (unchanged)
///   - [satisfaction] middle · 满足度 (avg satisfaction) — 柔绿 sage (unchanged)
///   - [target]       inner  · 悦己目标 (joy-target progress) — 樱粉 sakura pink;
///                    also the center 悦己指数 value tint; use [targetText] for the
///                    legible value label.
@immutable
class HappinessRingPalette {
  const HappinessRingPalette({
    required this.highlights,
    required this.satisfaction,
    required this.target,
    required this.targetText,
    required this.track,
  });

  final Color highlights;
  final Color satisfaction;
  final Color target;
  final Color targetText;
  final Color track;

  static const HappinessRingPalette light = HappinessRingPalette(
    highlights: Color(0xFF3BBDB8), // 青瓷 teal (unchanged)
    satisfaction: Color(0xFF97CA98), // 柔绿 sage (unchanged)
    target: Color(0xFFD98CA0), // 樱粉 sakura pink — joy identity
    targetText: Color(0xFFA53D5E), // deep rose — legible on light card
    track: Color(0xFFE9F0F0),
  );

  static const HappinessRingPalette dark = HappinessRingPalette(
    highlights: Color(0xFF4FD3CE),
    satisfaction: Color(0xFFAFDCA8),
    target: Color(0xFFE89BB0), // 樱粉 bright sakura — joy identity on dark
    targetText: Color(0xFFE89BB0), // reads well on dark surface
    track: Color(0xFF22343A),
  );

  static HappinessRingPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
