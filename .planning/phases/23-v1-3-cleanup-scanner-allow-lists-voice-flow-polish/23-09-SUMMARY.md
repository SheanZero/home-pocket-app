---
phase: 23
plan: "09"
subsystem: voice-flow-polish
tags: [voice, refactor, line-cap, mixin-extraction, gap-closure]
requirements: []
decisions-implemented: []
decisions-prepared: []
gap-closure: true
closes-gap-of: "23-VERIFICATION.md WARNING — voice_input_screen.dart 838 LOC exceeds <800 cap"

dependency-graph:
  requires: [23-06]
  provides:
    - VoiceLocaleReadinessMixin (Phase 23 D-07 cold-start gate, now reusable)
    - voice_input_screen_helpers.dart (3 pure functions: buildVoiceAudioFeatures, countVoiceWords, extractVoiceKeyword)
  affects:
    - lib/features/accounting/presentation/screens/voice_input_screen.dart

tech-stack:
  added: []
  patterns:
    - Mixin-on-ConsumerState<W> for cross-cutting Riverpod-aware behavior (second user-authored mixin after the D-10 mixin-on-State<W> precedent)
    - Top-level pure functions extracted from State class to satisfy file-length cap

key-files:
  created:
    - lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart
    - lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart
  modified:
    - lib/features/accounting/presentation/screens/voice_input_screen.dart

decisions:
  - "VoiceLocaleReadinessMixin constraint is on ConsumerState<W>, not on State<W>, because it needs ref.listenManual — intentionally tighter than the D-10 VoiceRecognitionEventHandlerMixin's State<W> constraint"
  - "Locale-string mirror stays in the host (host's _voiceLocaleId field), exposed to the mixin via the abstract onVoiceLocaleResolved(String) hook — the mixin owns readiness only, not the string itself, to keep scope contained"
  - "ProviderSubscription<AsyncValue<String>>? captured in the mixin and closed in dispose() — Riverpod 3 explicit-cleanup contract for listenManual"
  - "VoiceAudioFeatures helper converted to named-param top-level function (not positional) so the call site at _parseFinalResult is self-documenting"

metrics:
  duration: "~30 minutes"
  completed: "2026-05-25"
  tasks: 3
  files: 3
---

# Phase 23 Plan 09: Slim voice_input_screen below 800 LOC Summary

**One-liner:** Extract `VoiceLocaleReadinessMixin` (D-07 cold-start gate, 99 LOC) and 3 pure helpers (`buildVoiceAudioFeatures`, `countVoiceWords`, `extractVoiceKeyword`) to bring `voice_input_screen.dart` from 838 → 776 LOC, closing the only remaining Phase 23 VERIFICATION.md WARNING with 24 lines of headroom.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extract VoiceLocaleReadinessMixin | 26e2fa8 | voice_locale_readiness_mixin.dart (new), voice_input_screen.dart |
| 2 | Extract pure helpers to voice_input_screen_helpers.dart | e1dd6c3 | voice_input_screen_helpers.dart (new), voice_input_screen.dart |
| 3 | Verify gap closed and full test suite green | — (verification-only, no edits) | — |

## What Was Built

**Task 1 — `VoiceLocaleReadinessMixin`:**
- New file `lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart` (99 LOC)
- `mixin VoiceLocaleReadinessMixin<W extends ConsumerStatefulWidget> on ConsumerState<W>` — second user-authored mixin in `lib/`
- Owns `bool _isLocaleReady` (private), `bool get isLocaleReady` (public getter), `ProviderSubscription<AsyncValue<String>>? _localeSubscription` (cleanup handle), `void initLocaleReadiness()` (the listener registration), abstract `void onVoiceLocaleResolved(String localeId)` (host-mirror hook), and `dispose()` override that closes the subscription before `super.dispose()`
- Preserves D-07 behavior verbatim: `ref.listenManual` with `fireImmediately: true`; both `AsyncData` and `AsyncError` flip the flag (graceful degradation per RESEARCH Pitfall 3); only `AsyncData` invokes `onVoiceLocaleResolved` so the host's locale string updates
- The D-07 comment block ("Phase 23 D-07 (WR-01) ... RESEARCH §Pattern 2" and "RESEARCH Pitfall 3: graceful degradation") moved verbatim into the mixin so the rationale travels with the code
- Screen updates: import added, `with` clause appended `VoiceLocaleReadinessMixin`, `_isLocaleReady` field deleted (5 lines incl. docstring), `ref.listenManual` block (24 lines) collapsed to `initLocaleReadiness();`, `@override void onVoiceLocaleResolved(String localeId) => _voiceLocaleId = localeId;` added next to the existing single-line overrides, `_onLongPressStart` guard updated from `!_isLocaleReady` to `!isLocaleReady` (mixin getter)
- LOC progression: 838 → 815 (−23)

