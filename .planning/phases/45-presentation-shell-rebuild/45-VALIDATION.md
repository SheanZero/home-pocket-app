---
phase: 45
slug: presentation-shell-rebuild
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-17
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `45-RESEARCH.md` § Validation Architecture. Phase 45 is a **behavior-preserving structural refactor** (D-A1): goldens stay green, no visual change. Validation samples *structural invariants* (registry-derived refresh union, per-card structure, isolation), not new behavior.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `flutter_riverpod` test helpers + `mocktail` |
| **Config file** | `test/flutter_test_config.dart` (golden platform gate: off-macOS swaps in `BaselineExistenceGoldenComparator`) |
| **Quick run command** | `flutter test test/widget/features/analytics/ test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` |
| **Full suite command** | `flutter test` |
| **Static gate** | `flutter analyze` (MUST be 0 issues) + `dart format` on edited files only (repo not format-clean — do NOT format whole `test/`) |
| **Estimated runtime** | ~quick subset seconds; full suite minutes |

---

## Sampling Rate

- **After every task commit:** `flutter analyze` (0 issues) + the quick analytics + isolation test subset above.
- **After every plan wave:** Full `flutter test` — catches architecture tests (`home_screen_isolation`, `anti_toxicity_phase16/17`, `analytics_no_delta_ui`, `domain_import_rules`, `provider_graph_hygiene`) and the golden suite. *Per project memory: scoped tests miss architecture tests — run the FULL suite at wave merge.*
- **Before `/gsd-verify-work`:** Full suite green + `flutter analyze` 0 issues + every golden green (no re-baseline this phase).
- **Max feedback latency:** quick subset on each commit.

---

## Per-Task Verification Map

> Task IDs are assigned by the planner (TBD until PLAN.md exists). Rows below map each REDES-01 / GUARD-01 behavior + invariant to its automated check. Executor binds concrete `45-NN-MM` IDs.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | — | — | REDES-01 | — | N/A | structure/widget | `flutter test test/widget/features/analytics/presentation/screens/analytics_screen_test.dart` (shell still renders all leaf widgets — verify, don't rewrite) | ✅ (extend) | ⬜ pending |
| TBD | — | 0 | REDES-01 | — | N/A | source assertion | new test reads each `lib/features/analytics/presentation/widgets/cards/*.dart`, asserts newly-extracted wrapper LOC `< 400` | ❌ W0 | ⬜ pending |
| TBD | — | 0 | REDES-01 | — | N/A | unit | new `analytics_card_registry_test.dart`: union == expected provider set for solo & group ctx; registry drives both render order and refresh | ❌ W0 | ⬜ pending |
| TBD | — | 0 | GUARD-01 / D-B3 | — | union ⊆ analytics, 0 `home/*` | unit | iterate `registry.where(isVisible).expand(refreshTargets)` over solo+group ctx; assert every provider origin is an analytics `state_*` family, 0 `home/*` | ❌ W0 | ⬜ pending |
| TBD | — | — | GUARD-01 | — | HomeHero isolation | widget + source | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` (keep green) | ✅ | ⬜ pending |
| TBD | — | 0 | GUARD-01 | — | auto-dispose preserved | structure | `analytics_card_registry_test` asserts no union provider is keepAlive; `cards/*` import no `home/*` | ❌ W0 (partial) | ⬜ pending |
| TBD | — | — | REDES-01 (behavior) | — | no visible change | golden | `flutter test test/golden/daily_vs_joy_card_golden_test.dart test/golden/per_category_breakdown_card_golden_test.dart test/golden/home_hero_card_golden_test.dart` (no edit) | ✅ | ⬜ pending |
| TBD | — | — | REDES-01 (no regression) | — | no new copy | widget | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart test/.../anti_toxicity_phase17_test.dart` | ✅ | ⬜ pending |
| TBD | — | — | REDES-01 (no delta UI) | — | no cross-period delta leak | widget | `flutter test test/widget/features/analytics/presentation/screens/analytics_no_delta_ui_test.dart` | ✅ | ⬜ pending |
| TBD | — | — | D-D1 | — | N/A (doc) | doc/source (optional) | assert `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` contains `## Update` + the §4 carve-out phrase (or manual check) | ❌ optional | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/.../analytics_card_registry_test.dart` — the **new D-B3 unit test**: derive the invalidation union over solo & group `AnalyticsCardContext`, assert (a) union ⊆ analytics provider families, (b) 0 `home/*` providers, (c) render-order list non-empty and matches registry order, (d) family-scoped specs only present under `isGroupMode`. *(covers REDES-01 + GUARD-01 / D-B3)*
- [ ] Per-card LOC + `ConsumerWidget` structure assertion — source-reading test over `lib/features/analytics/presentation/widgets/cards/*.dart` *(covers REDES-01 SC-1; applies to newly-extracted wrappers — confirm A2 re pre-existing leaf widgets)*.
- [ ] Extend `analytics_screen_test.dart` to confirm the shell still renders all leaf widgets after extraction (existing `find.byType` assertions should pass unchanged — verify, don't rewrite).
- [ ] (optional) ADR-012 `## Update` presence test for D-D1.
- Framework install: **none** — `flutter_test` / `mocktail` / riverpod test helpers already present.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | — | All phase invariants have automated verification; goldens cover visual no-change. |

*All phase behaviors have automated verification.*

---

## Open Assumptions (carry into planning — see RESEARCH.md)

- **A1 (MEDIUM):** Dropping the direct `shadowBooksProvider` invalidate (it is a `home/*` provider) and relying on family analytics providers' transitive `watch(shadowBooksProvider.future)` re-read makes "union ⊆ analytics, 0 home/*" literally true. **Must be confirmed by a group-mode refresh test.**
- **A2:** SC-1's "< 400 LOC per card" applies to newly-extracted wrappers; pre-existing leaf widgets `DailyVsJoyCard` (471) / `PerCategoryBreakdownCard` (260) are out of scope for the LOC bound. Planner confirms.
- **Open Q:** Where shell-level `earliestTransactionMonth` read (not a card) lives in the registry model — researcher recommends a tiny `shellRefreshTargets`.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (the D-B3 union test + per-card structure test)
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (quick subset per commit)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
