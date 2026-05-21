---
phase: 17-manual-only-joy-sub-metric-happy-v2-03
plan: 03
subsystem: domain
tags: [entry-source, freezed, sync, accounting, happy-v2-03]

requires:
  - phase: 17-02
    provides: transactions.entry_source persistence column
provides:
  - Domain EntrySource enum with manual, voice, and ocr values
  - Transaction Freezed field with EntrySource.manual default
  - TransactionSyncMapper entrySource encode/decode with manual fallback for absent v16 payloads
  - Sync mapper tests for voice encoding, 3-value round-trip, absent fallback, and invalid rejection
affects: [transaction-domain, family-sync, entry-path-stamping, analytics-filtering]

tech-stack:
  added: []
  patterns:
    - Domain enum values map to persisted SQL strings via Enum.name
    - Sync mapper absent-field fallback is limited to missing field, not invalid values

key-files:
  created:
    - lib/features/accounting/domain/models/entry_source.dart
    - .planning/phases/17-manual-only-joy-sub-metric-happy-v2-03/17-03-SUMMARY.md
  modified:
    - lib/features/accounting/domain/models/transaction.dart
    - lib/features/accounting/domain/models/transaction.freezed.dart
    - lib/features/accounting/domain/models/transaction.g.dart
    - lib/features/accounting/domain/models/transaction_sync_mapper.dart
    - test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart

key-decisions:
  - "EntrySource lives in its own accounting domain model file and keeps the canonical manual, voice, ocr order."
  - "Invalid sync payload entrySource values throw ArgumentError; only absent values fall back to manual."

patterns-established:
  - "Backward-compatible sync field additions use a default-bearing Freezed field plus explicit mapper fallback."

requirements-completed: [HAPPY-V2-03]

duration: 4 min
completed: 2026-05-21
---

# Phase 17 Plan 03: Entry Source Domain and Sync Summary

**Domain and sync payloads now carry `EntrySource` with manual fallback for older payloads and explicit rejection of invalid values.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-21T00:58:01Z
- **Completed:** 2026-05-21T01:02:27Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `EntrySource { manual, voice, ocr }` in the accounting domain layer.
- Added `@Default(EntrySource.manual) EntrySource entrySource` to the Freezed `Transaction` model.
- Regenerated `transaction.freezed.dart` and `transaction.g.dart`.
- Extended `TransactionSyncMapper` so payloads emit `entrySource` and decode absent fields as `manual`.
- Added mapper tests for encode, all-value round-trip, absent fallback, and invalid value rejection.

## EntrySource Source

```dart
/// Transaction entry-path provenance.
///
/// Values persist as TEXT in `transactions.entry_source` via [Enum.name].
/// Create-transaction callers stamp the source explicitly at the use-case
/// boundary. `ocr` is reserved for MOD-005; Phase 17 declares it but does not
/// stamp production rows with it.
///
/// Keep member order aligned with the SQL CHECK domain: manual, voice, ocr.
enum EntrySource { manual, voice, ocr }
```

## Task Commits

Each task was committed atomically:

1. **Task 1: Create EntrySource enum and add entrySource field to Transaction** - `335965a` (feat)
2. **Task 2: Extend TransactionSyncMapper and mapper tests** - `12bad74` (feat)

**Plan metadata:** pending current commit

## Files Created/Modified

- `lib/features/accounting/domain/models/entry_source.dart` - New 3-value domain enum.
- `lib/features/accounting/domain/models/transaction.dart` - Imports `EntrySource` and adds the default-bearing field.
- `lib/features/accounting/domain/models/transaction.freezed.dart` - Regenerated Freezed model support.
- `lib/features/accounting/domain/models/transaction.g.dart` - Regenerated JSON serialization for `entrySource`.
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` - Encodes and decodes `entrySource`.
- `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart` - Adds entry-source mapper coverage.

Diff stats for requested files:

```text
lib/features/accounting/domain/models/transaction.dart              |  7 +++
lib/features/accounting/domain/models/transaction_sync_mapper.dart  |  4 ++
test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart | 70 ++++++++++++++++++++++
3 files changed, 81 insertions(+)
```

## New Test Names

From `flutter test test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart`:

- `toSyncMap encodes entrySource as enum name (voice)` - PASS
- `round-trip preserves entrySource across all 3 values` - PASS
- `fromSyncMap defaults missing entrySource to manual (D-09 fallback)` - PASS
- `fromSyncMap throws on invalid entrySource value` - PASS

## Verification

- `flutter pub run build_runner build --delete-conflicting-outputs` exited 0 and regenerated `transaction.freezed.dart` / `transaction.g.dart`.
- `flutter analyze lib/features/accounting/domain/models/entry_source.dart lib/features/accounting/domain/models/transaction.dart lib/features/accounting/domain/models/transaction_sync_mapper.dart test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart` returned `No issues found`.
- `flutter test test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart` passed 8 tests.
- Required greps passed for `enum EntrySource { manual, voice, ocr }`, `@Default(EntrySource.manual) EntrySource entrySource,`, mapper `entrySource` encoding, and mapper manual fallback.

## Decisions Made

- Kept `EntrySource.ocr` reserved but unstamped in production paths; MOD-005 owns real OCR stamping later.
- Let invalid sync values throw through `EntrySource.values.byName(...)`, preserving payload tampering visibility.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 17-04 can now thread `EntrySource` through transaction creation and persistence using the domain enum and generated `Transaction.entrySource` field.

---
*Phase: 17-manual-only-joy-sub-metric-happy-v2-03*
*Completed: 2026-05-21*
