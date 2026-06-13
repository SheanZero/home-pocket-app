@Tags(['golden'])
library;

// Dot-key gating tests for SmartKeyboard (Phase 42, plan 42-05, D-06 / CURR-04).
//
// Locked behavior under test:
//   - onDot == null (0-decimal currency, e.g. JPY/KRW): the dot cell renders as
//     a disabled blank tile (no '.' glyph, no tap handler) while the extra row
//     keeps its 3-cell structure and the 48dp floor — no key shift.
//   - onDot != null (USD/EUR/CNY): the dot key shows '.' and fires its callback.
//   - 48dp NON-NEGOTIABLE floor (UI-SPEC Hard Invariant 2) holds on the gated
//     layout.
//
// Goldens are macOS-baselined; CI (ubuntu) uses BaselineExistenceGoldenComparator
// (test/flutter_test_config.dart).
//
// Run: flutter test test/features/accounting/presentation/widgets/smart_keyboard_dot_gating_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';

import '../../../../helpers/test_localizations.dart';

/// Builds a SmartKeyboard with a fixed surface so key height is deterministic.
Widget _wrap({
  required bool dotEnabled,
  VoidCallback? onDotTap,
  ThemeMode themeMode = ThemeMode.light,
}) {
  const surface = Size(390, 844);
  return createLocalizedWidget(
    Theme(
      data: themeMode == ThemeMode.dark ? ThemeData.dark() : ThemeData.light(),
      child: MediaQuery(
        data: const MediaQueryData(
          size: surface,
          padding: EdgeInsets.only(bottom: 34),
        ),
        child: Scaffold(
          body: SmartKeyboard(
            onDigit: (_) {},
            onDelete: () {},
            onNext: () {},
            onDoubleZero: () {},
            // D-06: null hides/disables the dot key for 0-decimal currencies.
            onDot: dotEnabled ? (onDotTap ?? () {}) : null,
            actionLabel: 'Record',
            currencyLabel: dotEnabled ? 'USD' : 'JPY',
            currencySymbol: dotEnabled ? r'$' : '¥',
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SmartKeyboard — dot gating (D-06)', () {
    testWidgets('onDot null: no "." glyph, disabled tile present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(dotEnabled: false));
      await tester.pumpAndSettle();

      // No dot glyph is rendered for a 0-decimal currency.
      expect(find.text('.'), findsNothing);
      // The disabled placeholder occupies the cell.
      expect(
        find.byKey(const ValueKey('smart_keyboard_dot_disabled')),
        findsOneWidget,
      );
    });

    testWidgets('onDot provided: "." glyph present and fires callback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var dotTaps = 0;
      await tester.pumpWidget(
        _wrap(dotEnabled: true, onDotTap: () => dotTaps++),
      );
      await tester.pumpAndSettle();

      expect(find.text('.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('smart_keyboard_dot_disabled')),
        findsNothing,
      );

      await tester.tap(find.text('.'));
      await tester.pumpAndSettle();
      expect(dotTaps, 1);
    });

    testWidgets('48dp floor preserved on the dot-gated (0-decimal) layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667); // iPhone SE — worst case
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(dotEnabled: false));
      await tester.pumpAndSettle();

      // The disabled dot tile must still meet the 48dp NON-NEGOTIABLE floor.
      final disabledSize = tester.getSize(
        find.byKey(const ValueKey('smart_keyboard_dot_disabled')),
      );
      expect(
        disabledSize.height,
        greaterThanOrEqualTo(48.0),
        reason: 'UI-SPEC Hard Invariant 2: 48dp floor on gated dot cell',
      );

      // Row keeps its 3-cell structure: '00', '0', and the disabled tile.
      expect(find.text('00'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('SmartKeyboard — dot gating golden (D-06)', () {
    testWidgets('JPY dot-gated (light)', (tester) async {
      await tester.pumpWidget(_wrap(dotEnabled: false));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('smart_keyboard_root')),
        matchesGoldenFile('goldens/smart_keyboard_dot_gated_jpy_light.png'),
      );
    });

    testWidgets('JPY dot-gated (dark)', (tester) async {
      await tester.pumpWidget(
        _wrap(dotEnabled: false, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('smart_keyboard_root')),
        matchesGoldenFile('goldens/smart_keyboard_dot_gated_jpy_dark.png'),
      );
    });

    testWidgets('USD dot-enabled (light)', (tester) async {
      await tester.pumpWidget(_wrap(dotEnabled: true));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('smart_keyboard_root')),
        matchesGoldenFile('goldens/smart_keyboard_dot_enabled_usd_light.png'),
      );
    });

    testWidgets('USD dot-enabled (dark)', (tester) async {
      await tester.pumpWidget(
        _wrap(dotEnabled: true, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('smart_keyboard_root')),
        matchesGoldenFile('goldens/smart_keyboard_dot_enabled_usd_dark.png'),
      );
    });
  });
}
