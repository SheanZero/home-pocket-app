// Wave 0 test stub for ROW-02 soft-delete + hash-chain integrity (SC#3).
//
// This stub documents the test structure and contract. The test body calls
// fail('implement after AppDatabase.forTesting() setup') to remain in RED
// state until the full in-memory DB setup is wired in a later wave.
//
// Run: flutter test test/unit/features/list/delete_hash_chain_integrity_test.dart

// ignore_for_file: unused_import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show deleteTransactionUseCaseProvider;
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart'
    show appDatabaseProvider;

void main() {
  group('ROW-02 soft-delete hash-chain integrity', () {
    test(
        'soft-delete sets isDeleted=true and hash chain remains valid',
        () async {
      // Setup: in-memory test database via AppDatabase.forTesting()
      final db = AppDatabase.forTesting();
      final container = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );

      // Steps (to implement after DB+repo wiring):
      // 1. Insert 3 transactions via transactionRepository (establishes hash chain)
      // 2. Soft-delete the middle one via DeleteTransactionUseCase.execute(middleId)
      //    final useCase = container.read(deleteTransactionUseCaseProvider);
      //    await useCase.execute(middleId);

      // 3. Assert isDeleted = true on that row (via repository findById or DAO)
      // 4. Verify hash chain is valid on remaining non-deleted rows:
      //    final hashChain = HashChainService();
      //    hashChainService.verifyChain takes List<Map<String, dynamic>>:
      //      { transactionId, amount, timestamp, previousHash, currentHash }
      //    final result = hashChain.verifyChain(remainingMaps);
      //    expect(result.isValid, isTrue);

      // Dismiss unused-variable lint for the container stub reference.
      expect(container, isNotNull);

      // Stub body: RED state. Full implementation in wave after Phase 28-03.
      fail(
        'implement after AppDatabase.forTesting() repo insert + DAO raw-map fetch',
      );
    });
  });
}
