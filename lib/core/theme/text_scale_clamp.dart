import 'package:flutter/material.dart';

/// Maximum textScaler factor honored app-wide.
///
/// iOS Dynamic Type (and Android font-size) can scale text up to ~3.1x at the
/// largest accessibility sizes, which overflows the home screen's fixed
/// horizontal Rows — most visibly the ときめき/日常 split bar in
/// `home_hero_card.dart`. We still honor the user's font-size preference, but
/// cap the multiplier so the layout stays intact.
///
/// Ceiling chosen via the four-way preview comparison in quick 260604-fyd
/// (1.0 / 1.15 / 1.20 / 1.30) — user selected 1.2.
const double kMaxTextScaleFactor = 1.2;

/// A `MaterialApp.builder` that clamps the inherited [MediaQuery] textScaler to
/// at most [kMaxTextScaleFactor].
///
/// MaterialApp passes a null [child] only before its navigator subtree is
/// ready; we fall back to an empty box so the builder never throws.
Widget clampTextScaling(BuildContext context, Widget? child) {
  return MediaQuery.withClampedTextScaling(
    maxScaleFactor: kMaxTextScaleFactor,
    child: child ?? const SizedBox.shrink(),
  );
}
