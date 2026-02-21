import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:ulid/ulid.dart';

import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/device_identity_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../infrastructure/crypto/services/hash_chain_service.dart';
import '../../shared/utils/result.dart';
import '../dual_ledger/classification_service.dart';

String _trunc(String s, [int len = 16]) =>
    s.length <= len ? s : '${s.substring(0, math.min(len, s.length))}...';

/// Parameters for creating a new transaction.
class CreateTransactionParams {
  final String bookId;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final DateTime? timestamp;
  final String? note;
  final String? merchant;
  final int? soulSatisfaction; // null = use default 5
  final LedgerType? ledgerType; // null = auto-classify

  const CreateTransactionParams({
    required this.bookId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.timestamp,
    this.note,
    this.merchant,
    this.soulSatisfaction,
    this.ledgerType,
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
  }) : _transactionRepo = transactionRepository,
       _categoryRepo = categoryRepository,
       _deviceIdentityRepo = deviceIdentityRepository,
       _hashChainService = hashChainService,
       _classificationService = classificationService;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final DeviceIdentityRepository _deviceIdentityRepo;
  final HashChainService _hashChainService;
  final ClassificationService _classificationService;

  /// Genesis hash: 64 zero characters (no previous transaction).
  static const _genesisHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    dev.log(
      '[1/7 UseCase Input] amount=${params.amount} (int), '
      'type=${params.type.name}, categoryId=${params.categoryId}, '
      'note=${params.note}, bookId=${params.bookId}',
      name: 'DataFlow',
    );

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

    // 4.5 Resolve & validate soul satisfaction
    final int soulSatisfaction;
    if (resolvedLedgerType == LedgerType.soul) {
      soulSatisfaction = params.soulSatisfaction ?? 5;
      if (soulSatisfaction < 1 || soulSatisfaction > 10) {
        return Result.error(
          'soulSatisfaction must be between 1 and 10, got $soulSatisfaction',
        );
      }
    } else {
      // Non-soul transactions always get default
      soulSatisfaction = 5;
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
    dev.log(
      '[2/7 HashChain Input] id=$id, amount=$hashAmount (double), '
      'timestamp=$hashTimestamp (epoch sec), prevHash=${_trunc(prevHash)}',
      name: 'DataFlow',
    );

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
      soulSatisfaction: soulSatisfaction,
    );

    dev.log(
      '[3/7 Domain Object] id=$id, amount=${transaction.amount} (int), '
      'note=${transaction.note}, currentHash=${_trunc(currentHash)}',
      name: 'DataFlow',
    );

    // 9. Persist
    await _transactionRepo.insert(transaction);

    dev.log('[7/7 UseCase Done] Transaction $id persisted', name: 'DataFlow');
    return Result.success(transaction);
  }
}
