/// L1 ids whose `_other` L2 child does NOT follow the `${l1Id}_other`
/// convention. Single source of truth — both [VoiceCategoryResolver] and
/// the architecture test `test/architecture/category_other_l2_invariant_test.dart`
/// import this map.
///
/// Phase 21 D-03 + Phase 23 D-12 IN-05: Previously duplicated in both the
/// resolver and the architecture test. Lifted here to eliminate accidental drift.
/// See PATTERNS.md §7 caveat: destructive renaming is forbidden without an ADR.
/// When adding an entry, run:
///   flutter test test/architecture/category_other_l2_invariant_test.dart
/// to verify the override resolves to a real L2 row.
const Map<String, String> kCategoryOtherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
