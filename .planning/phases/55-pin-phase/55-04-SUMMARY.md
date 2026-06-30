---
phase: 55-pin-phase
plan: 04
subsystem: i18n
tags: [arb, flutter_localizations, gen-l10n, app-lock, pin, security]

# Dependency graph
requires:
  - phase: 54
    provides: onboardingLock* ARB key idiom + SecuritySection scaffold
provides:
  - 15 app-lock/PIN/forgot-PIN/SecuritySection ARB keys in ja/zh/en with parity
  - Regenerated lib/generated/app_localizations*.dart S getters for those keys
  - LOCK-09 forgot-PIN explanation copy (unrecoverable / reinstall / data loss, no recovery hint)
affects: [55-05, 55-06, 55-07, 55-08, 55-09, 55-10, 55-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Centralized ARB seeding: one foundation plan adds all lock i18n keys to avoid same-wave ARB collisions; consumer plans read S.of(context) keys read-only"

key-files:
  created: []
  modified:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/generated/app_localizations_en.dart

key-decisions:
  - "Used パスコード/密码/passcode wording consistently for the PIN credential, mirroring iOS conventions; the forgot key keeps its ForgotPin name but copy reads 'passcode'"
  - "Forgot-PIN explanation states unrecoverable + reinstall + unsynced local data loss with no recovery hint (LOCK-09, D-08, mitigates T-55-09)"
  - "Inserted new keys directly after the onboardingLock block (before @@locale) in all three files to keep lock i18n grouped"

patterns-established:
  - "ARB parity foundation plan: add all keys to ja(source)/zh/en at once + gen-l10n + force-add lib/generated, before any consumer Dart edits"

requirements-completed: [LOCK-09]

coverage:
  - id: D1
    description: "15 lock-screen/PIN/set-PIN/forgot-PIN/SecuritySection ARB keys exist in ja/zh/en with @-description blocks and identical key sets (parity)"
    requirement: "LOCK-09"
    verification:
      - kind: automated_ui
        ref: "grep -c each key == 1 in all three ARB files (15/15 OK); flutter gen-l10n exits 0 with no missing-translation warnings"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generated S getters resolve (S.appLock*/S.security*) and analyze clean"
    verification:
      - kind: automated_ui
        ref: "grep appLockForgotPinExplanation lib/generated/app_localizations.dart >=1; flutter analyze == No issues found"
        status: pass
    human_judgment: false
  - id: D3
    description: "appLockForgotPinExplanation copy states unrecoverable + reinstall + unsynced data loss with no recovery path (LOCK-09 / T-55-09)"
    requirement: "LOCK-09"
    verification:
      - kind: manual_procedural
        ref: "Review ja/zh/en appLockForgotPinExplanation values for accuracy and tone in real UI context (Plan 08/09 consumers)"
        status: unknown
    human_judgment: true
    rationale: "Copy faithfulness and tone across three languages is a human-judgment localization concern; automation can only confirm presence, not wording quality"

# Metrics
duration: 6min
completed: 2026-06-30
status: complete
---

# Phase 55 Plan 04: App-Lock i18n Foundation Summary

**Seeded 15 app-lock/PIN/forgot-PIN/SecuritySection (D-11) ARB keys in ja/zh/en with parity, regenerated lib/generated S getters, and authored LOCK-09 forgot-PIN copy that implies no recovery path.**

## Performance

- **Duration:** ~6 min
- **Completed:** 2026-06-30
- **Tasks:** 2
- **Files modified:** 7 (3 ARB + 4 generated Dart)

## Accomplishments
- Added 15 keys (`appLockPinTitle`, `appLockFaceIdPrompt`, `appLockFaceIdRetry`, `appLockUsePasscode`, `appLockForgotPin`, `appLockForgotPinExplanation`, `appLockSetPinTitle`, `appLockConfirmPinTitle`, `appLockPinMismatch`, `appLockReauthReason`, `securityAppLock`, `securityAppLockDescription`, `securityBiometricUnlock`, `securityBiometricUnlockDescription`, `securityChangePin`) to all three ARB files with `@`-description blocks — parity confirmed 15/15.
- `appLockForgotPinExplanation` states the passcode is unrecoverable, requires reinstalling the app, and loses unsynced local data, with no recovery hint (LOCK-09, D-08, mitigates threat T-55-09).
- Ran `flutter gen-l10n` (exit 0, no missing-translation warnings → parity proven); force-added the regenerated `lib/generated/app_localizations*.dart`.
- `flutter analyze`: 0 issues across the project; no leftover modified/untracked generated l10n file.

## Task Commits

Tasks 1 and 2 are tightly coupled (the generated Dart derives from the Task 1 ARB edits), so they were committed atomically:

1. **Task 1 + 2: ARB keys + regenerated localizations** - `37881440` (feat)

**Plan metadata:** _(this docs commit)_

## Files Created/Modified
- `lib/l10n/app_ja.arb` - 15 lock i18n keys (source/default locale)
- `lib/l10n/app_zh.arb` - 15 lock i18n keys (zh parity)
- `lib/l10n/app_en.arb` - 15 lock i18n keys (en template-arb-file)
- `lib/generated/app_localizations*.dart` - regenerated S getters (force-added; gitignored-yet-tracked)

## Decisions Made
- Passcode wording (パスコード/密码/passcode) used consistently for the credential.
- New keys grouped immediately after the existing onboardingLock block before `@@locale`.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All lock i18n keys are available via `S.of(context)` for Plans 05–11 (lock screen, set-PIN, SecuritySection D-11). Consumers must NOT re-edit these ARB files — read-only.
- Hardcoded-CJK UI scan is exercised at the wave merge after consumer plans land; this plan introduces no Dart UI so it cannot regress that scan.

---
*Phase: 55-pin-phase*
*Completed: 2026-06-30*
