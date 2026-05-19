---
phase: 09
slug: happiness-domain-formula-layer
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-02
---

# Phase 9 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

**Result:** SECURED — `threats_open: 0`
**Block Policy:** standard (any unmitigated `mitigate` threat blocks)

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Migration `onUpgrade` (v15 → v16) | Schema bump changes default `soul_satisfaction` from 5 → 2; once shipped no rollback. | Schema metadata only (pre-launch, no real user data). |
| Code-side default-value contract | Companion class default is the silent contract honored by every insert path that omits the column. | Soul-satisfaction integer 1..10. |
| SQL composition (DAO soul queries) | Centralized `_soulExpenseFilter` const vs. scattered string literals — drift risk on new queries. | Soul-ledger expense rows. |
| `getBestJoyMoment` argmax tiebreak | Without `amount DESC` tiebreak the user-facing happiness story degrades. | Single soul-row argmax (no PII). |
| Domain ↔ feature consumers (Phase 10/11) | Family/shared-joy domain types are the contract; per-member fields here would leak permanently. | Aggregate ints + 3-tuple shared-joy categories. |
| Application use-case ↔ repository | Use cases trust DAO/repository to apply the soul-only filter. | Filtered soul rows. |
| Provider graph integrity | Duplicate provider definitions break Riverpod caching and cause silent state divergence. | Riverpod scope (no external data). |
| Currency code source → formatter | `Book.currency` trusted as ISO 4217; fallback path defends against malformed inputs. | Currency code string. |
| Documentation ↔ future maintainers | Without explicit ADR, formula constants and policies become perpetual PR arguments. | None (organizational). |
| Widget test → widget callback | In-process callback values only; no external input, persistence, network, crypto, or auth surface. | Static Japanese label strings. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-9-01 | Tampering | Code-side default values across 5 sites | mitigate | All five sites use `2`: `lib/data/tables/transactions_table.dart:35` `Constant(2)`; `lib/data/daos/transaction_dao.dart:29,133` `int soulSatisfaction = 2`; `lib/features/accounting/domain/models/transaction.dart:42` `@Default(2) int soulSatisfaction`; `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart:16` `static const _faceValues = [2, 4, 6, 8, 10]` (lowest face = 2); `lib/application/analytics/demo_data_service.dart:134` survival baseline `2`. No site retains `5`. | closed |
| T-9-02 | Tampering / Information Disclosure | `lib/data/daos/analytics_dao.dart` soul queries | mitigate | Single `static const String _soulExpenseFilter` declared at `analytics_dao.dart:95-96`; composed by all six soul-aggregator queries at lines 246, 277, 310, 344, 380, 415. `analytics_repository_impl.dart` delegates without bypass. Survival exclusion covered by passing DAO tests (71 tests in 09-VERIFICATION). | closed |
| T-9-03 | Information Disclosure | `getBestJoyMoment` SQL argmax | mitigate | `analytics_dao.dart:346-347` uses `ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC LIMIT 1`. No `amount >= 500` or other amount-floor predicate present in lines 340-353. DAO fixture test pins the ordering. | closed |
| T-9-04 | Information Disclosure | `family_happiness.dart`, `get_family_happiness_use_case.dart` (per-member privacy) | mitigate | `lib/features/analytics/domain/models/family_happiness.dart:10-20` exposes only aggregate `int year/month/totalGroupSoulTx` plus `MetricResult<int>/<SharedJoyInsight>/<double>` — no `Map<MemberId,…>`, no per-member fields. `lib/features/analytics/domain/models/shared_joy_insight.dart:8-14` is exact 3-tuple `{categoryId, avgSatisfaction, totalCount}` with explicit "Per-person breakdowns are forbidden by contract" comment. `get_family_happiness_use_case.dart:102` returns `Value(highlightsSum, totalGroupSoulTx)`. Grep across `lib/features/analytics/domain/` and `lib/application/analytics/` for `Map<MemberId`, `memberId`, `MemberId` returns zero matches. | closed |
| T-9-05 | Tampering / Information Disclosure | Schema migration `onUpgrade` body (v15 → v16) | mitigate | `lib/data/app_database.dart:45` `int get schemaVersion => 16`. Migration gate at `app_database.dart:263-269` `if (from < 16)` documents default 5→2 change. CHECK constraint preserved at `lib/data/tables/transactions_table.dart:42` `'CHECK(soul_satisfaction BETWEEN 1 AND 10)'`. `test/unit/data/migrations/migration_v15_to_v16_test.dart` passes (per 09-VERIFICATION). | closed |
| T-09-14-01 | Tampering | `SatisfactionEmojiPicker._faceValues` RED-mutation restore | mitigate | `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart:16` `static const _faceValues = [2, 4, 6, 8, 10];` is the production mapping; no leftover RED-test mutation. 09-14-SUMMARY records `git diff --exit-code` PASS confirming no production diff after the RED proof. | closed |
| T-09-14-02 | Repudiation | HAPPY-08 gap-closure evidence | mitigate | `09-14-SUMMARY.md:55,78` documents temporary RED mutation `10 → 9` producing failing test result `[2, 4, 6, 8, 9]` and GREEN restoration after revert. Widget test `test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart:56-70` `pins all five face values to the v1.1 unipolar scale` taps `face_0..face_4` and asserts `expect(selectedValues, [2, 4, 6, 8, 10])`. | closed |
| T-09-14-03 | Information Disclosure | Widget test labels (static Japanese strings) | accept | Strings are compile-time constants from spec, contain no PII or user data, exist only inside test code. No runtime data exposure surface. See Accepted Risks Log. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Unregistered Threat Flags

