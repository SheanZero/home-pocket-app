---
phase: 54-onboarding-flow
plan: 07
subsystem: onboarding
tags: [flutter, onboarding, nested-navigator, boot-gate, popscope, riverpod, main]

# Dependency graph
requires:
  - phase: 54-onboarding-flow
    plan: 01
    provides: "AppSettings.onboardingComplete + setOnboardingComplete (the gate flag)"
  - phase: 54-onboarding-flow
    plan: 03
    provides: "SettingsScreen.scrollToSecurity deep-link target"
  - phase: 54-onboarding-flow
    plan: 05
    provides: "OnboardingSettingsScreen(onConfirmed) settings step"
  - phase: 54-onboarding-flow
    plan: 06
    provides: "OnboardingIntroScreen(onContinue) + OnboardingLockEntryScreen(onComplete(setupSecurity:))"
provides:
  - "OnboardingFlowScreen — nested-Navigator host of intro→settings→lock-entry with re-entrant back + root PopScope guard; writes onboarding_complete LAST and enters the shell (ONBOARD-07/D-11/D-12/D-13)"
  - "main.dart boot gate keyed on the captured onboardingComplete flag (after init settle AND after a data reset); ProfileOnboardingScreen boot gate retired (D-01/D-04/D-05/D-06)"
affects: [55-pin-biometric]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Nested Navigator flow host: a parent ConsumerStatefulWidget owns a GlobalKey<NavigatorState>; forward nav via child callbacks, back via the nested Navigator, root PopScope(canPop:false) delegating system back to nested.maybePop() (re-entrant, cannot pop out)"
    - "Completion writes the persisted gate flag LAST then pushReplacement on the ROOT navigator (Navigator.of(context, rootNavigator: true)) so the shell replaces the gate, not an inner flow route"
    - "Captured-after-init boot gate: read settingsRepository.getSettings() in _initialize/_reinitialize and store in a field — NEVER ref.watch(appSettingsProvider) in build() (avoids the branch-3 loading-null race, T-54-11)"
    - "Widget-test cleanup for MainShellScreen Drift streams: unmount via pumpWidget(SizedBox) then pump(1s) to flush the markAsClosed dispose-timer before the teardown invariant check"

key-files:
  created:
    - lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart
    - test/widget/features/onboarding/onboarding_flow_test.dart
    - test/widget/features/onboarding/onboarding_gate_test.dart
  modified:
    - lib/main.dart
    - test/main_characterization_smoke_test.dart
  deleted:
    - lib/features/profile/presentation/screens/profile_onboarding_screen.dart
    - test/widget/features/profile/presentation/screens/profile_onboarding_screen_test.dart

key-decisions:
  - "The flow host uses the ROOT navigator for pushReplacement(MainShellScreen) — mirrors the proven ProfileOnboardingScreen completion idiom (home: widget + pushReplacement)"
  - "The data-reset re-read lands in _reinitializeAfterDataReset (the missing read identified in the plan): settingsRepository is plaintext SharedPreferences, NOT wiped by the Drift data reset, so re-reading reflects the post-reset flag (delete→false→onboarding, import→true→shell)"
  - "ProfileOnboardingScreen historical doc-comment mentions left intact in 54-05/54-06 screens (port provenance); no live import or code reference remains"

patterns-established:
  - "Onboarding flow host owns nav + completion; the three step screens stay thin/presentational (callbacks only)"

requirements-completed: [ONBOARD-01, ONBOARD-07]

