import 'package:ulid/ulid.dart';

import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/device_identity_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../infrastructure/crypto/services/hash_chain_service.dart';
import '../../shared/utils/currency_conversion.dart';
import '../../shared/utils/result.dart';
import '../dual_ledger/classification_service.dart';
import '../family_sync/sync_engine.dart';
import '../family_sync/transaction_change_tracker.dart';

/// Parameters for creating a new transaction.
class CreateTransactionParams {
  final String bookId;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final DateTime? timestamp;
  final String? note;
  final String? merchant;
  final int? joyFullness; // null = use default 2
  final LedgerType? ledgerType; // null = auto-classify
  final EntrySource entrySource;

  // Foreign-currency provenance (partial-triple invariant: all three or none)
  final String? originalCurrency;
  final int? originalAmount;
  final String? appliedRate;

  const CreateTransactionParams({
    required this.bookId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.timestamp,
    this.note,
    this.merchant,
    this.joyFullness,
    this.ledgerType,
    // D-06: required, no default — every push site MUST specify.
    required this.entrySource,
    this.originalCurrency,
    this.originalAmount,
    this.appliedRate,
  });
}

/// Creates a new transaction with hash chain integrity.
///
/// Validates input, verifies category exists, computes hash chain link,
/// and persists the transaction.
class CreateTransactionUseCase {
  CreateTransactionUseCase({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required DeviceIdentityRepository deviceIdentityRepository,
    required HashChainService hashChainService,
    required ClassificationService classificationService,
    SyncEngine? syncEngine,
    TransactionChangeTracker? changeTracker,
  }) : _transactionRepo = transactionRepository,
       _categoryRepo = categoryRepository,
       _deviceIdentityRepo = deviceIdentityRepository,
       _hashChainService = hashChainService,
       _classificationService = classificationService,
       _syncEngine = syncEngine,
       _changeTracker = changeTracker;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final DeviceIdentityRepository _deviceIdentityRepo;
  final HashChainService _hashChainService;
  final ClassificationService _classificationService;
  final SyncEngine? _syncEngine;
  final TransactionChangeTracker? _changeTracker;

  /// Genesis hash: 64 zero characters (no previous transaction).
  static const _genesisHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    // 1. Validate input
    if (params.bookId.isEmpty) {
      return Result.error('bookId must not be empty');
    }
    if (params.amount <= 0) {
      return Result.error('amount must be greater than 0');
    }
    if (params.categoryId.isEmpty) {
      return Result.error('categoryId must not be empty');
    }

    // 1b. Foreign-currency triple validation (STORE-04 partial-triple invariant,
    // ADR-020 D-05 rate literal, WR-03 amount/currency shape) routed through the
    // single shared validator in currency_conversion.dart — same site used by
    // UpdateTransactionUseCase so the two never drift.
    final tripleResult = validateCurrencyTriple(
      originalCurrency: params.originalCurrency,
      originalAmount: params.originalAmount,
      appliedRate: params.appliedRate,
    );
    if (tripleResult.error != null) {
      return Result.error(tripleResult.error!);
    }
    if (tripleResult.isForeign) {
      // 1e. amount ↔ triple consistency (Phase 40 review WR-04): the hashed
      // JPY amount MUST be the canonical conversion of the triple. Callers
      // must derive amount via convertToJpy (ADR-020 Pitfall 1 — inline
      // arithmetic divergence is undetectable once persisted, because the
      // triple is excluded from the hash chain per ADR-021).
      final expectedAmount = tripleResult.jpyAmount!;
      if (params.amount != expectedAmount) {
        return Result.error(
          'amount (${params.amount}) does not match convertToJpy of the '
          'foreign-currency triple (expected $expectedAmount)',
        );
      }
    }

    // 2. Verify category exists
    final category = await _categoryRepo.findById(params.categoryId);
    if (category == null) {
      return Result.error('category not found');
    }

    // 3. Resolve device identity
    final deviceId = await _deviceIdentityRepo.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      return Result.error('deviceId is not available');
    }

    // 4. Determine ledger type: user override > auto-classification
    final LedgerType resolvedLedgerType;
    if (params.ledgerType != null) {
      resolvedLedgerType = params.ledgerType!;
    } else {
      final classification = await _classificationService.classify(
        categoryId: params.categoryId,
        merchant: params.merchant,
        note: params.note,
      );
      resolvedLedgerType = classification.ledgerType;
    }

    // 4.5 Resolve & validate joy fullness
    final int joyFullness;
    if (resolvedLedgerType == LedgerType.joy) {
      joyFullness = params.joyFullness ?? 2;
      if (joyFullness < 1 || joyFullness > 10) {
        return Result.error(
          'joyFullness must be between 1 and 10, got $joyFullness',
        );
      }
    } else {
      // Non-joy transactions always get default
      joyFullness = 2;
    }

    // 5. Get previous hash for chain
    final prevHash =
        await _transactionRepo.getLatestHash(params.bookId) ?? _genesisHash;

    // 6. Build transaction
    final id = Ulid().toString();
    final now = DateTime.now();
    final timestamp = params.timestamp ?? now;

    // 7. Compute hash chain
    final hashAmount = params.amount.toDouble();
    final hashTimestamp = timestamp.millisecondsSinceEpoch ~/ 1000;

    final currentHash = _hashChainService.calculateTransactionHash(
      transactionId: id,
      amount: hashAmount,
      timestamp: hashTimestamp,
      previousHash: prevHash,
    );

    // 8. Create domain object
    final transaction = Transaction(
      id: id,
      bookId: params.bookId,
      deviceId: deviceId,
      amount: params.amount,
      type: params.type,
      categoryId: params.categoryId,
      ledgerType: resolvedLedgerType,
      timestamp: timestamp,
      prevHash: prevHash,
      currentHash: currentHash,
      createdAt: now,
      note: params.note,
      merchant: params.merchant,
      joyFullness: joyFullness,
      entrySource: params.entrySource,
      originalCurrency: params.originalCurrency,
      originalAmount: params.originalAmount,
      appliedRate: params.appliedRate,
    );

    // 9. Persist
    await _transactionRepo.insert(transaction);

    // Track for incremental sync push
    _changeTracker?.trackCreate(
      TransactionSyncMapper.toCreateOperation(
        transaction,
        sourceBookId: params.bookId,
        sourceBookName: params.bookId,
        sourceBookType: 'remote_book:${params.bookId}',
      ),
    );

    // Fire-and-forget sync trigger — SyncEngine handles debounce and validity.
    _syncEngine?.onTransactionChanged();

    return Result.success(transaction);
  }
}
