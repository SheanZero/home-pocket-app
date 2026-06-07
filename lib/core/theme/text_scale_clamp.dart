import 'package:flutter/material.dart';

/// The single textScaler factor the UI renders at, app-wide.
///
/// iOS Dynamic Type (and Android font-size) can scale text up to ~3.1x at the
/// largest accessibility sizes, which overflows the home screen's fixed
/// horizontal Rows — most visibly the ときめき/日常 split bar in
/// `home_hero_card.dart`.
///
/// Decision history (quick 260604-fyd → follow-up 260607):
/// - A four-way preview (1.0 / 1.15 / 1.20 / 1.30) first landed a 1.2 ceiling.
/// - User then chose to LOCK scaling at 1.0 for now ("先不放大"), so the layout
///   always renders at design size regardless of the system font-size setting.
///
/// To re-enable scaling later, raise [kLockedTextScaleFactor] (or split it back
/// into separate min/max factors).
const double kLockedTextScaleFactor = 1.0;

/// A `MaterialApp.builder` that pins the inherited [MediaQuery] textScaler to
/// exactly [kLockedTextScaleFactor], ignoring the system font-size setting.
///
/// MaterialApp passes a null [child] only before its navigator subtree is
/// ready; we fall back to an empty box so the builder never throws.
Widget clampTextScaling(BuildContext context, Widget? child) {
  return MediaQuery.withClampedTextScaling(
    minScaleFactor: kLockedTextScaleFactor,
    maxScaleFactor: kLockedTextScaleFactor,
    child: child ?? const SizedBox.shrink(),
  );
}