**Task 2 — Pure helpers:**
- New file `lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart` (75 LOC)
- Three top-level pure functions:
  - `VoiceAudioFeatures buildVoiceAudioFeatures({required List<double> soundLevels, required List<DateTime> timestamps, required DateTime? startTime, required int partialResultCount, required int wordCount})` — converted to named-param signature
  - `int countVoiceWords(String text)` — body byte-identical
  - `String extractVoiceKeyword(VoiceParseResult result)` — body byte-identical
- Screen updates: import added, three instance methods deleted (45 lines), three call sites updated: `_onResult` uses `countVoiceWords(...)`, `_parseFinalResult` uses `buildVoiceAudioFeatures(soundLevels: _soundLevels, timestamps: _timestamps, startTime: _startTime, partialResultCount: _partialResultCount, wordCount: _lastWordCount)`, `build()` uses `extractVoiceKeyword(_parseResult!)`
- LOC progression: 815 → 776 (−39)

**Final LOC:** `voice_input_screen.dart` = **776** (target ≤790; hard cap <800). 24 lines of headroom for v1.4 micro-additions.

## Verification Results

### Phase 23 file analyzer (clean)

```
flutter analyze \
  lib/features/accounting/presentation/screens/voice_input_screen.dart \
  lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart \
  lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart
→ No issues found! (3 items analyzed)
```

### Project-wide analyzer (4 pre-existing infos — out of scope)

```
flutter analyze → 4 issues found
```

All 4 are pre-existing and NOT introduced by this plan:
1. `build/ios/SourcePackages/firebase_messaging-16.2.2/example/analysis_options.yaml:5:10` — vendor build artifact, `include_file_not_found`
2. `build/ios/SourcePackages/firebase_messaging-16.2.2/lib/src/messaging.dart:17:41` — vendor code, `prefer_final_fields` (info)
3. `lib/features/accounting/presentation/screens/category_selection_screen.dart:386:17` — pre-existing `onReorder` deprecation (last touched in unrelated commit `6186a85 chore: dart format codebase`)
4. `lib/features/accounting/presentation/screens/category_selection_screen.dart:502:13` — same

Scope-boundary rule: out-of-scope findings are documented, not fixed (see Deferred Issues below).

### Targeted tests (all pass)

```
flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart
→ 18/18 passed (incl. D-07 cold-start race tests at lines 1201 + 1252, D-08 popUntil tests, D-09 FocusNode cleanup, D-11 G-02 localized assert, G-01/G-02 gap closure tests)

flutter test test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart
→ 4/4 passed (D-05 intra-session guard 4-case suite untouched)
```

### Full suite (no NEW failures)

```
flutter test
→ +2026 passed, −11 failed
```

All 11 failures are HomeHeroCard light/ja golden pixel-diff failures in `test/golden/home_hero_card_golden_test.dart`. These match the documented pre-existing baseline drift exactly (per `23-VERIFICATION.md` "Pre-existing Test Suite Notes" — they pre-date Phase 23 and last commit to `home_hero_card_golden_test.dart` was `5e00df1 feat(14-03)`). Zero NEW failures introduced by Plan 23-09.

### Invariant preservation (grep evidence)

