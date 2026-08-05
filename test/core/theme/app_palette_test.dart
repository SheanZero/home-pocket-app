import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';

/// Unit test for AppPalette ThemeExtension — V15 warm-Japanese contract.
///
/// This test file is the machine-readable specification for the approved V15
/// light palette. The daily and Joy ledger colors remain unchanged.
///
/// Run: flutter test test/core/theme/app_palette_test.dart

void main() {
  group('AppPalette.light — V15 contract', () {
    test('background is warm beige #F5F0E7', () {
      expect(AppPalette.light.background, const Color(0xFFF5F0E7));
    });

    test('card is paper white #FFFDF8', () {
      expect(AppPalette.light.card, const Color(0xFFFFFDF8));
    });

    test('accentPrimary is V15 deep green #456B59', () {
      expect(AppPalette.light.accentPrimary, const Color(0xFF456B59));
      expect(AppPalette.light.accentPrimaryText, const Color(0xFF456B59));
      expect(
        AppPalette.light.primaryActionForeground,
        const Color(0xFFFFFFFF),
      );
    });

    test('shared and info use the V15 information blue #4F7186', () {
      expect(AppPalette.light.shared, const Color(0xFF4F7186));
      expect(AppPalette.light.info, const Color(0xFF4F7186));
    });

    test('daily is leaf-green #5FAE72', () {
      expect(AppPalette.light.daily, const Color(0xFF5FAE72));
    });

    test(
      'joy is 樱粉 Sakura Pink #D98CA0 (quick 260603-lr5b, Amber → Sakura)',
      () {
        expect(AppPalette.light.joy, const Color(0xFFD98CA0));
      },
    );

    test('dailyText (WCAG amount) is #2E6B3A', () {
      expect(AppPalette.light.dailyText, const Color(0xFF2E6B3A));
    });

    test('joyText (WCAG amount) is #A53D5E (deep rose ≥4.5:1 on #FFF)', () {
      expect(AppPalette.light.joyText, const Color(0xFFA53D5E));
    });

    test('success uses V15 muted green #4F826A', () {
      expect(AppPalette.light.success, const Color(0xFF4F826A));
    });

    test('error uses V15 muted red #B64F4F', () {
      expect(AppPalette.light.error, const Color(0xFFB64F4F));
    });
  });

  group('AppPalette.dark — Mockup V16 A3 contract', () {
    test('surfaces match the A3 ink-green hierarchy', () {
      expect(AppPalette.dark.background, const Color(0xFF171C19));
      expect(AppPalette.dark.card, const Color(0xFF222923));
      expect(AppPalette.dark.backgroundMuted, const Color(0xFF2B342D));
      expect(AppPalette.dark.backgroundDivider, const Color(0xFF354038));
    });

    test('text and borders match the A3 hierarchy', () {
      expect(AppPalette.dark.textPrimary, const Color(0xFFEEF1EB));
      expect(AppPalette.dark.textSecondary, const Color(0xFFA1ADA4));
      expect(AppPalette.dark.textTertiary, const Color(0xFF8B978E));
      expect(AppPalette.dark.borderDefault, const Color(0xFF354038));
      expect(AppPalette.dark.borderList, const Color(0xFF465248));
    });

    test('primary and ledger families match A3', () {
      expect(AppPalette.dark.accentPrimary, const Color(0xFF99BCA5));
      expect(AppPalette.dark.accentPrimaryText, const Color(0xFFB4D2BC));
      expect(AppPalette.dark.accentPrimaryLight, const Color(0xFF293B30));
      expect(
        AppPalette.dark.primaryActionForeground,
        const Color(0xFF222923),
      );
      expect(AppPalette.dark.daily, const Color(0xFF7DC88D));
      expect(AppPalette.dark.dailyLight, const Color(0xFF1A2E1A));
      expect(AppPalette.dark.joy, const Color(0xFFE89BB0));
      expect(AppPalette.dark.joyLight, const Color(0xFF2E1820));
      expect(AppPalette.dark.shared, const Color(0xFF91ADC2));
      expect(AppPalette.dark.sharedText, const Color(0xFFAAC4D7));
      expect(AppPalette.dark.sharedLight, const Color(0xFF263640));
    });

    test('semantic colors match A3', () {
      expect(AppPalette.dark.success, const Color(0xFF89B49C));
      expect(AppPalette.dark.warning, const Color(0xFFD3A571));
      expect(AppPalette.dark.error, const Color(0xFFE58C8C));
      expect(AppPalette.dark.info, const Color(0xFF8CB1C8));
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
