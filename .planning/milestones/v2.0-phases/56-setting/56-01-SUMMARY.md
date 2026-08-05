---
phase: 56-setting
plan: 01
subsystem: config-scaffolding
status: complete
tags: [dependency, legal, config, asset-parity, url-launcher]
requirements_completed: [DONATE-04, LEGAL-06]
dependency_graph:
  requires: []
  provides:
    - "url_launcher ^6.3.2 direct dependency"
    - "assets/legal/ bundle declaration"
    - "LegalUrls const config (privacyPolicyHosted/termsOfUseHosted/donation)"
    - "test/architecture/legal_asset_parity_test.dart (9-file gate)"
  affects:
    - "56-04 (assets decl for rootBundle)"
    - "56-05 (LegalUrls.donation + url_launcher)"
    - "56-02 (asset gate confirms drafts)"
tech_stack:
  added:
    - "url_launcher ^6.3.2 (flutter.dev verified publisher)"
  patterns:
    - "private-constructor const holder (mirrors feature_flags.dart)"
    - "dart:io File.existsSync() nested-loop architecture gate (mirrors arb_key_parity_test.dart)"
key_files:
  created:
    - lib/core/config/legal_urls.dart
    - test/architecture/legal_asset_parity_test.dart
  modified:
    - pubspec.yaml
    - pubspec.lock
decisions:
  - "D-04: LegalUrls is the single source of truth for hosted + donation placeholder URLs, each carrying 上线前填真实值"
  - "D-02: trilingual 9-file asset-existence gate enforces LEGAL-06 parity"
metrics:
  duration_min: 1
  completed: 2026-07-01
  tasks: 3
  files: 4
---

# Phase 56 Plan 01: Config Scaffolding Summary

Landed the phase's non-visual foundation — the single new runtime dependency (`url_launcher ^6.3.2`), the `assets/legal/` bundle declaration, the centralized placeholder-URL config `LegalUrls` (D-04), and the trilingual 9-file asset-existence gate (D-02 / LEGAL-06) — all committed atomically with a clean pub resolve that leaves the pinned win32 trio untouched.

## What Was Built

**Task 1 — url_launcher dependency + assets/legal/ declaration** (`chore` c9ce7f53)
- Added `url_launcher: ^6.3.2` to `pubspec.yaml` dependencies, next to `package_info_plus`, under a clarifying comment noting `url_launcher_windows` has no win32 dep.
- Declared `- assets/legal/` under `flutter.assets:` after `- assets/satisfaction/`.
- `flutter pub get` resolved clean (exit 0): `+ url_launcher 6.3.2`, `direct main` in pubspec.lock. win32 stayed at 5.15.0 — the file_picker/package_info_plus/share_plus trio was not disturbed.
- `ios/Podfile` and `ios/Runner/Info.plist` byte-unchanged (git diff empty for both) — https is pre-allowlisted on iOS.

**Task 2 — LegalUrls placeholder config** (`feat` 6c55e414)
- Created new dir `lib/core/config/` and `legal_urls.dart`.
- `class LegalUrls` with private constructor `LegalUrls._()` exposing three `static const String` placeholders: `privacyPolicyHosted`, `termsOfUseHosted`, `donation` — each `https://example.com/homepocket/{privacy,terms,support}` with a `上线前填真实值` marker (5 marker occurrences incl. doc comment).
- `flutter analyze` → 0 issues.

**Task 3 — trilingual asset-existence gate** (`test` 11222f69)
- Created `test/architecture/legal_asset_parity_test.dart` modeled on `arb_key_parity_test.dart`'s `dart:io` loop.
- Iterates `['privacy','terms','tokusho'] × ['ja','zh','en']` asserting each `assets/legal/{doc}_{lang}.md` exists via `File(...).existsSync()` with a path-naming `reason:`.
- Imports only `dart:io` + `package:flutter_test/flutter_test.dart` (no app imports).
- `flutter analyze` → 0 issues; test ran **GREEN on first run** (`+1: All tests passed!`) because plan 56-02 landed the 9 drafts in the same wave.

## Deviations from Plan

None — plan executed exactly as written. (The asset gate was described as authored-RED-turns-GREEN, but per the wave guardrail the 9 assets from 56-02 were already present, so it was verified GREEN immediately as expected.)

## Verification Evidence

- `flutter pub get` exit 0; `url_launcher` listed `direct main` in pubspec.lock; win32 5.15.0 unchanged.
- `flutter analyze lib/core/config/legal_urls.dart` → No issues found.
- `flutter analyze test/architecture/legal_asset_parity_test.dart` → No issues found.
- `flutter test test/architecture/legal_asset_parity_test.dart` → `+1: All tests passed!` (exit 0, not piped through tail).
- `git diff --name-only ios/Podfile ios/Runner/Info.plist` → empty.

## Self-Check: PASSED

- FOUND: lib/core/config/legal_urls.dart
- FOUND: test/architecture/legal_asset_parity_test.dart
- FOUND commit c9ce7f53 (Task 1)
- FOUND commit 6c55e414 (Task 2)
- FOUND commit 11222f69 (Task 3)
