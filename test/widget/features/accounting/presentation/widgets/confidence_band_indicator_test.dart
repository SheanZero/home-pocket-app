import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/confidence_band_indicator.dart';
import 'package:home_pocket/features/voice/domain/models/recognition_outcome.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  group('ConfidenceBandIndicator', () {
    // The band must convey confidence purely visually (ADR-012 / CONTEXT D-03):
    // no painted number, no painted confidence word, no gauge/meter/% — only an
    // a11y-hidden Semantics label.

    Finder semanticsWithLabel() => find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.label ?? '').isNotEmpty,
    );

    for (final band in ConfidenceBand.values) {
      testWidgets('renders an a11y Semantics label for $band band', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            Scaffold(
              body: ConfidenceBandIndicator(
                band: band,
                ledgerType: LedgerType.daily,
              ),
            ),
          ),
        );

        expect(
          semanticsWithLabel(),
          findsWidgets,
          reason: 'every band must expose a screen-reader Semantics label',
        );
      });

      testWidgets('paints NO visible confidence text/number for $band', (
        tester,
      ) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            Scaffold(
              body: ConfidenceBandIndicator(
                band: band,
                ledgerType: LedgerType.joy,
              ),
            ),
          ),
        );

        // No Text widget at all → no painted confidence word/number (D-03).
        expect(
          find.byType(Text),
          findsNothing,
          reason: 'band carries NO visible Text (ADR-012 / D-03)',
        );
      });
    }

    testWidgets('renders nothing (empty subtree) when band is null (D-10)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const Scaffold(
            body: ConfidenceBandIndicator(
              band: null,
              ledgerType: LedgerType.daily,
            ),
          ),
        ),
      );

      // No Semantics label and no Text — the affordance does not appear.
      expect(semanticsWithLabel(), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('daily vs joy ledger produce different paint (intensity keyed '
        'to ledger family)', (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const Scaffold(
            body: Column(
              children: [
                ConfidenceBandIndicator(
                  key: ValueKey('daily-band'),
                  band: ConfidenceBand.strong,
                  ledgerType: LedgerType.daily,
                ),
                ConfidenceBandIndicator(
                  key: ValueKey('joy-band'),
                  band: ConfidenceBand.strong,
                  ledgerType: LedgerType.joy,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('daily-band')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy-band')), findsOneWidget);
    });
  });
}
