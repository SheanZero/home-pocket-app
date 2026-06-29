---
phase: 54-onboarding-flow
reviewed: 2026-06-30T00:00:00Z
depth: deep
files_reviewed: 11
files_reviewed_list:
  - lib/main.dart
  - lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart
  - lib/features/onboarding/presentation/screens/onboarding_intro_screen.dart
  - lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart
  - lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart
  - lib/features/onboarding/presentation/utils/onboarding_locale_resolution.dart
  - lib/application/settings/clear_all_data_use_case.dart
  - lib/application/settings/import_backup_use_case.dart
  - lib/data/repositories/settings_repository_impl.dart
  - lib/features/settings/domain/models/app_settings.dart
  - lib/features/settings/presentation/screens/settings_screen.dart
findings:
  critical: 0
  high: 1
  medium: 0
  low: 5
  total: 6
status: issues_found
---

# Phase 54: Code Review Report

**Reviewed:** 2026-06-30
**Depth:** deep

> **Resolution (2026-06-30, during /gsd-execute-phase 54):** HI-01 (the one HIGH
> finding — onboarding completion `pushReplacement`-ing the root route detached the
> `_buildHome` gate, breaking D-05 and the no-restart contract on the same-session
> onboard→reset path) was **FIXED via TDD in commit `5fdcd6c5`**: onboarding
> completion now routes through a gate-owned `onCompleted` callback that flips
> `_needsOnboarding` (keeping `'/'` = the live gate); a RED→GREEN regression test
> (`onboarding_completion_gate_refresh_test.dart`) covers both onboard→import (shell
> re-points to the new bookId) and onboard→delete-all (gate returns to onboarding).
> Full suite 3393/3393, analyze 0. The **5 LOW items (LO-01..05) remain open** and
> are deferred as non-blocking follow-up (see `/gsd-code-review 54 --fix` or a quick task).
**Files Reviewed:** 11 (production `lib/` surfaces)
**Status:** issues_found

## Summary

Phase 54 wires a persisted `onboardingComplete` flag end-to-end, adds a
three-step nested-Navigator onboarding flow, makes delete-all wipe identity +
reset the gate (D-05), forces `onboardingComplete=true` on import (D-06), and
deep-links Settings to the security section. The non-UI primitives are clean:
the locale-resolution helper is pure and correct, the `'system'` sentinel can
never leak into `voiceLanguage`, the lock-entry skip path correctly writes the
explicit `setBiometricLock(false)` (D-13), and `setOnboardingComplete` is
written LAST in the flow host.

The one substantive concern is an interaction between the boot gate and the
flow host's completion mechanism: completing onboarding `pushReplacement`s the
root `'/'` route (the home gate) away, which detaches the very `_buildHome`
gate that `_reinitializeAfterDataReset` relies on to re-render after a reset.
In the same session, a subsequent delete-all or import then fails to refresh the
UI without an app restart — directly undercutting the D-05/D-06 "without an app
restart" contract for the reinstall→onboard→import-backup flow. This path is
not covered by any test (the data-reset test deliberately forces
`onboardingComplete=true` at boot to avoid it).

The mechanism predates Phase 54 (the retired `ProfileOnboardingScreen` used the
same root `pushReplacement`), but Phase 54 newly makes the boot gate
*load-bearing* for post-reset re-evaluation, so the latent fragility now
produces a user-visible wrong result. Everything else is LOW.

## High

### HI-01: Onboarding completion detaches the boot gate, so same-session delete-all / import does not refresh without a restart

**File:** `lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart:70-93`, `lib/main.dart:170-201,251-268`

**Issue:**
`_complete()` finishes onboarding with a root-navigator replacement:

```dart
final rootNavigator = Navigator.of(context, rootNavigator: true);
await ref.read(settingsRepositoryProvider).setOnboardingComplete(true);
...
rootNavigator.pushReplacement(
  MaterialPageRoute<void>(builder: (_) => MainShellScreen(bookId: widget.bookId)),
);
```

