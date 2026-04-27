---
phase: 05
slug: medium-fixes
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-27
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter `flutter_test` + Dart unit tests |
| **Config file** | `pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml` |
| **Quick run command** | `flutter test test/architecture/ test/unit/application/i18n/ test/unit/core/theme/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | project-dependent; use targeted commands after each task and full suite at plan/wave boundaries |

---

## Sampling Rate

- **After every task commit:** Run the targeted test command for touched files plus any scanner/architecture test introduced by that task.
- **After every plan wave:** Run `flutter analyze` and `flutter test`.
- **Before `$gsd-verify-work`:** Full suite must be green and `flutter gen-l10n` must have been run after ARB changes.
- **Max feedback latency:** one task; no three consecutive tasks may land without automated verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | MED-02 | — | N/A | architecture/unit | `flutter test test/architecture/` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 0 | MED-04, MED-05 | — | N/A | unit/script | `flutter gen-l10n && flutter test test/architecture/` | ❌ W0 | ⬜ pending |
| 05-03-01 | 03 | 2 | MED-03, MED-08 | — | N/A | widget/scanner | `flutter test test/widget/ test/architecture/` | ❌ W0 | ⬜ pending |
| 05-04-01 | 04 | 2 | MED-07, MED-08 | — | N/A | widget/style | `flutter test test/widget/ test/unit/core/theme/` | ❌ W0 | ⬜ pending |
| 05-05-01 | 05 | 3 | MED-01, MED-06 | — | N/A | scanner/final gate | `rg -n "MOD-009|mod009" lib --glob "*.dart" --glob "!lib/generated/**"; flutter analyze; flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] ARB parity test/script exists and compares `app_en.arb`, `app_ja.arb`, and `app_zh.arb` normal keys plus metadata keys.
- [ ] `flutter gen-l10n` is run after ARB edits.
- [ ] Scanner/test locations are decided before UI string extraction begins.

---

## Manual-Only Verifications

All Phase 5 behaviors should have automated verification. Manual review is limited to sanity-checking translation wording after ARB changes.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < one task
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
