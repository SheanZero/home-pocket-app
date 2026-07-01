---
phase: 56-setting
plan: 06
subsystem: settings
tags: [legal, sponsor, privacy, store-compliance, launch-gate]
requires:
  - "56-05: LegalSponsorSection widget"
  - "56-02: privacy_ja.md (口径 source)"
provides:
  - "LegalSponsorSection wired into live Settings screen (法的情報・応援 group reachable in-app)"
  - "store-privacy-form checklist (Apple/Google two-column launch deliverable)"
affects:
  - lib/features/settings/presentation/screens/settings_screen.dart
tech-stack:
  added: []
  patterns:
    - "Additive ListView insertion preserving const Divider() rhythm; frozen Phase-55 SecuritySection left byte-unchanged"
key-files:
  created:
    - .planning/phases/56-setting/56-store-privacy-form-checklist.md
  modified:
    - lib/features/settings/presentation/screens/settings_screen.dart
decisions:
  - "Store form declared non-reflexively: Data Collection = Yes (FCM push-token to Google when enabled), enumerating real v1.7 exchange-rate fetch — not a blanket 不収集"
  - "口径 locked identical to privacy_ja.md (56-02): F1 on-device/E2EE, F2 fx fetch, F3 push-token, F4 P2P E2EE, F5 no ads/tracking"
metrics:
  duration: ~15m
  completed: 2026-07-01
  tasks: 2
  files: 2
status: complete
---

# Phase 56 Plan 06: Finalize Launch Gate — LegalSponsorSection Wiring + Store-Privacy Checklist Summary

Wired the `LegalSponsorSection` (56-05) into the live Settings screen at the tone-C insertion point (before `AboutSection`), making the 法的情報・応援 group reachable in-app, and delivered a truthful two-column Apple/Google store-privacy-form checklist whose 口径 matches `privacy_ja.md` and the app's real network behavior.

## What Was Built

### Task 1 — LegalSponsorSection wired into Settings (commit 1cf14c37)
- Added `import '../widgets/legal_sponsor_section.dart';` alongside the existing widget imports (alphabetical position, after `joy_target_section`).
- Inserted `const LegalSponsorSection(),` + `const Divider(),` immediately before `const AboutSection(),` in the `ListView` — tone-C order (法的情報・応援 group then アプリについて).
- Pure additive insertion. `SecuritySection` / `KeyedSubtree(_securitySectionKey)` / `scrollToSecurity` deep-link logic left byte-unchanged (Phase 55 frozen — T-56-07 mitigated).
- `flutter analyze lib/.../settings_screen.dart`: 0 issues.

### Task 2 — Store-privacy-form checklist (commit e7367579)
- Wrote `.planning/phases/56-setting/56-store-privacy-form-checklist.md` as a launch-operator deliverable (`.planning/` doc, NOT in `lib/` — D-05).
- Two-column mapping: Apple Privacy Nutrition Labels (§1) vs Google Play Data Safety (§2).
- Non-reflexive 口径 (T-56-03 mitigated): a §0 real-data-flow table enumerates F1 on-device/4-layer-encrypted financial data (not collected), **F2 the real v1.7 exchange-rate outbound fetch** (rates only, no PII/financial data), F3 FCM push-token registration with Google (push-enabled only), F4 P2P family sync E2EE (no server storage), F5 no ads/tracking SDK.
- §3 口径-lock cross-check against `privacy_ja.md` §1–5; §4 launch-operator notes reserve store-review round-trip slack; fill-in placeholders for policy URL / support email / fx provider.

## Deviations from Plan

None — plan executed exactly as written.

## Phase Gate (final plan of phase 56)

- `flutter analyze` (full project): No issues found.
- `flutter test` (full suite): 3490 tests, all passed, exit 0 — includes architecture tests (`legal_asset_parity`, `arb_key_parity`, `hardcoded_cjk_ui_scan`). Not piped through `tail`; exit code confirmed 0.

## Self-Check: PASSED

- FOUND: lib/features/settings/presentation/screens/settings_screen.dart (import + `const LegalSponsorSection()` present)
- FOUND: .planning/phases/56-setting/56-store-privacy-form-checklist.md (non-empty, Nutrition/Data Safety/為替 present)
- FOUND: commit 1cf14c37 (Task 1)
- FOUND: commit e7367579 (Task 2)
