import 'package:flutter/material.dart';

/// Color set for the HomeHeroCard 「悦己充盈」 happiness rings (single mode).
///
/// v1.5 ring redesign — **COMET SWEEP + "Butter" scheme** (青瓷 / 薰衣草 / 奶油黄).
/// The three rings show three INDEPENDENT joy metrics (NOT proportions of a
/// whole), so colors are chosen for hue + lightness separation (colorblind
/// safe) and deliberately avoid the red family to stay on-brand with the
/// Teal Clarity palette. Defined here (core/theme) rather than as `Color(0x…)`
/// literals inside the feature widget.
///
/// Ring → metric mapping (outer → inner):
///   - [highlights]   outer  · 小确幸 (highlights count)
///   - [satisfaction] middle · 满足度 (avg satisfaction)
///   - [target]       inner  · 悦己目标 (joy-target progress) — also the
///                    center 悦己指数 value tint; use [targetText] for the
///                    legible value label since [target] (butter) is light.
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
    highlights: Color(0xFF3BBDB8), // 青瓷 teal
    satisfaction: Color(0xFF97CA98), // 柔绿 sage
    target: Color(0xFFF2D777), // 奶油黄 butter
    targetText: Color(0xFF8A7320), // deepened butter — legible on light card
    track: Color(0xFFE9F0F0),
  );

  static const HappinessRingPalette dark = HappinessRingPalette(
    highlights: Color(0xFF4FD3CE),
    satisfaction: Color(0xFFAFDCA8),
    target: Color(0xFFF7E08C),
    targetText: Color(0xFFF7E08C), // butter reads well on dark surface
    track: Color(0xFF22343A),
  );

  static HappinessRingPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
