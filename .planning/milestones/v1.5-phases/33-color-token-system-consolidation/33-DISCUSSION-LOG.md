# Phase 33: Color Token System & Consolidation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 33-Color Token System & Consolidation
**Areas discussed:** Token structure, Decorative literals, Hero gradient + olive, Dark-mode scope

---

## Token Structure — exposing ADR-018's new roles

| Option | Description | Selected |
|--------|-------------|----------|
| 沿用现有模式 | static-const on AppColors/AppColorsDark + context.wm* getters; zero new architecture, lowest risk | |
| 沿用 + 分组归类 | same static-const but nested semantic groups (AppColors.semantic.error) | |
| 迁移到 ThemeExtension | Flutter ThemeExtension<AppPalette>, resolve via Theme.of(context), integrates Material ColorScheme; larger refactor | ✓ |

**User's choice:** 迁移到 ThemeExtension

### Migration boundary (follow-up)

| Option | Description | Selected |
|--------|-------------|----------|
| 全量迁移 | ALL colors → ThemeExtension: existing static refs + context.wm* + new roles, unified via Theme.of(context).extension; largest change surface, pairs with Phase 34 full re-baseline | ✓ |
| 混合:主题色进、常量留 | light/dark-varying colors → extension; pure accents stay static const | |
| 只包新角色 | extension only for new *Text + semantic; existing classes untouched (two parallel mechanisms) | |

**User's choice:** 全量迁移
**Notes:** Significant scope expansion vs ADR-018's "minimal" framing — accepted explicitly. Flagged in CONTEXT.md as intentional.

---

## Decorative / Non-Semantic Literals

| Option | Description | Selected |
|--------|-------------|----------|
| 单独常量文件 | new non-semantic constants files in theme layer (avatar_palette.dart, overlay_colors.dart); keeps semantic token system clean | |
| 全部进语义 token | avatar wheel + overlays all become named roles in ThemeExtension/AppColors; single source of truth | ✓ |
| 头像色留在领域 | avatar presets stay as named constants in profile feature; only cross-cutting decorative → theme | |

**User's choice:** 全部进语义 token

### Re-hue decision (follow-up)

| Option | Description | Selected |
|--------|-------------|----------|
| 重调为 Teal 谱系 | decorative colors re-hued to teal/neutral to match Teal Clarity; planner defines new hex (enters Phase 34 golden diff) | ✓ |
| 保留原值、仅搬家 | copy existing hex, only relocate out of features; minimal change but residual coral/purple | |
| 交给 planner | per-color judgment | |

**User's choice:** 重调为 Teal 谱系
**Notes:** Pure black/white alpha overlays unaffected (hue-neutral). soft_toast red group identified as the `error` semantic family, not decorative.

---

## Hero gradient + olive

### Hero target-ring gradient

| Option | Description | Selected |
|--------|-------------|----------|
| Teal→金双轨渐变 | start = daily teal #1C7A86, end = joy gold #F0A81E; preserves cool→warm progress, reuses ledger tokens | ✓ |
| 金色深浅 ramp | joyText #9A6500 → joy #F0A81E, stays "gold" throughout | |
| 交给 planner | planner picks gradient consistent with cool-anchor+warm-pop | |

**User's choice:** Teal→金双轨渐变
**Notes:** Duplicate constants _joyTargetStartColor/_joyTargetEndColor removed, sourced from ledger tokens.

### olive (trends)

| Option | Description | Selected |
|--------|-------------|----------|
| 保留独立 emerald | olive = ADR-018 emerald #3DA77E, distinct third voice | |
| 合并到 daily/success | olive folds into daily(teal) or success(green); fewer tokens | ✓ |
| 交给 planner | decide merge by chart context | |

**User's choice:** 合并到 daily/success

### olive merge target (follow-up)

| Option | Description | Selected |
|--------|-------------|----------|
| 合并到 success(绿) | trends = success #2FA37A, reads as growth/positive, closest to olive's green | |
| 合并到 daily(teal) | trends = daily #1C7A86, neutral/brand reading | |
| 交给 planner | decide by whether trend charts co-occur with daily-ledger data | ✓ |

**User's choice:** 交给 planner

---

## Dark-Mode Scope

| Option | Description | Selected |
|--------|-------------|----------|
| 仅重调现有暗色 | ThemeExtension carries full dark hex, but Phase 33 only ensures existing dark surfaces (profile) re-hue correctly; aligns with THEME-V2-02 deferral | |
| 全量铺暗色 | every screen responds to dark mode; forward-complete; pulls THEME-V2-02 forward; bigger Phase 33/34 | ✓ |
| 交给 planner | planner draws a pragmatic boundary | |

**User's choice:** 全量铺暗色

### Scope confirmation (follow-up — contradicts documented THEME-V2-02 deferral)

| Option | Description | Selected |
|--------|-------------|----------|
| 确认,提前做暗色 | accept Phase 33/34 grows: per-screen dark adaptation + light+dark verification + dark golden set; CONTEXT marks THEME-V2-02 absorbed | ✓ |
| 改为仅重调现有暗色 | fall back to conservative; full dark stays in THEME-V2-02 | |

**User's choice:** 确认,提前做暗色
**Notes:** THEME-V2-02 absorbed/superseded into Phase 33. REQUIREMENTS.md/ROADMAP.md flagged for amend.

---

## Claude's Discretion

- olive merge target: success vs daily — planner decides from chart co-occurrence context (D-06).
- Whether `AppColors`/`AppColorsDark` static classes survive as internal raw-hex sources for the two ThemeExtension instances, or are deleted (D-02).
- Exact new hex for re-hued decorative tokens (avatar presets, tinted overlays) within the Teal/neutral family (D-04).
- Derived values (`*Border`, `*Chevron`, `fabGradient*`, shadows) — fine-tuned from anchor hex per ADR-018.
- Migration sequencing / verification strategy.

## Deferred Ideas

- REQUIREMENTS.md / ROADMAP.md amend: mark THEME-V2-02 absorbed into Phase 33 (action item).
- THEME-V2-01 runtime/user-selectable theming — still out of scope.
- Typography / spacing / component redesign — out of v1.5 scope.
