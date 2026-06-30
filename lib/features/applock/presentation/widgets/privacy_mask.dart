import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// Full-bleed OPAQUE privacy cover shown over the app while it is backgrounded
/// or inactive (sketch 002 tone B, D-07 / LOCK-04 / T-55-18).
///
/// It is a solid theme-following [AppPaletteContext.palette] surface with a
/// centered brand mark — deliberately an opaque [Container], NOT a blur filter.
/// A blur can leak ledger content in some OS app-switcher snapshot timings
/// (RESEARCH §5), so the mask paints an opaque colour that reveals nothing
/// underneath. The
/// host (Plan 11, `main.dart` via a synchronous `ValueNotifier<bool>`) toggles
/// it; this widget holds no state and shows no text.
class PrivacyMask extends StatelessWidget {
  const PrivacyMask({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      // Opaque, full-bleed — nothing behind it can show through.
      color: palette.background,
      alignment: Alignment.center,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: palette.borderDefault),
        ),
        child: Icon(
          Icons.lock_rounded,
          size: 44,
          color: palette.accentPrimary,
        ),
      ),
    );
  }
}
