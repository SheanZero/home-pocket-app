import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/detail_info_card.dart';

void main() {
  group('DetailInfoCard', () {
    Widget buildTestWidget({
      required List<DetailInfoRow> rows,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(body: DetailInfoCard(rows: rows)),
      );
    }

    testWidgets('renders all rows with labels and values', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          rows: [
            const DetailInfoRow(
              icon: Icons.calendar_today,
              label: '日付',
              value: '今日',
            ),
            DetailInfoRow(
              icon: Icons.grid_view,
              label: 'カテゴリ',
              value: '食費 › コンビニ',
              showChevron: true,
              onTap: () {},
            ),
          ],
        ),
      );

      expect(find.text('日付'), findsOneWidget);
      expect(find.text('今日'), findsOneWidget);
      expect(find.text('カテゴリ'), findsOneWidget);
      expect(find.text('食費 › コンビニ'), findsOneWidget);
    });

    testWidgets('shows dividers between rows', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          rows: const [
            DetailInfoRow(icon: Icons.calendar_today, label: 'A', value: '1'),
            DetailInfoRow(icon: Icons.grid_view, label: 'B', value: '2'),
            DetailInfoRow(icon: Icons.store, label: 'C', value: '3'),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('detail_info_divider_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('detail_info_divider_1')),
        findsOneWidget,
      );
    });

    testWidgets('chevron icon visible when showChevron is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          rows: const [
            DetailInfoRow(
              icon: Icons.grid_view,
              label: 'Test',
              value: 'Val',
              showChevron: true,
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders trailing section below the rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailInfoCard(
              rows: const [
                DetailInfoRow(
                  icon: Icons.calendar_today,
                  label: '日付',
                  value: '今日',
                ),
              ],
              trailing: const Text('memo section'),
            ),
          ),
        ),
      );

      expect(find.text('memo section'), findsOneWidget);
    });
  });
}
