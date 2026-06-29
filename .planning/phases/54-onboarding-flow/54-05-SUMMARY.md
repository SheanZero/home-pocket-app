---
phase: 54-onboarding-flow
plan: 05
subsystem: onboarding
tags: [onboarding, riverpod, i18n, locale, currency, voice, profile, settings]

requires:
  - phase: 54-onboarding-flow
    plan: 01
    provides: "preselectOnboardingLanguage + resolveVoiceLanguageForOnboarding (concrete voice default, never 'system')"
  - phase: 54-onboarding-flow
    plan: 02
    provides: "onboarding* ARB keys (settings rows, 未設定 placeholder, この設定で始める)"
provides:
  - "OnboardingSettingsScreen — merged single-page onboarding settings (nickname[required] + avatar + UI-language + currency + voice) with the D-14 nickname-required gate"
  - "onConfirmed VoidCallback contract — fires only on profile-save success; the flow host (54-07) wires it to lock-entry. The screen does NOT set onboarding_complete"
  - "NEW book-default currency write path: bookRepo.update(book.copyWith(currency:)) driven from CurrencySelectorSheet onSelect"
affects: [54-07-onboarding-gate]

tech-stack:
  added: []
  patterns:
    - "Each 「ラベル: 現在値 [変更]」 row writes through its existing provider immediately on edit (mirrors appearance_section await setX + ref.invalidate(appSettingsProvider))"
    - "Dialog owning its own TextEditingController (_NicknameDialog) avoids use-after-dispose during the route exit transition"
    - "Voice default routed through the 54-01 resolver at confirm so the persisted code is always concrete ja/zh/en"

key-files:
  created:
    - lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart
    - test/widget/features/onboarding/onboarding_settings_test.dart
    - .planning/phases/54-onboarding-flow/54-05-design-deviation-qa.md
  modified: []

key-decisions:
  - "Confirm persists untouched defaults (system language via setSystemDefault, concrete voice via resolveVoiceLanguageForOnboarding) before saving the profile; explicit edits already wrote through on-row for instant MaterialApp switch"
  - "The screen signals completion via onConfirmed and never navigates or sets onboarding_complete — that lands in 54-07 (flow host)"
  - "Nickname editor extracted into a dedicated _NicknameDialog StatefulWidget that owns its controller (lifecycle-safe)"

patterns-established:
  - "Onboarding settings page = profile_onboarding_screen identity capture + appearance_section 変更-row write-through, recombined with zero net-new visual language (D-03)"

requirements-completed: [ONBOARD-03, ONBOARD-04, ONBOARD-05, ONBOARD-07]

coverage:
  - id: D-14
    description: "この設定で始める disabled until nickname.trim() non-empty; nickname row shows 未設定 placeholder"
    verification:
      - kind: widget
        ref: "test/widget/features/onboarding/onboarding_settings_test.dart#D-14 nickname gate (disabled→enabled)"
        status: pass
    human_judgment: false
  - id: ONBOARD-03
    description: "UI-language explicit pick → setLocale(Locale(code)) persists concrete code; untouched → setSystemDefault() persists 'system'"
    requirement: "ONBOARD-03"
    verification:
      - kind: widget
        ref: "onboarding_settings_test.dart#explicit pick persists 'en' + confirm persists 'system'"
        status: pass
    human_judgment: false
  - id: ONBOARD-04
    description: "Currency selection writes Book.currency via bookRepo.update(book.copyWith(currency:))"
    requirement: "ONBOARD-04"
    verification:
      - kind: widget
        ref: "onboarding_settings_test.dart#currency selection writes Book.currency (fake bookRepo records USD)"
        status: pass
    human_judgment: false
  - id: ONBOARD-05
    description: "Voice default = chosen UI lang; untouched preselect resolves to a concrete ja/zh/en, never 'system'"
    requirement: "ONBOARD-05"
    verification:
      - kind: widget
        ref: "onboarding_settings_test.dart#confirm persists concrete voice (∈ {ja,zh,en}, not 'system')"
        status: pass
    human_judgment: false
  - id: ONBOARD-07
    description: "Confirm fires onConfirmed only on profile-save success (flow host advances to lock-entry)"
    requirement: "ONBOARD-07"
    verification:
      - kind: widget
        ref: "onboarding_settings_test.dart#confirm fires onConfirmed + profile saved"
        status: pass
    human_judgment: false
  - id: D-03
    description: "Design-deviation QA note records the user-directed identity-rows addition (recombines approved components, no net-new visual language)"
    verification:
      - kind: other
        ref: "grep -c D-03 .planning/phases/54-onboarding-flow/54-05-design-deviation-qa.md => 6"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-06-29
status: complete
---

# Phase 54 Plan 05: Merged Onboarding Settings Page Summary

