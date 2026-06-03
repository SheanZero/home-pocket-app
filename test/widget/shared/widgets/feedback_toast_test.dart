import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/widgets/feedback_toast.dart';
import 'package:home_pocket/shared/widgets/soft_toast.dart';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
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

  testWidgets('mixed success/error toasts also collapse to one', (tester) async {
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
}