coverage:
  - id: ONBOARD-07
    description: "Nested Navigator hosts intro→settings→lock-entry; re-entrant back (settings→intro, lock→settings); root PopScope cannot pop out (cannot dead-lock)"
    verification:
      - kind: widget
        ref: "onboarding_flow_test.dart#onContinue advances to settings; system back returns to intro + #root cannot be popped out of the flow"
        status: pass
    human_judgment: false
  - id: D-12
    description: "No progress bar — progress shown only via back gesture"
    verification:
      - kind: other
        ref: "onboarding_flow_screen.dart renders no step-indicator/progress widget (intro/settings/lock screens only)"
        status: pass
    human_judgment: false
  - id: D-11
    description: "Lock-entry is the trailing step, reached only after この設定で始める (settings onConfirmed → push lock-entry)"
    verification:
      - kind: widget
        ref: "onboarding_flow_test.dart#completing lock-entry (skip) ... (settings confirm → lock-entry reached)"
        status: pass
    human_judgment: false
  - id: D-13
    description: "onboarding_complete written LAST on lock-entry completion; 现在设置 → pushReplacement(MainShell) then push(SettingsScreen(scrollToSecurity:true))"
    verification:
      - kind: widget
        ref: "onboarding_flow_test.dart#completing lock-entry (skip) writes onboardingComplete=true LAST (flag absent before lock-entry, true after)"
        status: pass
    human_judgment: false
  - id: ONBOARD-01
    description: "Boot gate reads onboardingComplete captured after init settle; true→shell, false→OnboardingFlowScreen; never ref.watch in build, never inferred from profile"
    requirement: "ONBOARD-01"
    verification:
      - kind: widget
        ref: "onboarding_gate_test.dart#onboardingComplete false→OnboardingFlowScreen, true→MainShellScreen"
        status: pass
    human_judgment: false
  - id: D-01
    description: "ProfileOnboardingScreen boot gate retired (widget + test deleted, smoke test retargeted, getUserProfileUseCase existence-check dropped)"
    verification:
      - kind: other
        ref: "grep -rn ProfileOnboardingScreen lib/ test/ → no live imports/usages; flutter analyze 0 issues"
        status: pass
    human_judgment: false

# Metrics
duration: 28min
completed: 2026-06-29
status: complete
---

# Phase 54 Plan 07: Onboarding Flow Host + Boot Gate Summary

**`OnboardingFlowScreen` composes the four-screen flow (intro → settings → lock-entry) in a nested Navigator with re-entrant back and a root `PopScope` guard, writing `onboarding_complete` LAST on completion before entering the shell; `main.dart` branch 3 now gates on the captured flag (read after init settle AND re-read after a data reset), and the old `ProfileOnboardingScreen` boot gate is fully retired.**

## What Was Built

**Task 1 — `OnboardingFlowScreen` (nested-Navigator host).** A `ConsumerStatefulWidget(bookId)` hosting a nested `Navigator` (no routing package): the initial route is `OnboardingIntroScreen(onContinue: → push settings)`; settings `onConfirmed: → push lock-entry`; lock-entry `onComplete({setupSecurity}) → _complete`. A root `PopScope(canPop: false, onPopInvokedWithResult: → _nestedNavigatorKey.currentState?.maybePop())` makes the system back pop inner routes (settings→intro, lock→settings) while the intro (root) cannot be popped out of the flow — re-entrant, cannot dead-lock (ONBOARD-07/D-12). There is no progress bar (D-12). `_complete` writes `setOnboardingComplete(true)` LAST (not at settings-confirm), invalidates `appSettingsProvider`, then on the ROOT navigator (`Navigator.of(context, rootNavigator: true)`) `pushReplacement`es `MainShellScreen(bookId:)`; when `setupSecurity` it additionally `push`es `SettingsScreen(bookId:, scrollToSecurity: true)` (D-13 deep-link). Four widget tests cover initial intro, intro→settings + re-entrant system-back, the PopScope no-op on the root, and the completion flag-write-last + onboarding-routes-gone.

**Task 2 — boot gate rewire + ProfileOnboardingScreen retirement.** `main.dart`: `_needsProfileOnboarding` → `_needsOnboarding`, now derived from `settingsRepository.getSettings().onboardingComplete` read in `_initialize()` after the sync-engine wiring (captured into a field; the `getUserProfileUseCaseProvider` existence-check is removed). `_reinitializeAfterDataReset()` re-reads the flag after `invalidateAllDataProviders(ref)` — the missing read (D-05/D-06): because the flag is plaintext SharedPreferences (not wiped by the Drift data reset), delete-all returns to onboarding (→false) and import skips it (→true) without an app restart. `_buildHome()` branch 3 returns `OnboardingFlowScreen(bookId:)`. The `ProfileOnboardingScreen` widget + its test are deleted; the smoke characterization test is retargeted to the onboardingComplete gate; a new `onboarding_gate_test.dart` (VALIDATION ONBOARD-01) asserts true→shell / false→OnboardingFlowScreen.

