---
phase: 26
slug: providers-shell-wiring
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `26-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (built-in) + `mocktail ^1.0.4` |
| **Config file** | `analysis_options.yaml` (project-level) — already present |
| **Quick run command** | `flutter test test/unit/features/list/ -x` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30–90 seconds (list unit subset is fast; full suite longer) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/features/list/ -x`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** `flutter analyze` (0 NEW issues over the 4-issue baseline) + `flutter pub run build_runner build --delete-conflicting-outputs` (clean diff)
- **Max feedback latency:** ~90 seconds

---

## Per-Task Verification Map

> Task IDs are provisional (`{plan}-{task}`); the planner finalizes the exact IDs. Each row maps a requirement / success criterion to its automated proof.

| Item | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TaggedTransaction/MemberTag VO immutability | 1 | SC#3 (return type) | — | N/A | unit | `flutter test test/unit/features/list/domain/models/tagged_transaction_test.dart -x` | ❌ W0 | ⬜ pending |
| listFilterProvider holds 7-field VO | 2 | SC#1 | — | N/A | unit | `flutter test test/unit/features/list/presentation/providers/list_filter_notifier_test.dart -x` | ❌ W0 | ⬜ pending |
| clearAll() resets every field | 2 | FILTER-04 | — | N/A | unit | `flutter test test/unit/features/list/presentation/providers/list_filter_notifier_test.dart -x` | ❌ W0 | ⬜ pending |
| keepAlive:true encoded in annotation | 2 | SC#2 | — | N/A | static | `flutter analyze` (+ source assertion: annotation contains `keepAlive: true`) | ❌ W0 | ⬜ pending |
| Text search matches localized category name / merchant / note | 3 | FILTER-01 | — | No sensitive logging | unit | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart -x` | ❌ W0 | ⬜ pending |
| Ledger filter AND-composed | 3 | FILTER-02 | — | N/A | unit | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart -x` | ❌ W0 | ⬜ pending |
| categoryId single-value filter forwarded | 3 | FILTER-03 | — | N/A | unit | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart -x` | ❌ W0 | ⬜ pending |
| listTransactionsProvider returns `List<TaggedTransaction>` w/ AND-compose | 3 | SC#3 / FILTER-04 | — | N/A | unit | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart -x` | ❌ W0 | ⬜ pending |
| ListScreen reachable; analyze 0 new; build_runner clean | 4 | SC#4 | — | N/A | build | `flutter analyze && flutter pub run build_runner build --delete-conflicting-outputs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/features/list/domain/models/tagged_transaction_test.dart` — `TaggedTransaction`/`MemberTag` Freezed immutability + `copyWith` (SC#3 return type)
- [ ] `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` — SC#1 (7-field VO) + FILTER-04 (`clearAll`, mutators)
- [ ] `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` — SC#3 + FILTER-01/02/03 (AND-compose, localized text search, single-value category filter)

No framework install needed — `flutter_test` and `mocktail` already in `pubspec.yaml`.

**SC#3 mandatory test pattern:** use `ProviderContainer.test()` + `waitForFirstValue<List<TaggedTransaction>>(container, listTransactionsProvider(bookId: ...))` from `test/helpers/test_provider_scope.dart`. **Never** `await container.read(provider.future)` on the auto-dispose provider (Riverpod 3 disposes the orphan read). Mock the use case with Mocktail.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| List tab shows a loading state and is reachable | SC#4 | Visual reachability of the tab; no data rendered yet (loading-only scaffold per D-09) | Run app → tap List tab → observe loading indicator renders, no crash, tab navigable |

*FILTER-01..04 logic is encoded in providers this phase but is NOT user-observable until Phase 28 (sort/filter bar UI). Automated unit tests are the authoritative proof this phase.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (3 new test files)
- [ ] No watch-mode flags (use `-x` for fail-fast, not `--watch`)
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
