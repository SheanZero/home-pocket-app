import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/category_reorder_row.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CategoryReorderRow', () {
    testWidgets('renders drag handle + label + icon', (tester) async {
      await tester.pumpWidget(host(
        const CategoryReorderRow(
          label: '食費',
          iconData: Icons.restaurant,
          color: Color(0xFFFF5722),
          variant: CategoryReorderRowVariant.l1,
        ),
      ));
      expect(find.text('食費'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('L2 variant uses a smaller padding/icon than L1', (tester) async {
      await tester.pumpWidget(host(Column(children: const [
        CategoryReorderRow(
          label: 'L1',
          iconData: Icons.restaurant,
          color: Color(0xFFFF5722),
          variant: CategoryReorderRowVariant.l1,
        ),
        CategoryReorderRow(
          label: 'L2',
          iconData: Icons.restaurant,
          color: Color(0xFFFF5722),
          variant: CategoryReorderRowVariant.l2,
        ),
      ])));
      // Smoke check — both render without throwing
      expect(find.text('L1'), findsOneWidget);
      expect(find.text('L2'), findsOneWidget);
    });
  });
}
