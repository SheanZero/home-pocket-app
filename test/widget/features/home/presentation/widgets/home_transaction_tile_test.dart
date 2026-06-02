import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_transaction_tile.dart';

void main() {
  group('HomeTransactionTile', () {
    testWidgets('displays merchant, category, and formatted amount', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              l1Icon: Icons.restaurant,
              tagText: '生',
              tagBgColor: const Color(0xFFE8F0F8),
              tagTextColor: AppPalette.light.daily,
              merchant: 'イオンスーパー',
              category: '食費 · 生存',
              categoryColor: const Color(0xFFABABAB),
              formattedAmount: '-¥3,280',
              amountColor: const Color(0xFF1E2432),
            ),
          ),
        ),
      );

      expect(
        find.text('イオンスーパー'),
        findsOneWidget,
      );
      expect(find.text('食費 · 生存'), findsOneWidget);
      expect(find.text('-¥3,280'), findsOneWidget);
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
              category: 'Food · Survival',
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

    testWidgets('tag container has correct background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              l1Icon: Icons.restaurant,
              tagText: 'F',
              tagBgColor: const Color(0xFFE8F0F8),
              tagTextColor: AppPalette.light.daily,
              merchant: 'Test',
              category: 'Food',
              categoryColor: const Color(0xFFABABAB),
              formattedAmount: '-¥500',
              amountColor: const Color(0xFF1E2432),
            ),
          ),
        ),
      );

      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('joy type tints the leading L1 icon with joy color', (
      tester,
    ) async {
      final joyColor = AppPalette.light.joy;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              l1Icon: Icons.sports_esports,
              tagText: '魂',
              tagBgColor: const Color(0xFFE5F5ED),
              tagTextColor: joyColor,
              merchant: 'ヨドバシカメラ',
              category: '趣味 · 霊魂',
              categoryColor: joyColor,
              formattedAmount: '-¥12,800',
              amountColor: const Color(0xFF1E2432),
            ),
          ),
        ),
      );

      // categoryColor now drives the leading L1 icon tint (matches list tile).
      final iconWidget = tester.widget<Icon>(
        find.byIcon(Icons.sports_esports),
      );
      expect(iconWidget.color, joyColor);
    });
  });
}
