import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';

void main() {
  group('JoyLedgerSnapshot (Freezed value semantics)', () {
    test('two snapshots with identical fields are == and share hashCode', () {
      const a = JoyLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );
      const b = JoyLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('snapshot is immutable: copyWith returns a fresh instance', () {
      const original = JoyLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );

      final copied = original.copyWith(avgSatisfaction: 8.0);

      expect(copied.avgSatisfaction, 8.0);
      expect(original.avgSatisfaction, 7.5);
      expect(identical(copied, original), isFalse);
    });
  });

  group('DailyLedgerSnapshot (Freezed value semantics)', () {
    test('two snapshots with identical fields are == and share hashCode', () {
      const a = DailyLedgerSnapshot(entryCount: 10, totalSpend: 45000);
      const b = DailyLedgerSnapshot(entryCount: 10, totalSpend: 45000);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test(
      'D-04 type-system gate: DailyLedgerSnapshot.toString() MUST NOT '
      "expose the 'avgSatisfaction' field name — the field literally cannot "
      'exist (compile-time gate). transactions.joy_fullness defaults to '
      '2 and the picker only renders for joy-ledger entries (ADR-014 D-10), '
      'so AVG over daily rows is default-2-dominated and reads as '
      '"daily = always neutral/unhappy". Adding avgSatisfaction here is '
      'the regression mode this gate prevents.',
      () {
        const daily = DailyLedgerSnapshot(
          entryCount: 10,
          totalSpend: 45000,
        );

        expect(daily.toString(), isNot(contains('avgSatisfaction')));
      },
    );
  });

  group('DailyVsJoySnapshot composition', () {
    test('solo-mode construction: family fields are null', () {
      const joy = JoyLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );
      const daily = DailyLedgerSnapshot(
        entryCount: 10,
        totalSpend: 45000,
      );

      const snapshot = DailyVsJoySnapshot(joy: joy, daily: daily);

      expect(snapshot.joy, joy);
      expect(snapshot.daily, daily);
      expect(snapshot.familyJoy, isNull);
      expect(snapshot.familyDaily, isNull);
    });

    test('group-mode construction: all four sub-snapshots populated', () {
      const joy = JoyLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );
      const daily = DailyLedgerSnapshot(
        entryCount: 10,
        totalSpend: 45000,
      );
      const familyJoy = JoyLedgerSnapshot(
        entryCount: 12,
        totalSpend: 36000,
        avgSatisfaction: 8.1,
      );
      const familyDaily = DailyLedgerSnapshot(
        entryCount: 32,
        totalSpend: 140000,
      );

      const snapshot = DailyVsJoySnapshot(
        joy: joy,
        daily: daily,
        familyJoy: familyJoy,
        familyDaily: familyDaily,
      );

      expect(snapshot.joy, joy);
      expect(snapshot.daily, daily);
      expect(snapshot.familyJoy, familyJoy);
      expect(snapshot.familyDaily, familyDaily);
    });

    test('copyWith clears family fields back to solo mode', () {
      const snapshot = DailyVsJoySnapshot(
        joy: JoyLedgerSnapshot(
          entryCount: 4,
          totalSpend: 12000,
          avgSatisfaction: 7.5,
        ),
        daily: DailyLedgerSnapshot(entryCount: 10, totalSpend: 45000),
        familyJoy: JoyLedgerSnapshot(
          entryCount: 12,
          totalSpend: 36000,
          avgSatisfaction: 8.1,
        ),
        familyDaily: DailyLedgerSnapshot(
          entryCount: 32,
          totalSpend: 140000,
        ),
      );

      final cleared = snapshot.copyWith(
        familyJoy: null,
        familyDaily: null,
      );

      expect(cleared.familyJoy, isNull);
      expect(cleared.familyDaily, isNull);
      expect(cleared.joy, snapshot.joy);
      expect(cleared.daily, snapshot.daily);
    });
  });
}
