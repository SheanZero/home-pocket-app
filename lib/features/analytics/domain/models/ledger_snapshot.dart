import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_snapshot.freezed.dart';

/// STATSUI-V2-01 Daily-vs-Joy comparison surface (engagement axis).
///
/// Re-framed from "satisfaction axis" to "engagement axis" per CONTEXT D-01..D-04:
/// `transactions.joy_fullness` defaults to `2` and the picker only renders
/// for joy-ledger entries (ADR-014 D-10) — so a raw `AVG(joy_fullness)`
/// over daily rows would be default-2-dominated and read as
/// "daily = always neutral/unhappy". Phase 16 honors that asymmetry
/// structurally rather than papering over it with a misleading number.
///
/// Shared metrics (D-02): `entryCount` + `totalSpend` — same two numbers in
/// the same vertical order on both ledgers. Joy column additionally carries
/// `avgSatisfaction` (D-03 — single-sided by design; daily has no rating
/// picker).

/// Joy-ledger snapshot — engagement (count + spend) plus the joy-only
/// satisfaction rating (D-03).
@freezed
abstract class JoyLedgerSnapshot with _$JoyLedgerSnapshot {
  const factory JoyLedgerSnapshot({
    required int entryCount,
    required int totalSpend,
    required double avgSatisfaction,
  }) = _JoyLedgerSnapshot;
}

/// D-04 type-system gate — NO avgSatisfaction field.
///
/// `transactions.joy_fullness` defaults to `2` and the picker only
/// renders for joy-ledger entries (ADR-014 D-10), so AVG over daily rows
/// is default-2-dominated and reads as "daily = always neutral/unhappy".
/// Adding avgSatisfaction here is the regression mode this gate prevents.
@freezed
abstract class DailyLedgerSnapshot with _$DailyLedgerSnapshot {
  const factory DailyLedgerSnapshot({
    required int entryCount,
    required int totalSpend,
  }) = _DailyLedgerSnapshot;
}

/// Daily-vs-Joy comparison composite for the AnalyticsScreen card.
///
/// Solo mode: `familyJoy == null && familyDaily == null`.
/// Group mode (D-18, D-20): both family fields are non-null when the family
/// has >= 2 books in the active window. The model does not enforce the
/// group-mode invariant — the use case is responsible for that.
@freezed
abstract class DailyVsJoySnapshot with _$DailyVsJoySnapshot {
  const factory DailyVsJoySnapshot({
    required JoyLedgerSnapshot joy,
    required DailyLedgerSnapshot daily,
    JoyLedgerSnapshot? familyJoy,
    DailyLedgerSnapshot? familyDaily,
  }) = _DailyVsJoySnapshot;
}

/// Per-ledger snapshot row returned by `AnalyticsRepository.getLedgerSnapshot*`.
///
/// The DAO produces this directly (Data → Domain import allowed); the use case
/// (`GetDailyVsJoySnapshotUseCase`) composes a list of these into
/// [JoyLedgerSnapshot] + [DailyLedgerSnapshot]. Keeping this in the domain
/// layer means the repository interface can return `List<LedgerSnapshotRow>`
/// without any `lib/data/` import (CLAUDE.md Pitfall #2 — Domain → Data
/// forbidden, enforced by `import_guard`).
///
/// Plain Dart class (NOT `@freezed`) — same precedent as `LedgerTotalResult` in
/// `lib/data/daos/analytics_dao.dart` and the row classes in
/// `analytics_aggregate.dart` (no equality/copyWith needed for a transient
/// query row tuple; the use case composes domain Freezed types from this).
class LedgerSnapshotRow {
  const LedgerSnapshotRow({
    required this.ledgerType,
    required this.totalAmount,
    required this.entryCount,
  });

  final String ledgerType;
  final int totalAmount;
  final int entryCount;
}
