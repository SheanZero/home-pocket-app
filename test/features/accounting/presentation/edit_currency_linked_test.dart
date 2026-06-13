// CurrencyLinkedEditFields contract tests (Phase 42-09, updated quick 260613-mgc,
// generalized into the shared two-screen card quick 260613-ufn).
//
// As of quick 260613-mgc the in-card ORIGINAL-amount input row was REMOVED: the
// original amount is now edited from the screen's top headline keypad and
// injected here via the `originalAmount` prop. This card holds exactly TWO data
// rows now — an editable applied-rate field and a READ-ONLY derived JPY row.
//
// As of quick 260613-ufn the card is the SHARED card for BOTH the add and edit
// screens (D-1):
//   - The trailing clickable `edit_date_change_trigger` TextButton is REMOVED
//     (D-3). The 汇率日期 row is now a NON-CLICKABLE labeled row (key
//     `edit_rate_date`) showing the ACTUAL effective rate date (`actualRateDate`,
//     D-2).
//   - A pre-resolved weekend/holiday staleness note (`stalenessNote`) renders in
//     warning amber below the date row (key `edit_rate_staleness`) when non-null
//     (D-2). The host derives it from the RateResult (single staleness site).
//   - The date-change re-fetch (ADR-022 D-02 dialog / D-03 toast) logic is
//     RETAINED but is no longer wired to a tap — the host invokes it via the
//     public state method `triggerDateChangeRefetch()` after the date picker
//     changes (D-4).
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

import 'dart:async';

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
    DateTime? actualRateDate,
    String? stalenessNote,
    DateChangeRefetchRateSource? refetchRate,
    ValueChanged<CurrencyLinkedEditValue>? onChanged,
    ValueChanged<bool>? onAmountInvalid,
    Key? cardKey,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CurrencyLinkedEditFields(
              key: cardKey,
              originalCurrency: currency,
              originalAmount: originalAmount,
              appliedRate: rate,
              manualOverride: manualOverride,
              rateDate: rateDate ?? DateTime(2026, 6, 13),
              actualRateDate: actualRateDate,
              stalenessNote: stalenessNote,
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

      // Quick 260613-ufn (D-3): the clickable date-change TextButton is REMOVED.
      // The 汇率日期 row is a non-clickable labeled row showing the actual date.
      expect(
        find.byKey(const Key('edit_date_change_trigger')),
        findsNothing,
        reason: 'the clickable date-change TextButton is removed (ufn D-3)',
      );
      expect(
        find.byKey(const Key('edit_rate_date')),
        findsOneWidget,
        reason: 'a non-clickable labeled 汇率日期 row is present (ufn D-2/D-3)',
      );
      // The row (key on the Text itself) shows the formatted rate date
      // (en `06/13/2026`).
      expect(
        tester.widget<Text>(find.byKey(const Key('edit_rate_date'))).data,
        '06/13/2026',
        reason: 'rate date row shows DateFormatter(actualRateDate ?? rateDate)',
      );
      // The non-clickable row is not a TextButton.
      expect(
        find.ancestor(
          of: find.byKey(const Key('edit_rate_date')),
          matching: find.byType(TextButton),
        ),
        findsNothing,
        reason: 'the 汇率日期 row must not be tappable (ufn D-3)',
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

  group('quick 260613-ufn — 汇率日期 row shows actualRateDate + staleness', () {
    testWidgets(
      'actualRateDate overrides rateDate in the displayed 汇率日期 row (D-2)',
      (tester) async {
        await pumpHost(
          tester,
          currency: 'USD',
          originalAmount: 5000,
          rate: '148.30',
          manualOverride: false,
          rateDate: DateTime(2026, 6, 14), // requested (Sun)
          actualRateDate: DateTime(2026, 6, 12), // effective (Fri)
        );

        // The row shows the ACTUAL effective date (06/12/2026), not the
        // requested transaction date (06/14/2026).
        expect(
          tester.widget<Text>(find.byKey(const Key('edit_rate_date'))).data,
          '06/12/2026',
        );
      },
    );

    testWidgets('stalenessNote renders amber when non-null (D-2)', (
      tester,
    ) async {
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
        actualRateDate: DateTime(2026, 6, 12),
        stalenessNote: '06/12/2026 (most recent business day)',
      );

      final staleness = find.byKey(const Key('edit_rate_staleness'));
      expect(staleness, findsOneWidget);
      expect(
        tester.widget<Text>(staleness).data,
        '06/12/2026 (most recent business day)',
      );
    });

    testWidgets('staleness Text absent when stalenessNote is null', (
      tester,
    ) async {
      await pumpHost(
        tester,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
        // stalenessNote defaults to null.
      );

      expect(find.byKey(const Key('edit_rate_staleness')), findsNothing);
    });
  });

  group('ADR-022 D-02 — manual override + date change → two-choice dialog', () {
    testWidgets('shows a no-default two-choice dialog', (tester) async {
      final cardKey = GlobalKey<CurrencyLinkedEditFieldsState>();
      await pumpHost(
        tester,
        cardKey: cardKey,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: true,
        // Real-rate source resolves a fresh rate for the new date.
        refetchRate: () async => '160.00',
      );

      // Simulate a transaction-date change while a manual override is active —
      // the host invokes the retained logic via the public state method (ufn D-4).
      // Fire-and-forget: triggerDateChangeRefetch awaits the dialog's own future,
      // which never completes until the dialog is dismissed — awaiting it here
      // would deadlock pumpAndSettle. The host invokes it the same way.
      unawaited(cardKey.currentState!.triggerDateChangeRefetch());
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
      final cardKey = GlobalKey<CurrencyLinkedEditFieldsState>();
      await pumpHost(
        tester,
        cardKey: cardKey,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
        // Real-rate source returns 160.00 for the new date.
        refetchRate: () async => '160.00',
      );

      // Date change auto-refetches a rate that moves JPY by >1% (148.30→160.00:
      // 7415 → 8000, |8000-7415|/7415 ≈ 7.9% > 1%).
      await cardKey.currentState!.triggerDateChangeRefetch();
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
      final cardKey = GlobalKey<CurrencyLinkedEditFieldsState>();
      await pumpHost(
        tester,
        cardKey: cardKey,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: true, // would normally trigger the D-02 dialog
        refetchRate: null, // no source supplied
      );

      await cardKey.currentState!.triggerDateChangeRefetch();
      await tester.pumpAndSettle();

      // Degrades gracefully: nothing surfaces, the existing rate stays.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('7,415'), findsOneWidget);
    });

    testWidgets('source resolving null → no-op (RateUnavailable / offline)', (
      tester,
    ) async {
      final cardKey = GlobalKey<CurrencyLinkedEditFieldsState>();
      await pumpHost(
        tester,
        cardKey: cardKey,
        currency: 'USD',
        originalAmount: 5000,
        rate: '148.30',
        manualOverride: false,
        refetchRate: () async => null, // unavailable / offline
      );

      await cardKey.currentState!.triggerDateChangeRefetch();
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