None. All 14 plan SUMMARY files (`09-01-SUMMARY.md` through `09-14-SUMMARY.md`) explicitly declare `## Threat Flags` = "None" with rationale (no new endpoint, auth path, file-access pattern, schema change, persistence boundary, or crypto surface beyond what is mapped to T-9-* threats).

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-09-01 | T-09-14-03 | Widget test labels (`'不満'`, `'やや不満'`, `'普通'`, `'良い'`, `'とても良い'`, `'最高！'`) are compile-time spec constants used only inside `test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart:18-20`. They contain no PII, no user data, and never reach runtime. | gsd-security-auditor (orchestrator-confirmed) | 2026-05-02 |

---

## Outstanding Advisories (non-blocking)

These advisories were surfaced by `09-VERIFICATION.md` (`Anti-Patterns Found`) and `09-REVIEW.md`. They are **not** declared phase-9 threats and do not block phase advancement; they are recorded here for downstream phase owners.

1. **WR-01** — `lib/features/analytics/presentation/providers/state_happiness.dart:60-67` resolves shadow books only. Plan 09-08 explicitly scoped current-book resolution to Phase 10/11 consumers.
2. **WR-02** — `lib/application/analytics/demo_data_service.dart:130-134` generates random satisfaction `1..10` for soul demo data; can yield value `1` (legal under CHECK 1..10 but outside picker bucket set `{2,4,6,8,10}`). Not a phase-9 threat: T-9-01 mandates default `2`, not bucket-only generation. Should be aligned to picker buckets before demo analytics is user-visible.
3. **REQUIREMENTS.md stale `thinSample` wording** — Doc-only; does not affect implementation contracts.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-02 | 8 | 8 | 0 | gsd-security-auditor (Phase 9 State-B initial run) |

### Verification Method

- All `mitigate` threats verified by direct file read and grep for the declared mitigation pattern at the cited paths.
- T-9-01 lockstep verified by `grep "soulSatisfaction\|soul_satisfaction"` across `lib/` covering all 5 declared sites.
- T-9-02 soul-filter composition confirmed by 6 occurrences of `$_soulExpenseFilter` in `analytics_dao.dart` aligning with the 6 declared soul aggregators.
- T-9-04 per-member-field absence confirmed by zero grep matches for `Map<MemberId`, `memberId`, `MemberId` in domain/application analytics layers.
- T-9-05 schema migration gate, CHECK preservation, and default-2 change verified against `app_database.dart` and `transactions_table.dart`; migration test passes per 09-VERIFICATION.
- T-09-14-01/02 production state and RED/GREEN evidence verified against widget source and `09-14-SUMMARY.md`.
- Implementation files were not modified during this audit (read-only).

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-02
