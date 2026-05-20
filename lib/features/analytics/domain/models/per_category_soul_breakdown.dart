import 'package:freezed_annotation/freezed_annotation.dart';

part 'per_category_soul_breakdown.freezed.dart';

/// HAPPY-V2-01 per-category satisfaction breakdown for the soul ledger.
///
/// Layout (D-06): vertical ranked list, one row per category — each row is
/// rendered as a [PerCategorySoulBreakdownItem]. Sort order (D-07):
/// `avg satisfaction DESC, count DESC, category_id ASC` — identical tie-break
/// to `getSharedJoyCategoryInsight`. Min-N fold (D-08): categories with
/// `count < 3` collapse into a single aggregate `Other` row carried by
/// [PerCategorySoulBreakdown.otherCount] / [PerCategorySoulBreakdown.otherCategoryCount].
/// Per ADR-012 §6 there is NO per-member projection — the model intentionally
/// does not carry `bookId` (the use case sums across the relevant book set).

/// Domain interchange shape.
///
/// This is the SOURCE OF TRUTH consumed by the `AnalyticsRepository`
/// interface, use cases, providers, and widgets. The DAO's row-tuple
/// counterpart (a Drift-row `(categoryId, avgSatisfaction, totalCount)`
/// triple defined inside `lib/data/daos/analytics_dao.dart` — see Plan 16-04)
/// is converted to [PerCategorySoulBreakdownItem] by the repository
/// implementation. Domain MUST NOT import the DAO row type (CLAUDE.md
/// Pitfall #2 — Domain → Data forbidden, enforced by `import_guard`).
@freezed
abstract class PerCategorySoulBreakdownItem
    with _$PerCategorySoulBreakdownItem {
  const factory PerCategorySoulBreakdownItem({
    required String categoryId,
    required double avgSatisfaction,
    required int totalCount,
  }) = _PerCategorySoulBreakdownItem;
}

/// Aggregate of per-category soul-ledger satisfaction within an active window.
///
/// Field semantics (D-08 / D-09 / D-10):
/// - [items] — qualifying rows (>= min-N entries), pre-sorted by use case per D-07.
/// - [totalCount] — sum of ALL entry counts in window (qualifying + Other).
/// - [otherCount] — entries that landed in `< min-N` categories (folded into Other).
/// - [otherCategoryCount] — number of `< min-N` categories folded into Other.
///
/// The model carries the Other counts as plain ints (D-10: NO averaged
/// satisfaction for Other — averaging averages across heterogeneous low-N
/// categories produces a misleading signal).
@freezed
abstract class PerCategorySoulBreakdown with _$PerCategorySoulBreakdown {
  const factory PerCategorySoulBreakdown({
    required List<PerCategorySoulBreakdownItem> items,
    required int totalCount,
    required int otherCount,
    required int otherCategoryCount,
  }) = _PerCategorySoulBreakdown;
}
