# Phase 32: Palette Exploration & Selection - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Explore color-palette directions and **select exactly one canonical palette** from 4–5 concrete Pencil mockup proposals, recording the decision plus every semantic role's exact hex value in an ADR (next sequential = **ADR-018**). This is the middle link of v1.5 「文案与配色统一」:

- **Phase 32 (this phase):** mine design references → synthesize directions → produce 4–5 full Pencil schemes → user selects one (or a named hybrid) → ADR-018.
- **Phase 33 (downstream):** build the semantic token system encoding the selected palette, replace ~62 hardcoded `Color(0x…)` literals.
- **Phase 34 (downstream):** regenerate golden/visual baselines to the new palette.

**This phase does NOT touch code colors, tokens, or goldens.** Its only artifacts are: mined-reference synthesis (written directions), Pencil mockups, and the accepted ADR-018. No `lib/` changes.

**Current palette (code = source of truth, `lib/core/theme/app_colors.dart`):**
- Base: warm ivory `#FCFBF9` + **coral primary `#E85A4F`** (the "Wa-Modern 和风现代" identity, documented in `docs/design/design-system.md`).
- 日常 (Daily) accent = blue `#5A9CC8`; 悦己 (Joy) accent = green `#47B88A`; plus olive (trends), shared (group mode), and a dark theme (`AppColorsDark`, currently used only on profile surfaces).
- (Note: prior project-memory said "sky-blue primary `#8AB8DA`" — that is **stale**; coral is the actual primary.)

</domain>

<decisions>
## Implementation Decisions

### Base Tone & Continuity (基调与延续性)
- **D-01:** **Keep coral as the brand anchor, but open everything else for exploration.** The coral primary (`#E85A4F`) is a brand-memory point that stays present across all 4–5 schemes; background, ledger accents, auxiliary colors, and semantic colors are all explorable (including cooler / more-neutral variants). NOT a full open-ended "even-the-primary-can-change" exploration, and NOT a conservative variations-only-on-Wa-Modern pass — the middle path.

### Dual-Ledger Accent Strategy (双轨账本配色)
- **D-02:** **日常 (Daily) and 悦己 (Joy) accents must read as a clear contrast**, not analogous/low-conflict like the current blue↔green. Daily reads calm/cool/neutral; Joy reads warm/bright. This strengthens the core「两本账不同」semantic while staying tasteful (no garish clash).
- **D-03:** **No "celebratory亮点色" elevation of Joy.** The user explicitly chose "明确对比" (visual distinction) over "悦己升格为可庆祝亮点色". Joy is visually distinct/warmer, but the schemes must NOT introduce celebration-style affordances — stays consistent with the anti-gamification posture (ADR-016 §5 100% behavior contract; the existing `joy_celebration_overlay` is not a license to amplify).

### Warm-Color Coexistence (珊瑚主色 vs 悦己暖 accent)
- **D-04:** **Deliberately left UNLOCKED — each of the 4–5 schemes explores a different resolution.** Because coral-primary (warm) and Joy-accent (user wants warm/bright) both lean warm and can compete, this tension is an *exploration axis*, not a fixed rule. Schemes should span genuinely different solutions, e.g.: (a) coral demoted to a pure **action color** (FAB / primary button / strong CTA only, not a ledger semantic) + Joy in a separate warm family (gold/amber/orange); (b) Joy as a **coral-family bright tint** distinguished from primary by lightness/saturation rather than hue; (c) other planner-devised resolutions. At selection time all resolutions are compared side-by-side.

