import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';

/// Unit test for AppPalette ThemeExtension — ADR-019 hex contract.
///
/// This test file is the machine-readable specification for which ADR-019 hex
/// values app_palette.dart must encode. All expected Color values are sourced
/// directly from ADR-019's "逐角色 Hex 表" (Light / Dark columns).
///
/// ADR-019 Sakura Mochi × Wakaba replaces ADR-018 Teal Clarity.
///
/// Run: flutter test test/core/theme/app_palette_test.dart

void main() {
  group('AppPalette.light — ADR-019 contract', () {
    test('background is warm cream #FBF7F4', () {
      expect(AppPalette.light.background, const Color(0xFFFBF7F4));
    });

    test('accentPrimary is leaf green #6FA36F (not teal)', () {
      expect(AppPalette.light.accentPrimary, const Color(0xFF6FA36F));
    });

    test('daily is leaf-green #5FAE72', () {
      expect(AppPalette.light.daily, const Color(0xFF5FAE72));
    });

    test('joy is 桜餅 Amber #C8841A (quick soqks, Mauve removed)', () {
      expect(AppPalette.light.joy, const Color(0xFFC8841A));
    });

    test('dailyText (WCAG amount) is #2E6B3A', () {
      expect(AppPalette.light.dailyText, const Color(0xFF2E6B3A));
    });

    test('joyText (WCAG amount) is #A15C00 (deep amber ≥4.5:1 on #FFF)', () {
      expect(AppPalette.light.joyText, const Color(0xFFA15C00));
    });

    test('success is emerald #2FA37A (unchanged from ADR-018)', () {
      expect(AppPalette.light.success, const Color(0xFF2FA37A));
    });

    test('error is #E5484D (red — semantic only, not brand)', () {
      expect(AppPalette.light.error, const Color(0xFFE5484D));
    });
  });

  group('AppPalette.dark — ADR-019 contract', () {
    test('background is warm-dark #171210', () {
      expect(AppPalette.dark.background, const Color(0xFF171210));
    });

    test('accentPrimary is bright leaf green #8DC68D on dark', () {
      expect(AppPalette.dark.accentPrimary, const Color(0xFF8DC68D));
    });

    test('daily is #7DC88D (bright leaf on dark)', () {
      expect(AppPalette.dark.daily, const Color(0xFF7DC88D));
    });

    test('joy is #E0A040 (bright amber on dark — Mauve removed)', () {
      expect(AppPalette.dark.joy, const Color(0xFFE0A040));
    });

    test('textPrimary is #F0EBE6 (warm near-white on dark background)', () {
      expect(AppPalette.dark.textPrimary, const Color(0xFFF0EBE6));
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
