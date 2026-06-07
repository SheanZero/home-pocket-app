---
phase: 31
slug: terminology-rename
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `31-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK ^3.10.8) + `drift`/`sqlite3` for migration tests |
| **Config file** | none custom — standard `flutter test`; golden via `matchesGoldenFile` |
| **Quick run command** | `flutter test test/unit/data/migrations/` (migration only) |
| **Full suite command** | `flutter test` then `flutter test --coverage` (≥80% per CLAUDE.md) |
| **Estimated runtime** | ~migration subset seconds; full suite minutes |

---

## Sampling Rate

- **After every task commit:** relevant grep gate(s) for that surface + `flutter analyze`
- **After every plan wave:** `flutter gen-l10n` + `build_runner build --delete-conflicting-outputs` + `git diff --exit-code` (generated) + `flutter test test/unit/data/migrations/`
- **Before `/gsd-verify-work`:** all 4 ROADMAP greps zero, `flutter analyze` 0, `custom_lint` 0, full `flutter test` green, ADR-017 present
- **Max feedback latency:** grep gates instant; analyzer seconds; migration tests seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (planner fills) | — | 0 | D-02 / D-16 | — | N/A | unit | `flutter test test/unit/data/migrations/ledger_type_v18_migration_test.dart` | ❌ W0 | ⬜ pending |
| (planner fills) | — | — | TERMID-01 | — | N/A | grep gate | `grep -rnE '"[^"]*(soul\|survival\|Soul\|Survival)[^"]*"\s*:' lib/l10n/*.arb` ⇒ 0 (excl @-metadata; D-18 also clears descriptions) | ✅ | ⬜ pending |
| (planner fills) | — | — | TERMID-02/03 | — | N/A | grep gate | `grep -rnE '\b(soulLight\|survivalLight\|soulRoi\|soulSatisfaction(Bg\|Border))\b\|AppColors\.survival\|AppColors\.soul' lib/` ⇒ 0 | ✅ | ⬜ pending |
| (planner fills) | — | — | TERM-01..04 | — | N/A | grep gate | `grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb` ⇒ 0 (D-18 makes naive grep zero-hit) | ✅ | ⬜ pending |
| (planner fills) | — | — | TERMID-03 | — | N/A | analyzer/codegen | `flutter analyze` ⇒ 0; `dart run custom_lint --no-fatal-infos` ⇒ 0; `flutter gen-l10n && build_runner && git diff --exit-code` (AUDIT-10) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/data/migrations/ledger_type_v18_migration_test.dart` — covers D-02: assert `schemaVersion == 18`; insert v17 rows with `'survival'/'soul'`, run v18 steps, assert rows now `'daily'/'joy'`; assert `category_ledger_configs` accepts `'daily'/'joy'` and rejects `'survival'/'soul'` post-CHECK. Model on `entry_source_v17_migration_test.dart` + `category_v14_migration_test.dart` (`_runVNMigrationSteps` contract).
- [ ] Migration coverage for the `transactions.soul_satisfaction → joy_fullness` column rename (D-16) — assert column renamed, data preserved.
- [ ] Verify whether sibling migration tests assert a global target schema version that needs a v18 bump (vs a new sibling test).
- No framework install needed — `flutter_test` + `sqlite3` already present.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Golden pixel re-baseline | (Phase 34) | Full golden re-baseline is Phase 34's job; P31 must only keep the suite green | Skip/accept temp golden baselines as needed; do not leave suite red |

*Golden pixel diffs are deferred to Phase 34 — Phase 31 keeps the suite green only.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (v18 migration tests)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for quick gates
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
