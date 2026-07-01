---
phase: 56-setting
plan: 04
subsystem: settings
status: complete
tags: [legal, i18n, rootBundle, settings, offline, security-v12]
requirements_completed: [LEGAL-01, LEGAL-02, LEGAL-04]
dependency_graph:
  requires: [56-01, 56-02, 56-03]
  provides:
    - "LegalDocScreen(doc: LegalDoc) — generic offline per-locale legal reader"
    - "enum LegalDoc { privacy, terms, tokusho } with String get slug"
  affects: [56-05]
tech_stack:
  added:
    - "rootBundle.loadString (flutter/services) — first repo usage"
  patterns:
    - "56-RESEARCH Pattern 2: locale-keyed asset load with {ja,zh,en} whitelist guard (V12)"
    - "FutureBuilder loading->SelectableText inside SingleChildScrollView + Scaffold(AppBar)"
key_files:
  created:
    - lib/features/settings/presentation/screens/legal_doc_screen.dart
    - test/widget/features/settings/legal_doc_screen_test.dart
  modified: []
decisions:
  - "D-02: long-form legal text loaded from bundled per-locale assets (not ARB), rendered verbatim as plain SelectableText (no markdown renderer — RESEARCH A2)"
  - "V12/T-56-02: locale segment whitelisted to {ja,zh,en} (default ja) before path interpolation; doc is a closed enum — no untrusted path reaches rootBundle"
  - "error branch reuses existing S.error getter (no new ARB key needed)"
metrics:
  duration: ~10 min
  completed: 2026-07-01
  tasks: 1
  files: 2
---

# Phase 56 Plan 04: LegalDocScreen (offline per-locale legal reader) Summary

Reusable offline legal-document reader (`LegalDocScreen`) that renders the privacy / terms / 特商法 drafts verbatim from bundled per-locale `assets/legal/{doc}_{lang}.md` via the repo's first `rootBundle.loadString`, keyed off `currentLocaleProvider` with a `{ja,zh,en}` whitelist guard on the locale segment (V12). Written task-level TDD (RED → GREEN).

## What Was Built

- `enum LegalDoc { privacy, terms, tokusho }` with `String get slug` (asset stem), defined in-file per the `set_pin_screen` in-file-enum idiom.
- `LegalDocScreen extends ConsumerWidget`:
  - resolves `lang = ref.watch(currentLocaleProvider).value?.languageCode ?? 'ja'`, then `safeLang = {'ja','zh','en'}.contains(lang) ? lang : 'ja'` (V12 guard).
  - builds `'assets/legal/${doc.slug}_$safeLang.md'` and loads it inside a `FutureBuilder` (loading → `CircularProgressIndicator`; error → `S.error`; done → `SelectableText` in a padded `SingleChildScrollView`).
  - `Scaffold(appBar: AppBar(title: Text(<S title per doc>)))` — privacy→`privacyPolicy`, terms→`termsOfUse`, tokusho→`tokushoNotice`; theming via `context.palette` (ADR-019).
- 9 widget/unit tests covering per-locale load, `請求` (請求時提供) render for 特商法, zh-variant switch, unsupported-locale fallback (no throw), AppBar titles from `S`, and slug mapping.

## Verification

- `flutter test test/widget/features/settings/legal_doc_screen_test.dart` → 9/9 pass (exit 0).
- FULL `flutter test` → **+3483 All tests passed** (wave gate; not piped through `tail`).
- `flutter analyze` → No issues found (0).
- Architecture gates green: `hardcoded_cjk_ui_scan` (no hardcoded CJK in the new Dart — all titles via `S`), `legal_asset_parity` (all doc×locale assets exist).
- Grep acceptance: `rootBundle.loadString(` present; `{'ja', 'zh', 'en'}` whitelist guard present.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Error-branch S getter name**
- **Found during:** Task 1 (GREEN)
- **Issue:** Initial implementation referenced a non-existent `S.errorGeneric` for the FutureBuilder error branch.
- **Fix:** Switched to the existing generic `S.error` getter — no new ARB key required.
- **Files modified:** lib/features/settings/presentation/screens/legal_doc_screen.dart
- **Commit:** 054bf3b1

**2. [Rule 1 - Bug] pumpAndSettle timeout on rootBundle cache-hit reloads**
- **Found during:** Task 1 (test authoring)
- **Issue:** `rootBundle` caches decoded strings; the second load of an already-cached asset left the `FutureBuilder` spinner animating the simulated clock, timing out `pumpAndSettle` for every test after the first per-asset load (4/9 failing in-suite, passing in isolation).
- **Fix:** Added `tearDown(rootBundle.clear)` so each test is a fresh (settling) cache-miss. This is a test-harness fix; production code unchanged.
- **Files modified:** test/widget/features/settings/legal_doc_screen_test.dart
- **Commit:** 8d88e9ec / 054bf3b1

## Threat Model Compliance

- **T-56-02 (Tampering, path from locale segment):** mitigated — `languageCode` whitelisted to `{ja,zh,en}` default `ja` before interpolation; `doc` is a closed enum. No arbitrary/user path reaches `rootBundle.loadString`. Asserted by the unsupported-locale fallback test.
- **T-56-04 (DoS, missing-asset throw):** mitigated — whitelist guard + 56-01 asset-parity gate guarantee every `{doc}_{lang}` exists; `FutureBuilder` shows a spinner (never a raw throw on the happy path).

## Known Stubs

None. The screen is fully wired to real bundled assets. (Downstream: 56-05 pushes `LegalDocScreen(doc: ...)` from the section rows.)

## Self-Check: PASSED

- FOUND: lib/features/settings/presentation/screens/legal_doc_screen.dart
- FOUND: test/widget/features/settings/legal_doc_screen_test.dart
- FOUND commit: 8d88e9ec (test RED)
- FOUND commit: 054bf3b1 (feat GREEN)
