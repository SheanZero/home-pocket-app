/// One per-day JOY count bucket — the 小确幸 calendar heatmap depth (D-C1,
/// Phase 46). `count` is the number of joy一刻 (笔数) on [date], NOT a sum of
/// amounts (Pitfall 3).
///
/// Domain-pure plain immutable value class (const ctor + value equality),
/// deliberately NOT Freezed — no Flutter import, no build_runner — mirroring
/// `L1CategoryRollup` / `JoyCategoryAmount`.
class PerDayJoyCount {
  const PerDayJoyCount({required this.date, required this.count});

  /// The local calendar day this count belongs to, anchored to midnight
  /// (DateTime(year, month, day)).
  final DateTime date;

  /// Number of joy-ledger expense transactions on [date].
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerDayJoyCount &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          count == other.count;

  @override
  int get hashCode => Object.hash(date, count);

  @override
  String toString() => 'PerDayJoyCount(date: $date, count: $count)';
}
