import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/models/ledger_row_data.dart';
import 'package:home_pocket/features/home/presentation/widgets/ledger_comparison_section.dart';

void main() {
  testWidgets('renders 2 rows in solo mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LedgerComparisonSection(
            rows: const [
              LedgerRowData(
                tagText: '生',
                tagBgColor: Color(0xFFE8F0F8),
                tagTextColor: Color(0xFF5A9CC8),
                title: '生存帳本',
                titleColor: Color(0xFF1E2432),
                subtitle: '先月 ¥198,000',
                formattedAmount: '¥186,200',
                amountColor: Color(0xFF5A9CC8),
                chevronColor: Color(0xFFC4C4C4),
              ),
              LedgerRowData(
                tagText: '灵',
                tagBgColor: Color(0xFFE5F5ED),
                tagTextColor: Color(0xFF47B88A),
                title: '灵魂帳本',
                titleColor: Color(0xFF47B88A),
                subtitle: '先月 ¥54,800',
                formattedAmount: '¥62,300',
                amountColor: Color(0xFF47B88A),
                chevronColor: Color(0xFFC4C4C4),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('生存帳本'), findsOneWidget);
    expect(find.text('灵魂帳本'), findsOneWidget);
    expect(find.text('¥186,200'), findsOneWidget);
    expect(find.text('¥62,300'), findsOneWidget);
  });

  testWidgets('renders 3 rows in group mode with shared ledger', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LedgerComparisonSection(
            rows: const [
              LedgerRowData(
                tagText: '生',
                tagBgColor: Color(0xFFE8F0F8),
                tagTextColor: Color(0xFF5A9CC8),
                title: '生存帳本',
                titleColor: Color(0xFF1E2432),
                subtitle: '',
                formattedAmount: '¥186,200',
                amountColor: Color(0xFF5A9CC8),
                chevronColor: Color(0xFFC4C4C4),
              ),
              LedgerRowData(
                tagText: '灵',
                tagBgColor: Color(0xFFE5F5ED),
                tagTextColor: Color(0xFF47B88A),
                title: '灵魂帳本',
                titleColor: Color(0xFF47B88A),
                subtitle: '',
                formattedAmount: '¥62,300',
                amountColor: Color(0xFF47B88A),
                chevronColor: Color(0xFFC4C4C4),
              ),
              LedgerRowData(
                tagText: '共',
                tagBgColor: Color(0xFFFFF0E0),
                tagTextColor: Color(0xFFD4845A),
                title: '花の帳本',
                titleColor: Color(0xFF1E2432),
                subtitle: '',
                formattedAmount: '¥33,300',
                amountColor: Color(0xFFD4845A),
                chevronColor: Color(0xFFD4B89A),
                borderColor: Color(0xFFF0DCC8),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('花の帳本'), findsOneWidget);
    expect(find.text('¥33,300'), findsOneWidget);
  });

  testWidgets('renders subtitle when non-empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LedgerComparisonSection(
            rows: const [
              LedgerRowData(
                tagText: '生',
                tagBgColor: Color(0xFFE8F0F8),
                tagTextColor: Color(0xFF5A9CC8),
                title: '生存帳本',
                titleColor: Color(0xFF1E2432),
                subtitle: '先月 ¥198,000',
                formattedAmount: '¥186,200',
                amountColor: Color(0xFF5A9CC8),
                chevronColor: Color(0xFFC4C4C4),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('先月 ¥198,000'), findsOneWidget);
  });

  testWidgets('hides subtitle when empty string', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LedgerComparisonSection(
            rows: const [
              LedgerRowData(
                tagText: '生',
                tagBgColor: Color(0xFFE8F0F8),
                tagTextColor: Color(0xFF5A9CC8),
                title: '生存帳本',
                titleColor: Color(0xFF1E2432),
                subtitle: '',
                formattedAmount: '¥186,200',
                amountColor: Color(0xFF5A9CC8),
                chevronColor: Color(0xFFC4C4C4),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('先月 ¥198,000'), findsNothing);
  });

  testWidgets('invokes onRowTap callback when row is tapped', (tester) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LedgerComparisonSection(
            rows: const [
              LedgerRowData(
                tagText: '生',
                tagBgColor: Color(0xFFE8F0F8),
                tagTextColor: Color(0xFF5A9CC8),
                title: '生存帳本',
                titleColor: Color(0xFF1E2432),
                subtitle: '',
                formattedAmount: '¥186,200',
                amountColor: Color(0xFF5A9CC8),
                chevronColor: Color(0xFFC4C4C4),
              ),
            ],
            onRowTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    await tester.tap(find.text('生存帳本'));
    expect(tappedIndex, equals(0));
  });
}
