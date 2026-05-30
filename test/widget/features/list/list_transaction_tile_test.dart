// Widget tests for ListTransactionTile (ROW-01 / ROW-02).
//
// ListTransactionTile is defined in:
//   lib/features/list/presentation/widgets/list_transaction_tile.dart
//
// Run: flutter test test/widget/features/list/list_transaction_tile_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show deleteTransactionUseCaseProvider;
import 'package:home_pocket/features/list/domain/models/tagged_transaction.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_transaction_tile.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

/// Minimal TaggedTransaction fixture for widget tests.
TaggedTransaction _makeTx({String id = 'tx-1'}) {
  final now = DateTime(2026, 5, 1, 10, 30);
  return TaggedTransaction(
    transaction: Transaction(
      id: id,
      bookId: 'book1',
      deviceId: 'device1',
      amount: 1500,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
      timestamp: now,
      currentHash: 'stub_hash',
      createdAt: now,
      entrySource: EntrySource.manual,
    ),
  );
}

/// Pumps a ListTransactionTile inside UncontrolledProviderScope + MaterialApp.
Future<void> _pumpTile(
  WidgetTester tester,
  ProviderContainer container,
  TaggedTransaction tx, {
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: ListTransactionTile(
            taggedTx: tx,
            bookId: 'book1',
            onTap: onTap ?? () {},
            tagText: '生存',
            tagBgColor: const Color(0xFFE8F0F8),
            tagTextColor: const Color(0xFF5A9CC8),
            category: '食費',
            categoryColor: const Color(0xFF5A9CC8),
            formattedAmount: '¥1,500',
            formattedTime: '10:30',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ListTransactionTile', () {
    testWidgets('ROW-01: tapping tile invokes onTap callback',
        (tester) async {
      final mockDelete = _MockDeleteTransactionUseCase();
      when(() => mockDelete.execute(any()))
          .thenAnswer((_) async => Result.success(null));

      final container = ProviderContainer.test(overrides: [
        deleteTransactionUseCaseProvider.overrideWithValue(mockDelete),
      ]);

      bool tapped = false;
      final tx = _makeTx();
      await _pumpTile(
        tester,
        container,
        tx,
        onTap: () => tapped = true,
      );

      await tester.tap(find.byType(ListTransactionTile));
      // Only pump one frame — do not pumpAndSettle because that would try to
      // settle the TransactionEditScreen navigation which needs full providers.
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('ROW-02: left swipe shows confirm dialog', (tester) async {
      final mockDelete = _MockDeleteTransactionUseCase();
      when(() => mockDelete.execute(any()))
          .thenAnswer((_) async => Result.success(null));

      final container = ProviderContainer.test(overrides: [
        deleteTransactionUseCaseProvider.overrideWithValue(mockDelete),
      ]);

      final tx = _makeTx();
      await _pumpTile(tester, container, tx);

      await tester.drag(
        find.byType(ListTransactionTile),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
