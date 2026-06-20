import 'monthly_report.dart';

/// Category breakdown restricted to ONE member's transactions + that member's
/// window total / entry count (260620-v2m / D2) — fed to `DonutHero` when the
/// donut is in 分类 dimension AND a member filter is active.
///
/// Plain immutable value holder; the [breakdowns] rows carry only
/// categoryId/amount/transactionCount meaningfully (name/icon/color/percentage
/// are placeholders re-derived by the hero).
class MemberFilteredCategoryBreakdown {
  const MemberFilteredCategoryBreakdown({
    required this.breakdowns,
    required this.total,
    required this.entryCount,
  });

  final List<CategoryBreakdown> breakdowns;
  final int total;
  final int entryCount;
}

/// One per-MEMBER expense aggregate bucket — the slice weight for the donut's
/// 成员 (member) dimension (260620-v2m / D2).
///
/// Domain-pure plain immutable value class (const ctor + value equality),
/// deliberately NOT Freezed — no Flutter import, no build_runner / .freezed.dart
/// — mirroring [JoyCategoryAmount] / `L1CategoryRollup`.
///
/// D2: THIS APP HAS NO "payer" FIELD. The only per-transaction member identity
/// is the recording device `transactions.deviceId`, so [deviceId] is the
/// canonical member key here. Display name / avatar are resolved at the UI layer
/// via `activeGroupMembers` (group_members table); single-device / not-in-group
/// degrades gracefully to a single bucket. There is NO 共同帐户 pseudo-member.
class MemberSpendBreakdown {
  const MemberSpendBreakdown({
    required this.deviceId,
    required this.amount,
    required this.transactionCount,
  });

  /// The recording device id this aggregate groups by (canonical member key).
  final String deviceId;

  /// Sum of expense amounts (minor units) recorded by this device in the window.
  final int amount;

  /// Number of expense transactions recorded by this device in the window.
  final int transactionCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberSpendBreakdown &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          amount == other.amount &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode => Object.hash(deviceId, amount, transactionCount);

  @override
  String toString() =>
      'MemberSpendBreakdown(deviceId: $deviceId, amount: $amount, '
      'transactionCount: $transactionCount)';
}