**`OnboardingSettingsScreen` — a single page of unified 「ラベル: 現在値 [変更]」 rows (nickname[required] + avatar + UI-language + 記帳通貨 + 音声入力言語) that writes each field through its existing provider on edit, blocks `この設定で始める` until a nickname is set (D-14), and signals completion via `onConfirmed` (never setting `onboarding_complete`).**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3
- **Files created:** 3 (screen, widget test, design-deviation QA note)

## Accomplishments

- **Task 1 — screen + D-14 gate:** Built `OnboardingSettingsScreen` (`ConsumerStatefulWidget`, `required bookId`, `required onConfirmed`) with five unified `_SettingsRow`s (D-10). Each row opens its editor (nickname text dialog, avatar `AvatarPickerScreen` push, language/voice radio dialogs, currency `CurrencySelectorSheet` bottom sheet). `この設定で始める` gradient button (ported `_ProfileGradientButton`) stays disabled while `_nickname.trim()` is empty; nickname row shows the `未設定` placeholder. All strings via `S.of(context)`, all colors via `context.palette` (ADR-019).
- **Task 2 — write-through + confirm:** UI-language explicit pick → `localeProvider.setLocale` (instant MaterialApp switch), system → `setSystemDefault`, both + `ref.invalidate(appSettingsProvider)` (D-07/D-08). Currency → `bookRepo.update(book.copyWith(currency:))` + invalidate `bookByIdProvider` (NEW book-default write path, ONBOARD-04/D-09). Voice → immediate `setVoiceLanguage`; `_confirm` routes the default through `resolveVoiceLanguageForOnboarding` so the persisted code is always concrete ja/zh/en, never `system` (D-09/Pitfall 4). Confirm persists untouched defaults, runs `saveUserProfileUseCase.execute`, and on success invalidates `userProfileProvider` + fires `onConfirmed` (error → mapped feedback, `onConfirmed` not fired).
- **Task 3 — D-03 QA note:** Wrote `54-05-design-deviation-qa.md` documenting the intentional, user-directed addition of nickname + avatar rows absent from approved sketch 001 tone-A — recombines already-approved components (行+変更 idiom + existing identity controls), zero net-new visual language, confirm copy locked to `この設定で始める`.

## Task Commits

1. **Task 1: OnboardingSettingsScreen unified rows + nickname-required gate** — `16945c9e` (feat)
2. **Task 2: write-through language/currency/voice/profile on confirm** — `539f34d1` (feat)
3. **Task 3: record D-03 design-deviation QA note** — `157c2935` (docs)

## Files Created

- `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart` — the merged settings page + `_NicknameDialog` / `_SettingsRow` / `_OnboardingGradientButton` helpers + ported `_messageForError`
- `test/widget/features/onboarding/onboarding_settings_test.dart` — 6 widget tests (D-14 gate, five-row render, explicit-language persist, currency write-through, confirm system+concrete-voice + onConfirmed)
- `.planning/phases/54-onboarding-flow/54-05-design-deviation-qa.md` — D-03 deviation record

## Verification

- `flutter analyze` → No issues found (0).
- `flutter test test/widget/features/onboarding/onboarding_settings_test.dart` → 6/6 pass.
- Wave-gate architecture tests `hardcoded_cjk_ui_scan` + `arb_key_parity` → pass (no hardcoded CJK in the screen; ARB parity unchanged).
- Acceptance greps on the screen: `setLocale|setSystemDefault`=3 (≥2), `copyWith(currency:`=1 (==1), `resolveVoiceLanguageForOnboarding`=3 (≥1), `saveUserProfileUseCase`=1 (≥1), `S.of(context)`=5 (≥5).

## Deviations from Plan

None functional. Task 1's `_isSaving` was first declared `final` (no mutation in Task 1, to keep analyze at 0) and converted to a mutable field in Task 2 when the confirm flow began writing it — a natural two-commit split, not a behavior change. The nickname editor was extracted into a dedicated `_NicknameDialog` StatefulWidget (vs an inline `showDialog` builder) to own the `TextEditingController` lifecycle and avoid a use-after-dispose assertion during the dialog's exit transition (Rule 1 — fix the controller-lifecycle bug surfaced by the RED test).

## Known Stubs

None. The screen wires every row through a real existing provider. `onConfirmed` is an intentional seam (not a stub): the flow host in 54-07 supplies the lock-entry navigation and the final `setOnboardingComplete(true)`, per the plan's explicit scope boundary.

## Self-Check: PASSED

- `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart` — FOUND
- `test/widget/features/onboarding/onboarding_settings_test.dart` — FOUND
- `.planning/phases/54-onboarding-flow/54-05-design-deviation-qa.md` — FOUND
- Commits `16945c9e`, `539f34d1`, `157c2935` — FOUND in git log

---
*Phase: 54-onboarding-flow*
*Completed: 2026-06-29*
