---
phase: 41
slug: exchange-rate-service
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter SDK) |
| **Config file** | `test/flutter_test_config.dart` |
| **Quick run command** | `flutter test test/application/currency/ test/data/ test/infrastructure/` (scope to phase files) |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~180 seconds (full suite, 2635+ tests) |

---

## Sampling Rate

- **After every task commit:** Run scoped `flutter test` on the touched test files
- **After every plan wave:** Run `flutter test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 200 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (filled by planner) | — | — | RATE-01..06 | — | — | unit | — | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing infrastructure covers all phase requirements (flutter_test + mocktail already installed; Phase 40 test patterns in `test/data/repositories/exchange_rate_repository_impl_test.dart` reusable).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live API smoke (Frankfurter / fawazahmed0) | RATE-01 | Real network calls excluded from unit suite | Optional: run app, enter foreign-currency transaction, observe rate fetch |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 200s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
