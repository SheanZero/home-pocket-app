---
phase: 54-onboarding-flow
plan: 02
subsystem: i18n
tags: [arb, l10n, onboarding, i18n, ja, zh, en]

requires: []
provides:
  - "24 onboarding* ARB keys in ja/zh/en (intro selling points, settings rows, confirm button, lock-entry) — consumed by 54-05 (settings) and 54-06 (intro/lock-entry) via S.of(context).onboarding*"
  - "onboardingStart = この設定で始める (locked confirm copy, distinct from profileStart=はじめる)"
  - "onboardingNicknameUnset = 未設定 nickname empty-state placeholder (D-14)"
  - "Regenerated lib/generated/app_localizations*.dart with the new getters"
affects: [54-05-onboarding-settings, 54-06-onboarding-screens]

tech-stack:
  added: []
  patterns:
    - "Single-owner ARB plan: one plan authors every onboarding string so Wave-2 screen plans never collide on shared ARB files (MEMORY: same-wave executors collide on ARB l10n keys)"
    - "Keys defined ahead of Dart consumers — arb_key_parity only enforces cross-locale parity, not key usage; no unused-l10n test exists"
    - "@metadata mirrored across all three ARB files (parity test enforces metadata key-set match, not just normal keys)"

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
  - "4 distinct intro selling points (privacy/encryption, local-first, dual-ledger, voice) each as title+body keys — the sketch tone-A merged privacy+local-first; D-02/must_haves require 4 separate, so split them"
  - "Reused existing `language`/`language*` keys for the UI-language picker; minted onboarding-prefixed labels only for currency (onboardingRowCurrency) and voice (onboardingRowVoice) rows — no clean generic label key existed"
  - "ARB + regenerated localizations committed together in one atomic commit (project guidance + files_modified lists both) to avoid leaving generated Dart stale between commits (AUDIT-10 invariant)"

patterns-established:
  - "onboarding* key family: onboardingIntro* / onboardingSettings* / onboardingRow* / onboardingLock* / onboardingStart / onboardingChange / onboardingNicknameUnset"

requirements-completed: [ONBOARD-02]

coverage:
  - id: SC5
    description: "arb_key_parity_test passes (ja/zh/en normal + @metadata key sets match)"
    verified: "flutter test test/architecture/arb_key_parity_test.dart → +2 All tests passed"
  - id: D-02
    description: "4 approved intro selling points exist as ARB keys in all three locales"
    verified: "onboardingIntro{Privacy,Local,Ledger,Voice}{Title,Body} present in ja/zh/en"
  - id: D-11/D-13
    description: "lock-entry title/description/skip/setup-now keys in all three files"
    verified: "onboardingLock{Title,Description,Skip,SetupNow} present in ja/zh/en"
---

# Phase 54 Plan 02: Onboarding ARB Keys (single owner) Summary

Authored 24 `onboarding*` ARB keys in all three locales (ja default, zh, en) covering the entire onboarding-flow UI surface — intro selling points, the basic-settings rows, the locked confirm button, and the trailing lock-entry screen — then regenerated the Flutter localizations. This plan is the single owner of onboarding ARB edits so the Wave-2 screen plans (54-05 settings, 54-06 intro/lock-entry) can reference `S.of(context).onboarding*` without touching the shared ARB files.

## What Was Built

**Task 1 — ARB keys (single owner):** Added 24 keys to `app_ja.arb`, `app_zh.arb`, `app_en.arb` with mirrored `@metadata`:
- **Intro (D-02 / ONBOARD-02):** `onboardingIntroTitle`, `onboardingIntroSubtitle`, 4 selling-point pairs (`onboardingIntroPrivacy{Title,Body}`, `onboardingIntroLocal{Title,Body}`, `onboardingIntroLedger{Title,Body}`, `onboardingIntroVoice{Title,Body}`), `onboardingIntroContinue`, `onboardingIntroSkip`.
- **Settings (D-01/D-03/D-10):** `onboardingSettingsTitle`, `onboardingSettingsSubtitle`, `onboardingSettingsHint`, `onboardingRowCurrency`, `onboardingRowVoice`, `onboardingChange`, `onboardingNicknameUnset` (D-14 未設定 placeholder). UI-language picker reuses the existing `language`/`language*` keys.
- **Confirm:** `onboardingStart` = `この設定で始める` (locked, distinct from `profileStart`=はじめる).
- **Lock-entry (D-11/D-13):** `onboardingLockTitle`, `onboardingLockDescription`, `onboardingLockSkip`, `onboardingLockSetupNow`.

**Task 2 — Regenerate localizations:** `flutter gen-l10n` regenerated `lib/generated/app_localizations*.dart` so the `onboarding*` getters exist; force-added the (tracked) generated files; `flutter analyze` clean.

## Verification

- `flutter test test/architecture/arb_key_parity_test.dart` → All tests passed (normal + metadata key sets match across ja/zh/en; OCR stubs preserved).
- Equal key counts across the three files: 1338 / 1338 / 1338 (715 normal + 622 metadata + @@locale each).
- `grep -c onboardingStart lib/generated/app_localizations.dart` → 1 (getter generated).
- ja value of `onboardingStart` is exactly `この設定で始める`.
- `flutter analyze` → No issues found.

## Deviations from Plan

None functional. The plan's two tasks were committed as a single atomic commit rather than two, because the project guidance and the plan's own `files_modified` require the regenerated localizations to land alongside the ARB edits (committing ARB alone would momentarily leave the generated Dart stale, violating the AUDIT-10 no-stale-generated invariant). All Task 1 and Task 2 acceptance criteria were met.

## Known Stubs

None. The keys are intentionally defined ahead of their Dart consumers (54-05 / 54-06) — `arb_key_parity` enforces only cross-locale parity, not key usage, and no unused-l10n test exists, so unreferenced-until-Wave-2 keys are safe (verified in the plan objective).

## Self-Check: PASSED
- lib/l10n/app_ja.arb, app_zh.arb, app_en.arb — FOUND, onboardingStart present in all three
- lib/generated/app_localizations.dart — FOUND, onboardingStart getter present
- Commit 114c9d70 — FOUND in git log
