import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/shared/widgets/feedback_toast.dart';
import 'package:home_pocket/shared/widgets/soft_toast.dart';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return ctx;
  }

  testWidgets('a single feedback toast is visible at a time (no stacking)', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);

    showSuccessFeedback(ctx, 'first');
    await tester.pump();
    expect(find.byType(SoftToast), findsOneWidget);
    expect(find.text('first'), findsOneWidget);

    // Second toast must REPLACE the first, not stack on top of it.
    showSuccessFeedback(ctx, 'second');
    await tester.pump();
    expect(find.byType(SoftToast), findsOneWidget);
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);

    // Advance past the auto-hide timer so teardown has no pending Timer.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(SoftToast), findsNothing);
  });

  testWidgets('mixed success/error toasts also collapse to one', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);

    showErrorFeedback(ctx, 'oops');
    await tester.pump();
    showSuccessFeedback(ctx, 'done');
    await tester.pump();

    expect(find.byType(SoftToast), findsOneWidget);
    expect(find.text('oops'), findsNothing);
    expect(find.text('done'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(SoftToast), findsNothing);
  });

  testWidgets('feedback uses the compact centered status-pill style', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);

    showSuccessFeedback(ctx, '邀请码已重新生成');
    await tester.pump();

    final surface = tester.widget<Container>(
      find.byKey(const Key('feedback-toast-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, AppPalette.light.card);
    expect(decoration.borderRadius, BorderRadius.circular(26));
    expect(decoration.border, isNull);
    expect(
      tester.getSize(find.byKey(const Key('feedback-toast-icon-badge'))),
      const Size.square(28),
    );
    final icon = tester.widget<Icon>(
      find.byKey(const Key('feedback-toast-leading-icon')),
    );
    expect(icon.size, 18);
    expect(find.byKey(const Key('feedback-toast-dismiss')), findsNothing);

    final message = tester.widget<Text>(find.text('邀请码已重新生成'));
    expect(message.style?.decoration, TextDecoration.none);

    final surfaceSize = tester.getSize(
      find.byKey(const Key('feedback-toast-surface')),
    );
    expect(surfaceSize.height, 52);
    expect(surfaceSize.width, lessThan(320));

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('long feedback expands, wraps, and stays inside the viewport', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);

    showErrorFeedback(
      ctx,
      'A longer localized error message should wrap without changing the '
      'shared pill language or overflowing the screen.',
    );
    await tester.pump();

    final surfaceSize = tester.getSize(
      find.byKey(const Key('feedback-toast-surface')),
    );
    expect(surfaceSize.width, lessThanOrEqualTo(360));
    expect(surfaceSize.height, greaterThanOrEqualTo(52));
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('feedback action uses the same pill without an underline', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);

    showInfoFeedback(ctx, 'Rate updated', actionLabel: 'Undo', onAction: () {});
    await tester.pump();

    final action = tester.widget<TextButton>(
      find.byKey(const Key('feedback-toast-action')),
    );
    final actionText = tester.widget<Text>(find.text('Undo'));
    expect(action.style, isNotNull);
    expect(actionText.style?.decoration, TextDecoration.none);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
