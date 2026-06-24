---
phase: 51-cross-validation-daily-joy-ledger-rework
plan: 01
subsystem: voice
tags: [flutter, freezed, import_guard, clean-architecture, recognition, domain-relocation]

# Dependency graph
requires:
  - phase: 50-decoupled-recognizers
    provides: MerchantCandidate / VoiceParseResult value objects + kMerchantAutoFillFloor (the recognition verdict types being relocated)
provides:
  - New lib/features/voice/domain/ feature tree with a 3-file import_guard chain (feature-level deny + models/ + services/ whitelists)
  - MerchantCandidate relocated to features/voice/domain/models/ (cross-feature accounting->voice domain coupling removed)
  - VoiceParseResult (+ CategoryMatchResult / MatchSource / VoiceAudioFeatures) relocated to features/voice/domain/models/, merchantLedgerType field deleted
  - 'voice' added to domain_import_rules_test.dart features const so the new dir inherits arch-guard enforcement
affects: [51-02 RecognitionReconciler, 51-02 RecognitionOutcome, 51 LEDGER wave-2, voice recognition]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "voice/domain/ feature module hosts recognition value objects (centralized so reconciler + outcome can live beside them without cross-feature domain coupling)"
    - "Cross-feature domain->domain model import (LedgerType from accounting) expressed as relative path ../../../accounting/domain/models/transaction.dart in source + import_guard, matching features/list and features/shopping_list"

key-files:
  created:
    - lib/features/voice/domain/import_guard.yaml
    - lib/features/voice/domain/models/import_guard.yaml
    - lib/features/voice/domain/services/import_guard.yaml
    - lib/features/voice/domain/models/merchant_candidate.dart
    - lib/features/voice/domain/models/voice_parse_result.dart
  modified:
    - test/architecture/domain_import_rules_test.dart
    - lib/application/voice/recognition/merchant_recognizer.dart
    - lib/application/voice/recognition/category_recognizer.dart
    - lib/application/voice/parse_voice_input_use_case.dart
    - lib/application/voice/voice_satisfaction_estimator.dart
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart

key-decisions:
  - "Extended the models/ subdir arch-test allow-shape check to accept isCrossFeatureDomainModel (Rule 3 blocking-issue fix): adding 'voice' to the features const made the cross-feature transaction.dart entry trip a check that only had the escape on the repositories/ subdir, not models/. Mirrors the existing repositories/ escape and the precedent set by features/list + features/shopping_list (which import accounting LedgerType cross-feature but were never in the features list)."
  - "voice_parse_result.dart imports LedgerType via relative path ../../../accounting/domain/models/transaction.dart (not a package: import) to match the import_guard allow entry format and the list/shopping_list precedent."

patterns-established:
  - "New voice/domain import_guard chain mirrors accounting/domain: parent owns deny only, per-subdir children own the allow whitelist."

requirements-completed: [XVAL-01]

# Metrics
duration: ~25min
completed: 2026-06-24
status: complete
---

# Phase 51 Plan 01: Voice Domain Recognition-Type Relocation Summary

**Created lib/features/voice/domain/ (3-file import_guard chain) and relocated MerchantCandidate + VoiceParseResult into it, deleting the dead merchantLedgerType field — pure behavior-neutral move, full suite 3261/3261 green.**

## Performance

- **Duration:** ~25 min active
- **Started:** 2026-06-24T06:01:04Z
- **Completed:** 2026-06-24
- **Tasks:** 2
- **Files modified:** 19 (5 created incl. 2 moved models + 3 import_guards, 14 modified incl. cascade imports + arch test; 2 freezed parts regenerated in new location)

## Accomplishments
- New `lib/features/voice/domain/` feature tree with a full 3-file import_guard chain (feature-level deny-only parent + `models/` and `services/` per-subdir allow whitelists), mirroring the accounting domain pattern (D-11).
- `MerchantCandidate` and `VoiceParseResult` (+ `CategoryMatchResult` / `MatchSource` / `VoiceAudioFeatures`) relocated from `features/accounting/domain/models/` into `features/voice/domain/models/`, removing the cross-feature accounting->voice domain coupling. Freezed parts regenerated in the new location; stale ones deleted.
- Deleted the unpopulated `merchantLedgerType` field from `VoiceParseResult` (D-12) — ledger is a pure function of the final category, never the merchant hint.
- All 17 cascade import sites (lib application/presentation + tests) repointed to the new paths; `'voice'` added to the arch-test `features` const so the new dir inherits guard-shape enforcement (Pitfall 6).

## Task Commits

Each task was committed atomically:

1. **Task 1: Create voice/domain import_guard chain + add 'voice' to arch-test features** - `e8de6276` (feat)
2. **Task 2: Move MerchantCandidate + VoiceParseResult into voice/domain, delete merchantLedgerType** - `84f05768` (feat)

_Note: Task 2 was a `tdd="true"` relocation task; the existing voice/recognizer test suite serves as the behavior spec (assertions unchanged), so it is a single GREEN-equivalent commit — no new RED test was written for a pure move._

