import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/current_book_provider.dart';
import 'package:home_pocket/features/accounting/presentation/providers/current_device_provider.dart';
import 'package:home_pocket/features/accounting/presentation/providers/transaction_form_notifier.dart';
import 'package:home_pocket/features/accounting/presentation/screens/transaction_form_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Helper to wrap widget with localization support and provider overrides for testing
Widget wrapWithLocalizations(Widget child,
    {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'), // Use English for tests
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'),
        Locale('en'),
        Locale('zh'),
      ],
      home: child,
    ),
  );
}

/// Default provider overrides for TransactionFormScreen tests
final defaultTestOverrides = [
  currentBookIdProvider.overrideWith((_) async => 'test_book_id'),
  currentDeviceIdProvider.overrideWith((_) async => 'test_device_id'),
];

void main() {
  group('TransactionFormScreen', () {
    testWidgets('should render all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(
          const TransactionFormScreen(),
          overrides: defaultTestOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar
      expect(find.text('New Transaction'), findsOneWidget);

      // Verify form fields
      expect(find.byType(TextFormField),
          findsNWidgets(3)); // Amount, Note, Merchant
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Note (Optional)'), findsOneWidget);
      expect(find.text('Merchant (Optional)'), findsOneWidget);

      // Verify buttons
      expect(find.byType(SegmentedButton<TransactionType>), findsOneWidget);
      expect(find.byType(SegmentedButton<LedgerType>), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Verify submit button
      expect(find.text('Create Transaction'), findsOneWidget);

      // Scroll to bottom to find Cancel button
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify cancel button after scrolling
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should update amount when text changes',
        (WidgetTester tester) async {
      final container = ProviderContainer(overrides: defaultTestOverrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrapWithLocalizations(const TransactionFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find amount field
      final amountField = find.byKey(const Key('amount_field'));

      // Enter amount
      await tester.enterText(amountField, '100.50');
      await tester.pump();

      // Verify state updated (10050 cents)
      final state = container.read(transactionFormNotifierProvider);
      expect(state.amount, 10050);
    });

    testWidgets('should switch transaction type', (WidgetTester tester) async {
      final container = ProviderContainer(overrides: defaultTestOverrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrapWithLocalizations(const TransactionFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially expense
      var state = container.read(transactionFormNotifierProvider);
      expect(state.type, TransactionType.expense);

      // Tap income button
      await tester.tap(find.text('Income'));
      await tester.pump();

      // Verify state updated
      state = container.read(transactionFormNotifierProvider);
      expect(state.type, TransactionType.income);
    });

    testWidgets('should switch ledger type', (WidgetTester tester) async {
      final container = ProviderContainer(overrides: defaultTestOverrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrapWithLocalizations(const TransactionFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially survival
      var state = container.read(transactionFormNotifierProvider);
      expect(state.ledgerType, LedgerType.survival);

      // Tap soul button
      await tester.tap(find.text('Soul Ledger'));
      await tester.pump();

      // Verify state updated
      state = container.read(transactionFormNotifierProvider);
      expect(state.ledgerType, LedgerType.soul);
    });

    testWidgets('should update note and merchant', (WidgetTester tester) async {
      final container = ProviderContainer(overrides: defaultTestOverrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrapWithLocalizations(const TransactionFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find note field
      final noteField = find.byKey(const Key('note_field'));

      // Find merchant field
      final merchantField = find.byKey(const Key('merchant_field'));

      // Enter note
      await tester.enterText(noteField, 'Test note');
      await tester.pump();

      // Enter merchant
      await tester.enterText(merchantField, 'Test merchant');
      await tester.pump();

      // Verify state updated
      final state = container.read(transactionFormNotifierProvider);
      expect(state.note, 'Test note');
      expect(state.merchant, 'Test merchant');
    });

    testWidgets('should show validation errors when submitting invalid form',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(
          const TransactionFormScreen(),
          overrides: defaultTestOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit button without filling form
      await tester.tap(find.text('Create Transaction'));
      await tester.pumpAndSettle();

      // Verify validation errors are shown
      expect(find.text('Please enter an amount'), findsOneWidget);
      expect(find.text('Please select a category'), findsOneWidget);
    });

    testWidgets('should enable submit button when form valid',
        (WidgetTester tester) async {
      final container = ProviderContainer(overrides: defaultTestOverrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrapWithLocalizations(const TransactionFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Fill amount
      final amountField = find.byKey(const Key('amount_field'));
      await tester.enterText(amountField, '100');
      await tester.pump();

      // Select category (open dropdown)
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select first category from dropdown menu
      await tester.tap(find.byType(DropdownMenuItem<String>).first);
      await tester.pumpAndSettle();

      // Verify submit button enabled
      final state = container.read(transactionFormNotifierProvider);
      expect(state.canSubmit, true);
    });

    testWidgets('should show validation error for empty amount',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(
          const TransactionFormScreen(),
          overrides: defaultTestOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit without filling form
      await tester.tap(find.text('Create Transaction'));
      await tester.pumpAndSettle();

      // Verify error message shown
      expect(find.text('Please enter an amount'), findsOneWidget);
    });

    testWidgets('should show validation error for empty category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(
          const TransactionFormScreen(),
          overrides: defaultTestOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Fill only amount
      final amountField = find.byKey(const Key('amount_field'));
      await tester.enterText(amountField, '100');
      await tester.pump();

      // Tap submit without selecting category
      await tester.tap(find.text('Create Transaction'));
      await tester.pumpAndSettle();

      // Verify error message shown
      expect(find.text('Please select a category'), findsOneWidget);
    });

    testWidgets('should close screen when cancel button tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: defaultTestOverrides,
          child: MaterialApp(
            locale: const Locale('en'), // Use English for tests
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ja'),
              Locale('en'),
              Locale('zh'),
            ],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TransactionFormScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Form'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open form screen
      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      // Verify form screen is showing
      expect(find.text('New Transaction'), findsOneWidget);

      // Scroll to bottom to find Cancel button
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify form screen is closed
      expect(find.text('New Transaction'), findsNothing);
    });
  });
}
