import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/alternate_category_chips.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  group('AlternateCategoryChips', () {
    CategoryMatchResult alt(String id, double c) => CategoryMatchResult(
      categoryId: id,
      confidence: c,
      source: MatchSource.merchant,
    );

    testWidgets('caps at 3 alternate chips + 1 exit chip (4 total) for 5 '
        'alternates (D-04)', (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: AlternateCategoryChips(
              alternates: [
                alt('category_food', 0.9),
                alt('category_transport', 0.8),
                alt('category_daily_goods', 0.7),
                alt('category_entertainment', 0.6),
                alt('category_medical', 0.5),
              ],
              selectedCategoryId: null,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      // 3 alternate chips + 1 exit chip.
      expect(find.byType(ActionChip), findsNWidgets(4));
    });

    testWidgets('tapping an alternate chip fires onSelect with that id', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: AlternateCategoryChips(
              alternates: [
                alt('category_food', 0.9),
                alt('category_transport', 0.8),
              ],
              selectedCategoryId: null,
              onSelect: (id) => selected = id,
            ),
          ),
        ),
      );

      // Tap the first alternate chip (food).
      await tester.tap(find.byKey(const ValueKey('alt-chip-category_food')));
      await tester.pump();

      expect(selected, 'category_food');
    });

    testWidgets('exit chip is present and labeled by the new ARB key '
        '(recognitionAlternatesMore)', (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: AlternateCategoryChips(
              alternates: [alt('category_food', 0.9)],
              selectedCategoryId: null,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('alt-chip-exit')), findsOneWidget);
      // 'More' is the en exit-chip ARB value.
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('renders no number/%/score on any chip (ADR-012)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: AlternateCategoryChips(
              alternates: [
                alt('category_food', 0.93),
                alt('category_transport', 0.81),
              ],
              selectedCategoryId: null,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      // No confidence figure leaks onto a chip — assert none of the raw
      // confidence values appear as text.
      expect(find.textContaining('0.9'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('93'), findsNothing);
    });

    testWidgets('empty alternates still renders only the exit chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: AlternateCategoryChips(
              alternates: const [],
              selectedCategoryId: null,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.byKey(const ValueKey('alt-chip-exit')), findsOneWidget);
    });
  });
}
