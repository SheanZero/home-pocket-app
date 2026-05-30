// Wave 0 widget test stubs for CategoryFilterSheet (FILTER-03, D-02, B2).
//
// CategoryFilterSheet is defined in:
//   lib/features/list/presentation/widgets/list_category_filter_sheet.dart
// TODO: created in 28-04 — that widget does not exist yet; the import below
// will fail to resolve until Wave 3 (28-04) creates the file.
//
// These stubs cover:
//   - Apply button calling setCategories with _localSelected
//   - D-02: L1 tap cascades to all its L2 children
//   - Tristate: L1 renders partial when some L2 selected, all when all selected,
//               none when none selected (B2)
//
// Run: flutter test test/widget/features/list/list_category_filter_sheet_test.dart

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/generated/app_localizations.dart';
// TODO: created in 28-04
// import 'package:home_pocket/features/list/presentation/widgets/list_category_filter_sheet.dart';

/// Pumps a CategoryFilterSheet stub inside UncontrolledProviderScope + MaterialApp.
///
/// [initialSelected] pre-populates the sheet's local selection state.
/// TODO: uncomment and wire CategoryFilterSheet once 28-04 creates it.
Future<void> _pumpSheet(
  WidgetTester tester,
  ProviderContainer container, {
  Set<String> initialSelected = const {},
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Center(
            // TODO: created in 28-04 — replace with:
            // CategoryFilterSheet(initialSelected: initialSelected),
            child: Text('category_filter_sheet stub: ${initialSelected.length} selected'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CategoryFilterSheet', () {
    testWidgets(
        'Apply button calls setCategories with _localSelected',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpSheet(tester, container, initialSelected: {});
      // TODO: created in 28-04 — implement after CategoryFilterSheet exists:
      //   // Pump sheet with empty initialSelected
      //   // Tap Apply button
      //   await tester.tap(find.text('適用'));
      //   await tester.pumpAndSettle();
      //   // Verify setCategories was called — categoryIds remains empty
      //   expect(container.read(listFilterProvider).categoryIds, isEmpty);
      fail('implement in 28-04 after CategoryFilterSheet is created');
    });

    testWidgets(
        'D-02: L1 tap cascades to all its L2 children',
        (tester) async {
      final container = ProviderContainer.test();
      await _pumpSheet(tester, container, initialSelected: {});
      // TODO: created in 28-04 — implement after CategoryFilterSheet exists:
      //   // Find and tap the L1 checkbox for the first parent category
      //   // Verify all L2 child IDs appear in _localSelected (reflected in UI)
      //   await tester.tap(find.byType(Checkbox).first);
      //   await tester.pumpAndSettle();
      //   // all L2 checkboxes under that L1 should be checked (value == true)
      fail('implement in 28-04 after CategoryFilterSheet with L1→L2 cascade is created');
    });

    testWidgets(
        'tristate: L1 renders partial when some L2 selected, all when all L2 selected, none when none selected',
        (tester) async {
      // Scenario: pump with half of an L2 set selected → L1 should be partial (null)
      // For stub: just verify initial state logic via provider, not yet the widget.
      final container = ProviderContainer.test();
      await _pumpSheet(tester, container, initialSelected: {'cat_food_1'});
      // TODO: created in 28-04 — implement tristate rendering verification:
      //   // Find the L1 checkbox for the parent of 'cat_food_1'
      //   final l1Checkbox = find.byWidgetPredicate((w) =>
      //     w is Checkbox && w.tristate == true && w.value == null);
      //   expect(l1Checkbox, findsWidgets); // at least one partial L1
      //
      //   // All children selected → L1 value == true
      //   // No children selected → L1 value == false
      fail('implement in 28-04 after CategoryFilterSheet tristate logic is created');
    });
  });
}
