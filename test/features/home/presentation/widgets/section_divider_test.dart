import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/section_divider.dart';

void main() {
  testWidgets('SectionDivider renders label text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionDivider(label: '今月の支出')),
      ),
    );
    expect(find.text('今月の支出'), findsOneWidget);
  });

  testWidgets('SectionDivider renders divider line', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionDivider(label: 'Test')),
      ),
    );
    final containers = find.byType(Container);
    expect(containers, findsWidgets);
  });
}
