import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:home_pocket/shared/constants/default_synonyms.dart';

/// HARD GATE (Phase 50 DECOUP-02, D-04 / Pitfall 3): every
/// [DefaultVoiceSynonyms] seed `categoryId` MUST be a categoryId the resolver
/// can actually land on — either a real L2 id, OR an L1 id that
/// [VoiceCategoryResolver._ensureL2] resolves to one of its L2 children.
///
/// This blocks the silent-null bug class: a typo in any of the ~200+
/// hand-authored seed rows pointing at a non-existent id would otherwise
/// resolve to null on `findById` with no compile-time complaint.
///
/// KEY DIFFERENCE from the Phase-49 merchant gate
/// (`default_merchants_categoryid_test.dart`): merchant rows must be a real
/// L2 (level == 2). Synonym seeds legitimately ALSO use L1 ids (e.g.
/// `食事` -> `cat_food`), relying on `_ensureL2`'s `${l1}_other` /
/// first-child net. So the legal set here is `l2Ids` UNION `l1WithChild`.
void main() {
  // Real L2 ids: every Category whose level == 2.
  final l2Ids = DefaultCategories.all
      .where((c) => c.level == 2)
      .map((c) => c.id)
      .toSet();

  // L1 ids that have at least one L2 child — these are `_ensureL2`-resolvable
  // (the resolver routes `cat_food` -> `cat_food_other` or its first child).
  // An L1 with NO child would resolve to null, so it must NOT be legal.
  final l1WithChild = DefaultCategories.all
      .where(
        (c) =>
            c.level == 1 &&
            DefaultCategories.all.any((x) => x.parentId == c.id),
      )
      .map((c) => c.id)
      .toSet();

  // The legal categoryId set a seed may point at.
  final legalIds = {...l2Ids, ...l1WithChild};

  group('DefaultVoiceSynonyms categoryId integrity', () {
    test('seed list is non-empty', () {
      expect(DefaultVoiceSynonyms.all, isNotEmpty);
    });

    test('l1WithChild legal set is non-empty (guards a broken filter)', () {
      expect(l1WithChild, isNotEmpty);
    });

    test(
      'every seed categoryId is a real L2 id OR an _ensureL2-resolvable L1',
      () {
        // Build the offenders list so a failure names the exact bad rows.
        final offenders = DefaultVoiceSynonyms.all
            .where((s) => !legalIds.contains(s.categoryId))
            .map((s) => '"${s.keyword}" -> ${s.categoryId}')
            .toList();

        expect(
          offenders,
          isEmpty,
          reason:
              'These seeds map to a categoryId that is neither a real L2 nor '
              'an L1-with-child (silent-null risk, Pitfall 3):\n'
              '${offenders.join('\n')}',
        );
      },
    );

    test('every seed categoryId resolves the FULL seed list (no sampling)', () {
      // Exercise EVERY entry, not a subset — guards against a partial-coverage
      // gate that would let a tail offender slip through.
      for (final s in DefaultVoiceSynonyms.all) {
        expect(
          legalIds.contains(s.categoryId),
          isTrue,
          reason:
              'Seed "${s.keyword}" maps to non-legal categoryId ${s.categoryId}',
        );
      }
    });
  });
}
