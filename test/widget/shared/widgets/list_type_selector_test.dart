// Widget tests for ListTypeSelector — public/private pill-chip selector.
//
// Run: flutter test test/widget/shared/widgets/list_type_selector_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/widgets/list_type_selector.dart';

Widget _wrap({
  required String selected,
  required ValueChanged<String> onChanged,
  bool enabled = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ListTypeSelector(
        selected: selected,
        onChanged: onChanged,
        publicLabel: 'Public',
        privateLabel: 'Private',
        enabled: enabled,
      ),
    ),
  );
}

void main() {
  group('ListTypeSelector', () {
    testWidgets('renders both chips with provided labels, public chip first',
        (tester) async {
      await tester.pumpWidget(
        _wrap(selected: 'public', onChanged: (_) {}),
      );
      await tester.pump();

      // Both chips present
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);

      // Public chip first — by key
      expect(
        find.byKey(const ValueKey('list_type_public_chip')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('list_type_private_chip')),
        findsOneWidget,
      );

      // Verify order: public chip appears before private chip
      final publicOffset = tester
          .getTopLeft(find.byKey(const ValueKey('list_type_public_chip')));
      final privateOffset = tester
          .getTopLeft(find.byKey(const ValueKey('list_type_private_chip')));
      expect(publicOffset.dx, lessThan(privateOffset.dx),
          reason: 'Public chip must appear before private chip');
    });

    testWidgets(
        'tapping the non-selected chip calls onChanged with its value',
        (tester) async {
      String? changed;
      await tester.pumpWidget(
        _wrap(
          selected: 'public',
          onChanged: (v) => changed = v,
        ),
      );
      await tester.pump();

      // Tap the private chip (non-selected)
      await tester.tap(find.byKey(const ValueKey('list_type_private_chip')));
      await tester.pump();

      expect(changed, equals('private'),
          reason: 'Tapping private chip must call onChanged with "private"');
    });

    testWidgets(
        'selected="public" → tapping public chip calls onChanged("public")',
        (tester) async {
      String? changed;
      await tester.pumpWidget(
        _wrap(
          selected: 'private',
          onChanged: (v) => changed = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('list_type_public_chip')));
      await tester.pump();

      expect(changed, equals('public'));
    });

    testWidgets('enabled:false → tapping a chip does NOT call onChanged',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _wrap(
          selected: 'public',
          onChanged: (_) => called = true,
          enabled: false,
        ),
      );
      await tester.pump();

      // Tapping either chip must not call onChanged (IgnorePointer active)
      await tester.tap(find.byKey(const ValueKey('list_type_private_chip')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('list_type_public_chip')));
      await tester.pump();

      expect(called, isFalse,
          reason: 'IgnorePointer must prevent onChanged calls when disabled');
    });
  });
}