```
$ wc -l lib/features/accounting/presentation/screens/voice_input_screen.dart
776  (< 800 cap; 24-line headroom)

$ grep -c '!isLocaleReady' lib/features/accounting/presentation/screens/voice_input_screen.dart
1                                            # D-07 guard reads mixin getter

$ grep -c 'ref.listenManual' lib/features/accounting/presentation/screens/voice_input_screen.dart
0                                            # D-07 listener moved out

$ grep -c 'voiceLocaleIdProvider' lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart
6                                            # provider referenced in mixin (1 import + 1 listener call + 4 docstring)

$ grep -c 'waitForCelebrationDismissed' lib/features/accounting/presentation/screens/voice_input_screen.dart
1                                            # D-08 soul-ledger pop deferral intact

$ grep -c '_merchantFocus\.dispose\|_noteFocus\.dispose' lib/features/accounting/presentation/screens/voice_input_screen.dart
2                                            # D-09 FocusNode cleanup intact

$ grep -c 'VoiceRecognitionEventHandlerMixin' lib/features/accounting/presentation/screens/voice_input_screen.dart
2                                            # D-10 mixin still in chain (import + with-clause)

$ grep -c 'VoiceLocaleReadinessMixin' lib/features/accounting/presentation/screens/voice_input_screen.dart
2                                            # new mixin in with-clause + import

$ git diff main..HEAD --stat lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
(empty — D-05/D-10 mixin file untouched)

$ grep -rn '_isLocaleReady\b' lib/ | grep -v 'voice_locale_readiness_mixin.dart' | wc -l
0                                            # private symbol lives only in its new home
```

**Result: all D-05, D-07, D-08, D-09, D-10, D-11 invariants preserved.**

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Minor Deviations

**1. [Rule 3 — Out of scope, deferred] 4 pre-existing analyzer issues**

- **Found during:** Task 3 full project `flutter analyze`
- **Issue:** Project-wide analyze surfaces 4 issues (2 in `build/ios/SourcePackages/firebase_messaging` vendor code; 2 in `lib/features/accounting/presentation/screens/category_selection_screen.dart` — pre-existing `onReorder` deprecations)
- **Scope:** All 4 are unrelated to Phase 23's modified files. `category_selection_screen.dart` was last touched in `6186a85 chore: dart format codebase` — not in any Phase 23 commit.
- **Decision:** Per scope-boundary rule ("Only auto-fix issues DIRECTLY caused by the current task's changes. Pre-existing warnings, linting errors, or failures in unrelated files are out of scope.") — leave for v1.4+ cleanup. Phase 23 plans 1-8 already shipped without addressing these, confirming they pre-date this plan and are a separate concern.
- **Files modified:** none (intentionally not fixed)
- **Commit:** —

## Deferred Issues

| Item | Reason |
|------|--------|
| `category_selection_screen.dart:386, 502` `onReorder` deprecated | Pre-existing; out of scope for a voice-screen gap-closure plan |
| `firebase_messaging` vendor `prefer_final_fields` + `include_file_not_found` | Vendor build artifact; not part of project source |

These are documented for v1.4+ pickup if/when a Flutter SDK bump or `category_selection_screen.dart` touch happens organically.

## Known Stubs

None — this plan is a pure code-organization refactor. No new data flows; no new UI surfaces; no placeholder values.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes. The new mixin reads from the existing `voiceLocaleIdProvider` (already in scope) and writes to a private field with explicit `dispose()` cleanup (T-23-09-03 disposition: `mitigate` → executed by closing `_localeSubscription` before `super.dispose()`). The new helper file contains 3 pure functions with no external I/O.

## Self-Check: PASSED

- [x] `lib/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart` — exists (99 LOC)
- [x] `lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart` — exists (75 LOC)
- [x] `lib/features/accounting/presentation/screens/voice_input_screen.dart` — modified (776 LOC, < 800 cap)
- [x] Commit `26e2fa8` exists (Task 1 — mixin extraction)
- [x] Commit `e1dd6c3` exists (Task 2 — helper extraction)
- [x] All 18 voice_input_screen widget tests pass
- [x] All 4 voice_recognition_event_handler_mixin unit tests pass
- [x] `flutter analyze` on the 3 Phase-23-touched files reports 0 issues
- [x] Full `flutter test` shows no NEW failures vs. documented pre-existing HomeHeroCard light/ja baseline drift (11 failures, all matching the documented baseline)
- [x] D-05, D-07, D-08, D-09, D-10, D-11 invariants preserved per grep evidence above
- [x] 23-VERIFICATION.md WARNING resolved via path (b) slim-down (838 → 776 LOC)