The root navigator's only route at this point is the `'/'` route, whose content
is `home: Builder(builder: (context) => _buildHome(context))` (`main.dart:236`).
`pushReplacement` removes that `'/'` route and replaces it with a standalone
`MainShellScreen` carrying a *fixed* `bookId` captured at the gate. The home
`Builder` (the gate) is now detached from the navigator.

`_reinitializeAfterDataReset` (`main.dart:170-201`) refreshes the UI purely by
`setState`-ing fields the home `Builder` reads (`_initialized`, `_needsOnboarding`,
`_bookId`). That mechanism only works while `'/'` IS the home gate — which the
passing `data_reset_refresh_test.dart` confirms, but only for the
`onboardingComplete == true` at-boot case it explicitly forces (see its comment
at lines 109-125: *"with the app already past the onboarding gate, so the flag
is forced true"*). After `_complete` has replaced `'/'`, those `setState`s no
longer reach the displayed route.

Concrete failure (reliably reproducible, all in one session):
1. Fresh install → `onboardingComplete=false` → OnboardingFlowScreen is `'/'`.
2. User completes onboarding → `_complete` `pushReplacement`s `'/'` → shell with
   the boot book id. The home gate is now detached.
3. User opens Settings → **Import backup** (the canonical reinstall-and-restore
   flow — a fresh user *must* finish onboarding first because the PopScope
   `canPop:false` prevents leaving the flow, so this path always hits the
   detached state). `_restoreData` deletes the boot book and inserts the backup's
   book, then fires `dataResetSignalProvider`.
4. `_reinitializeAfterDataReset` re-reads `onboardingComplete=true` and
   `setState(_bookId = importedId)` — but the displayed `MainShellScreen` is the
   replaced route bound to the **old, now-deleted** boot book id. The view shows
   a dangling/empty book; the restored data is not displayed until an app
   restart.

The symmetric delete-all case (D-05) is worse: after onboarding-in-session,
`delete-all` should "behave like a fresh install and re-trigger onboarding"
(`clear_all_data_use_case.dart:44-46`), but with `'/'` detached the app stays on
the wiped shell instead of returning to the onboarding flow.

This is a wrong, user-visible result in the single most important returning-user
flow, and it contradicts the phase's own decision contract
(`main.dart:180-184`: *"both must re-evaluate without an app restart"*).

**Fix:** Drive completion through the gate instead of replacing the gate route.
Pass a completion callback from `_HomePocketAppState` into
`OnboardingFlowScreen` that flips `_needsOnboarding=false` + `setState` (and
deep-links security via the same gate-owned navigation), so `'/'` remains the
home `Builder` and `_reinitializeAfterDataReset` keeps working for later resets.
For example:

```dart
// main.dart — _buildHome
if (_needsOnboarding) {
  return OnboardingFlowScreen(
    bookId: _bookId!,
    onCompleted: ({required bool setupSecurity}) {
      setState(() => _needsOnboarding = false);
      if (setupSecurity) { /* push SettingsScreen(scrollToSecurity:true) */ }
    },
  );
}
```

At minimum, add a widget test that boots the **full** `HomePocketApp` gate
(`onboardingComplete=false`), completes the flow, then fires
`dataResetSignalProvider` for both the delete-all (→ expect OnboardingFlowScreen)
and import (→ expect shell with the imported bookId) cases, to prove the
"without an app restart" contract on the post-onboarding path.

## Low

### LO-01: `OnboardingLockEntryScreen._setupNow` checks `_busy` but never sets it — double-tap can fire `onComplete` twice

**File:** `lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart:55-61`

**Issue:** `_skip` correctly guards re-entrancy (`if (_busy) return; setState(() => _busy = true);`). `_setupNow` reads the same guard but never sets `_busy`, so two quick taps on 今すぐ設定 both pass the check and both call `widget.onComplete(setupSecurity: true)`. The flow host's `_complete` has no guard of its own and reads `Navigator.of(context, rootNavigator: true)` before its first `mounted` check — a second invocation against a context being torn down after the first `pushReplacement` could throw or double-push the SettingsScreen deep-link.

**Fix:** Mirror `_skip` — set a guard before routing:
```dart
void _setupNow() {
  if (_busy) return;
  setState(() => _busy = true);
  widget.onComplete(setupSecurity: true);
}
```

### LO-02: `_confirm` can leave the start button permanently disabled if a write throws

**File:** `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart:262-307`

**Issue:** `_confirm` sets `_isSaving = true`, then performs a chain of awaited writes (`setSystemDefault`, `setVoiceLanguage`, profile save). `_isSaving` is only reset to `false` on the explicit `result.isSuccess == false` branch. If any of the locale/voice writes *throws* (rather than returning a Result), the exception propagates uncaught, `_isSaving` stays `true`, and `_canStart` is stuck `false` — the user can never retry confirm without leaving the screen. Per the project coding-style rule ("handle errors explicitly at every level"), wrap the write chain.

**Fix:** Wrap the body in `try { … } catch (e) { setState(() => _isSaving = false); showErrorFeedback(...); }`, or reset `_isSaving` in a `finally` on the non-navigating paths.

### LO-03: `_applyCurrencySelection` updates the row even when the book lookup returns null

**File:** `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart:203-215`

**Issue:** When `book == null` the persist is skipped, but `setState(() => _currencyCode = code)` still runs, so the UI shows a currency that was never written to `Book.currency`. For the onboarding `bookId` this should not happen, but the divergence is a silent display-vs-persistence inconsistency. Guard the state update behind the same `book != null` condition (or surface an error).

### LO-04: Nickname dialog's only action is labeled "変更" (Change) and has no explicit confirm/cancel pair

**File:** `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart:490-496`

**Issue:** The `_NicknameDialog`'s single `TextButton` uses `l10n.onboardingChange` ("変更"/"Change"/"更改") as its confirm/commit label, which reads oddly for a save action and offers no explicit Cancel (dismissal relies on the barrier). Minor i18n/UX nit; functionally the barrier-dismiss returns null and preserves the prior value. Consider a dedicated confirm string (e.g. an OK/保存 key) and an explicit Cancel action.

### LO-05: `ClearAllDataUseCase.execute` is non-atomic; the added identity-wipe extends an unrolled-back delete→write sequence

**File:** `lib/application/settings/clear_all_data_use_case.dart:29-60`

**Issue:** `execute` deletes transactions/categories/books, resets settings, then (new in Phase 54) finds and deletes the `UserProfile`, with no transaction wrapping the sequence. A throw in the new profile `find()`/`delete()` step (or any earlier step) leaves the wipe partially applied and reported as `Result.error`, with no rollback — e.g. data deleted and settings reset but the profile still present, or vice versa. This mirrors the pre-existing non-atomic pattern in `_restoreData`, so it is a robustness note rather than a regression, but the added step widens the window. If the underlying repos share a Drift database, consider wrapping the destructive sequence in a single `transaction { … }`.

---

## Notes (verified correct, no action)

- `onboarding_locale_resolution.dart` — pure/deterministic; `'system'` cannot leak into `voiceLanguage` (always resolves to ja/zh/en). Correct.
- `onboarding_lock_entry_screen._skip` — correctly writes the explicit `setBiometricLock(false)` to defeat the `biometricLockEnabled` default-true (D-13).
- `onboarding_flow_screen` — `setOnboardingComplete(true)` is written LAST (only on lock-entry completion); PopScope `canPop:false` + nested `maybePop()` is re-entrant and cannot dead-lock; dialogs use the root navigator and the currency sheet on the nested navigator both pop correctly under the guard.
- `main.dart` boot gate — reads the persisted flag AFTER init settle into a field, never `ref.watch`-ed in build, never inferred from currency/profile (ONBOARD-01 / D-04). The `_bookId!` non-null assertions at lines 264/267 are guarded by `_initialized`, which is only set true alongside a non-null `_bookId`. Correct.
- `import_backup_use_case` — `copyWith(onboardingComplete: true)` correctly forces the flag for pre-Phase-54 backups whose settings map omits the key (D-06). (The surrounding untrusted-JSON casts and non-atomic `_restoreData` are pre-existing Phase 41 code, out of scope here.)
- `settings_screen` deep-link — one-shot `_didScrollToSecurity` guard + jump-to-bottom-then-`ensureVisible` correctly handles the lazily-culled ListView.

---

_Reviewed: 2026-06-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
