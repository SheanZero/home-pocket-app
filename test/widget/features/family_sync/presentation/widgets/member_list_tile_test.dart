import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/member_list_tile.dart';

void main() {
  testWidgets('MemberListTile shows name, role, and owner badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberListTile(
            name: '太郎のiPhone',
            roleLabel: 'オーナー',
            isOwner: true,
            isCurrentUser: true,
            youSuffix: ' (あなた)',
            ownerBadgeLabel: 'オーナー',
          ),
        ),
      ),
    );

    expect(find.textContaining('太郎のiPhone'), findsOneWidget);
    expect(find.text('オーナー'), findsAtLeastNWidgets(1));
  });

  testWidgets('MemberListTile shows remove button for non-owner', (
    tester,
  ) async {
    var removed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberListTile(
            name: '花子のiPhone',
            roleLabel: 'メンバー',
            removeLabel: '削除',
            onRemove: () => removed = true,
          ),
        ),
      ),
    );

    expect(find.text('花子のiPhone'), findsOneWidget);
    expect(find.text('削除'), findsOneWidget);
    await tester.tap(find.text('削除'));
    expect(removed, isTrue);
  });
}
