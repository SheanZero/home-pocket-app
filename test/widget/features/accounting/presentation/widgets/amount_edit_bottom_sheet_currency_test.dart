/// Quick task 260613-mgc — Task 1: AmountEditBottomSheet gains an optional
/// currency-aware (major-unit decimal) mode so a foreign edit row can reuse the
/// EXISTING keypad sheet (SmartKeyboard) to edit the ORIGINAL amount.
///
/// Locked behavior:
///   - JPY default mode (no currency / 'JPY'): byte-identical — initialAmount is
///     an integer, onConfirm returns parsed.round() integer JPY. (Covered by the
///     OCR/Voice/edit-JPY suites; this file only adds the foreign-mode contract.)
///   - Foreign mode (currency='USD', initialAmount = minor units 11290):
///       * initial editStr is the MAJOR-unit decimal string "112.90"
///       * the displayed badge shows the supplied symbol/label ($ / USD)
///       * confirming returns the value back in MINOR units (round-trip 11290)
///       * typing a new major value converts via subunitToUnitFor on confirm
///       * decimal cap = currencyFractionDigitsFor(currency)
///   - 0-decimal foreign currency (KRW): the dot key is disabled (onDot null).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  String displayText(WidgetTester tester) {
    // AmountDisplay renders the (formatted) current editStr in a Text widget;
    // the badge holds symbol + label. Read the AmountDisplay's `amount` prop.
    final display = tester.widget<AmountDisplay>(find.byType(AmountDisplay));
    return display.amount;
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    required int initialAmount,
    String? currency,
    String currencySymbol = r'$',
    String currencyLabel = 'USD',
    required ValueChanged<int> onConfirm,
  }) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        AmountEditBottomSheet(
          initialAmount: initialAmount,
          currency: currency,
          currencySymbol: currencySymbol,
          currencyLabel: currencyLabel,
          onConfirm: onConfirm,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AmountEditBottomSheet — currency-aware (foreign) mode', () {
    testWidgets(
      'USD 11290 minor seeds the major-unit string "112.90"',
      (tester) async {
        await pumpSheet(
          tester,
          initialAmount: 11290,
          currency: 'USD',
          onConfirm: (_) {},
        );

        expect(displayText(tester), '112.90');
        // Badge shows the supplied symbol + label. The label also appears in
        // the SmartKeyboard currency cell, so assert presence (findsWidgets).
        expect(find.text(r'$'), findsWidgets);
        expect(find.text('USD'), findsWidgets);
        // Scoped check: the AmountDisplay badge carries the USD label.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('amount_currency_badge')),
            matching: find.text('USD'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'confirming the unchanged seed round-trips back to MINOR units (11290)',
      (tester) async {
        int? confirmed;
        await pumpSheet(
          tester,
          initialAmount: 11290,
          currency: 'USD',
          onConfirm: (v) => confirmed = v,
        );

        // Tap the Confirm action key without editing.
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(
          confirmed,
          11290,
          reason: '112.90 major USD → 11290 minor units (round-trip)',
        );
      },
    );

    testWidgets(
      'typing a fresh major value converts to MINOR units on confirm',
      (tester) async {
        int? confirmed;
        await pumpSheet(
          tester,
          initialAmount: 11290,
          currency: 'USD',
          onConfirm: (v) => confirmed = v,
        );

        // Clear and type "200" → 200.00 USD → 20000 minor.
        // The keypad backspaces the seed, then we type digits.
        final keyboard = find.byType(SmartKeyboard);
        expect(keyboard, findsOneWidget);

        // Delete all 5 chars of "112.90".
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byIcon(Icons.backspace_outlined));
          await tester.pump();
        }
        await tester.tap(find.widgetWithText(InkWell, '2').first);
        await tester.pump();
        await tester.tap(find.widgetWithText(InkWell, '0').first);
        await tester.pump();
        await tester.tap(find.widgetWithText(InkWell, '0').first);
        await tester.pump();

        expect(displayText(tester), '200');

        // Confirm via the Confirm label.
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(confirmed, 20000, reason: '200 USD major → 20000 minor units');
      },
    );

    testWidgets(
      'KRW (0-decimal) disables the dot key in foreign mode',
      (tester) async {
        await pumpSheet(
          tester,
          initialAmount: 5000,
          currency: 'KRW',
          currencySymbol: '₩',
          currencyLabel: 'KRW',
          onConfirm: (_) {},
        );

        // The disabled dot tile is rendered (no '.' digit key).
        expect(
          find.byKey(const ValueKey('smart_keyboard_dot_disabled')),
          findsOneWidget,
        );
        expect(find.widgetWithText(InkWell, '.'), findsNothing);
      },
    );
  });

  group('AmountEditBottomSheet — JPY default mode is unchanged', () {
    testWidgets('no currency: editStr is the integer string, badge is ¥ JPY', (
      tester,
    ) async {
      int? confirmed;
      await tester.pumpWidget(
        createLocalizedWidget(
          AmountEditBottomSheet(
            initialAmount: 3280,
            onConfirm: (v) => confirmed = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(displayText(tester), '3280');
      expect(find.text('¥'), findsWidgets);
      // 'JPY' also appears in the SmartKeyboard currency cell — assert presence
      // and that the AmountDisplay badge specifically carries it.
      expect(find.text('JPY'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('amount_currency_badge')),
          matching: find.text('JPY'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();
      expect(confirmed, 3280, reason: 'JPY mode returns the integer unchanged');
    });
  });
}
