import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';

void main() {
  group('HomeTransactionTile', () {
    testWidgets('shows tag, merchant, category, and amount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              l1Icon: Icons.restaurant,
              tagText: '太',
              tagBgColor: const Color(0xFFE8F0F8),
              tagTextColor: AppPalette.light.daily,
              merchant:
                  'スーパーマーケット',
              category: '食費',
              categoryColor: const Color(0xFFABABAB),
              formattedAmount: '-¥3,480',
              amountColor: const Color(0xFF1E2432),
            ),
          ),
        ),
      );

      expect(find.text('太'), findsOneWidget);
      expect(
        find.text('スーパーマーケット'),
        findsOneWidget,
      );
      expect(find.text('食費'), findsOneWidget);
      expect(find.text('-¥3,480'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              l1Icon: Icons.restaurant,
              tagText: 'T',
              tagBgColor: const Color(0xFFE8F0F8),
              tagTextColor: AppPalette.light.daily,
              merchant: 'Test',
              category: 'Food',
              categoryColor: const Color(0xFFABABAB),
              formattedAmount: '-¥1,000',
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
      final bgColor = const Color(0xFFE5F5ED);
      final textColor = AppPalette.light.joy;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              l1Icon: Icons.menu_book,
              tagText: '魂',
              tagBgColor: bgColor,
              tagTextColor: textColor,
              merchant: 'Bookstore',
              category: 'Education',
              categoryColor: const Color(0xFFABABAB),
              formattedAmount: '-¥2,500',
              amountColor: const Color(0xFF1E2432),
            ),
          ),
        ),
      );

      // Verify tag text widget has the correct colour
      final tagWidget = tester.widget<Text>(find.text('魂'));
      expect(tagWidget.style?.color, textColor);

      // Verify tag container has the correct background
      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text('魂'), matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, bgColor);
    });

    testWidgets('applies category colour to the leading L1 icon', (
      tester,
    ) async {
      final catColor = AppPalette.light.joy;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              l1Icon: Icons.sports_esports,
              tagText: 'S',
              tagBgColor: const Color(0xFFE5F5ED),
              tagTextColor: AppPalette.light.joy,
              merchant: 'Shop',
              category: 'Hobby',
              categoryColor: catColor,
              formattedAmount: '-¥800',
              amountColor: const Color(0xFF1E2432),
            ),
          ),
        ),
      );

      // categoryColor now tints the leading L1 icon (matches the list tile).
      final iconWidget = tester.widget<Icon>(
        find.byIcon(Icons.sports_esports),
      );
      expect(iconWidget.color, catColor);
    });

    testWidgets('applies amount colour', (tester) async {
      final amtColor = AppPalette.light.error;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              l1Icon: Icons.restaurant,
              tagText: 'A',
              tagBgColor: const Color(0xFFE8F0F8),
              tagTextColor: AppPalette.light.daily,
              merchant: 'Cafe',
              category: 'Dining',
              categoryColor: const Color(0xFFABABAB),
              formattedAmount: '+¥1,200',
              amountColor: amtColor,
            ),
          ),
        ),
      );

      final amountWidget = tester.widget<Text>(find.text('+¥1,200'));
      expect(amountWidget.style?.color, amtColor);
    });
  });
}
