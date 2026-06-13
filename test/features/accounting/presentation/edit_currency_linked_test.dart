// CurrencyLinkedEditFields contract tests (Phase 42-09, updated quick 260613-mgc).
//
// As of quick 260613-mgc the in-card ORIGINAL-amount input row was REMOVED: the
// original amount is now edited from the screen's top headline keypad and
// injected here via the `originalAmount` prop. This card holds exactly TWO rows
// now — an editable applied-rate field and a READ-ONLY derived JPY row.
//
// Locked behavior under test (DISP-04 / ADR-022 D-01/D-02/D-03):
//   - D-01: JPY is a READ-ONLY derived value (convertToJpy of original × rate);
//           it is never a direct input. Editing the rate OR re-pumping with a
//           new originalAmount prop recomputes the displayed JPY.
//   - D-02: manual-override + date change → two-choice dialog with NO default.
//   - D-03: no-override + >1% JPY change → non-blocking toast with an Undo that
//           restores the OLD rate (5s).
//
// See: docs/arch/03-adr/ADR-022_Edit_Semantics.md (D-01/D-02/D-03),
//      lib/shared/utils/currency_conversion.dart (convertToJpy — D-12 single site).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/currency_linked_edit_fields.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required String currency,
    required int originalAmount,
    required String rate,
    required bool manualOverride,
    DateTime? rateDate,
    DateChangeRefetchRateSource? refetchRate,
    ValueChanged<CurrencyLinkedEditValue>? onChanged,
    ValueChanged<bool>? onAmountInvalid,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CurrencyLinkedEditFields(
              originalCurrency: currency,
              originalAmount: originalAmount,
              appliedRate: rate,
              manualOverride: manualOverride,
              rateDate: rateDate ?? DateTime(2026, 6, 13),
              dateChangeRefetchRate: refetchRate,
              onChanged: onChanged,
              onAmountInvalid: onAmountInvalid,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ADR-022 D-01 — JPY is read-only derived; card has rate + JPY only', () {
    testWidgets('exactly one editable TextField (rate); JPY is derived text', (
      tester,
    ) async {
      // USD 50.00 @ 148.30 → 7415 JPY (read-only display).
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
      );

      // The original-amount input row is gone (quick 260613-mgc): only the rate
      // remains editable; JPY is a read-only derived Text.
      expect(
        find.byType(TextField),
        findsOneWidget,
        reason: 'only the applied-rate field is editable; JPY is derived',
      );
      expect(find.byKey(const Key('edit_rate_field')), findsOneWidget);
      expect(
        find.byKey(const Key('edit_original_amount_field')),
        findsNothing,
        reason: 'the in-card original-amount input was removed (260613-mgc)',
      );
      expect(find.textContaining('7,415'), findsOneWidget);

      // Quick 260613-n5c: the date-change trigger shows the FORMATTED actual
      // date (en `06/13/2026`), not the static word 「日期/Date」.
      expect(
        find.descendant(
          of: find.byKey(const Key('edit_date_change_trigger')),
          matching: find.text('06/13/2026'),
        ),
        findsOneWidget,
        reason: 'date-change trigger must show DateFormatter(rateDate) (n5c)',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('edit_date_change_trigger')),
          matching: find.text('Date'),
        ),
        findsNothing,
        reason: 'the static word Date must no longer appear (n5c)',
      );
    });

    testWidgets('changing the rate recomputes the read-only JPY (D-12)', (
      tester,
    ) async {
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
      );

      // Edit the rate to 150.00 → 5000/100 × 150.00 = 7500 JPY.
      final rateField = find.byKey(const Key('edit_rate_field'));
      await tester.enterText(rateField, '150.00');
      await tester.pumpAndSettle();

      expect(find.textContaining('7,500'), findsOneWidget);
    });

    testWidgets(
      're-pumping with a new originalAmount prop recomputes JPY (headline drives it)',
      (tester) async {
        await pumpHost(
          tester,
          currency: 'USD',
          originalAmount: 5000, // 50.00 USD → 7415 JPY
          rate: '148.30',
          manualOverride: false,
        );
        expect(find.textContaining('7,415'), findsOneWidget);

        // The headline keypad edited the original amount to 60.00 USD (6000
        // minor). The host re-pumps the card with the new prop.
        await pumpHost(
          tester,
          currency: 'USD',
          originalAmount: 6000, // 60.00 USD → 6000/100 × 148.30 = 8898 JPY
          rate: '148.30',
          manualOverride: false,
        );

        expect(find.textContaining('8,898'), findsOneWidget);
        expect(find.textContaining('7,415'), findsNothing);
      },
    );
  });

  group('ADR-022 D-02 — manual override + date change → two-choice dialog', () {
    testWidgets('shows a no-default two-choice dialog', (tester) async {
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: true,
        // Real-rate source resolves a fresh rate for the new date.
        refetchRate: () async => '160.00',
      );

      // Simulate a transaction-date change while a manual override is active.
      await tester.tap(find.byKey(const Key('edit_date_change_trigger')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byKey(const Key('dialog_keep_manual_rate')), findsOneWidget);
      expect(
        find.byKey(const Key('dialog_refetch_for_new_date')),
        findsOneWidget,
      );
    });
  });

  group('ADR-022 D-03 — no override + >1% change → non-blocking toast + Undo', () {
    testWidgets('shows toast with Undo that restores the old rate', (
      tester,
    ) async {
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
        // Real-rate source returns 160.00 for the new date.
        refetchRate: () async => '160.00',
      );

      // Date change auto-refetches a rate that moves JPY by >1% (148.30→160.00:
      // 7415 → 8000, |8000-7415|/7415 ≈ 7.9% > 1%).
      await tester.tap(find.byKey(const Key('edit_date_change_trigger')));
      await tester.pumpAndSettle();

      // Non-blocking: no dialog, a SnackBar toast with an Undo action.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);

      final undo = find.byKey(const Key('toast_undo_button'));
      expect(undo, findsOneWidget);
      await tester.tap(undo);
      await tester.pumpAndSettle();

      // Undo restores the OLD rate → JPY returns to 7415.
      expect(find.textContaining('7,415'), findsOneWidget);
    });
  });

  group('never-block-save — real re-fetch resolves no rate', () {
    testWidgets('null rate source → date change is a no-op (no dialog/toast)', (
      tester,
    ) async {
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: true, // would normally trigger the D-02 dialog
        refetchRate: null, // no source supplied
      );

      await tester.tap(find.byKey(const Key('edit_date_change_trigger')));
      await tester.pumpAndSettle();

      // Degrades gracefully: nothing surfaces, the existing rate stays.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('7,415'), findsOneWidget);
    });

    testWidgets('source resolving null → no-op (RateUnavailable / offline)', (
      tester,
    ) async {
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
        refetchRate: () async => null, // unavailable / offline
      );

      await tester.tap(find.byKey(const Key('edit_date_change_trigger')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('7,415'), findsOneWidget);
    });
  });

  // ── Seed presentation: JPY row reflects the injected original × rate ───────
  group('derived JPY row reflects the injected original amount', () {
    testWidgets('USD seed 5000 minor @ 148.30 → 7,415 JPY', (tester) async {
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
      );

      expect(find.textContaining('7,415'), findsOneWidget);
    });

    testWidgets('JPY seed 5000 minor @ 1 → 5,000 JPY (0-decimal)', (
      tester,
    ) async {
      await pumpHost(
        tester,
        currency: 'JPY',
        originalAmount: 5000, // JPY has no sub-unit: minor == major
        rate: '1',
        manualOverride: false,
      );

      expect(find.textContaining('5,000'), findsOneWidget);
    });
  });

  // ── WR-06: a cleared/non-positive injected amount degrades JPY to em-dash ──
  group('WR-06 — non-positive injected amount → JPY em-dash + onAmountInvalid', () {
    testWidgets('re-pumping originalAmount 0 → JPY shows the em-dash', (
      tester,
    ) async {
      final invalidEvents = <bool>[];
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
        onAmountInvalid: invalidEvents.add,
      );
      expect(find.textContaining('7,415'), findsOneWidget);

      // The headline cleared the amount to 0 → host re-pumps with 0.
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 0,
        rate: '148.30',
        manualOverride: false,
        onAmountInvalid: invalidEvents.add,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('—'), findsOneWidget);
      expect(
        invalidEvents.contains(true),
        isTrue,
        reason: 'a non-positive injected amount must report invalid (WR-06)',
      );
    });
  });
}
