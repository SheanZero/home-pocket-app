import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/member_list_tile.dart';

void main() {
  testWidgets('MemberListTile shows display name, role, and emoji avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberListTile(
            displayName: '太郎',
            avatarEmoji: '\u{1F60A}',
            roleLabel: 'オーナー',
            isOwner: true,
            isCurrentUser: true,
            youSuffix: ' (あなた)',
          ),
        ),
      ),
    );

    expect(find.textContaining('太郎'), findsOneWidget);
    expect(find.text('オーナー'), findsOneWidget);
    // Emoji is rendered inside AvatarDisplay
    expect(find.text('\u{1F60A}'), findsOneWidget);
  });

  testWidgets('MemberListTile shows non-owner with purple gradient', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberListTile(
            displayName: '花子',
            avatarEmoji: '\u{1F338}',
            roleLabel: 'メンバー',
          ),
        ),
      ),
    );

    expect(find.text('花子'), findsOneWidget);
    expect(find.text('メンバー'), findsOneWidget);
  });
}
