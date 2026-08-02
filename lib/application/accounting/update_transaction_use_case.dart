import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/models/transaction_family_sync_policy.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/currency_conversion.dart';
import '../../shared/utils/result.dart';
import '../family_sync/sync_engine.dart';
import '../family_sync/category_reference_sync_service.dart';
import '../family_sync/transaction_change_tracker.dart';
import '../family_sync/transaction_sync_version.dart';

/// Parameters for updating an existing transaction.
///
/// ## Pass-through vs coalesce semantics (EDIT-02 contract)
///
/// **Pass-through fields (`note`, `merchant`):** These are applied verbatim to
/// [seed.copyWith] without a coalesce operator. The form always sends the user's
/// final post-edit value:
/// - Non-null string: the user typed something; update the field.
/// - `null`: the user cleared the field; set the field to null (delete it).
///
/// This makes "user clears note → save → row's note is null" a reachable state,
/// satisfying EDIT-02 ("user can modify any editable field").
///
/// **Coalesce fields (`amount`, `categoryId`, `timestamp`, `ledgerType`,
/// `joyFullness`):** These use `?? seed.field` because `null` means
/// "form did not send an override for this field — keep the seed value". These
/// fields are never user-clearable via the form; they always have a value when
/// set by the user.
class UpdateTransactionParams {
  final Transaction seed;
  final int? amount;
  final String? categoryId;
  final DateTime? timestamp;

  /// Pass-through: `null` means "user cleared the field". No coalesce operator.
  final String? note;

  /// Pass-through: `null` means "user cleared the field". No coalesce operator.
  final String? merchant;

  final LedgerType? ledgerType;
  final int? joyFullness;
  final bool? isPrivate;

  /// Foreign-currency provenance triple (originalCurrency / originalAmount /
  /// appliedRate). Coalesce semantics (EDIT-02): `null` means "form did not
  /// send an override — keep the seed's existing currency fields". When the
  /// triple is supplied, [execute] recomputes [amount] via the single-site
  /// `convertToJpy()` (ADR-020) and re-validates the partial-triple invariant.
  ///
  /// These fields are EXCLUDED from the hash chain (ADR-021) — editing them
  /// never rehashes the row.
  final String? originalCurrency;
  final int? originalAmount;
  final String? appliedRate;

  const UpdateTransactionParams({
    required this.seed,
    this.amount,
    this.categoryId,
    this.timestamp,
    this.note,
    this.merchant,
    this.ledgerType,
    this.joyFullness,
    this.isPrivate,
    this.originalCurrency,
    this.originalAmount,
    this.appliedRate,
  });
}

/// Updates an existing transaction in the database.
///
/// Mirrors [CreateTransactionUseCase] shape (params class + execute(params)
/// returning `Future<Result<Transaction>>`).
///
/// Key invariants:
/// - Seven mutable fields: `amount`, `categoryId`, `timestamp`, `note`,
///   `merchant`, `ledgerType`, `joyFullness` (D-07).
/// - Seven immutable fields re-saved verbatim via [copyWith] default:
///   `id`, `bookId`, `deviceId`, `prevHash`, `currentHash`, `createdAt`,
///   `entrySource` (D-07 / D-08 / SC-3).
/// - `updatedAt` is stamped to [DateTime.now] on every save (D-07).
/// - Hash chain is NOT recomputed (D-08) — `currentHash`/`prevHash` stay frozen.
/// - On success: change tracker + sync engine are notified (D-20).
class UpdateTransactionUseCase {
  UpdateTransactionUseCase({
    required TransactionRepository transactionRepository,
    SyncEngine? syncEngine,
    TransactionChangeTracker? changeTracker,
    CategoryReferenceSyncService? categoryReferenceSyncService,
  }) : _transactionRepo = transactionRepository,
       _syncEngine = syncEngine,
       _changeTracker = changeTracker,
       _categoryReferenceSyncService = categoryReferenceSyncService;

  final TransactionRepository _transactionRepo;
  final SyncEngine? _syncEngine;
  final TransactionChangeTracker? _changeTracker;
  final CategoryReferenceSyncService? _categoryReferenceSyncService;

