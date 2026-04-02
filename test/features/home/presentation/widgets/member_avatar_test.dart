import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/member_avatar.dart';

void main() {
  testWidgets('MemberAvatar displays initial', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(initial: '\u592a', color: Color(0xFF5A9CC8)),
        ),
      ),
    );
    expect(find.text('\u592a'), findsOneWidget);
  });

  testWidgets('MemberAvatar has correct size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(initial: '\u82b1', color: Color(0xFFE85A4F)),
        ),
      ),
    );
    final box = tester.getSize(find.byType(MemberAvatar));
    expect(box.width, 28); // 24 + 2*2 for outside stroke
    expect(box.height, 28);
  });

  testWidgets('MemberAvatar uses custom size and stroke', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(
            initial: 'A',
            color: Color(0xFF47B88A),
            size: 32,
            strokeWidth: 3,
          ),
        ),
      ),
    );
    final box = tester.getSize(find.byType(MemberAvatar));
    expect(box.width, 38); // 32 + 2*3
    expect(box.height, 38);
  });

  testWidgets('MemberAvatar renders circle with correct colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(initial: 'B', color: Color(0xFFE85A4F)),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, const Color(0xFFE85A4F));
    expect(decoration.border, isNotNull);
  });
}
