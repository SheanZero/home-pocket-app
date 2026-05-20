import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_snapshot.freezed.dart';

/// STATSUI-V2-01 Soul-vs-Survival comparison surface (engagement axis).
///
/// Re-framed from "satisfaction axis" to "engagement axis" per CONTEXT D-01..D-04:
/// `transactions.soul_satisfaction` defaults to `2` and the picker only renders
/// for soul-ledger entries (ADR-014 D-10) — so a raw `AVG(soul_satisfaction)`
/// over survival rows would be default-2-dominated and read as
/// "survival = always neutral/unhappy". Phase 16 honors that asymmetry
/// structurally rather than papering over it with a misleading number.
///
/// Shared metrics (D-02): `entryCount` + `totalSpend` — same two numbers in
/// the same vertical order on both ledgers. Soul column additionally carries
/// `avgSatisfaction` (D-03 — single-sided by design; survival has no rating
/// picker).

/// Soul-ledger snapshot — engagement (count + spend) plus the soul-only
/// satisfaction rating (D-03).
@freezed
abstract class SoulLedgerSnapshot with _$SoulLedgerSnapshot {
  const factory SoulLedgerSnapshot({
    required int entryCount,
    required int totalSpend,
    required double avgSatisfaction,
  }) = _SoulLedgerSnapshot;
}

/// D-04 type-system gate — NO avgSatisfaction field.
///
/// `transactions.soul_satisfaction` defaults to `2` and the picker only
/// renders for soul-ledger entries (ADR-014 D-10), so AVG over survival rows
/// is default-2-dominated and reads as "survival = always neutral/unhappy".
/// Adding avgSatisfaction here is the regression mode this gate prevents.
@freezed
abstract class SurvivalLedgerSnapshot with _$SurvivalLedgerSnapshot {
  const factory SurvivalLedgerSnapshot({
    required int entryCount,
    required int totalSpend,
  }) = _SurvivalLedgerSnapshot;
}

/// Soul-vs-Survival comparison composite for the AnalyticsScreen card.
///
/// Solo mode: `familySoul == null && familySurvival == null`.
/// Group mode (D-18, D-20): both family fields are non-null when the family
/// has >= 2 books in the active window. The model does not enforce the
/// group-mode invariant — the use case is responsible for that.
@freezed
abstract class SoulVsSurvivalSnapshot with _$SoulVsSurvivalSnapshot {
  const factory SoulVsSurvivalSnapshot({
    required SoulLedgerSnapshot soul,
    required SurvivalLedgerSnapshot survival,
    SoulLedgerSnapshot? familySoul,
    SurvivalLedgerSnapshot? familySurvival,
  }) = _SoulVsSurvivalSnapshot;
}

/// Per-ledger snapshot row returned by `AnalyticsRepository.getLedgerSnapshot*`.
///
/// The DAO produces this directly (Data → Domain import allowed); the use case
/// (`GetSoulVsSurvivalSnapshotUseCase`) composes a list of these into
/// [SoulLedgerSnapshot] + [SurvivalLedgerSnapshot]. Keeping this in the domain
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
