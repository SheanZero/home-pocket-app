import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/features/home/presentation/widgets/transaction_list_card.dart';

void main() {
  group('TransactionListCard', () {
    testWidgets('renders children with dividers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListCard(
              children: [Text('Row 1'), Text('Row 2'), Text('Row 3')],
            ),
          ),
        ),
      );

      expect(find.text('Row 1'), findsOneWidget);
      expect(find.text('Row 2'), findsOneWidget);
      expect(find.text('Row 3'), findsOneWidget);
    });

    testWidgets('inserts dividers between children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListCard(
              children: [Text('A'), Text('B'), Text('C')],
            ),
          ),
        ),
      );

      // 3 children + 2 dividers = 5 widgets in the Column
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 5);
    });

    testWidgets('renders empty children without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListCard(children: []),
          ),
        ),
      );

      expect(find.byType(TransactionListCard), findsOneWidget);
    });

    testWidgets('single child has no dividers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListCard(
              children: [Text('Only')],
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 1);
    });

    testWidgets('outer container has correct decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListCard(
              children: [Text('Item')],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TransactionListCard),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.clipBehavior, Clip.hardEdge);

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.card);
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(decoration.border, Border.all(color: AppColors.borderList));
    });
  });
}
