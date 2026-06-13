// WAVE 0 RED SCAFFOLD — Phase 42, producing plan 42-09 (edit-host currency fields).
//
// This file references CurrencyLinkedEditFields — a widget that DOES NOT EXIST
// yet. It is therefore EXPECTED to fail to compile (RED) until plan 42-09 adds
// the two-input/one-derived edit host to TransactionDetailsForm.
//
// Locked behavior under test (DISP-04 / ADR-022 D-01/D-02/D-03):
//   - D-01: JPY is a READ-ONLY derived value (convertToJpy of original × rate);
//           it is never a direct input — no bidirectional loop. Editing the
//           original amount OR the rate recomputes the displayed JPY.
//   - D-02: manual-override + date change → two-choice dialog with NO default
//           (「保留手动汇率」/「按新日期重取」).
//   - D-03: no-override + >1% JPY change (|newJpy-oldJpy|/oldJpy > 0.01) →
//           non-blocking toast with an Undo that restores the OLD rate (5s).
//
// The widget surface assumed here (to be ratified by plan 42-09):
//   CurrencyLinkedEditFields({
//     required String originalCurrency,
//     required int originalAmount,        // minor units
//     required String appliedRate,
//     required bool manualOverride,
//     ValueChanged<...>? onChanged,
//   })
//
// Do NOT weaken assertions to make them pass. RED is the intended state.
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
    DateChangeRefetchRateSource? refetchRate,
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
              dateChangeRefetchRate: refetchRate,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ADR-022 D-01 — JPY is read-only derived', () {
    testWidgets('JPY field is not editable (no TextField for JPY)', (
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

      // The derived JPY must be shown but NOT be an input — the host exposes
      // exactly two editable inputs (original amount + rate).
      final editable = find.byType(TextField);
      expect(
        editable,
        findsNWidgets(2),
        reason: 'only original amount + rate are editable; JPY is derived',
      );
      expect(find.textContaining('7,415'), findsOneWidget);
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
      expect(find.byKey(const Key('dialog_refetch_for_new_date')), findsOneWidget);
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
}
