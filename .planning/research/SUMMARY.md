# Project Research Summary

**Project:** Home Pocket (まもる家計簿) — v2.0 pre-launch capstone
**Domain:** Pre-launch gating/lock/compliance for a shipped local-first encrypted Flutter family-accounting app (Japan market, iOS 14+/Android 7+)
**Researched:** 2026-06-28
**Confidence:** HIGH (integration/stack/architecture grounded in current source; store-policy/JP-legal specifics MEDIUM, flagged for legal review)

## Executive Summary

This milestone adds four pre-launch surfaces to an already-shipped app — first-run onboarding (mandatory UI-language / currency / voice-language setup), an app-lock (Face ID/biometric + PIN), a Settings donation link, and a Japanese-market legal section (Privacy Policy / Terms / OSS licenses, with 特商法 flagged). The defining characteristic of the research is that **this is an integration milestone, not a greenfield build.** Almost everything needed already exists in the codebase: `local_auth ^3.0.1`, `flutter_secure_storage ^10.2.0` (with a pre-wired `StorageKeys.pinHash` slot), `crypto`/`cryptography` KDFs, the SharedPreferences-backed `SettingsRepository`, the v1.7 JPY-first currency selector, voice-locale routing, and Flutter's built-in `showLicensePage`. The single genuinely-new runtime dependency is **`url_launcher ^6.3.2`** (donation link), and it has been verified clear of the project's `win32`-pinned `file_picker`/`share_plus`/`package_info_plus` trap.

The recommended approach is to attach both new gates to the **one existing integration seam** — the synchronous branch ladder in `HomePocketApp._buildHome()` (`lib/main.dart`), mirroring the existing `_needsProfileOnboarding` gate. Gate config is read once in `_initialize()` after `AppInitializer` completes and held in local widget state, so the gates can never race init and never flash protected content. Onboarding writes through existing providers (`localeProvider`, `BookRepository.update` for currency, `setVoiceLanguage`) and sets a single `onboarding_complete` flag **last**; app-lock adds a `PinService` (salted slow-KDF hash in the Keychain), an `AppLockScreen`, and a `WidgetsBindingObserver` for resume re-lock; legal/donation extend the Settings `AboutSection`.

The key risks are concentrated in security and compliance, not feature complexity. The highest-severity pitfall is **changing `flutter_secure_storage` keychain accessibility** — on 10.x this silently bricks every existing install (documented project gotcha, quick 260610-ss7); the PIN must reuse the shared `unlocked_this_device` options. Other critical risks: weak/plaintext PIN storage (use salted slow KDF + persisted lockout), onboarding racing `AppInitializer`, missing re-lock-on-resume plus app-switcher data leak, biometric edge cases with no PIN fallback, ARB trilingual-parity / hardcoded-CJK scan failures on the large legal copy volume, and store-review/特商法 rejection of the donation path. Mitigation is well-understood for all of them and mapped to specific phases below.

## Key Findings

### Recommended Stack

The milestone needs **almost no new dependencies** — onboarding persistence, biometric, PIN hashing, secure storage, OSS-license display, and the about/version surface are all satisfiable with packages already in `pubspec.yaml` or Flutter built-ins. Frame every decision as "reuse vs add" and default to reuse. No `go_router` (boot-time branch widgets, not routes), no IAP/payment SDK (donation is a link), no `sqlite3_flutter_libs` (banned), no `flutter_markdown` (discontinued 2025), and do not bump the win32-pinned trio.

**Core technologies:**
- `url_launcher ^6.3.2` (NEW, the only added dep): donation link via `launchUrl(..., LaunchMode.externalApplication)` — verified no win32 conflict (`url_launcher_windows` deps only flutter + platform interface).
- `local_auth ^3.0.1` (reuse): Face ID/Touch ID/Android biometric — extend existing `biometric_service.dart`, do not re-wrap.
- `flutter_secure_storage ^10.2.0` (reuse): PIN hash+salt + lock flags in `StorageKeys.pinHash` — keep `unlocked_this_device` accessibility unchanged.
- `crypto ^3.0.6` / `cryptography ^2.7.0` (reuse): salted slow-KDF (PBKDF2 ≥100k iterations or Argon2id) for the PIN — never plaintext, never fast hash.
- `shared_preferences ^2.3.4` via `SettingsRepository` (reuse): UI-language, voice-language, and the new `onboarding_complete` flag — same store the app already reads.
- Flutter built-ins `showLicensePage`/`LicenseRegistry` (reuse): OSS attribution, auto-aggregates transitive deps.

