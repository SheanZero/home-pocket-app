# Requirements: Home Pocket — Milestone v1.5 文案与配色统一

**Defined:** 2026-05-31
**Core Value:** A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations.

**Milestone goal:** Unify the half-migrated dual-ledger vocabulary across all three locales *and* internal code identifiers, and consolidate scattered hardcoded colors into a single semantic design-token system. Brownfield consistency refactor — no new user-facing features.

**Locked locale mapping:**

| Concept | zh | ja | en |
|---|---|---|---|
| Survival ledger | 日常 | 日常 (にちじょう) | Daily |
| Soul ledger | 悦己 | ときめき | Joy |

## v1 Requirements

### Terminology — User-Facing Copy (TERM)

- [x] **TERM-01**: Every user-facing Chinese (zh) string for the two ledgers reads 日常 (never 生存) and 悦己 (never 灵魂/魂) — across home, analytics, list, settings, and accounting surfaces, including compound terms (e.g. 悦己支出, 悦己充盈度).
- [x] **TERM-02**: Every user-facing Japanese (ja) string reads 日常 (never 生存) and ときめき (never 魂/ソウル) consistently, coherent with the existing ときめき指数 joy-index term.
- [x] **TERM-03**: Every user-facing English (en) string reads Daily (never Survival) and Joy (never Soul) consistently, including short labels and metric labels.
- [x] **TERM-04**: No old-vocabulary term (生存/灵魂/魂/ソウル/Survival/Soul) appears in any rendered UI string across all three ARB files; verified by an exhaustive grep over `lib/l10n/*.arb` values returning zero stale hits (excluding intentional historical references in `@description` metadata if any).

### Terminology — Internal Identifiers (TERMID)

- [x] **TERMID-01**: ARB keys are renamed to the new vocabulary (e.g. `soulLedger`→`joyLedger`, `survival*`→`daily*`, `soul*`→`joy*`) with every Dart call site updated and `flutter gen-l10n` regenerated cleanly.
- [x] **TERMID-02**: Theme/color symbols and related Dart identifiers are renamed (`AppColors.survival`→`daily`, `AppColors.soul`→`joy`, and dependent variable/field names) with no stale references remaining in non-generated source.
- [x] **TERMID-03**: The codebase builds and `flutter analyze` reports 0 issues after the identifier rename; generated files (`.g.dart`, `S` localizations) are regenerated and consistent (AUDIT-10 guardrail green).
- [x] **TERMID-04**: The governing lexical-hierarchy decision record (ADR-015 or successor) is updated to document the locked 日常/悦己/ときめき/Daily/Joy mapping as the canonical vocabulary.

### Palette — Design Exploration & Selection (PALETTE)

- [x] **PALETTE-01**: Design references are mined — brand DESIGN.md files from VoltAgent/awesome-design-md (Linear, Notion, Stripe, Claude, etc.) plus the dual-ledger family-finance context — and synthesized into candidate global color directions (mood, primary, dual-ledger accents) with rationale.
- [x] **PALETTE-02**: 4–5 distinct full color-scheme proposals are produced — each defining primary + 日常/悦己 ledger accents + surface + semantic roles — and rendered as Pencil mockups of representative screens (e.g. home hero, transaction list, analytics) for side-by-side comparison.
- [x] **PALETTE-03**: The user reviews the 4–5 Pencil schemes and selects one (or a hybrid) as the canonical palette; the decision and final hex values are recorded as an ADR.

### Color — Token System & Consolidation (COLOR)

- [x] **COLOR-01**: All hardcoded `Color(0x…)` literals in non-theme, non-generated source (~62 occurrences) are replaced by references to centralized `AppColors`/design tokens; no raw hex color literals remain in feature/UI code.
- [x] **COLOR-02**: The **selected** palette (PALETTE-03) is applied consistently across all surfaces — primary, 日常 (daily) ledger accent, 悦己 (joy) ledger accent, surfaces, and semantic colors — with any mismatched or stale-color usages corrected.
- [x] **COLOR-03**: A complete semantic design-token system exists in the theme layer (primary / ledger / surface / semantic groups + the profile dark palette) encoding the selected palette as the single source of truth, with duplicate constant definitions (e.g. `_joyTargetStartColor`, repeated profile dark constants) removed.
- [ ] **COLOR-04**: Golden / visual baselines are regenerated to the new palette and passing, with diffs confirmed as intended (the palette change is the only visual delta); full test suite green.

## v2 Requirements

### Theming (THEME)

- **THEME-V2-01**: Runtime theming / user-selectable accent palettes built on the new token system.
- ~~**THEME-V2-02**: Full dark-mode rollout beyond the profile screens, using the semantic tokens.~~ *(Pulled forward into Phase 33 per D-07 decision — full dark rollout delivered as part of Color Token System consolidation. No longer a v2 future item.)*

## Out of Scope

| Feature | Reason |
|---------|--------|
| New user-facing features or screens | This milestone is terminology + palette/color refactor only |
| Changing ledger semantics or behavior | Only labels/colors change; daily/joy logic untouched |
| Shipping more than one selectable theme | Exactly ONE palette is chosen and applied; runtime theme-switching is THEME-V2 |
| Typography / spacing / component redesign | Palette explores color only; references may surface type/layout but those are out of scope |
| Migrating database column names (e.g. `entry_source` values) beyond the v1.5 terminology scope | **Qualified (D-06/D-02/D-16/ADR-017):** The v1.5 terminology rename DOES migrate `ledger_type` stored values (`survival→daily`, `soul→joy`) and renames the `soul_satisfaction` column to `joy_fullness` (v17→v18 migration, per D-02/D-16/ADR-017). Other DB column changes (e.g. `entry_source`) remain out of scope. |
| English voice / MOD-005 OCR / family-calendar deferrals | Tracked separately; unrelated to terminology/color |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TERM-01 | Phase 31 | Complete |
| TERM-02 | Phase 31 | Complete |
| TERM-03 | Phase 31 | Complete |
| TERM-04 | Phase 31 | Complete |
| TERMID-01 | Phase 31 | Complete |
| TERMID-02 | Phase 31 | Complete |
| TERMID-03 | Phase 31 | Complete |
| TERMID-04 | Phase 31 | Complete |
| PALETTE-01 | Phase 32 | Complete |
| PALETTE-02 | Phase 32 | Complete |
| PALETTE-03 | Phase 32 | Complete |
| COLOR-01 | Phase 33 | Complete |
| COLOR-02 | Phase 33 | Complete |
| COLOR-03 | Phase 33 | Complete |
| COLOR-04 | Phase 34 | Pending |
| THEME-V2-02 | Phase 33 | Pulled forward (D-07) |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-31*
*Last updated: 2026-05-31 — traceability filled by roadmap (15/15 mapped)*
