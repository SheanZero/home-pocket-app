import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../accounting/domain/models/transaction.dart';

part 'category_drill_down.freezed.dart';

/// Transient carrier for one L1-category drill-down (Phase 44, DRILL-01).
///
/// Returned by `GetCategoryDrillDownUseCase`: the window-filtered transactions
/// for ONE tapped L1 category (including all its L2 children — Pitfall 2), plus
/// a neutral descriptive summary. The [subtotal]/[count] come from Plan 01's
/// shared `l1RollupFromTransactions` (the SAME rule the OVW-01 donut uses), so
/// the drill header can never drift from the donut slice (D-11).
///
/// No JSON: this is transient state behind an auto-dispose provider.
@freezed
abstract class CategoryDrillDown with _$CategoryDrillDown {
  const factory CategoryDrillDown({
    /// Window + L1-filtered transactions, sorted time-descending.
    required List<Transaction> transactions,

    /// Sum of [transactions] amounts (minor units), sourced from Plan 01's
    /// `l1RollupFromTransactions` — the single source-of-truth (D-11).
    required int subtotal,

    /// Number of transactions in this L1 for the window.
    required int count,

    /// Plain descriptive average per window-day (subtotal / window days).
    /// Descriptive only — never a target/goal (D-03, ADR-012-safe).
    int? avgPerDay,
  }) = _CategoryDrillDown;
}
