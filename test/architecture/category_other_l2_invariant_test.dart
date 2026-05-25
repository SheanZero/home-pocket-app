import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/constants/category_other_id_overrides.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

/// Architecture invariant test — Phase 21 D-03.
///
/// Asserts that every L1 in `DefaultCategories.expenseL1` has a corresponding
/// L2 reachable via the `${l1Id}_other` naming convention, with one documented
/// override: `cat_other_expense` resolves to `cat_other_other` (NOT
/// `cat_other_expense_other`) — see `default_categories.dart:1181`.
///
/// Phase 21 CONTEXT.md D-03:
///   "When a match resolves only to L1, the resolver returns `${l1Id}_other`
///    (e.g., `cat_food` → `cat_food_other`, `cat_transport` → `cat_transport_other`)."
///
/// VoiceCategoryResolver._ensureL2 (Plan 03) depends on this invariant. If a
/// future edit to `default_categories.dart` removes or renames an `_other` L2,
/// the resolver would silently degrade — this test traps that drift at CI
/// time, well before the resolver fallback runs in production.
///
/// Override map note (CONTEXT.md D-03): the `cat_other_expense` L1 aliases to
/// `cat_other_other` rather than the synthetic `cat_other_expense_other`. The
/// override is intentional and historical — destructive renaming is forbidden
/// without an ADR (PATTERNS.md §7 caveat), so we accommodate it here. Adding
/// entries to [kCategoryOtherIdOverrides] is permitted ONLY after
/// VoiceCategoryResolver._ensureL2 (Plan 03) is updated to consult the same
/// map.
///
/// Phase 23 D-12 IN-05: the override map was moved to
/// lib/shared/constants/category_other_id_overrides.dart as [kCategoryOtherIdOverrides].
///
/// Run: flutter test test/architecture/category_other_l2_invariant_test.dart

// Override map moved to lib/shared/constants/category_other_id_overrides.dart per Phase 23 D-12 IN-05

void main() {
  group('Category L2 _other invariant (Phase 21 D-03)', () {
    test(
      'every expense L1 has a corresponding \${l1Id}_other L2 (with documented overrides)',
      () {
        final l1Ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();

        // Sanity guard: 19 L1s per CONTEXT.md (PRD §10.0); if this changes,
        // re-read D-03 and confirm the override map is still correct.
        expect(
          l1Ids.length,
          19,
          reason:
              'Expected exactly 19 expense L1 categories per PRD §10.0; '
              'a count change suggests `default_categories.dart` was edited '
              '— re-validate Phase 21 D-03 assumptions before adjusting this gate.',
        );

        final l2ById = {
          for (final c in DefaultCategories.all.where((c) => c.level == 2))
            c.id: c,
        };

        final missing = <String>[];
        for (final l1Id in l1Ids) {
          final expectedOtherId = kCategoryOtherIdOverrides[l1Id] ?? '${l1Id}_other';
          final otherL2 = l2ById[expectedOtherId];
          if (otherL2 == null) {
            missing.add(l1Id);
            continue;
          }
          expect(
            otherL2.level,
            2,
            reason:
                '$expectedOtherId must be level=2 (L1=$l1Id) — Phase 21 D-03 invariant',
          );
          expect(
            otherL2.parentId,
            l1Id,
            reason:
                '$expectedOtherId parentId must equal $l1Id — Phase 21 D-03 invariant',
          );
        }

        expect(
          missing,
          isEmpty,
          reason:
              'Missing _other L2 for L1(s): $missing — Phase 21 D-03 invariant broken; '
              'VoiceCategoryResolver fallback will degrade. Either add the missing '
              '`<l1Id>_other` L2 to `default_categories.dart`, or — if the L2 must '
              'use a non-convention id — add an entry to `kCategoryOtherIdOverrides` '
              'in lib/shared/constants/category_other_id_overrides.dart '
              'AND update VoiceCategoryResolver._ensureL2 (Plan 03) to consult it.',
        );
      },
    );
  });
}
