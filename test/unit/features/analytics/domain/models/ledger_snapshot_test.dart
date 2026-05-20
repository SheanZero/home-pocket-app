import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';

void main() {
  group('SoulLedgerSnapshot (Freezed value semantics)', () {
    test('two snapshots with identical fields are == and share hashCode', () {
      const a = SoulLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );
      const b = SoulLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('snapshot is immutable: copyWith returns a fresh instance', () {
      const original = SoulLedgerSnapshot(
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

  group('SurvivalLedgerSnapshot (Freezed value semantics)', () {
    test('two snapshots with identical fields are == and share hashCode', () {
      const a = SurvivalLedgerSnapshot(entryCount: 10, totalSpend: 45000);
      const b = SurvivalLedgerSnapshot(entryCount: 10, totalSpend: 45000);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test(
      'D-04 type-system gate: SurvivalLedgerSnapshot.toString() MUST NOT '
      "expose the 'avgSatisfaction' field name — the field literally cannot "
      'exist (compile-time gate). transactions.soul_satisfaction defaults to '
      '2 and the picker only renders for soul-ledger entries (ADR-014 D-10), '
      'so AVG over survival rows is default-2-dominated and reads as '
      '"survival = always neutral/unhappy". Adding avgSatisfaction here is '
      'the regression mode this gate prevents.',
      () {
        const survival = SurvivalLedgerSnapshot(
          entryCount: 10,
          totalSpend: 45000,
        );

        expect(survival.toString(), isNot(contains('avgSatisfaction')));
      },
    );
  });

  group('SoulVsSurvivalSnapshot composition', () {
    test('solo-mode construction: family fields are null', () {
      const soul = SoulLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );
      const survival = SurvivalLedgerSnapshot(
        entryCount: 10,
        totalSpend: 45000,
      );

      const snapshot = SoulVsSurvivalSnapshot(soul: soul, survival: survival);

      expect(snapshot.soul, soul);
      expect(snapshot.survival, survival);
      expect(snapshot.familySoul, isNull);
      expect(snapshot.familySurvival, isNull);
    });

    test('group-mode construction: all four sub-snapshots populated', () {
      const soul = SoulLedgerSnapshot(
        entryCount: 4,
        totalSpend: 12000,
        avgSatisfaction: 7.5,
      );
      const survival = SurvivalLedgerSnapshot(
        entryCount: 10,
        totalSpend: 45000,
      );
      const familySoul = SoulLedgerSnapshot(
        entryCount: 12,
        totalSpend: 36000,
        avgSatisfaction: 8.1,
      );
      const familySurvival = SurvivalLedgerSnapshot(
        entryCount: 32,
        totalSpend: 140000,
      );

      const snapshot = SoulVsSurvivalSnapshot(
        soul: soul,
        survival: survival,
        familySoul: familySoul,
        familySurvival: familySurvival,
      );

      expect(snapshot.soul, soul);
      expect(snapshot.survival, survival);
      expect(snapshot.familySoul, familySoul);
      expect(snapshot.familySurvival, familySurvival);
    });

    test('copyWith clears family fields back to solo mode', () {
      const snapshot = SoulVsSurvivalSnapshot(
        soul: SoulLedgerSnapshot(
          entryCount: 4,
          totalSpend: 12000,
          avgSatisfaction: 7.5,
        ),
        survival: SurvivalLedgerSnapshot(entryCount: 10, totalSpend: 45000),
        familySoul: SoulLedgerSnapshot(
          entryCount: 12,
          totalSpend: 36000,
          avgSatisfaction: 8.1,
        ),
        familySurvival: SurvivalLedgerSnapshot(
          entryCount: 32,
          totalSpend: 140000,
        ),
      );

      final cleared = snapshot.copyWith(
        familySoul: null,
        familySurvival: null,
      );

      expect(cleared.familySoul, isNull);
      expect(cleared.familySurvival, isNull);
      expect(cleared.soul, snapshot.soul);
      expect(cleared.survival, snapshot.survival);
    });
  });
}
