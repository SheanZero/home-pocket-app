import '../../features/accounting/domain/models/transaction.dart';
import '../../shared/constants/default_categories.dart';

/// Derives the non-authoritative `ledger_hint` for a merchant purely from its
/// `categoryId`, evaluated against the const `DefaultCategories` data (no DB
/// round-trip).
///
/// This is the SINGLE SOURCE OF TRUTH for ledger derivation at seed time. It
/// mirrors [CategoryService.resolveLedgerType] precedence exactly:
///
/// 1. Direct config lookup in [DefaultCategories.defaultLedgerConfigs] — catches
///    both L1 configs and L2 overrides.
/// 2. Otherwise, the L2 inherits its parent L1's config (via the category's
///    `parentId`).
///
/// A parity test (`ledger_hint_derivation_test.dart`) asserts this stays
/// byte-equal to `resolveLedgerType`, pre-empting the Phase-51 ledger desync.
/// Do NOT introduce a second hardcoded merchant→ledger map (D-09).
///
/// Throws [StateError] if [categoryId] has no resolvable ledger config. Callers
/// must only pass categoryIds that pass the `categoryId-∈-L2` gate; an
/// unresolvable id signals a data-integrity bug, not a runtime-recoverable case.
LedgerType deriveLedgerHint(String categoryId) {
  final configs = DefaultCategories.defaultLedgerConfigs;

  // 1. Direct config (L1 config or L2 override).
  for (final config in configs) {
    if (config.categoryId == categoryId) {
      return config.ledgerType;
    }
  }

  // 2. L2 without override → inherit from parent L1.
  final category = DefaultCategories.all.firstWhere(
    (c) => c.id == categoryId,
    orElse: () => throw StateError(
      'deriveLedgerHint: unknown categoryId "$categoryId" '
      '(not present in DefaultCategories)',
    ),
  );

  final parentId = category.parentId;
  if (parentId != null) {
    for (final config in configs) {
      if (config.categoryId == parentId) {
        return config.ledgerType;
      }
    }
  }

  throw StateError(
    'deriveLedgerHint: no ledger config resolvable for categoryId '
    '"$categoryId" (parent "$parentId")',
  );
}
