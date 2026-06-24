import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

/// Architecture invariant test — Phase 51 D-19 (LEDGER-02).
///
/// Asserts that EVERY reachable category (19 L1 + every L2) in
/// `DefaultCategories.all` resolves to a non-null [LedgerType] under the same
/// resolution rule [CategoryService.resolveLedgerType] uses:
///   - direct config (L1, or an L2 with an override) → its own ledger
///   - L2 without override → inherits its parent L1's config ledger
///   - else → null
///
/// This is a pure const-data variant (no DB), mirroring `deriveLedgerHint`'s
/// pure evaluation and `category_other_l2_invariant_test.dart`'s structure. It
/// is a REGRESSION NET, not a current-gap filler: D-17 confirms there are no
/// null gaps today (all 19 L1 have a config, so every L2 inherits non-null).
/// It traps a FUTURE edit that adds an L1 without a config, or an L2 whose
/// parent L1 config is missing — either of which would let a category silently
/// fall back to `LedgerType.daily` in production, masking the config gap.
///
/// Run: flutter test test/architecture/ledger_reachable_l2_invariant_test.dart

/// Pure const-data resolver mirroring `CategoryService.resolveLedgerType`'s
/// rule over `DefaultCategories.defaultLedgerConfigs` + `DefaultCategories.all`.
/// Returns null when neither a direct config nor a parent-L1 config exists.
LedgerType? _resolveLedger(String categoryId) {
  final configByCategoryId = {
    for (final c in DefaultCategories.defaultLedgerConfigs)
      c.categoryId: c.ledgerType,
  };
  final categoryById = {for (final c in DefaultCategories.all) c.id: c};

  final category = categoryById[categoryId];
  if (category == null) return null;

  // Direct config (works for both L1 and L2-with-override).
  final direct = configByCategoryId[categoryId];
  if (direct != null) return direct;

  // L2 without override → inherit from parent L1.
  if (category.level == 2 && category.parentId != null) {
    return configByCategoryId[category.parentId!];
  }

  return null;
}

void main() {
  group('Reachable-L2 ledger non-null invariant (Phase 51 D-19)', () {
    test(
      'every expense L1 and every L2 resolves to a non-null LedgerType',
      () {
        // Sanity guard: 19 expense L1 per PRD §10.0. A count change means
        // `default_categories.dart`'s tree was edited — re-validate that every
        // L1 still carries a ledger config before adjusting this gate.
        expect(
          DefaultCategories.expenseL1.length,
          19,
          reason:
              'Expected exactly 19 expense L1 categories per PRD §10.0; '
              'a count change suggests `default_categories.dart` was edited '
              '— re-validate that every reachable category still resolves to a '
              'non-null ledger (D-19) before adjusting this gate.',
        );

        for (final cat in DefaultCategories.all) {
          expect(
            _resolveLedger(cat.id),
            isNotNull,
            reason:
                'category ${cat.id} (level ${cat.level}) resolves to null '
                'ledger — silent daily fallback would mask a config gap '
                '(LEDGER-02 D-19). Add a ledger config for this category (or '
                'for its parent L1) in `_defaultLedgerConfigs`.',
          );
        }
      },
    );
  });
}
