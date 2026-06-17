/// One per-L1-category JOY amount bucket — a segment weight for the 悦己花在哪
/// horizontal stacked bar (D-C2, Phase 46).
///
/// Domain-pure plain immutable value class (const ctor + value equality),
/// deliberately NOT Freezed — no Flutter import, no build_runner / .freezed.dart
/// — so it stays a genuine domain helper output, mirroring `L1CategoryRollup` in
/// category_l1_rollup.dart. A dedicated semantic type (over reusing
/// `L1CategoryRollup`) is chosen because the joy segment carries only
/// `(categoryId, amount)` — no transactionCount — and the field set communicates
/// the 悦己花在哪 intent at call sites without dragging an unused count.
class JoyCategoryAmount {
  const JoyCategoryAmount({required this.categoryId, required this.amount});

  /// The L1 category id this joy-amount aggregates into.
  final String categoryId;

  /// Sum of joy-ledger expense amounts (minor units) rolled up to this L1.
  final int amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JoyCategoryAmount &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(categoryId, amount);

  @override
  String toString() =>
      'JoyCategoryAmount(categoryId: $categoryId, amount: $amount)';
}
