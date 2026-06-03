import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart';

void main() {
  group('SatisfactionEmojiPicker', () {
    Widget buildTestWidget({
      required int value,
      required ValueChanged<int> onChanged,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: SatisfactionEmojiPicker(
            value: value,
            onChanged: onChanged,
            title: '満足度',
            levelLabels: const ['無難', '快適', '順調', '満足', '至福'],
            bottomLabels: const ['無難', '順調', '至福！'],
          ),
        ),
      );
    }

    testWidgets('renders 5 face buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 5, onChanged: (_) {}));

      for (var i = 0; i < 5; i++) {
        expect(find.byKey(ValueKey('face_$i')), findsOneWidget);
      }
    });

    testWidgets('renders the 5 satisfaction face SVGs', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 6, onChanged: (_) {}));

      final svgs = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
      expect(svgs.length, 5);
    });

    testWidgets('renders satisfaction labels', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 8, onChanged: (_) {}));

      expect(find.text('無難'), findsOneWidget);
      expect(find.text('順調'), findsOneWidget);
      expect(find.text('至福！'), findsOneWidget);
    });

    testWidgets('tapping a face calls onChanged with mapped value', (
      tester,
    ) async {
      int? newValue;

      await tester.pumpWidget(
        buildTestWidget(value: 5, onChanged: (value) => newValue = value),
      );

      await tester.tap(find.byKey(const ValueKey('face_4')));

      expect(newValue, 10);
    });

    testWidgets('pins all five face values to the v1.1 unipolar scale', (
      tester,
    ) async {
      final selectedValues = <int>[];

      await tester.pumpWidget(
        buildTestWidget(value: 2, onChanged: selectedValues.add),
      );

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(ValueKey('face_$i')));
      }

      expect(selectedValues, [2, 4, 6, 8, 10]);
    });

    testWidgets('shows header with satisfaction label text', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 7, onChanged: (_) {}));

      expect(find.text('満足度'), findsOneWidget);
      expect(find.text('満足'), findsOneWidget);
    });
  });
}
