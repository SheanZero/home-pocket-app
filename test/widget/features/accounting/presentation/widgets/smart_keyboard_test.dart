import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  group('SmartKeyboard — responsive height (SC-2 / KEYPAD-01)', () {
    // TEST 1: 48 dp floor on the DIGIT + extra rows, on all three surfaces.
    // 260623-0cj: the floor is scoped to the digit/extra keys — the action
    // (bottom) row is intentionally shorter and is covered by its own test.
    const digitLabels = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '00', '.'];
    for (final surfaceSize in const [
      Size(375, 667), // iPhone SE
      Size(390, 844), // iPhone 14
      Size(428, 926), // iPhone Pro Max
    ]) {
      testWidgets(
        'every DIGIT key height >= 48 dp on '
        '${surfaceSize.width.toInt()}x${surfaceSize.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = surfaceSize;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            createLocalizedWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: surfaceSize,
                  padding: const EdgeInsets.only(bottom: 34),
                ),
                child: Scaffold(
                  body: SmartKeyboard(
                    onDigit: (_) {},
                    onDelete: () {},
                    onNext: () {},
                    onDoubleZero: () {},
                    onDot: () {},
                    actionLabel: 'Record',
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Each digit/extra key's InkWell meets the 48 dp touch-target floor.
          for (final label in digitLabels) {
            final ink = find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(InkWell),
                )
                .first;
            expect(
              tester.getSize(ink).height,
              greaterThanOrEqualTo(48.0),
              reason:
                  'Digit "$label" below 48 dp floor on '
                  '${surfaceSize.width.toInt()}x${surfaceSize.height.toInt()}',
            );
          }
        },
      );
    }

    // TEST 1b (260623-0cj R2): the action(bottom) row is a fixed 44 dp —
    // shorter than the digit rows, equal to the voice key height.
    testWidgets(
      '260623-0cj: action(bottom) row is a fixed 44 dp, shorter than digit keys',
      (tester) async {
        const surface = Size(390, 844);
        tester.view.physicalSize = surface;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createLocalizedWidget(
            MediaQuery(
              data: const MediaQueryData(
                size: surface,
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: Scaffold(
                body: SmartKeyboard(
                  onDigit: (_) {},
                  onDelete: () {},
                  onNext: () {},
                  onDoubleZero: () {},
                  onDot: () {},
                  actionLabel: 'Save',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final digitH = tester
            .getSize(
              find
                  .ancestor(of: find.text('1'), matching: find.byType(InkWell))
                  .first,
            )
            .height;
        final saveH = tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('Save'),
                    matching: find.byType(InkWell),
                  )
                  .first,
            )
            .height;

        expect(
          saveH,
          lessThan(digitH),
          reason: '260623-0cj: the bottom row must be shorter than digit rows',
        );
        expect(
          saveH,
          closeTo(44.0, 0.6),
          reason: '260623-0cj R2: action row height is a fixed 44 dp',
        );
      },
    );

    // TEST 1c (260623-0cj R2): showTopBorder toggles the keypad's own top
    // border (the single-page entry screen hands the border to VoiceRecordBar).
    testWidgets('260623-0cj R2: showTopBorder controls the keypad top border',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      BoxDecoration decoOf(WidgetTester t) => t
          .widget<Container>(find.byKey(const ValueKey('smart_keyboard_root')))
          .decoration! as BoxDecoration;

      // Default keeps the top border (standalone callers unaffected).
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: SmartKeyboard(
              onDigit: (_) {},
              onDelete: () {},
              onNext: () {},
              actionLabel: 'Save',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decoOf(tester).border, isNotNull,
          reason: 'default showTopBorder:true keeps the top border');

      // Explicit false drops it (一体 with the white voice bar above).
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: SmartKeyboard(
              onDigit: (_) {},
              onDelete: () {},
              onNext: () {},
              actionLabel: 'Save',
              showTopBorder: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decoOf(tester).border, isNull,
          reason: 'showTopBorder:false removes the keypad top border');
    });

    // TEST 2 (P19-B3 spacing): column gap = 6 dp TOTAL (3 dp per side)
    testWidgets(
      'column gap between adjacent digit keys is 6 dp (P19-B3)',
      (tester) async {
        const surface = Size(390, 844);
        tester.view.physicalSize = surface;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createLocalizedWidget(
            MediaQuery(
              data: const MediaQueryData(size: surface),
              child: Scaffold(
                body: SmartKeyboard(
                  onDigit: (_) {},
                  onDelete: () {},
                  onNext: () {},
                  onDoubleZero: () {},
                  onDot: () {},
                  actionLabel: 'Record',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // (a) Source-level: Padding wrappers must use horizontal: 3
        final paddings = find.descendant(
          of: find.byKey(const ValueKey('smart_keyboard_root')),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Padding &&
                w.padding is EdgeInsets &&
                (w.padding as EdgeInsets).left == 3.0 &&
                (w.padding as EdgeInsets).right == 3.0,
          ),
        );
        // There should be at least 5 such paddings (3 digit rows * 3 keys + extra row + action row)
        expect(
          paddings,
          findsAtLeastNWidgets(5),
          reason: 'Expected each key Padding to have horizontal: 3 (P19-B3)',
        );

        // (b) Rendered-gap: measure gap between first two InkWells in row 1
        final digitInkWells = find.descendant(
          of: find.byKey(const ValueKey('smart_keyboard_root')),
          matching: find.byType(InkWell),
        );
        final elements = digitInkWells.evaluate().toList();
        // The first two InkWells are '1' and '2' keys
        final box1 = elements[0].renderObject as RenderBox;
        final box2 = elements[1].renderObject as RenderBox;
        final pos1 = box1.localToGlobal(Offset.zero);
        final pos2 = box2.localToGlobal(Offset.zero);
        final gap = pos2.dx - (pos1.dx + box1.size.width);
        // P19-B3: 3 dp right padding on key 1 + 3 dp left padding on key 2 = 6 dp
        expect(
          gap,
          closeTo(6.0, 0.5),
          reason:
              'Rendered column gap should be 6 dp (3+3), got '
              '${gap.toStringAsFixed(2)} dp',
        );

        // (c) Row gap: assert SizedBox(height: 12) between rows
        final rowGaps = find.descendant(
          of: find.byKey(const ValueKey('smart_keyboard_root')),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == 12.0,
          ),
        );
        expect(
          rowGaps,
          findsAtLeastNWidgets(4),
          reason: 'Expected 4 inter-row gaps of 12 dp (D-07)',
        );
      },
    );

    // TEST 3: rename nextLabel->actionLabel + no 'Next' leak
    testWidgets(
      'actionLabel is rendered; no "Next" text leaks (RESEARCH pitfall 6)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createLocalizedWidget(
            Scaffold(
              body: SmartKeyboard(
                onDigit: (_) {},
                onDelete: () {},
                onNext: () {},
                actionLabel: 'Record',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Record'), findsOneWidget);
        expect(find.text('Next'), findsNothing);
      },
    );

    // TEST 4: digit glyphs use tabular figures
    testWidgets(
      'digit glyph text style includes tabular figures (UI-SPEC Typography)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createLocalizedWidget(
            Scaffold(
              body: SmartKeyboard(
                onDigit: (_) {},
                onDelete: () {},
                onNext: () {},
                actionLabel: 'Record',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the '1' digit text widget and check its style includes tabular figures
        final digitTexts = find.descendant(
          of: find.byKey(const ValueKey('smart_keyboard_root')),
          matching: find.byWidgetPredicate(
            (w) => w is Text && w.data == '1',
          ),
        );
        expect(digitTexts, findsOneWidget);
        final text = tester.widget<Text>(digitTexts);
        final features = text.style?.fontFeatures;
        expect(features, isNotNull);
        expect(
          features!.any((f) => f.feature == 'tnum'),
          isTrue,
          reason: 'Digit glyph must include FontFeature.tabularFigures()',
        );
      },
    );

    // TEST 5: action row uniform height (D-08)
    testWidgets(
      'action row keys (backspace, currency, Save) all have uniform height (D-08)',
      (tester) async {
        const surface = Size(390, 844);
        tester.view.physicalSize = surface;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createLocalizedWidget(
            MediaQuery(
              data: const MediaQueryData(size: surface),
              child: Scaffold(
                body: SmartKeyboard(
                  onDigit: (_) {},
                  onDelete: () {},
                  onNext: () {},
                  onDoubleZero: () {},
                  onDot: () {},
                  actionLabel: 'Save',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Currency key is identified by its ValueKey
        final currencyKey = find.byKey(
          const ValueKey('smart_keyboard_currency_key'),
        );
        expect(currencyKey, findsOneWidget);
        final currencyHeight = tester.getSize(currencyKey).height;

        // Backspace key: find InkWell containing backspace icon
        final backspaceIcon = find.descendant(
          of: find.byKey(const ValueKey('smart_keyboard_root')),
          matching: find.byWidgetPredicate(
            (w) => w is Icon && w.icon == Icons.backspace_outlined,
          ),
        );
        expect(backspaceIcon, findsOneWidget);
        // Get the Container ancestor height (the key container)
        final backspaceContainers = find.ancestor(
          of: backspaceIcon,
          matching: find.byType(Container),
        );
        final backspaceHeight =
            tester.getSize(backspaceContainers.first).height;

        // Save/action key: find 'Save' text
        final saveText = find.text('Save');
        expect(saveText, findsOneWidget);
        final saveContainers = find.ancestor(
          of: saveText,
          matching: find.byType(Container),
        );
        final saveHeight = tester.getSize(saveContainers.first).height;

        // All three action-row keys must have equal height within +/-0.5 dp
        expect(
          (backspaceHeight - currencyHeight).abs(),
          lessThanOrEqualTo(0.5),
          reason:
              'Backspace ($backspaceHeight dp) and currency ($currencyHeight dp) '
              'heights should match (D-08)',
        );
        expect(
          (saveHeight - currencyHeight).abs(),
          lessThanOrEqualTo(0.5),
          reason:
              'Save ($saveHeight dp) and currency ($currencyHeight dp) heights '
              'should match (D-08)',
        );
      },
    );
  });
}