  Future<Result<Transaction>> execute(UpdateTransactionParams params) async {
    // 1. Validate overrides (only when non-null — null means "no change")
    if (params.amount != null && params.amount! <= 0) {
      return Result.error('amount must be greater than 0');
    }
    if (params.categoryId != null && params.categoryId!.isEmpty) {
      return Result.error('categoryId must not be empty');
    }

    // 1b. Foreign-currency triple (DISP-03/DISP-04). Coalesce each field from
    //     the seed (EDIT-02 — omitted triple keeps the row's existing currency
    //     provenance, does NOT null it out). The coalesced triple is then
    //     validated and converted through the SAME shared site as
    //     CreateTransactionUseCase (currency_conversion.dart), so the two paths
    //     can never drift.
    final originalCurrency =
        params.originalCurrency ?? params.seed.originalCurrency;
    final originalAmount = params.originalAmount ?? params.seed.originalAmount;
    final appliedRate = params.appliedRate ?? params.seed.appliedRate;

    final tripleResult = validateCurrencyTriple(
      originalCurrency: originalCurrency,
      originalAmount: originalAmount,
      appliedRate: appliedRate,
    );
    if (tripleResult.error != null) {
      return Result.error(tripleResult.error!);
    }

    // For a foreign row, the JPY `amount` is DERIVED from the triple via the
    // single-site convertToJpy() (ADR-020 .round()) — never an inline product,
    // and it overrides any explicit amount param so the stored amount always
    // matches the triple. For a native (JPY) row, fall back to the normal
    // amount coalesce.
    final int resolvedAmount = tripleResult.isForeign
        ? tripleResult.jpyAmount!
        : (params.amount ?? params.seed.amount);

    // 2. Build updated row from seed.copyWith (CLAUDE.md Pitfall #4 — immutability)
    //    Coalesce fields: null param → keep seed value.
    //    Pass-through fields: note/merchant applied verbatim (null = user cleared).
    //    Immutable fields (id, bookId, deviceId, prevHash, currentHash, createdAt,
    //    entrySource) flow through copyWith default — D-07 / D-08 / SC-3.
    //
    //    Currency fields are EXCLUDED from the hash chain (ADR-021): editing
    //    them recomputes `amount` but the row's prevHash/currentHash flow
    //    through copyWith UNCHANGED — there is NO rehash on this path.
    final now = DateTime.now();
    final resolvedIsPrivate = params.isPrivate ?? params.seed.isPrivate;
    final logicalRevision = nextSyncRevision(params.seed, now);
    final nextRevision = logicalRevision > params.seed.familySharedRevision
        ? logicalRevision
        : params.seed.familySharedRevision + 1;
    final familySyncVisibility =
        TransactionFamilySyncPolicy.visibilityForUpdate(
          before: params.seed,
          isPrivate: resolvedIsPrivate,
        );
    final updated = params.seed.copyWith(
      amount: resolvedAmount,
      categoryId: params.categoryId ?? params.seed.categoryId,
      timestamp: params.timestamp ?? params.seed.timestamp,
      note: params
          .note, // pass-through: no ?? — null clears the field (B1/EDIT-02)
      merchant: params
          .merchant, // pass-through: no ?? — null clears the field (B1/EDIT-02)
      ledgerType: params.ledgerType ?? params.seed.ledgerType,
      joyFullness: params.joyFullness ?? params.seed.joyFullness,
      originalCurrency: originalCurrency,
      originalAmount: originalAmount,
      appliedRate: appliedRate,
      updatedAt: now, // D-07: stamp on every save
      isPrivate: resolvedIsPrivate,
      syncRevision: nextRevision,
      syncOriginDeviceId: params.seed.deviceId,
      familySyncVisibility: familySyncVisibility,
      familySharedRevision: familySyncVisibility == FamilySyncVisibility.shared
          ? nextRevision
          : params.seed.familySharedRevision,
      // entrySource, id, bookId, deviceId, prevHash, currentHash, createdAt
      // are preserved by copyWith default (D-07/D-08/SC-3).
    );

    // 3. Build the operation before persistence so the production repository
    // can atomically commit the business mutation and durable outbox row.
    Map<String, dynamic>? syncOperation;
    if (TransactionFamilySyncPolicy.shouldSendWithdrawal(updated)) {
      syncOperation = TransactionSyncMapper.toWithdrawalOperation(updated);
    } else if (TransactionFamilySyncPolicy.shouldSendLive(updated)) {
      syncOperation = TransactionSyncMapper.toUpdateOperation(
        updated,
        sourceBookId: updated.bookId,
        sourceBookName: updated.bookId,
        sourceBookType: 'remote_book:${updated.bookId}',
      );
      final categorySync = _categoryReferenceSyncService;
      if (categorySync != null) {
        syncOperation = await categorySync.attachToBillOperation(
          transaction: updated,
          operation: syncOperation,
        );
      }
    }

    final durableRepository =
        _transactionRepo is DurableFamilySyncTransactionRepository
        ? _transactionRepo as DurableFamilySyncTransactionRepository
        : null;
    final usesDurableOutbox = durableRepository != null;
    final outboxEnqueued = durableRepository != null
        ? await durableRepository.updateWithFamilySyncOutbox(
            updated,
            operation: syncOperation,
          )
        : await _updateLegacy(updated);

    if (syncOperation != null && !usesDurableOutbox) {
      if (syncOperation['op'] == 'delete') {
        _changeTracker?.trackDelete(
          transactionId: updated.id,
          bookId: updated.bookId,
          operation: syncOperation,
        );
      } else {
        _changeTracker?.trackUpdate(syncOperation);
      }
    }

    if (syncOperation != null && (outboxEnqueued || !usesDurableOutbox)) {
      // Fire-and-forget sync trigger — SyncEngine handles debounce (D-20).
      _syncEngine?.onTransactionChanged();
    }

    return Result.success(updated);
  }

  Future<bool> _updateLegacy(Transaction transaction) async {
    await _transactionRepo.update(transaction);
    return false;
  }
}
