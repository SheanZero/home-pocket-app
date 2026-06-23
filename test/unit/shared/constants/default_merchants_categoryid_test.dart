import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:home_pocket/shared/constants/default_merchants.dart';

/// HARD GATE (T-49-CAT, Pitfall #5): every DefaultMerchants.categoryId MUST be
/// a real L2 id in DefaultCategories. This blocks the D-04 silent-null bug class
/// (a merchant mapped to an L1 / removed id resolves to null on findById).
void main() {
  // The single source of truth for the legal L2 id set: every Category whose
  // level == 2 (equivalently parentId != null) in DefaultCategories.
  final l2Ids = DefaultCategories.all
      .where((c) => c.level == 2)
      .map((c) => c.id)
      .toSet();

  group('DefaultMerchants categoryId integrity', () {
    test('seed list is non-empty', () {
      expect(DefaultMerchants.all, isNotEmpty);
    });

    test('every merchant categoryId is a real L2 id in DefaultCategories', () {
      // Build the offenders list so a failure names the exact bad rows.
      final offenders = DefaultMerchants.all
          .where((m) => !l2Ids.contains(m.categoryId))
          .map((m) => '${m.id} -> ${m.categoryId}')
          .toList();

      expect(
        offenders,
        isEmpty,
        reason:
            'These merchants map to a categoryId that is not a real L2 id '
            '(D-04 silent-null risk):\n${offenders.join('\n')}',
      );
    });

    test('every merchant categoryId resolves the FULL seed list (no sampling)',
        () {
      // Exercise EVERY entry, not a subset — guards against a partial-coverage
      // gate that would let a tail offender slip through.
      for (final m in DefaultMerchants.all) {
        expect(
          l2Ids.contains(m.categoryId),
          isTrue,
          reason: 'Merchant ${m.id} maps to non-L2 categoryId ${m.categoryId}',
        );
      }
    });

    test('merchant ids are unique', () {
      final ids = DefaultMerchants.all.map((m) => m.id).toList();
      final dupes = <String>{};
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) dupes.add(id);
      }
      expect(dupes, isEmpty, reason: 'Duplicate merchant ids: $dupes');
    });

    test('every merchant id starts with mer_ (stable authored id scheme)', () {
      final bad = DefaultMerchants.all
          .where((m) => !m.id.startsWith('mer_'))
          .map((m) => m.id)
          .toList();
      expect(bad, isEmpty, reason: 'Merchant ids must start with mer_: $bad');
    });

    test('every merchant has a non-empty nameJa', () {
      final bad = DefaultMerchants.all
          .where((m) => m.nameJa.trim().isEmpty)
          .map((m) => m.id)
          .toList();
      expect(bad, isEmpty, reason: 'Merchants with empty nameJa: $bad');
    });
  });
}
