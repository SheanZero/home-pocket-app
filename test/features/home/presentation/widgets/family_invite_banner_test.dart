import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';

void main() {
  Widget buildSubject({VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(body: FamilyInviteBanner(onTap: onTap ?? () {})),
    );
  }

  testWidgets('shows CTA button text', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('\u5BB6\u65CF\u3092\u62DB\u5F85\u3059\u308B'), findsOneWidget);
  });

  testWidgets('shows title', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(
      find.text('\u5BB6\u65CF\u3068\u4E00\u7DD2\u306B\u7BA1\u7406\u3057\u3088\u3046'),
      findsOneWidget,
    );
  });

  testWidgets('shows subtitle', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(
      find.text('\u30D1\u30FC\u30C8\u30CA\u30FC\u3092\u62DB\u5F85\u3057\u3066\n\u5BB6\u8A08\u7C3F\u3092\u30EA\u30A2\u30EB\u30BF\u30A4\u30E0\u3067\u5171\u6709'),
      findsOneWidget,
    );
  });

  testWidgets('onTap triggers when CTA button is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildSubject(onTap: () => tapped = true));

    await tester.tap(find.text('\u5BB6\u65CF\u3092\u62DB\u5F85\u3059\u308B'));
    expect(tapped, isTrue);
  });

  testWidgets('displays two avatar circles with material icons', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.face), findsOneWidget);
    expect(find.byIcon(Icons.face_2), findsOneWidget);
  });

  testWidgets('CTA button includes heart icon', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('uses vertical Column layout', (tester) async {
    await tester.pumpWidget(buildSubject());

    final columnFinder = find.descendant(
      of: find.byType(FamilyInviteBanner),
      matching: find.byType(Column),
    );
    expect(columnFinder, findsWidgets);
  });
}