### Expected Features

**Must have (table stakes):**
- Onboarding: device-locale-aware language pre-selection, JPY default, re-entrant (can't get stuck), progress + back nav — "confirm a sensible default," not "fill a blank form."
- App-lock: biometric-first with mandatory PIN fallback, lock on cold launch, re-lock on resume past grace threshold, failed-attempt feedback + escalating cooldown (no default data-wipe), Settings toggle.
- Donation: exactly one unobtrusive external-browser link in Settings (応援/支援 framing), no IAP, no webview, no nags.
- Legal: Privacy Policy (hosted URL mandatory for App Store Connect + in-app), 利用規約, OSS licenses — all localized in ja/zh/en.

**Should have (competitive / on-brand):**
- Skippable privacy/local-first intro slides (trust differentiator vs account-pushing kakeibo apps).
- Voice-input language confirmed during onboarding, defaulted to chosen UI language.
- App-lock prompt offered (clearly skippable) during onboarding for adoption-without-nagging.

**Defer (v2.x / future):**
- Forgot-PIN → BIP39 recovery reset (strongly recommended; if descoped, document the lockout trade-off explicitly).
- Configurable re-lock grace period (ship a fixed default first).
- 特商法 表記 entry (add if/when legal review says the donation path triggers it).
- Opt-in "erase after N failures" (default off, likely never).

### Architecture Approach

There is a single integration seam: the synchronous gate ladder in `HomePocketApp._buildHome()`. `AppInitializer` completes (KeyManager → DB → container) before `runApp`, so by the time `HomePocketApp` mounts the container is guaranteed ready. Both new gates are added as branches in this ladder, **below** the existing error/spinner branches and reading config resolved once in `_initialize()` — never as a second `ProviderScope`, never as an async gate in `build()`, never via go_router. Order: error → loading → onboarding (branch 3, first-run only) → app-lock (branch 4, launch + resume) → profile onboarding (branch 5) → main shell (branch 6).

**Major components:**
1. `OnboardingFlow` (NEW `features/onboarding/presentation/`) — intro + mandatory language/currency/voice setup writing through existing providers; writes `onboarding_complete` last.
2. `AppLockScreen` + `AppLockController` (NEW `features/app_lock/`) — biometric + PIN unlock UI; `WidgetsBindingObserver` re-locks on `resumed`-after-`paused` (mirrors `SyncEngine`).
3. `PinService` (NEW `infrastructure/security/`) — salted-hash PIN, verify, store/clear via pre-wired `StorageKeys.pinHash`.
4. `LegalSection` / `DonationSection` (extend `AboutSection`) — Privacy/Terms/特商法/OSS + `url_launcher` donation; legal text as bundled localized `assets/legal/` (offline).
5. Modified `lib/main.dart` (`_initialize()` + `_buildHome()` branches 3/4), `SecuritySection` (PIN setup tile), ARB ja/zh/en.

Persistence is per-setting and justified: PIN hash → Keychain (only true secret); lock toggles + `onboarding_complete` → SharedPreferences (boot-safe, no DB dependency); UI/voice language → SharedPreferences (canonical paths); currency → encrypted Drift `Book.currency` (per-book domain data).

### Critical Pitfalls

1. **Changing keychain accessibility bricks every install** — keep the new PIN write on the shared `unlocked_this_device` options object; never pass per-call `IOSOptions(accessibility:)`. Add a regression test asserting the shared options object. (Project memory: quick 260610-ss7.)
2. **Weak PIN storage** — salted slow KDF (≥100k iterations) in secure storage, constant-time compare, persisted retry counter with escalating backoff (cleared only on success), no auto-wipe. Run KDF off the main isolate (`compute`) to avoid unlock jank on Android 7.
3. **Onboarding races `AppInitializer`** — derive the onboarding decision from settled init state held in local widget state; write `onboarding_complete` exactly once on explicit finish; never infer completion from "currency != null."
4. **No re-lock on resume + app-switcher leak** — re-lock on `paused`/resume (NOT `inactive`, which loops the biometric prompt); suppress re-lock while a biometric prompt is in flight; shield overlay on `inactive` so the switcher snapshot shows no data; lock screen sits as a root overlay above the IndexedStack, and fully no-ops when disabled.
5. **Biometric edge cases with no PIN fallback** — PIN mandatory whenever lock enabled; handle the full `local_auth` error taxonomy (`notAvailable`/`notEnrolled`/`lockedOut`/`permanentlyLockedOut`/`passcodeNotSet`/cancel) → route to PIN; check availability at enable + each unlock.
6. **i18n parity / CJK scan on new screens (esp. legal)** — every visible string through ARB ×3 + `flutter gen-l10n` + `git add -f lib/generated/`; for long legal docs use bundled per-locale assets WITH a matching "all three locales present" gate; run hardcoded-CJK scan + full `flutter test` before done.
7. **Donation rejection / 特商法** — external browser only, neutral non-transactional wording, no reward; prepare a 特商法 表記 surface; verify via a real TestFlight/internal-track review, not self-assessment.
8. **Store privacy forms / OSS attribution** — fill Apple/Google forms truthfully and consistently with the policy (disclose the v1.7 exchange-rate network call); surface `showLicensePage` (don't hand-maintain); hosted Privacy Policy + 利用規約 URLs in all three languages.

## Implications for Roadmap

> Numbering continues from v1.9 Phase 52 → this milestone starts at **Phase 53**. The architecture and pitfalls research independently converge on the same four-phase, design-gate-first ordering.

### Phase 53: HTML design gate (no production code)
**Rationale:** Mirrors the v1.8 Phase 43 precedent — onboarding flow approved as an HTML draft before any Dart, per the explicit milestone requirement. Can start early/in parallel with research since it produces no code.
**Delivers:** Approved HTML design drafts for the onboarding flow, the lock screen, and the legal/donation Settings layout.
**Addresses:** Onboarding UX (step order: language-first), app-lock screen, legal/donation layout.
**Avoids:** Rework from building the flow before the design is settled.

### Phase 54: Onboarding flow
**Rationale:** Build before app-lock because the lock setup is *offered during* onboarding; the onboarding gate slot is the structural prerequisite for the milestone.
**Delivers:** Gate branch 3 + mandatory language/currency/voice setup writing through existing providers; `onboarding_complete` written last; optional skippable intro; optional "set up app lock" prompt placeholder.
**Uses:** `localeProvider`, `SettingsRepository`, `BookRepository.update`, `voiceLocaleIdProvider`, v1.7 currency selector.
**Implements:** `OnboardingFlow` + gate branch in `_buildHome()`.
**Avoids:** Pitfall 3 (race/idempotency), Pitfall 6 (i18n parity).

### Phase 55: App-lock (highest-risk — own phase + security review)
**Rationale:** The highest-risk integration (keychain + lifecycle + biometric). Depends on the onboarding lock prompt existing.
**Delivers:** `AppLockScreen` (biometric + PIN), `PinService` (salted KDF), `AppLockController` resume re-lock + switcher shield, gate branch 4, `SecuritySection` PIN/toggle controls.
**Uses:** `local_auth`, `flutter_secure_storage` (shared accessibility), `crypto`/`cryptography`.
**Avoids:** Pitfalls 1, 2, 4, 5 (keychain brick, weak PIN, resume leak, biometric fallback).

### Phase 56: Settings legal + donation + Japan compliance (launch gate)
**Rationale:** Independent of the gates; schedule last but with slack for a real store-review round-trip — donation/privacy rejection is the most likely external blocker.
**Delivers:** Privacy/Terms/特商法/OSS surfaces, `url_launcher` donation link, bundled localized legal assets, trilingual ARB, hosted-URL coordination, store privacy-form reconciliation.
**Uses:** `url_launcher`, `showLicensePage`, bundled `assets/legal/`.
**Avoids:** Pitfalls 6, 7, 8 (i18n, donation/特商法, privacy forms/OSS).

### Phase Ordering Rationale
- **Design-gate-first** is a hard milestone requirement (HTML draft → strict implementation) and matches the proven Phase 43 precedent.
- **Onboarding before app-lock** because step ⑤ of onboarding offers to enable a lock that must already exist.
- **App-lock isolated** because it concentrates the three highest-severity integration risks and warrants its own security review.
- **Legal/donation last but early-scheduled for review slack** — it is the only phase whose blocker (store review) is external and non-deterministic.

### Research Flags

Phases likely needing deeper research / external verification during planning:
- **Phase 55 (App-lock):** keychain-accessibility regression behavior on a populated install, `local_auth` error taxonomy, and off-isolate KDF tuning warrant a focused security review (`--research-phase` or `gsd-secure-phase`).
- **Phase 56 (Legal/compliance):** 特商法 applicability to an individual developer's external-platform donation, APPI policy wording, and current Apple/Google donation-review stance are MEDIUM-confidence and need a JP-savvy legal advisor + a real review submission — not self-assessment.

Phases with standard patterns (skip research-phase):
- **Phase 53 (HTML design):** established Phase 43 precedent.
- **Phase 54 (Onboarding):** all write paths already exist; pattern mirrors `_needsProfileOnboarding`.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Versions confirmed in `pubspec.yaml`/`pubspec.lock`; `url_launcher` win32-conflict cleared by transitive analysis. |
| Features | MEDIUM-HIGH | UX patterns well-established; Apple-policy + Japan-legal specifics MEDIUM and flagged. |
| Architecture | HIGH | All integration points read directly from current source (main.dart, app_initializer, secure_storage_service, settings/about/security sections, state_locale). |
| Pitfalls | MEDIUM-HIGH | Integration/security pitfalls HIGH (codebase + project memory grounded); store-policy/legal MEDIUM (policies shift, needs JP legal sign-off). |

**Overall confidence:** HIGH for engineering execution; MEDIUM for external compliance/store-review outcomes.

### Gaps to Address

- **特商法 applicability** to an external-platform donation by an individual developer — resolve with a JP legal advisor in Phase 56; default to providing a 特商法 表記 surface if in doubt.
- **Store-review approval of the donation link** — non-deterministic; verify via TestFlight/internal-track submission and keep a fallback (soften wording / external Settings entry) ready.
- **Forgot-PIN recovery decision** — whether BIP39 recovery resets the PIN; decide explicitly in Phase 55, and if descoped, ensure lock copy promises no recovery that doesn't exist.
- **Re-lock grace policy** — confirm default (immediate vs 1 min) and whether user-configurable; ship a fixed default first.
- **PIN length** — pick and fix 4 vs 6 digits (research recommends 6) before Phase 55 implementation.
- **Hosted legal URLs** — Privacy Policy + 利用規約 must exist as reachable URLs for both store listings (ops/external task, not pure code).

## Sources

### Primary (HIGH confidence)
- Repo source: `lib/main.dart`, `lib/core/initialization/app_initializer.dart`, `lib/infrastructure/security/secure_storage_service.dart` + `providers.dart`, `lib/data/repositories/settings_repository_impl.dart`, settings `about_section.dart`/`security_section.dart`, `state_locale.dart`/`state_settings.dart`, `profile_onboarding_screen.dart` — integration seams, pre-wired `pinHash` slot, write-through paths.
- `pubspec.yaml`/`pubspec.lock` — already-present versions; `url_launcher_windows` resolves win32-free.
- CLAUDE.md + project memory `flutter-secure-storage-accessibility-read-filter` (quick 260610-ss7) — keychain-accessibility brick, iOS pin constraints, no-go_router / no-sqlite3_flutter_libs, ARB parity discipline.

### Secondary (MEDIUM confidence)
- Apple App Review Guidelines (3.1.1/3.1.3) + external-link updates; Google Play donation/external-link policy — donation-review stance, region-scoped entitlements.
- Japan スマホ新法 (in force 2025-12-18) — external payment links permitted/fee-capped, but review approval still required.
- pub.dev `url_launcher` / `local_auth` / `flutter_secure_storage` docs; Flutter `showLicensePage`/`LicenseRegistry`.

### Tertiary (LOW confidence — needs validation)
- 特定商取引法 表記 applicability for individual-operator external-platform donations — confirm with JP legal advisor.
- APPI privacy-policy wording expectations — confirm against PPC guidance before store submission.

---
*Research completed: 2026-06-28*
*Ready for roadmap: yes*
