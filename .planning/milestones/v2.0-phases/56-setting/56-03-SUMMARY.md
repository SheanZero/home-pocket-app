---
phase: 56-setting
plan: 03
subsystem: i18n
status: complete
tags: [i18n, arb, l10n, legal, sponsor, LEGAL-06]
requires:
  - lib/l10n/app_en.arb (template-arb)
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
provides:
  - "S.of(context).legalSponsorSectionTitle"
  - "S.of(context).termsOfUse"
  - "S.of(context).tokushoNotice"
  - "S.of(context).tokushoNoticeSubtitle"
  - "S.of(context).sponsorRow"
  - "S.of(context).sponsorRowSubtitle"
  - "S.of(context).sponsorLaunchError"
affects:
  - 56-04 (reader-screen appbar titles)
  - 56-05 (legal/sponsor tile labels + launch-error SnackBar)
tech_stack:
  added: []
  patterns:
    - "CJK confined to ARB (never inline in Dart) so hardcoded_cjk_ui_scan stays green"
    - "template-arb-file = app_en.arb; new keys added there first, then ja/zh with identical key-sets"
    - "reuse existing privacyPolicy / openSourceLicenses (not re-added)"
key_files:
  created: []
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
decisions:
  - "D-02 honored: only short chrome labels added to ARB; no long legal body prose (that stays in bundled assets from 56-01/56-02)"
  - "sponsorLaunchError kept neutral/non-alarming (e.g. ja ブラウザを開けませんでした), shown only if the external launch returns false"
metrics:
  duration: ~4 min
  tasks: 2
  files: 7
  completed: 2026-07-01
requirements_completed: [LEGAL-06]
---

# Phase 56 Plan 03: Legal & Sponsor ARB Labels Summary

Added 7 new short UI labels (legal-info group title, terms/tokusho tiles + subtitle, sponsor row + subtitle, neutral launch-error) across all three ARB locales with full key-set parity and `@meta` descriptions, then regenerated the `S` getters via `flutter gen-l10n` — so the reader screen (56-04) and sponsor section (56-05) can consume `S.of(context)` with zero further ARB edits.

## What Was Built

### Task 1 — 7 new labels in app_{en,ja,zh}.arb (commit `837b3a99`)
Added identical key-sets to all three ARB files, each with a sibling `@key` metadata `description` object. Japanese canonical values taken from the approved tone-C sketch (`003-legal-sponsor/index.html`):

| Key | ja | zh | en |
|-----|----|----|----|
| `legalSponsorSectionTitle` | 法的情報・応援 | 法律信息・支持 | Legal & Support |
| `termsOfUse` | 利用規約 | 使用条款 | Terms of Use |
| `tokushoNotice` | 特定商取引法に基づく表記 | 基于特定商业交易法的标示 | Commercial Transaction Notice |
| `tokushoNoticeSubtitle` | 日本での提供に必要な表記 | 在日本提供服务所需的标示 | Required for offering the service in Japan |
| `sponsorRow` | 開発を応援する | 支持开发 | Support Development |
| `sponsorRowSubtitle` | 広告なし運営を続けるために | 为了持续无广告运营 | To keep the app running ad-free |
| `sponsorLaunchError` | ブラウザを開けませんでした | 无法打开浏览器 | Couldn't open the browser |

The existing `privacyPolicy` and `openSourceLicenses` keys were reused (not duplicated) for the privacy/license tiles.

### Task 2 — regenerate + validate (commit `738c5efd`)
`flutter gen-l10n` regenerated `lib/generated/app_localizations*.dart`, exposing getters for all 7 keys. `flutter test test/architecture/arb_key_parity_test.dart` passed (+2, all tests). Generated files were force-added (`git add -f`) per the gitignored-yet-tracked gotcha so no stale generated Dart is left in HEAD.

## Verification

- All 7 keys present in en/ja/zh ARB (grep loop OK); JSON valid in all three.
- All 7 `get <key>` getters present in `app_localizations.dart`.
- `arb_key_parity_test`: 2/2 tests passed (normal + metadata key-sets match, OCR stubs preserved).
- No long legal prose added to ARB (D-02); CJK stays in ARB, none inline in Dart.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All 7 keys have real trilingual values reachable via `S.of(context)`.

## Self-Check: PASSED
