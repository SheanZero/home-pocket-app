import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';

/// Unit test for AppPalette ThemeExtension — ADR-018 hex contract.
///
/// This test file is the machine-readable specification for which ADR-018 hex
/// values app_palette.dart must encode. All expected Color values are sourced
/// directly from ADR-018's "逐角色 Hex 表" (Light / Dark columns).
///
/// Expected state:
///   BEFORE Plan 33-02 creates app_palette.dart → FAILS (compile error)
///   AFTER  Plan 33-02 lands                    → PASSES
///
/// Run: flutter test test/core/theme/app_palette_test.dart

void main() {
  group('AppPalette.light — ADR-018 contract', () {
    test('background matches ADR-018 light #F8FCFD', () {
      expect(AppPalette.light.background, const Color(0xFFF8FCFD));
    });

    test('accentPrimary is teal #0E9AA7 (not coral)', () {
      expect(AppPalette.light.accentPrimary, const Color(0xFF0E9AA7));
    });

    test('daily is teal-navy #1C7A86', () {
      expect(AppPalette.light.daily, const Color(0xFF1C7A86));
    });

    test('joy is warm gold #F0A81E', () {
      expect(AppPalette.light.joy, const Color(0xFFF0A81E));
    });

    test('dailyText (WCAG amount) is #145E68', () {
      expect(AppPalette.light.dailyText, const Color(0xFF145E68));
    });

    test('joyText (WCAG amount) is #9A6500', () {
      expect(AppPalette.light.joyText, const Color(0xFF9A6500));
    });

    test('success is emerald #2FA37A', () {
      expect(AppPalette.light.success, const Color(0xFF2FA37A));
    });

    test('error is #E5484D (red — semantic only, not brand)', () {
      expect(AppPalette.light.error, const Color(0xFFE5484D));
    });
  });

  group('AppPalette.dark — ADR-018 contract', () {
    test('background matches ADR-018 dark #0C1719', () {
      expect(AppPalette.dark.background, const Color(0xFF0C1719));
    });

    test('accentPrimary is brightened teal #3FC2CE', () {
      expect(AppPalette.dark.accentPrimary, const Color(0xFF3FC2CE));
    });

    test('daily is #4FB0BC (brightened teal-navy)', () {
      expect(AppPalette.dark.daily, const Color(0xFF4FB0BC));
    });

    test('joy is #F0C13A (brightened gold)', () {
      expect(AppPalette.dark.joy, const Color(0xFFF0C13A));
    });

    test('textPrimary is #E8F2F3 (light text on dark background)', () {
      // Also used by scattered_emoji_background.dart (D-07 dark adaptation)
      expect(AppPalette.dark.textPrimary, const Color(0xFFE8F2F3));
    });
  });

  group('AppPalette copyWith', () {
    test('returns new instance with overridden card field', () {
      final modified = AppPalette.light.copyWith(card: const Color(0xFF000000));
      expect(modified.card, const Color(0xFF000000));
      // background remains unchanged
      expect(modified.background, AppPalette.light.background);
    });

    test('returns identical values when no overrides given', () {
      final copy = AppPalette.light.copyWith();
      expect(copy.accentPrimary, AppPalette.light.accentPrimary);
      expect(copy.daily, AppPalette.light.daily);
    });
  });

  group('AppPalette lerp', () {
    test('at t=0.0 returns light instance background', () {
      final result = AppPalette.light.lerp(AppPalette.dark, 0.0);
      expect(result.background, AppPalette.light.background);
    });

    test('at t=1.0 returns dark instance background', () {
      final result = AppPalette.light.lerp(AppPalette.dark, 1.0);
      expect(result.background, AppPalette.dark.background);
    });
  });
}
