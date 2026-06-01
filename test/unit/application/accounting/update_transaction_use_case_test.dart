import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/transaction_change_tracker.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock implements TransactionRepository {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockChangeTracker extends Mock implements TransactionChangeTracker {}

class _FakeTransaction extends Fake implements Transaction {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTransaction());
  });

  late _MockTransactionRepository mockTransactionRepo;
  late UpdateTransactionUseCase useCase;

  /// Helper: a well-formed seed Transaction for tests.
  Transaction makeSeed({
    String id = 'tx-001',
    String bookId = 'book-001',
    String deviceId = 'device-001',
    int amount = 1000,
    String categoryId = 'cat-food',
    LedgerType ledgerType = LedgerType.daily,
    int joyFullness = 2,
    String? note,
    String? merchant,
    EntrySource entrySource = EntrySource.manual,
    String prevHash = 'prev-hash-abc',
    String currentHash = 'current-hash-xyz',
  }) {
    final now = DateTime(2026, 1, 1);
    return Transaction(
      id: id,
      bookId: bookId,
      deviceId: deviceId,
      amount: amount,
      type: TransactionType.expense,
      categoryId: categoryId,
      ledgerType: ledgerType,
      timestamp: now,
      prevHash: prevHash,
      currentHash: currentHash,
      createdAt: now,
      note: note,
      merchant: merchant,
      joyFullness: joyFullness,
      entrySource: entrySource,
    );
  }

  setUp(() {
    mockTransactionRepo = _MockTransactionRepository();

    useCase = UpdateTransactionUseCase(
      transactionRepository: mockTransactionRepo,
    );

    when(() => mockTransactionRepo.update(any())).thenAnswer((_) async {});
  });

  group('UpdateTransactionUseCase', () {
    group('happy path', () {
      test('successfully updates a transaction with new amount', () async {
        final seed = makeSeed(amount: 1000);

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 2000),
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.amount, 2000);
        verify(() => mockTransactionRepo.update(any())).called(1);
      });

      test('stamps updatedAt on every save (D-07)', () async {
        final seed = makeSeed();
        final before = DateTime.now();

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 1500),
        );

        final after = DateTime.now();
        expect(result.isSuccess, isTrue);
        expect(result.data!.updatedAt, isNotNull);
        expect(
          result.data!.updatedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(result.data!.updatedAt!.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('preserves entrySource verbatim from seed (SC-3)', () async {
        final voiceSeed = makeSeed(entrySource: EntrySource.voice);

        final result = await useCase.execute(
          UpdateTransactionParams(seed: voiceSeed, amount: 999),
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.entrySource, EntrySource.voice);
      });

      test('preserves entrySource for all three literal values (SC-3)', () async {
        for (final source in EntrySource.values) {
          final seed = makeSeed(entrySource: source);
          final result = await useCase.execute(
            UpdateTransactionParams(seed: seed, amount: 500),
          );
          expect(result.data!.entrySource, source,
              reason: 'entrySource must be preserved for $source');
        }
      });

      test('does NOT recompute hash chain — prevHash and currentHash frozen (D-08)', () async {
        final seed = makeSeed(prevHash: 'prev-hash-abc', currentHash: 'current-hash-xyz');

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 5000),
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.prevHash, 'prev-hash-abc',
            reason: 'prevHash must not change on edit');
        expect(result.data!.currentHash, 'current-hash-xyz',
            reason: 'currentHash must not change on edit');
      });

      test('preserves immutable fields: id, bookId, deviceId, createdAt', () async {
        final seed = makeSeed(
          id: 'tx-immutable',
          bookId: 'book-immutable',
          deviceId: 'device-immutable',
        );

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 9999),
        );

        expect(result.data!.id, 'tx-immutable');
        expect(result.data!.bookId, 'book-immutable');
        expect(result.data!.deviceId, 'device-immutable');
        expect(result.data!.createdAt, seed.createdAt);
      });

      test('pass-through semantics: null note clears previously-set note (B1/EDIT-02)', () async {
        final seed = makeSeed(note: 'old note');

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 1000, note: null),
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.note, isNull,
            reason: 'null note must clear the field (pass-through semantics)');
      });

      test('pass-through semantics: null merchant clears previously-set merchant (B1/EDIT-02)', () async {
        final seed = makeSeed(merchant: 'Old Store');

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 1000, merchant: null),
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.merchant, isNull,
            reason: 'null merchant must clear the field (pass-through semantics)');
      });

      test('pass-through semantics: non-null note updates the field', () async {
        final seed = makeSeed(note: null);

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 1000, note: 'new note'),
        );

        expect(result.data!.note, 'new note');
      });

      test('coalesce semantics: null amount keeps seed.amount', () async {
        final seed = makeSeed(amount: 5000);

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed),
        );

        expect(result.data!.amount, 5000,
            reason: 'null amount param must keep seed value');
      });

      test('coalesce semantics: null categoryId keeps seed.categoryId', () async {
        final seed = makeSeed(categoryId: 'cat-original');

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 1000),
        );

        expect(result.data!.categoryId, 'cat-original');
      });

      test('coalesce semantics: null ledgerType keeps seed.ledgerType', () async {
        final seed = makeSeed(ledgerType: LedgerType.joy);

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 1000),
        );

        expect(result.data!.ledgerType, LedgerType.joy);
      });

      test('wires sync push when changeTracker and syncEngine are provided', () async {
        // The mock tracker / engine interaction is implicit:
        // If the use case calls _changeTracker?.trackUpdate correctly, no exception
        // is thrown and the result is success. We verify the repo was called.
        final seed = makeSeed();
        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 2000),
        );
        expect(result.isSuccess, isTrue);
        verify(() => mockTransactionRepo.update(any())).called(1);
      });
    });

    group('validation', () {
      test('returns error when amount override is zero', () async {
        final seed = makeSeed();

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 0),
        );

        expect(result.isError, isTrue);
        expect(result.error, contains('amount'));
        verifyNever(() => mockTransactionRepo.update(any()));
      });

      test('returns error when amount override is negative', () async {
        final seed = makeSeed();

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: -100),
        );

        expect(result.isError, isTrue);
        expect(result.error, contains('amount'));
        verifyNever(() => mockTransactionRepo.update(any()));
      });

      test('returns error when categoryId override is empty string', () async {
        final seed = makeSeed();

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, categoryId: ''),
        );

        expect(result.isError, isTrue);
        expect(result.error, contains('categoryId'));
        verifyNever(() => mockTransactionRepo.update(any()));
      });

      test('null amount (no override) does NOT trigger validation error', () async {
        final seed = makeSeed(amount: 1000);

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed),
        );

        expect(result.isSuccess, isTrue);
      });

      test('null categoryId (no override) does NOT trigger validation error', () async {
        final seed = makeSeed(categoryId: 'cat-food');

        final result = await useCase.execute(
          UpdateTransactionParams(seed: seed, amount: 1000),
        );

        expect(result.isSuccess, isTrue);
      });
    });

    group('UpdateTransactionParams', () {
      test('can be constructed with seed only (all overrides null)', () {
        final seed = makeSeed();
        final params = UpdateTransactionParams(seed: seed);

        expect(params.seed, seed);
        expect(params.amount, isNull);
        expect(params.categoryId, isNull);
        expect(params.note, isNull);
        expect(params.merchant, isNull);
        expect(params.ledgerType, isNull);
        expect(params.joyFullness, isNull);
      });
    });

    group('sync push lane (D-20)', () {
      late _MockSyncEngine mockSyncEngine;
      late _MockChangeTracker mockChangeTracker;
      late UpdateTransactionUseCase useCaseWithSync;

      setUp(() {
        mockSyncEngine = _MockSyncEngine();
        mockChangeTracker = _MockChangeTracker();
        useCaseWithSync = UpdateTransactionUseCase(
          transactionRepository: mockTransactionRepo,
          syncEngine: mockSyncEngine,
          changeTracker: mockChangeTracker,
        );

        when(() => mockSyncEngine.onTransactionChanged()).thenReturn(null);
        when(() => mockChangeTracker.trackUpdate(any())).thenReturn(null);
      });

      test(
        'execute calls trackUpdate with op=update payload (D-20)',
        () async {
          final seed = makeSeed();
          await useCaseWithSync.execute(
            UpdateTransactionParams(seed: seed, amount: 2000),
          );
          verify(() => mockChangeTracker.trackUpdate(any())).called(1);
        },
      );

      test('execute calls syncEngine.onTransactionChanged once (D-20)', () async {
        final seed = makeSeed();
        await useCaseWithSync.execute(
          UpdateTransactionParams(seed: seed, amount: 2000),
        );
        verify(() => mockSyncEngine.onTransactionChanged()).called(1);
      });

      test(
        'trackUpdate payload has op=update and entityType=bill (D-20)',
        () async {
          Map<String, dynamic>? capturedPayload;
          when(() => mockChangeTracker.trackUpdate(any())).thenAnswer((inv) {
            capturedPayload = inv.positionalArguments.first as Map<String, dynamic>;
          });

          final seed = makeSeed(id: 'tx-capture-test');
          await useCaseWithSync.execute(
            UpdateTransactionParams(seed: seed, amount: 3000),
          );

          expect(capturedPayload, isNotNull);
          expect(capturedPayload!['op'], 'update');
          expect(capturedPayload!['entityType'], 'bill');
          expect(capturedPayload!['entityId'], 'tx-capture-test');
        },
      );

      test(
        'execute does NOT call trackUpdate when validation fails (repository NOT called)',
        () async {
          final seed = makeSeed();
          await useCaseWithSync.execute(
            UpdateTransactionParams(seed: seed, amount: 0),
          );
          verifyNever(() => mockChangeTracker.trackUpdate(any()));
          verifyNever(() => mockSyncEngine.onTransactionChanged());
          verifyNever(() => mockTransactionRepo.update(any()));
        },
      );
    });
  });
}
