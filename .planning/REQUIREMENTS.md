# Requirements: Home Pocket — Milestone v1.2 Happiness Metric Refresh

**Defined:** 2026-05-19
**Core Value (from PROJECT.md):** A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes survival spending from soul spending so families can have honest money conversations.

**Trigger:** ADR-016 ratify (2026-05-19) — Joy metric supersede from density to Σ joy_contribution. v1.2 packages this migration with v1.1's deferred Joy/Analytics backlog into one coherent refresh milestone.

---

## v1.2 Requirements (Active)

Requirements committed for this milestone. Each maps to one roadmap phase.

### Joy Metric Migration (JOYMIG-*) — ADR-016 implementation

- [x] **JOYMIG-01**: User sees `Σ joy_contribution` (not density Joy/¥) as the principal Joy metric in HomeHero — both in the central numeric display and as the value driving the ring fill.
- [ ] **JOYMIG-02**: User can configure a monthly Joy target (`monthly_joy_target`) in Settings; when unconfigured, the system computes and shows a recommended value (historical median of past 3 months if ≥3 months of data exist, else a hardcoded fallback baseline TBD by Phase 13 spike).
- [x] **JOYMIG-03**: HomeHero ring resets to 0% at the start of each calendar month and fills toward the active target (configured or recommended) as soul transactions accumulate.
- [x] **JOYMIG-04**: HomeHero ring color transitions smoothly from sage green (`#47B88A`, soul ledger green) to gold as the fill progresses; the color reaches gold saturation at or beyond 100% and stays there (no oscillation, no second-cycle re-color).
- [ ] **JOYMIG-05**: AnalyticsScreen surfaces `Σ joy_contribution` as the primary Joy KPI; density (Joy/¥) is removed from all user-facing surfaces (KPI strip, trend, distribution, story).
- [x] **JOYMIG-06**: When HomeHero ring crosses 100%, the app produces **no** discrete events — no copy text, no animation pulse, no toast, no notification, no haptic feedback. Only the ambient ring color (per JOYMIG-04) changes. This requirement is a hard contract per ADR-012 §2 and ADR-016 §5.

### Happiness Domain Extensions (carried from v1.1 v2 backlog)

- [ ] **HAPPY-V2-01**: User can view a per-category satisfaction breakdown in AnalyticsScreen — which spending categories bring the most joy (e.g., "Coffee shops: 8.2 avg / 12 entries"). Carried from `.planning/milestones/v1.1-REQUIREMENTS.md`.
- [x] **HAPPY-V2-02**: User can select custom time windows (week / month / quarter / year / arbitrary date range) for all Joy metrics, with the selection persisting per session. Carried from `.planning/milestones/v1.1-REQUIREMENTS.md`.
- [ ] **HAPPY-V2-03**: User can opt to view a manual-entry-only Joy sub-metric variant (excludes voice-estimated entries). Requires schema migration to add `entry_source` column to transactions table (Phase 9 of v1.1 confirmed the column does not currently exist). Carried from `.planning/milestones/v1.1-REQUIREMENTS.md`.

### Analytics Surface Extensions

- [ ] **STATSUI-V2-01**: User can view a Soul-vs-Survival happiness comparison surface in AnalyticsScreen — uses anti-toxicity framing (no value judgment language such as "better" or "worse"; descriptive comparison only, e.g., "Soul ledger averages 7.4 satisfaction; survival ledger 5.1"). Carried from `.planning/milestones/v1.1-REQUIREMENTS.md`.

### Tooling

- [x] **TOOL-V2-02**: ARB keys are reconciled with the new Joy vocabulary across ja/zh/en. **Note:** the original v1.1-deferral intent (rename `homeHappinessROI → homeJoyPerYen`, `homeSoulFullness → homeJoyIndex`) is **partially invalidated** by JOYMIG-05 — `joyPerYen` is no longer a target metric. Active goal: deprecated density-related keys are removed or renamed to vocabulary aligned with `Σ joy_contribution`; ARB parity locked across ja/zh/en; `flutter gen-l10n` succeeds without warnings.

---

## v2 Requirements (Deferred from v1.2)

Acknowledged but not in v1.2 roadmap.

### Family privacy hardening
- **FAMILY-V2-01**: 4th DAO method for SQL-side `category × avg satisfaction` aggregation (carried from v1.1; only justified if data volumes require it).
- **FAMILY-V2-02**: Family conversation-prompt cards ("This month you all loved coffee shops. Share a story?") — explicitly opt-in, no automation. Carried from v1.1.
- **FAMILY-V2-03**: Strict FAMILY-03 consent gate. Schema v16→v17, `familyConsentProvider`, group settings UI, new ADR Privacy Consent Gate. Carried from v1.1; v1.2 chose Joy-axis focus over family-axis to keep milestone scope coherent.

### Tooling
- **TOOL-V2-01**: `fl_chart 1.x` upgrade (`FUTURE-TOOL-fl_chart-1x`) — bundle with any future Analytics chart-stack work. Not blocking v1.2 since current charts continue to function.

### Release readiness
- **FUTURE-QA-01**: Smoke test execution as v1 release gate. Outside v1.2 metric-focused scope.

