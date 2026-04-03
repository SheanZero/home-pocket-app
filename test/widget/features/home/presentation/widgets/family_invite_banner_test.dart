import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';

void main() {
  Widget buildSubject({VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(body: FamilyInviteBanner(onTap: onTap ?? () {})),
    );
  }

  group('FamilyInviteBanner', () {
    testWidgets('displays invite title and CTA text', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('家族と一緒に管理しよう'), findsOneWidget);
      expect(find.text('家族を招待する'), findsOneWidget);
    });

    testWidgets('triggers onTap callback via CTA button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onTap: () => tapped = true));

      await tester.tap(find.text('家族を招待する'));
      expect(tapped, isTrue);
    });

    testWidgets('shows two avatar circles with icons', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.face), findsOneWidget);
      expect(find.byIcon(Icons.face_2), findsOneWidget);
    });

    testWidgets('displays subtitle text', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(
        find.text('\u30D1\u30FC\u30C8\u30CA\u30FC\u3092\u62DB\u5F85\u3057\u3066\n\u5BB6\u8A08\u7C3F\u3092\u30EA\u30A2\u30EB\u30BF\u30A4\u30E0\u3067\u5171\u6709'),
        findsOneWidget,
      );
    });

    testWidgets('CTA button includes heart icon', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