## Files Created/Modified
- `lib/features/voice/domain/import_guard.yaml` - Feature-level deny-only guard (copied from accounting/domain).
- `lib/features/voice/domain/models/import_guard.yaml` - Allow whitelist: freezed_annotation, merchant_candidate.dart (intra-domain), ../../../accounting/domain/models/transaction.dart (LedgerType cross-feature).
- `lib/features/voice/domain/services/import_guard.yaml` - Allow whitelist for the incoming 51-02 reconciler (model leaves).
- `lib/features/voice/domain/models/merchant_candidate.dart` - Relocated MerchantCandidate freezed value object (byte-identical body).
- `lib/features/voice/domain/models/voice_parse_result.dart` - Relocated VoiceParseResult; merchantLedgerType deleted; transaction import rewritten to relative cross-feature path.
- `test/architecture/domain_import_rules_test.dart` - Added 'voice' to features const; extended models/ subdir check to accept cross-feature domain models.
- `lib/application/voice/{recognition/merchant_recognizer,recognition/category_recognizer,parse_voice_input_use_case,voice_satisfaction_estimator}.dart` - Import paths repointed to voice/domain.
- `lib/features/accounting/presentation/screens/{voice_ptt_session_mixin,voice_input_screen_helpers}.dart` - Import paths repointed (../../domain/ -> ../../../voice/domain/).
- 11 test files - package: import paths repointed to voice/domain (+ one doc-comment path fix).

## Decisions Made
- **Arch-test models/ escape (Rule 3):** Adding `'voice'` to the `features` const enabled the `models/` subdir allow-shape assertion against voice, but that assertion only permitted annotations or intra-domain leaves (no `/`) — it lacked the `isCrossFeatureDomainModel` escape that the sibling `repositories/` assertion already had. Since `voice_parse_result.dart` legitimately imports accounting's `LedgerType` (a pure domain->domain dependency, no layer violation — the same thing `features/list` and `features/shopping_list` already do), I extended the `models/` check to accept cross-feature domain models. This is the minimal principled fix and keeps the new dir under full guard enforcement.
- **Relative import for cross-feature LedgerType:** `voice_parse_result.dart` imports `../../../accounting/domain/models/transaction.dart` (relative, not `package:`), matching the import_guard allow-entry format and the list/shopping_list precedent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Extended models/ subdir arch-test to accept cross-feature domain models**
- **Found during:** Task 1 (arch-test features-const update)
- **Issue:** The plan's Task 1 action says to add `package:home_pocket/features/accounting/domain/models/transaction.dart` to voice's `models/import_guard.yaml`, but the `models/` subdir assertion in `domain_import_rules_test.dart` (lines 64-87) only accepted annotations or intra-domain leaves (entries with no `/`). Any cross-feature transaction.dart entry — whether package: or relative — would have failed that assertion once `'voice'` was a listed feature. The plan's own two requirements (add 'voice' to features list AND voice_parse_result importing accounting LedgerType) were mutually unsatisfiable under the existing test.
- **Fix:** Added the `isCrossFeatureDomainModel` predicate (entry contains `/domain/models/` and ends with `.dart`) to the `models/` subdir allow-shape check — mirroring the identical escape that the `repositories/` subdir check already carried (lines 105-109). Also used the relative-path form `../../../accounting/domain/models/transaction.dart` in both the source import and the import_guard entry, matching the established `features/list` + `features/shopping_list` precedent.
- **Files modified:** test/architecture/domain_import_rules_test.dart, lib/features/voice/domain/models/import_guard.yaml, lib/features/voice/domain/models/voice_parse_result.dart
- **Verification:** `flutter test test/architecture/domain_import_rules_test.dart` — all 21 tests pass incl. the 3 new voice tests; custom_lint reports zero import_guard violations under lib/features/voice/domain/.
- **Committed in:** e8de6276 (Task 1) + 84f05768 (Task 2)

---

**Total deviations:** 1 auto-fixed (1 blocking — Rule 3).
**Impact on plan:** The fix was necessary to make the plan's two stated requirements coexist under the arch guard. It is principled (mirrors the existing repositories/ escape + established list/shopping_list precedent), not scope creep. No behavior change.

## Issues Encountered
None during planned work. The relocation was behavior-neutral throughout: `flutter analyze` = 0 and the full suite stayed 3261/3261 green.

## Deferred Issues (out of scope)
- `custom_lint` reports 4 **pre-existing** `import_guard` WARNINGs unrelated to this plan, in files this plan did not touch: `lib/features/accounting/domain/repositories/merchant_repository.dart` (x2), `lib/features/analytics/domain/models/category_drill_down.dart`, `lib/features/analytics/domain/models/member_spend_breakdown.dart`. These are custom_lint warnings (not analyzer errors — `flutter analyze` is 0) and existed before this plan. Logged for awareness; not fixed (scope boundary). New `lib/features/voice/domain/` is clean (zero import_guard violations).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `features/voice/domain/` exists with a working, arch-guarded import_guard chain — ready for 51-02 to add `RecognitionReconciler` (into `domain/services/`, whitelist already prepared) and `RecognitionOutcome` (into `domain/models/`, allow chain ready).
- `merchantLedgerType` is gone; the ledger-from-merchant short-circuit removal (51 LEDGER wave-2) can proceed against a clean DTO.
- No blockers.

## Self-Check: PASSED

All 5 created files exist on disk; both task commits (`e8de6276`, `84f05768`) present in git history.

---
*Phase: 51-cross-validation-daily-joy-ledger-rework*
*Completed: 2026-06-24*
