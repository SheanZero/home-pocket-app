import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/group_bar.dart';

void main() {
  const members = [
    (initial: '太', color: Color(0xFF5A9CC8)),
    (initial: '花', color: Color(0xFFE85A4F)),
  ];

  const threeMembers = [
    (initial: '太', color: Color(0xFF5A9CC8)),
    (initial: '花', color: Color(0xFFE85A4F)),
    (initial: '翔', color: Color(0xFF8A9178)),
  ];

  Widget buildSubject({
    String familyName = '田中家',
    List<({String initial, Color color})> memberList = members,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GroupBar(
          familyName: familyName,
          members: memberList,
          onTap: onTap,
        ),
      ),
    );
  }

  group('GroupBar', () {
    testWidgets('shows family name', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('田中家'), findsOneWidget);
    });

    testWidgets('shows people icon', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('shows chevron right icon', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows member avatars', (tester) async {
      await tester.pumpWidget(buildSubject(memberList: threeMembers));

      expect(find.text('太'), findsOneWidget);
      expect(find.text('花'), findsOneWidget);
      expect(find.text('翔'), findsOneWidget);
    });

    testWidgets('onTap callback is invoked', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildSubject(onTap: () => tapped = true));
      await tester.tap(find.byType(GroupBar));

      expect(tapped, isTrue);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(GroupBar));

      // No exception means the test passes.
    });

    testWidgets('renders correctly with a single member', (tester) async {
      await tester.pumpWidget(buildSubject(
        memberList: const [(initial: 'A', color: Color(0xFF5A9CC8))],
      ));

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders correctly with empty members list', (tester) async {
      await tester.pumpWidget(buildSubject(memberList: const []));

      expect(find.text('田中家'), findsOneWidget);
    });
  });
}