## Verification

- `flutter analyze` (whole project) → **No issues found (0)**.
- `flutter test test/widget/features/onboarding/` → **18/18 pass** (flow 4 + gate 2 + intro/lock/settings 12).
- `flutter test test/main_characterization_smoke_test.dart` → **9/9 pass** (retargeted).
- Task 1 acceptance greps on `onboarding_flow_screen.dart`: `PopScope`=2 (≥1), `setOnboardingComplete(true)`=1, `scrollToSecurity: true`=1, `go_router|GoRouter`=0.
- Task 2 acceptance greps: `_needsProfileOnboarding|ProfileOnboardingScreen` in main.dart=0, `_needsOnboarding`=4 (≥3), `getUserProfileUseCaseProvider` in main.dart=0, `getSettings` in main.dart=2 (init + reinit re-read); no live `ProfileOnboardingScreen` import/usage in lib/ or test/.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test infra] MainShellScreen Drift stream dispose-timer leaks the completion/true-gate widget tests**
- **Found during:** Task 1 + Task 2 (completing the flow / gate-true case boots `MainShellScreen`)
- **Issue:** Booting the real `MainShellScreen` opens Drift query streams; on teardown Drift's `StreamQueryStore.markAsClosed` schedules a delayed close timer that trips the `!timersPending` invariant (and hangs the test harness ~2 min). Overriding `syncEngineProvider`/`syncStatusStreamProvider`/`activeGroupProvider` (the SyncEngine periodic timer) was necessary but not sufficient.
- **Fix:** After the assertions, unmount the tree inside the test body (`await tester.pumpWidget(const SizedBox()); await tester.pump(const Duration(seconds: 1));`) so the Drift dispose-timer flushes before the teardown invariant check. Mirrors the plan's "assert loosely to avoid booting the whole shell" guidance.
- **Files modified:** test/widget/features/onboarding/onboarding_flow_test.dart, test/widget/features/onboarding/onboarding_gate_test.dart
- **Committed in:** 3852a552 (flow), 154e5a90 (gate)

### Clarifications (not behavior changes)

- The acceptance grep `grep -rc "ProfileOnboardingScreen" lib/ test/` is non-zero ONLY due to historical doc-comment provenance notes in `onboarding_intro_screen.dart` / `onboarding_lock_entry_screen.dart` / `onboarding_settings_screen.dart` ("ported from `ProfileOnboardingScreen`"), written by 54-05/54-06. There is **no live import or code reference** to the deleted class anywhere (verified) and `flutter analyze` is clean. Per D-01's intent ("no dangling import/reference"), these prose attributions are left intact rather than scrubbing files owned by earlier plans.

## Known Stubs

None. The flow wires the three real step screens and the real gate flag end-to-end. The lock-entry "现在设置" path deep-links to the existing `SecuritySection` (the real PIN/biometric is Phase 55's scope, as planned — not a stub of this plan).

## Threat Surface

No new surface beyond the plan's `<threat_model>`. **T-54-11** (branch-3 reactive-read race) is mitigated exactly as registered: the gate flag is captured into `_needsOnboarding` once `getSettings()` resolves in `_initialize`/`_reinitialize` — never `ref.watch(appSettingsProvider)` in `build()`. **T-54-12** (plaintext flag tampering) remains accepted (at worst a re-shown/skipped onboarding; no data exposure).

## Self-Check: PASSED

- `lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart` — FOUND
- `test/widget/features/onboarding/onboarding_flow_test.dart` — FOUND
- `test/widget/features/onboarding/onboarding_gate_test.dart` — FOUND
- `lib/main.dart` — FOUND (rewired)
- `lib/features/profile/presentation/screens/profile_onboarding_screen.dart` — DELETED (confirmed absent)
- Commit `3852a552` (Task 1) — FOUND
- Commit `154e5a90` (Task 2) — FOUND

---
*Phase: 54-onboarding-flow*
*Completed: 2026-06-29*
