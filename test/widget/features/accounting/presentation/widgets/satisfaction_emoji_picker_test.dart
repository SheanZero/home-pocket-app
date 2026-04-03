import 'package:flutter/material.dart';
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
            levelLabels: const ['不満', 'やや不満', '普通', '良い', 'とても良い'],
            bottomLabels: const ['不満', '普通', '最高！'],
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

    testWidgets('renders satisfaction labels', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 8, onChanged: (_) {}));

      expect(find.text('不満'), findsOneWidget);
      expect(find.text('普通'), findsOneWidget);
      expect(find.text('最高！'), findsOneWidget);
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

    testWidgets('shows header with satisfaction label text', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 7, onChanged: (_) {}));

      expect(find.text('満足度'), findsOneWidget);
      expect(find.text('良い'), findsOneWidget);
    });
  });
}
