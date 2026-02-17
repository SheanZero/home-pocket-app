import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
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
              merchant: 'イオンスーパー',
              categoryLabel: '食費 · 生存',
              formattedAmount: '-\u00a53,280',
              ledgerType: LedgerType.survival,
              iconData: Icons.shopping_cart,
            ),
          ),
        ),
      );

      expect(find.text('イオンスーパー'), findsOneWidget);
      expect(find.text('食費 · 生存'), findsOneWidget);
      expect(find.text('-\u00a53,280'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              merchant: 'Test',
              categoryLabel: 'Food · Survival',
              formattedAmount: '-\u00a51,000',
              ledgerType: LedgerType.survival,
              iconData: Icons.shopping_cart,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HomeTransactionTile));
      expect(tapped, isTrue);
    });

    testWidgets('shows icon in a rounded container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              merchant: 'Test',
              categoryLabel: 'Food',
              formattedAmount: '-\u00a5500',
              ledgerType: LedgerType.survival,
              iconData: Icons.train,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.train), findsOneWidget);
    });

    testWidgets('soul type uses green color for category label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTransactionTile(
              merchant: 'ヨドバシカメラ',
              categoryLabel: '趣味 · 灵魂',
              formattedAmount: '-\u00a512,800',
              ledgerType: LedgerType.soul,
              iconData: Icons.gamepad,
            ),
          ),
        ),
      );

      final categoryText = tester.widget<Text>(find.text('趣味 · 灵魂'));
      expect(categoryText.style?.color, isNotNull);
    });
  });
}
