import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/transaction_change_tracker.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _FakeTransaction extends Fake implements Transaction {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTransaction()));
  late _MockTransactionRepository mockRepo;
  late DeleteTransactionUseCase useCase;

  setUp(() {
    mockRepo = _MockTransactionRepository();
    useCase = DeleteTransactionUseCase(transactionRepository: mockRepo);
  });

  group('DeleteTransactionUseCase', () {
    test('soft-deletes an existing transaction', () async {
      when(() => mockRepo.findById('tx_001')).thenAnswer(
        (_) async => Transaction(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_local',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.daily,
          timestamp: DateTime(2026, 2, 6),
          currentHash: 'hash_001',
          createdAt: DateTime(2026, 2, 6),
        ),
      );
      when(() => mockRepo.update(any())).thenAnswer((_) async {});

      final result = await useCase.execute('tx_001');

      expect(result.isSuccess, isTrue);
      final tombstone =
          verify(() => mockRepo.update(captureAny())).captured.single
              as Transaction;
      expect(tombstone.isDeleted, isTrue);
      expect(tombstone.syncRevision, greaterThan(0));
    });

    test('returns error when transaction not found', () async {
      when(
        () => mockRepo.findById('nonexistent'),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute('nonexistent');

      expect(result.isError, isTrue);
      expect(result.error, contains('not found'));
      verifyNever(() => mockRepo.update(any()));
    });

    test('returns error when id is empty', () async {
      final result = await useCase.execute('');

      expect(result.isError, isTrue);
      verifyNever(() => mockRepo.findById(any()));
    });

    test('soft-deletes successfully without sync engine', () async {
      when(() => mockRepo.findById('tx_002')).thenAnswer(
        (_) async => Transaction(
          id: 'tx_002',
          bookId: 'book_001',
          deviceId: 'dev_local',
          amount: 500,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.daily,
          timestamp: DateTime(2026, 3, 15),
          currentHash: 'hash_002',
          createdAt: DateTime(2026, 3, 15),
        ),
      );
      when(() => mockRepo.update(any())).thenAnswer((_) async {});

      final result = await useCase.execute('tx_002');

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.update(any())).called(1);
    });

    test(
      'delete shared transaction sends minimal historical withdrawal',
      () async {
        final tracker = TransactionChangeTracker();
        final sharedUseCase = DeleteTransactionUseCase(
          transactionRepository: mockRepo,
          changeTracker: tracker,
        );
        when(() => mockRepo.findById('shared')).thenAnswer(
          (_) async => Transaction(
            id: 'shared',
            bookId: 'book_001',
            deviceId: 'dev_local',
            amount: 900,
            type: TransactionType.expense,
            categoryId: 'secret-category',
            ledgerType: LedgerType.daily,
            timestamp: DateTime(2026, 3, 15),
            note: 'secret-note',
            currentHash: 'hash',
            createdAt: DateTime(2026, 3, 15),
            syncRevision: 8,
            syncOriginDeviceId: 'dev_local',
            familySyncVisibility: FamilySyncVisibility.shared,
            familySharedRevision: 8,
          ),
        );
        when(() => mockRepo.update(any())).thenAnswer((_) async {});

        expect((await sharedUseCase.execute('shared')).isSuccess, isTrue);
        final operation = tracker.flush().single;
        expect(operation['op'], 'delete');
        expect(
          (operation['data'] as Map<String, dynamic>).keys,
          unorderedEquals({'isDeleted', 'syncRevision', 'syncOriginDeviceId'}),
        );
        expect(operation.toString(), isNot(contains('secret')));
      },
    );
  });
}
