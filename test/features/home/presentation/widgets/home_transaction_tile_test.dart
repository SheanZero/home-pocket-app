import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';

void main() {
  group('HomeTransactionTile', () {
    testWidgets('shows tag, merchant, category, and amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              tagText: '\u592a',
              tagBgColor: Color(0xFFE8F0F8),
              tagTextColor: Color(0xFF5A9CC8),
              merchant: '\u30b9\u30fc\u30d1\u30fc\u30de\u30fc\u30b1\u30c3\u30c8',
              category: '\u98df\u8cbb',
              categoryColor: Color(0xFFABABAB),
              formattedAmount: '-\u00a53,480',
              amountColor: Color(0xFF1E2432),
            ),
          ),
        ),
      );

      expect(find.text('\u592a'), findsOneWidget);
      expect(
        find.text('\u30b9\u30fc\u30d1\u30fc\u30de\u30fc\u30b1\u30c3\u30c8'),
        findsOneWidget,
      );
      expect(find.text('\u98df\u8cbb'), findsOneWidget);
      expect(find.text('-\u00a53,480'), findsOneWidget);
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
              category: 'Food',
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

    testWidgets('applies tag background and text colours', (tester) async {
      const bgColor = Color(0xFFE5F5ED);
      const textColor = Color(0xFF47B88A);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              tagText: '\u9b42',
              tagBgColor: bgColor,
              tagTextColor: textColor,
              merchant: 'Bookstore',
              category: 'Education',
              categoryColor: Color(0xFFABABAB),
              formattedAmount: '-\u00a52,500',
              amountColor: Color(0xFF1E2432),
            ),
          ),
        ),
      );

      // Verify tag text widget has the correct colour
      final tagWidget = tester.widget<Text>(find.text('\u9b42'));
      expect(tagWidget.style?.color, textColor);

      // Verify tag container has the correct background
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('\u9b42'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, bgColor);
    });

    testWidgets('applies category colour', (tester) async {
      const catColor = Color(0xFF47B88A);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              tagText: 'S',
              tagBgColor: Color(0xFFE5F5ED),
              tagTextColor: Color(0xFF47B88A),
              merchant: 'Shop',
              category: 'Hobby',
              categoryColor: catColor,
              formattedAmount: '-\u00a5800',
              amountColor: Color(0xFF1E2432),
            ),
          ),
        ),
      );

      final categoryWidget = tester.widget<Text>(find.text('Hobby'));
      expect(categoryWidget.style?.color, catColor);
    });

    testWidgets('applies amount colour', (tester) async {
      const amtColor = Color(0xFFE85A4F);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              tagText: 'A',
              tagBgColor: Color(0xFFE8F0F8),
              tagTextColor: Color(0xFF5A9CC8),
              merchant: 'Cafe',
              category: 'Dining',
              categoryColor: Color(0xFFABABAB),
              formattedAmount: '+\u00a51,200',
              amountColor: amtColor,
            ),
          ),
        ),
      );

      final amountWidget = tester.widget<Text>(find.text('+\u00a51,200'));
      expect(amountWidget.style?.color, amtColor);
    });
  });
}
