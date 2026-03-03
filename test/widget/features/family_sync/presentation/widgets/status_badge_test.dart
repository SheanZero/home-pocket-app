import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge.owner shows owner badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge.owner(label: 'オーナー')),
      ),
    );

    expect(find.text('オーナー'), findsOneWidget);
  });

  testWidgets('StatusBadge.pending shows pending badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge.pending(label: '承認待ち')),
      ),
    );

    expect(find.text('承認待ち'), findsOneWidget);
  });

  testWidgets('StatusBadge.synced shows synced badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge.synced(label: '同期済')),
      ),
    );

    expect(find.text('同期済'), findsOneWidget);
  });
}
