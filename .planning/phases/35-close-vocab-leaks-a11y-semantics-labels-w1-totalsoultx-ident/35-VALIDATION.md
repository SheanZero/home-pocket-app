---
phase: 35
slug: close-vocab-leaks-a11y-semantics-labels-w1-totalsoultx-ident
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 35-RESEARCH.md "## Validation Architecture". Brownfield vocabulary-cleanup
> phase — no new test files; existing Flutter suite is the regression net.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (already configured) |
| **Config file** | none — existing infrastructure covers all phase requirements |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~analyze <30s · full suite ~several min (2281+ tests) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze` (fast static gate)
- **After every plan wave:** Run `flutter test test/unit/` + `flutter test test/widget/features/analytics/`
- **Before `/gsd-verify-work`:** Full `flutter test` suite must be green (2281+ tests)
- **Max feedback latency:** ~30s for the static gate

---

## Per-Task Verification Map

| Behavior | Plan | Wave | Test Type | Automated Command | Status |
|----------|------|------|-----------|-------------------|--------|
| W1: Semantics labels route through l10n (`l10n.listLedgerDaily`/`listLedgerJoy`), no hardcoded vocab | 01 | 1 | static grep | `grep -rn "'Survival ledger'\|'Soul ledger'" lib/` → 0 | ⬜ pending |
| W1: no analyze regressions | 01 | 1 | static | `flutter analyze` → 0 new issues | ⬜ pending |
| W2: `totalSoulTx`/`totalGroupSoulTx` renamed everywhere (lib + test) | 02 | 1 | static grep | `grep -rEin "SoulTx\|SurvivalTx" lib/ test/ --include="*.dart" \| grep -v "\.freezed\.dart\|\.g\.dart"` → 0 | ⬜ pending |
| W2: build_runner produces clean generated files | 02 | 1 | static | `flutter analyze` → 0 errors | ⬜ pending |
| W2: Freezed model fields accessible via new names | 02 | 1 | unit | `flutter test test/unit/features/analytics/` | ⬜ pending |
| W2: all existing tests pass with renamed fields | 02 | 1 | regression | `flutter test` → 2281+ green | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No new test files need to be
created. The relevant analytics tests already exist; they will go RED on the W2 rename
until every consumer + fixture is updated (GREEN).

---

## Manual-Only Verifications

| Behavior | Why Manual | Test Instructions |
|----------|------------|-------------------|
| W1: screen reader announces "Daily ledger"/"Joy ledger" for ledger-filter chips | a11y output is not asserted by golden/widget tests in this repo | Enable VoiceOver (iOS) / TalkBack (Android), focus the ledger-filter chips in the list screen, confirm the announced label uses Daily/Joy vocabulary in the active locale |

*The static greps + full suite cover everything else automatically.*

---

## Validation Sign-Off

- [ ] W1 + W2 grep gates return 0
- [ ] `flutter analyze` clean (no new issues)
- [ ] Full `flutter test` suite green (2281+)
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
