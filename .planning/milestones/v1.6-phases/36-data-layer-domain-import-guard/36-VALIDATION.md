---
phase: 36
slug: data-layer-domain-import-guard
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-07
validated: 2026-06-07
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (SDK) + `package:sqlite3` for raw contract tests |
| **Config file** | None — uses `flutter test` directly |
| **Quick run command** | `flutter test test/unit/data/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~120 seconds (full); ~10s (data/ subset) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze && dart run custom_lint --no-fatal-infos`
- **After every plan wave:** Run `flutter test test/unit/data/`
- **Before `/gsd-verify-work`:** `flutter test && flutter analyze` must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 0 | SHOP-01 | — | `shopping_items` has `list_type` with `CHECK(list_type IN ('public','private'))` | contract | `flutter test test/unit/data/migrations/shopping_items_v20_contract_test.dart` | ✅ | ✅ green |
| 36-01-02 | 01 | 0 | SYNC-05 | — | `completed_at` column exists in v20 physical schema (D-03 reconciliation) | contract | same as above | ✅ | ✅ green |
| 36-02-01 | 02 | 1 | DONE-02 | — | `watchByListType` orders `is_completed ASC, sort_order ASC, created_at ASC` | unit | `flutter test test/unit/data/daos/shopping_item_dao_test.dart` | ✅ | ✅ green |
| 36-02-02 | 02 | 1 | DONE-02 | — | Soft-deleted rows excluded from `watchByListType` stream | unit | same as above | ✅ | ✅ green |
| 36-03-01 | 03 | 1 | ITEM-05 | — | `note` encrypted at repository boundary; round-trips to plaintext | unit | `flutter test test/unit/data/repositories/shopping_item_repository_impl_test.dart` | ✅ | ✅ green |
| 36-03-02 | 03 | 1 | ITEM-05 | — | `estimatedPrice` stored/retrieved as integer (not double); `tags` JSON round-trips | unit | same as above | ✅ | ✅ green |
| 36-04-01 | 04 | 1 | ITEM-03 | — | `ShoppingItemRepository` + domain models have no `data/**`/`infrastructure/**` imports | lint | `dart run custom_lint --no-fatal-infos` | ✅ | ✅ green |
| 36-05-01 | 05 | 1 | ITEM-03 | — | `LedgerTypeSelector` imports from `lib/shared/widgets/` in all consumers; `CategorySelectionScreen` allow-listed | lint | `dart run custom_lint --no-fatal-infos` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/unit/data/migrations/shopping_items_v20_contract_test.dart` — raw-sqlite3 physical schema verification + real-Drift index assertion (SHOP-01, SYNC-05) — 7/7 green
- [x] `test/unit/data/daos/shopping_item_dao_test.dart` — DAO ordering, soft-delete exclusion, reactive stream, upsert (DONE-02) — 3/3 green
- [x] `test/unit/data/repositories/shopping_item_repository_impl_test.dart` — note encryption, estimatedPrice integer, tags JSON, decrypt-failure fallback (ITEM-05) — 7/7 green

*No new test framework install needed — `flutter_test` + `sqlite3` already in dev deps.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Documentation reconciliation (REQUIREMENTS.md SYNC-05/D7, ROADMAP field list, CLAUDE.md v-ref) reflects D-03 | SYNC-05 | Docs accuracy is not unit-testable | Grep REQUIREMENTS.md/ROADMAP.md/CLAUDE.md confirm `completedAt`/v20 references present and no stale "no completedAt"/"v18→v19" text |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ✅ validated 2026-06-07 — all 8 tasks COVERED, 17/17 tests green, custom_lint clean

---

## Validation Audit 2026-06-07

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**State:** A (audit existing draft). Phase was executed (7 SUMMARYs) after the draft VALIDATION.md was written. All 3 planned Wave-0 test files exist and run green; both lint-enforced ITEM-03 rows pass `custom_lint`. No gaps to fill — no auditor spawn needed.

**Live evidence (re-run during audit, not copied from VERIFICATION.md):**
- `flutter test test/unit/data/migrations/...contract_test.dart test/unit/data/daos/...dao_test.dart test/unit/data/repositories/...repository_impl_test.dart` → **17/17 passed** (7 + 3 + 7).
- `dart run custom_lint --no-fatal-infos` → **"No issues found!"** (ITEM-03 import-guard for 36-04, 36-05).

**Fix applied:** documented `flutter test` commands had a dangling `-x` (exclude-tags requires an argument → command errored). Removed `-x` from the Quick-run command, Sampling-Rate wave command, and the three Per-Task contract/unit commands so the documented sampling commands actually run.
