import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/member_avatar.dart';

void main() {
  testWidgets('MemberAvatar shows first character', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MemberAvatar(name: '太郎', isOwner: true)),
      ),
    );

    expect(find.text('太'), findsOneWidget);
  });

  testWidgets('MemberAvatar uses primary fill for owner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MemberAvatar(name: '太郎', isOwner: true)),
      ),
    );

    final container = tester.widget<Container>(
      find.ancestor(of: find.text('太'), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, equals(const Color(0xFF5A9CC8)));
  });

  testWidgets('MemberAvatar uses light fill for member', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MemberAvatar(name: '花子', isOwner: false)),
      ),
    );

    expect(find.text('花'), findsOneWidget);
    final container = tester.widget<Container>(
      find.ancestor(of: find.text('花'), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, equals(const Color(0xFFEEF4FA)));
  });
}