### Daily Color Tone (日常色调)
- **D-05:** **Also left UNLOCKED — each scheme tries a different take.** "日常偏冷静中性" can mean either a continued cool blue/teal (continuity with current `#5A9CC8`, cool↔warm contrast against the warm primary) OR a true neutral gray/slate (makes Joy's warmth pop hardest — "Daily = restrained background, Joy = highlight"). Schemes should cover both ends so the selection reveals which pairs best with the chosen Joy/primary.

### Reference Sources (参考来源)
- **D-06:** **Trust Claude to synthesize — no brand preference pre-locked.** Mine the VoltAgent/awesome-design-md brand DESIGN.md set (Linear, Notion, Stripe, Claude, etc.) AND the dual-ledger family-finance context, then synthesize 4–5 distinct directions. The user did NOT bias toward cool-minimal (Linear/Stripe) or warm-neutral (Notion/Claude) — researcher weighs both against the "家庭财务 + 双轨 + 和风" context. (PALETTE-01.)

### Pencil Deliverable (Pencil 交付与选定方式)
- **D-07:** **Each of the 4–5 schemes is rendered across THREE representative screens — home hero, transaction list, analytics — in BOTH light and dark.** Light+dark is required in the mockups (not light-only), so dark-mode behavior is visible at selection time even though the current `AppColorsDark` only covers profile surfaces. Each scheme defines: primary + 日常/悦己 ledger accents + surface + semantic roles (success/warning/error/info).
- **D-08:** **Selection allows a named hybrid** — user may pick one scheme outright OR designate a named hybrid (e.g. "Scheme B's Joy + Scheme D's Daily"); PALETTE-03 explicitly permits this. The selected palette + final hex for every semantic role is recorded in **ADR-018**.

### Claude's Discretion
- **Number of schemes:** target the roadmap's **4–5** (at least 4 *distinct directions* required by Success Criterion #1). Planner decides 4 vs 5 based on how many genuinely-distinct directions the mined references yield.
- **Accessibility floor:** apply a sensible WCAG default to every proposed palette — body/label text ≥ **4.5:1** contrast, large text / UI affordances ≥ **3:1** — so the selected palette is implementable in Phase 33 without rework. Flag any scheme role that cannot meet this.
- **No mid-exploration coarse-screen checkpoint requested** — produce all 4–5 schemes and present them together for the single final selection (no "narrow to 2 first" round), unless the planner finds a strong reason to stage it.
- **Pencil mechanics** (one `.pen` doc vs several, frame layout, how schemes are laid out for side-by-side comparison) are the planner/executor's call — no `.pen` file exists yet, so it will be created fresh.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` §"Palette — Design Exploration & Selection (PALETTE)" — PALETTE-01/02/03 (the locked deliverable definition: mine references → 4–5 Pencil schemes → user selects → ADR).
- `.planning/ROADMAP.md` §"Phase 32: Palette Exploration & Selection" — fixed goal + 3 success criteria (≥4 distinct directions; exactly 4–5 Pencil mockups over representative screens; selection recorded as accepted ADR with final hex per role).

### Current Palette & Design Language (the "anchor" being explored from)
- `lib/core/theme/app_colors.dart` — **source of truth** for the current palette (`AppColors` light + `AppColorsDark`). Coral primary `#E85A4F`, warm ivory bg `#FCFBF9`, daily `#5A9CC8`, joy `#47B88A`, olive/shared. The coral anchor (D-01) and the ~62 literals Phase 33 will replace both reference this.
- `docs/design/design-system.md` — documented "Wa-Modern" design language (the identity D-01 anchors coral to).
- `docs/design/design-tokens.json` + `docs/design/flutter_color_mapping.dart` — existing token/mapping artifacts; informs the semantic-role taxonomy each scheme must fill (and feeds Phase 33).

### Design Reference Mining Source (PALETTE-01)
- **VoltAgent / awesome-design-md** (external GitHub repo of brand `DESIGN.md` files — Linear, Notion, Stripe, Claude, etc.). The researcher mines these; no local copy exists, fetch during research.

### Cross-Phase / ADR Context
- `.planning/phases/31-terminology-rename/31-CONTEXT.md` §D-11/D-12 — the color *symbols* (`daily`, `joy`, `dailyLight`, `joyLight`, `joyRoiBg`, `joyFullnessBg`, etc.) were **already renamed** in Phase 31; Phase 33 only *consolidates* them. Phase 32 schemes should describe roles by these existing semantic names, not invent a parallel naming.
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §5 — anti-gamification / 100% behavior contract (no discrete celebration events); constrains D-03 (Joy is distinct, not celebratory).
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — canonical 日常/悦己/ときめき/Daily/Joy vocabulary; current max ADR is 017, so the palette ADR = **ADR-018** (update `docs/arch/03-adr/ADR-000_INDEX.md`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/theme/app_colors.dart` (`AppColors` + `AppColorsDark`): the existing semantic-role inventory each scheme must fill — backgrounds, text (primary/secondary/tertiary), borders, primary accent (+ light/border + FAB gradient), daily/joy ledger accents (+ light tints), olive (trends), shared (group mode), recording state, semantic pills. A scheme is "complete" when it answers every one of these roles.
- `docs/design/design-tokens.json`: prior token structure — useful as the skeleton for what semantic groups the new palette must define.

### Established Patterns
- Coral as primary is wired through FAB gradient, action gradient, action/fab shadows, input-active border, recording gradient — D-04's "coral as action-only" resolution is *already partly how the code uses it*, which lowers Phase-33 risk for schemes that lean that way.
- Dark theme exists but is profile-scoped only (`THEME-V2-02` defers full dark rollout) — so D-07's dark mockups are *exploratory/forward-looking*, not a commitment to ship full dark mode in v1.5.

### Integration Points
- This phase produces **zero code**. The hand-off to Phase 33 is ADR-018 (hex values per semantic role, named to match the already-renamed `AppColors` symbols) + the selected Pencil scheme.

</code_context>

<specifics>
## Specific Ideas

- Representative screens for mockups: **home hero, transaction list, analytics** (named in ROADMAP success criterion #2).
- Concrete warmth-coexistence resolutions to span across schemes (from D-04): coral-as-action-color + gold/amber Joy; coral-family bright Joy distinguished by lightness; (planner may add more).
- Daily-tone span (from D-05): cool blue/teal continuity vs neutral gray/slate.
- Output ADR number is **ADR-018** (current max = ADR-017).

</specifics>

<deferred>
## Deferred Ideas

- **Runtime theming / user-selectable accent palettes** — explicitly `THEME-V2-01`, out of v1.5. v1.5 picks exactly ONE palette.
- **Full dark-mode rollout beyond profile screens** — `THEME-V2-02`. Dark mockups in D-07 are for evaluation only; shipping full dark mode is a future milestone.
- **Typography / spacing / component redesign** — out of scope per REQUIREMENTS.md; if mined references surface type/layout ideas, capture but do not act.

</deferred>

---

*Phase: 32-Palette Exploration & Selection*
*Context gathered: 2026-06-01*
