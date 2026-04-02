import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';

void main() {
  group('HomeTransactionTile', () {
    testWidgets('displays merchant, category, and formatted amount', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              tagText: '\u751f',
              tagBgColor: Color(0xFFE8F0F8),
              tagTextColor: Color(0xFF5A9CC8),
              merchant: '\u30a4\u30aa\u30f3\u30b9\u30fc\u30d1\u30fc',
              category: '\u98df\u8cbb \u00b7 \u751f\u5b58',
              categoryColor: Color(0xFFABABAB),
              formattedAmount: '-\u00a53,280',
              amountColor: Color(0xFF1E2432),
            ),
          ),
        ),
      );

      expect(
        find.text('\u30a4\u30aa\u30f3\u30b9\u30fc\u30d1\u30fc'),
        findsOneWidget,
      );
      expect(
        find.text('\u98df\u8cbb \u00b7 \u751f\u5b58'),
        findsOneWidget,
      );
      expect(find.text('-\u00a53,280'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              tagText: 'T',
              tagBgColor: const Color(0xFFE8F0F8),
              tagTextColor: const Color(0xFF5A9CC8),
              merchant: 'Test',
              category: 'Food \u00b7 Survival',
              categoryColor: const Color(0xFFABABAB),
              formattedAmount: '-\u00a51,000',
              amountColor: const Color(0xFF1E2432),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HomeTransactionTile));
      expect(tapped, isTrue);
    });

    testWidgets('tag container has correct background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              tagText: 'F',
              tagBgColor: Color(0xFFE8F0F8),
              tagTextColor: Color(0xFF5A9CC8),
              merchant: 'Test',
              category: 'Food',
              categoryColor: Color(0xFFABABAB),
              formattedAmount: '-\u00a5500',
              amountColor: Color(0xFF1E2432),
            ),
          ),
        ),
      );

      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('soul type uses green color for category label', (
      tester,
    ) async {
      const soulGreen = Color(0xFF47B88A);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              tagText: '\u9b42',
              tagBgColor: Color(0xFFE5F5ED),
              tagTextColor: soulGreen,
              merchant: '\u30e8\u30c9\u30d0\u30b7\u30ab\u30e1\u30e9',
              category: '\u8da3\u5473 \u00b7 \u970a\u9b42',
              categoryColor: soulGreen,
              formattedAmount: '-\u00a512,800',
              amountColor: Color(0xFF1E2432),
            ),
          ),
        ),
      );

      final categoryText = tester.widget<Text>(
        find.text('\u8da3\u5473 \u00b7 \u970a\u9b42'),
      );
      expect(categoryText.style?.color, soulGreen);
    });
  });
}