### Architecture / docs
- **FUTURE-DOC**: ARCH-008 cites ADR-006 instead of ADR-007 (1-line fix; reserved for batched doc sweep).
- **FUTURE-TOOL-03**: Re-evaluate global coverage threshold (currently 70%, was 80% pre-Phase-8); revisit after this milestone close.
- **FUTURE-ARCH-04**: `recoverFromSeed()` key-overwrite bug fix (HIGH-severity per CONCERNS.md; held because security-architecture changes are out of scope per long-term project rule).

---

## Out of Scope (v1.2 boundaries)

Explicitly excluded. Documented to prevent scope creep during planning.

| Feature | Reason |
|---------|--------|
| **OCR / MOD-005** | v1.2 is Joy-metric focused; OCR is its own milestone-sized effort. |
| **Family privacy hardening (FAMILY-V2-03)** | Requires schema v16→v17 + new ADR; bundling with Joy migration would dilute milestone focus. Stays in v2 backlog. |
| **fl_chart 1.x upgrade (TOOL-V2-01)** | Independent of Joy metric work; defer to a tooling-focused milestone or until a chart-stack issue forces it. |
| **Release-readiness QA / smoke tests** | Premature before Joy metric stabilizes; defer to a v1-release-prep milestone. |
| **Cross-period Joy comparison ("this month vs last month")** | Hard-blocked by ADR-012 #4 (no cross-period delta) and ADR-016 §3. Permanent exclusion. |
| **Joy achievement notifications / milestone toasts** | Hard-blocked by ADR-012 #2 and ADR-016 §5 (100% behavior contract). Permanent exclusion. |
| **Family member Joy leaderboards** | Hard-blocked by ADR-012 #6. Permanent exclusion (cross-milestone). |
| **Streak displays (consecutive days, etc.)** | Hard-blocked by ADR-012 #5. Permanent exclusion (cross-milestone). |
| **Public sharing of Joy data** | Hard-blocked by ADR-012 #5. Permanent exclusion (cross-milestone). |

---

## Cross-Phase Constraints (apply to every v1.2 phase)

These hold for ALL phases in this milestone; planner and reviewer should treat them as non-negotiable:

1. **ADR-012 No Gamification v1.1** — no streaks, badges, achievement unlocks, cross-period delta surfaces, leaderboards, public sharing. ADR-016 §5 is the canonical interpretation for ring behavior.
2. **ADR-014 Unipolar Positive Satisfaction** — `soul_satisfaction` default = 2, scale 1..10 retained; do not alter semantics.
3. **ADR-016 §2** — `Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)` is the single Joy expression. Density (Joy/¥) is retired; do not reintroduce it as a primary surface.
4. **ADR rules (`.claude/rules/arch.md`)** — ADR-013 stays ✅ 已接受 (per-tx PTVF scaling formula remains active); any further updates to it are append-only via `## Update YYYY-MM-DD` segments.
5. **CI guardrails (permanent)** — `flutter analyze` 0 issues; `custom_lint` 0 errors; `import_guard` + `riverpod_lint` 0 violations; per-file coverage ≥70% on changed files (or `--deferred` justification); global coverage ≥70%; `build_runner` clean-diff; `sqlite3_flutter_libs` rejection.
6. **i18n parity** — every UI string change goes through ARB ja/zh/en in lockstep; `flutter gen-l10n` must succeed without warnings.

---

## Traceability

Populated by gsd-roadmapper on 2026-05-19 with v1.2 ROADMAP.md creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| JOYMIG-01 | Phase 14 | Complete |
| JOYMIG-02 | Phase 13 | Pending |
| JOYMIG-03 | Phase 14 | Complete |
| JOYMIG-04 | Phase 14 | Complete |
| JOYMIG-05 | Phase 13 | Pending |
| JOYMIG-06 | Phase 14 | Complete |
| HAPPY-V2-01 | Phase 16 | Pending |
| HAPPY-V2-02 | Phase 15 | Complete |
| HAPPY-V2-03 | Phase 17 | Pending |
| STATSUI-V2-01 | Phase 16 | Pending |
| TOOL-V2-02 | Phase 14 | Complete |

**Coverage:**
- Active v1.2 requirements: 11 total
- Mapped: 11/11 ✓ (no orphans, no duplicates)

**Per-phase REQ count:**
- Phase 13: 2 (JOYMIG-02, JOYMIG-05) — backend foundation
- Phase 14: 5 (JOYMIG-01, JOYMIG-03, JOYMIG-04, JOYMIG-06, TOOL-V2-02) — frontend + ARB
- Phase 15: 1 (HAPPY-V2-02) — custom time windows
- Phase 16: 2 (HAPPY-V2-01, STATSUI-V2-01) — analytics surface extensions
- Phase 17: 1 (HAPPY-V2-03) — manual-only sub-metric (schema migration + toggle)

---

## Sourcing

- **ADR-016 Decision (2026-05-19)** → JOYMIG-01..06
- **v1.1-REQUIREMENTS.md §v2 Requirements** → HAPPY-V2-01, HAPPY-V2-02, HAPPY-V2-03, STATSUI-V2-01, TOOL-V2-02
- **Hard constraints derived from ADR-012/013/014/016** → Out of Scope rows + Cross-Phase Constraints
- **Prior project decisions (`.claude/rules/arch.md`, ADR conventions)** → Cross-Phase Constraints §4

---
*Requirements defined: 2026-05-19*
*Last updated: 2026-05-19 — Traceability table populated by gsd-roadmapper; all 11 REQs mapped across Phases 13-17*
