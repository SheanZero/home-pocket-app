import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/satisfaction_bottom_sheet.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets(
    'shows the category reason and returns the selected satisfaction',
    (tester) async {
      int? selectedValue;

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  selectedValue = await SatisfactionBottomSheet.show(
                    context,
                    request: const SatisfactionPromptRequest(
                      currentValue: 2,
                      reason: SatisfactionPromptReason.categoryInference,
                      categoryName: '外出就餐',
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
          locale: const Locale('zh'),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('satisfaction-bottom-sheet')),
        findsOneWidget,
      );
      expect(find.text('已根据“外出就餐”设为悦己支出'), findsOneWidget);
      expect(find.text('这笔消费让你有多满足？'), findsOneWidget);
      expect(find.text('当前为「平和」，选择后可随时修改'), findsOneWidget);
      expect(find.text('平和'), findsOneWidget);
      expect(find.text('还好'), findsOneWidget);
      expect(find.text('不错'), findsOneWidget);
      expect(find.text('很棒'), findsOneWidget);
      expect(find.text('最爱'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('face_3')));
      await tester.pumpAndSettle();

      expect(selectedValue, 8);
      expect(
        find.byKey(const ValueKey('satisfaction-bottom-sheet')),
        findsNothing,
      );
    },
  );

  testWidgets('keep action returns the current value', (tester) async {
    int? selectedValue;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                selectedValue = await SatisfactionBottomSheet.show(
                  context,
                  request: const SatisfactionPromptRequest(
                    currentValue: 6,
                    reason: SatisfactionPromptReason.manualSelection,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
        locale: const Locale('zh'),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保持「不错」'));
    await tester.pumpAndSettle();

    expect(selectedValue, 6);
  });

  testWidgets('fits the satisfaction choices at 320 logical pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => SatisfactionBottomSheet.show(
                context,
                request: const SatisfactionPromptRequest(
                  currentValue: 2,
                  reason: SatisfactionPromptReason.manualSelection,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        locale: const Locale('zh'),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('face_4')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
