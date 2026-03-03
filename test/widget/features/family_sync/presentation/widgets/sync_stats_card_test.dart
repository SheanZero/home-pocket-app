import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/sync_stats_card.dart';

void main() {
  testWidgets('SyncStatsCard displays all three stats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatsCard(
            memberCount: 3,
            syncedEntries: 128,
            lastSyncText: '2分前',
            memberLabel: 'メンバー',
            syncedLabel: '同期済帳票',
            lastSyncLabel: '最終同期',
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('2分前'), findsOneWidget);
  });
}
