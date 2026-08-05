---
phase: 56
slug: setting
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-01
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `56-RESEARCH.md` §Validation Architecture. Task IDs are filled once plans are written.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (SDK) + architecture tests under `test/architecture/` |
| **Config file** | none custom (standard `flutter test`; `flutter_test_config.dart` handles golden platform gate) |
| **Quick run command** | `flutter test test/widget/features/settings/ test/architecture/legal_asset_parity_test.dart` |
| **Full suite command** | `flutter test` (MUST run before section/wave gate — architecture tests are global) |
| **Estimated runtime** | settings scope ~seconds; full suite ~minutes (2300+ tests) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/widget/features/settings/ test/architecture/legal_asset_parity_test.dart`
- **After every plan wave / before section gate:** Run **FULL** `flutter test` (architecture tests `hardcoded_cjk_ui_scan`, `arb_key_parity`, new asset-parity are global — scoped runs miss them). **Never pipe through `tail`** (masks exit code — memory `main-dart-boot-provider-...`).
- **Before `/gsd-verify-work`:** Full suite green + `flutter analyze` 0 issues.
- **Max feedback latency:** quick scope < ~30s; full suite is the wave-gate barrier.

---

## Per-Task Verification Map

> Requirement-level map from research. `Task ID` column is filled during planning once plan/task IDs exist.

| Task ID | Req | Behavior | Test Type | Automated Command | File Exists | Status |
|---------|-----|----------|-----------|-------------------|-------------|--------|
| TBD | LEGAL-01 | Privacy screen loads ja/zh/en asset, renders text | widget | `flutter test test/widget/features/settings/legal_doc_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | LEGAL-02 | Terms screen loads + renders | widget | `legal_doc_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | LEGAL-03 | License tile invokes `showLicensePage` | widget | `legal_sponsor_section_test.dart` | ❌ W0 | ⬜ pending |
| TBD | LEGAL-04 | 特商法 screen renders (「請求時提供」copy present) | widget | `legal_doc_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | LEGAL-06 | ARB parity for new short labels | architecture | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ (auto-covers) | ⬜ pending |
| TBD | LEGAL-06 | No hardcoded CJK in new Dart | architecture | `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart` | ✅ (auto-covers) | ⬜ pending |
| TBD | LEGAL-06 | Asset trilingual existence gate (3 docs × ja/zh/en) | architecture | `flutter test test/architecture/legal_asset_parity_test.dart` | ❌ W0 | ⬜ pending |
| TBD | DONATE-01/03 | Sponsor row renders, neutral copy, no dialog | widget | `legal_sponsor_section_test.dart` | ❌ W0 | ⬜ pending |
| TBD | DONATE-02 | Tapping sponsor calls `launchUrl` w/ `externalApplication` | widget + mock | mock `UrlLauncherPlatform.instance`, assert params | ❌ W0 | ⬜ pending |
| TBD | DONATE-04 | URL sourced from `LegalUrls.donation` constant | unit/widget | assert launched uri == `LegalUrls.donation` | ❌ W0 | ⬜ pending |
| TBD | LEGAL-05 | Store privacy checklist truthful (v1.7 fx call reflected) | doc review | `.planning/` checklist deliverable review | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/architecture/legal_asset_parity_test.dart` — asserts all `assets/legal/{privacy,terms,tokusho}_{ja,zh,en}.md` exist (`File(...).existsSync()` loop; model on `arb_key_parity_test.dart`). Covers **LEGAL-06** (asset gate).
- [ ] `test/widget/features/settings/legal_sponsor_section_test.dart` — section render, neutral sponsor copy, `launchUrl` mock, license-page invocation. Covers **DONATE-01/02/03/04, LEGAL-03**.
- [ ] `test/widget/features/settings/legal_doc_screen_test.dart` — per-locale asset load + render (`TestWidgetsFlutterBinding` + `rootBundle`; assets available in test via pubspec). Covers **LEGAL-01/02/04**.
- [x] Existing `arb_key_parity_test.dart` + `hardcoded_cjk_ui_scan_test.dart` auto-cover new ARB keys / new Dart (no edit needed).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| External browser actually opens sponsor URL on physical iOS + Android | DONATE-02 | `LaunchMode.externalApplication` real-launch not mockable on-device; iOS https-allowlist claim (A1) needs on-device confirmation | On-device UAT: tap 応援 row → confirm system browser (not in-app WebView) opens the donation URL, app backgrounds |
| App Store Connect / Play Console submission round-trip | LEGAL-05 (store form) | Real store review, not self-assessed | Deferred to launch; store-review margin reserved |

---

## Deferred to Legal (not machine-checkable)

- Legal accuracy / adequacy of trilingual drafts — 上线前由日本法务复核 (D-01).
- 特商法 applicability + whether full 表記 required — LEGAL-V2-01 (v2).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (3 new test files above)
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (quick scope < ~30s)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
