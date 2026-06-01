# Phase 32 — Palette Synthesis (PALETTE-01) · v2

**Deliverable:** PALETTE-01 — mined-reference synthesis into 5 distinct candidate palette directions.
**Date:** 2026-06-01
**Source brief:** `32-CONTEXT.md`, `32-UI-SPEC.md` §Color, `32-RESEARCH.md`, **+ user redirect at the PALETTE-03 checkpoint (2026-06-01).**
**Selected:** **Scheme D — Teal Clarity** (see §Selection). Ratified as **ADR-018**.

> ## Revision note — v2 supersedes v1 (coral-anchored)
> The original v1 synthesis kept coral `#E85A4F` as a fixed brand anchor (D-01). At the PALETTE-03 human-selection checkpoint the user **rejected all 5 coral-anchored schemes** and redirected: *break from the existing colors entirely, give 5 genuinely new overall identities (each its own primary, the nav/menu base included — no obligation to red/coral), mined from brand DESIGN.md references.* This v2 replaces the coral directions. **D-01 (coral anchor) is explicitly lifted by the user.** Clarified intent (AskUserQuestion, 2026-06-01): 5 **distinct primary hues**; **rethink the Daily/Joy relationship** per scheme (not a fixed cool-vs-warm rule); **no red/coral primary** (red only as semantic `error`); **≥1 dark/charcoal-led** theme; keep light+dark per scheme; keep the net-new `success/warning/error/info` family.

Role names are the exact `AppColors` / `AppColorsDark` symbols (Phase 31) — never a parallel naming (Pitfall 4).

---

## Mining Synthesis

Re-mined the VoltAgent/awesome-design-md set for **diverse primary hues** (2026-06-01, fresh):

- **Indigo / blue-violet:** Stripe `#533afd`, Notion `#5645d4`, Coinbase `#0052ff`, Revolut `#494fdf` — calm, trustworthy fintech voltage.
- **Emerald / green:** Spotify `#1ed760` (+ near-black surfaces `#121212`), Wise lime `#9fe870` — fresh, energetic.
- **Violet / purple:** Notion `#5645d4`, Vercel violet `#7928ca` — creative, expressive.
- **Teal / cyan:** Vercel cyan `#50e3c2`, Notion/Claude teal `#2a9d99` — crisp, clear, modern.
- **Charcoal + warm mono:** Vercel ink `#171717` + amber `#f5a623`, Figma black `#000000` + warm block tints — premium, dark-led.

Cross-cutting patterns applied: (1) a single disciplined primary voltage per identity (Coinbase/Vercel) drives the **nav/menu base**; (2) pastel `*Light` tint ladders (Notion/Figma block tints) derive every `dailyLight`/`joyLight`/`sharedLight`; (3) a full `success/warning/error/info` family per scheme (Spotify/Vercel/Wise), with **red reserved exclusively for `error`** per the user guardrail; (4) each scheme answers the dual-ledger distinction (D-02) with its **own** Daily/Joy logic rather than a uniform cool-vs-warm rule.

---

## Direction A: Indigo Trust

**Mood.** Calm, trustworthy, fintech-grade. Indigo primary drives the nav and CTAs; surfaces are cool near-white. **Daily/Joy logic — cross-temperature:** Daily is a slate-indigo (primary's calmer cousin), Joy is a warm amber pop — distinct by temperature, both coordinated to the indigo identity.
**Lineage.** Stripe / Linear indigo.

| Role | Light | Role | Light |
|---|---|---|---|
| `background` | `#FBFBFE` | `accentPrimary` (nav) | `#4F46E5` |
| `card` | `#FFFFFF` | `accentPrimaryLight` | `#ECEBFB` |
| `backgroundMuted` | `#F1F1F9` | `daily` | `#5566C2` |
| `textPrimary` | `#1C1F35` | `dailyText` (amount) | `#3D4D9E` |
| `textSecondary` | `#6E7191` | `dailyLight` | `#ECEEF9` |
| `textTertiary` | `#B6B9CC` | `joy` | `#E8973A` |
| `borderDefault` | `#ECECF4` | `joyText` (amount) | `#A85F00` |
| `borderList` | `#E6E6F0` | `joyLight` | `#FBEBD2` |
| `olive` (trends) | `#3DA77E` | `shared` | `#7C5CFC` |
| `oliveLight` | `#E4F4EE` | `sharedText` | `#5B3FD6` |
| `success` | `#2FA37A` | `sharedLight` | `#EEEAFD` |
| `warning` | `#C98A00` | `error` | `#E5484D` |
| `info` | `#3D4D9E` | | |

**Dark:** bg `#14151F`, card `#1E2030`, primary `#7E78F0`, daily `#8A97E0`, joy `#E8B36F`, shared `#A48FFF`, success `#5FC79E`, warning `#E5B53A`, error `#F0676B`, info `#8A97E0`.

---

## Direction B: Emerald Fresh

**Mood.** Fresh, energetic, optimistic. Emerald primary on mint-white. **Daily/Joy logic — same family, different energy:** Daily is a deep calm pine, Joy is a bright lively lime — both green-family, separated by lightness/vividness (the "rethink": one hue family at two energies). Shared steps out to amber for a clear third voice.
**Lineage.** Spotify / Duolingo green.

| Role | Light | Role | Light |
|---|---|---|---|
| `background` | `#FAFDFB` | `accentPrimary` (nav) | `#0E9F6E` |
| `card` | `#FFFFFF` | `accentPrimaryLight` | `#E2F5EE` |
| `backgroundMuted` | `#EEF5F1` | `daily` | `#1E8E6E` |
| `textPrimary` | `#122019` | `dailyText` | `#15705A` |
| `textSecondary` | `#5E7268` | `dailyLight` | `#E2F1EB` |
| `textTertiary` | `#AEC2B8` | `joy` | `#5FC93C` |
| `borderDefault` | `#E6F0EA` | `joyText` | `#357A18` |
| `borderList` | `#DDEBE4` | `joyLight` | `#ECF7E0` |
| `olive` (trends) | `#4A9E96` | `shared` | `#E08A2C` |
| `oliveLight` | `#E2F2F0` | `sharedText` | `#A85F00` |
| `success` | `#2FB36A` | `sharedLight` | `#FBEEDD` |
| `warning` | `#C98A00` | `error` | `#E5484D` |
| `info` | `#2A8FB8` | | |

**Dark:** bg `#0E1714`, card `#182420`, primary `#3FC78E`, daily `#4FB892`, joy `#8AD96A`, shared `#E8A85A`, success `#3FC78E`, warning `#E5B53A`, error `#F0676B`, info `#4FA8D0`.

---

## Direction C: Violet Creative

**Mood.** Creative, expressive, a little playful. Violet primary. **Daily/Joy logic — split-complement:** Daily is a cool periwinkle-blue, Joy is a warm rose-pink — a lively split off the violet identity. Shared=amber.
**Lineage.** Notion / Twitch / Vercel violet.

| Role | Light | Role | Light |
|---|---|---|---|
| `background` | `#FCFBFF` | `accentPrimary` (nav) | `#7C5CFC` |
| `card` | `#FFFFFF` | `accentPrimaryLight` | `#EFEAFE` |
| `backgroundMuted` | `#F3F0FA` | `daily` | `#6979E8` |
| `textPrimary` | `#221C33` | `dailyText` | `#4453C2` |
| `textSecondary` | `#6E6685` | `dailyLight` | `#ECEEFB` |
| `textTertiary` | `#BBB4CC` | `joy` | `#EC5B9E` |
| `borderDefault` | `#EFEAF6` | `joyText` | `#C42E72` |
| `borderList` | `#E9E4F2` | `joyLight` | `#FCE7F1` |
| `olive` (trends) | `#3DA77E` | `shared` | `#F0913A` |
| `oliveLight` | `#E4F4EE` | `sharedText` | `#A85F00` |
| `success` | `#2FA37A` | `sharedLight` | `#FCEEDD` |
| `warning` | `#C98A00` | `error` | `#E5484D` |
| `info` | `#4453C2` | | |

**Dark:** bg `#16131F`, card `#211C30`, primary `#A48FFF`, daily `#8A97E8`, joy `#F07AB0`, shared `#F0A85A`, success `#5FC79E`, warning `#E5B53A`, error `#F0676B`, info `#8A97E8`.

---

## Direction D: Teal Clarity — ✅ SELECTED

**Mood.** Crisp, clear, modern, trustworthy. Teal primary `#0E9AA7` drives the nav/menu base; surfaces are clean cool near-white. **Daily/Joy logic — cool anchor + warm pop:** Daily is a deep teal-navy (anchored, serious), Joy is a sunny gold (warm highlight) — the strongest, most legible dual-ledger split of the set, while staying off red/coral. Shared is a steel-blue (a cool third voice, distinct from teal Daily by hue).
**Lineage.** Vercel cyan/teal + Coinbase single-voltage discipline.

| Role | Light | Role | Light |
|---|---|---|---|
| `background` | `#F8FCFD` | `accentPrimary` (nav) | `#0E9AA7` |
| `card` | `#FFFFFF` | `accentPrimaryLight` | `#E0F4F5` |
| `backgroundMuted` | `#ECF4F5` | `daily` | `#1C7A86` |
| `textPrimary` | `#112025` | `dailyText` (amount) | `#145E68` |
| `textSecondary` | `#5A7176` | `dailyLight` | `#E0F0F2` |
| `textTertiary` | `#ABC2C6` | `joy` | `#F0A81E` |
| `borderDefault` | `#E5F0F1` | `joyText` (amount) | `#9A6500` |
| `borderList` | `#DBEAEC` | `joyLight` | `#FBEFCF` |
| `olive` (trends) | `#3DA77E` | `shared` | `#5B8AC4` |
| `oliveLight` | `#E4F4EE` | `sharedText` (amount) | `#3A6396` |
| `success` | `#2FA37A` | `sharedLight` | `#E8EFF7` |
| `warning` | `#C98A00` | `error` | `#E5484D` |
| `info` | `#2A8FB8` | | |

**Dark:** bg `#0C1719`, card `#162527`, primary `#3FC2CE`, daily `#4FB0BC`, joy `#F0C13A`, shared `#7FA8D8`, success `#3FC78E`, warning `#E5B53A`, error `#F0676B`, info `#5AA8E0`. (Full dark table in ADR-018.)

---

## Direction E: Charcoal + Warm (dark-led)

**Mood.** Premium, restrained, monochrome ink with a single warm spark. The dark/charcoal-led option (per user guardrail). Light mode: charcoal-ink primary `#1F2430` drives the nav (the "menu base" is near-black, not a hue); dark mode is the hero, where a warm amber becomes the action voltage. **Daily/Joy logic — accent pair on a neutral primary:** since the primary is neutral ink, the two ledgers carry the color — Daily a cool steel-blue, Joy a warm honey-amber. Shared=muted plum.
**Lineage.** Vercel ink / Figma black + warm accent.

| Role | Light | Role | Light |
|---|---|---|---|
| `background` | `#FBFBFA` | `accentPrimary` (nav, charcoal) | `#1F2430` |
| `card` | `#FFFFFF` | `accentPrimaryLight` | `#EAEBEE` |
| `backgroundMuted` | `#F2F2F0` | `daily` | `#5B7290` |
| `textPrimary` | `#1A1D24` | `dailyText` | `#41587A` |
| `textSecondary` | `#6B6F78` | `dailyLight` | `#ECEFF3` |
| `textTertiary` | `#B6B9C0` | `joy` | `#E0A33C` |
| `borderDefault` | `#ECECEA` | `joyText` | `#946000` |
| `borderList` | `#E6E6E4` | `joyLight` | `#FAEFD8` |
| `olive` (trends) | `#6E8E5A` | `shared` | `#9A6FB0` |
| `oliveLight` | `#EEF3E6` | `sharedText` | `#6E4684` |
| `success` | `#3DA77E` | `sharedLight` | `#F1EAF5` |
| `warning` | `#C98A00` | `error` | `#E5484D` |
| `info` | `#41587A` | | |

**Dark (hero):** bg `#15171C`, card `#1F222A`, primary→warm action `#E0A33C`, daily `#7E94B2`, joy `#E8B86A`, shared `#B58FC8`, success `#5FC79E`, warning `#E5B53A`, error `#F0676B`, info `#7E94B2`.

---

## Accessibility Verification

Computed via WCAG 2.1 relative-luminance; amount text on `card #FFFFFF` uses the `*Text` variant (the fill/tint is tag/affordance only). Re-confirmed visually via `get_screenshot` per scheme.

| Scheme | `dailyText` | `joyText` | `sharedText` | body text | red usage | Disqualifier? |
|---|---|---|---|---|---|---|
| A Indigo Trust | `#3D4D9E` ✓ | `#A85F00` ✓ | `#5B3FD6` ✓ | ✓ | error only | none |
| B Emerald Fresh | `#15705A` ✓ | `#357A18` ✓ | `#A85F00` ✓ | ✓ | error only | none |
| C Violet Creative | `#4453C2` ✓ | `#C42E72` ✓ | `#A85F00` ✓ | ✓ | error only | none |
| **D Teal Clarity** | `#145E68` ✓ | `#9A6500` ✓ | `#3A6396` ✓ | ✓ | error only | none |
| E Charcoal + Warm | `#41587A` ✓ | `#946000` ✓ | `#6E4684` ✓ | ✓ | error only | none |

All amount-text variants clear ≥4.5:1 on white; red appears **only** as the `error` semantic (user guardrail). No disqualifiers.

---

## Distinctness Check

Five genuinely distinct **primary hue families** (each = a different nav/menu base), satisfying "5 different overall designs":

| Scheme | Primary hue | Nav base | Identity |
|---|---|---|---|
| A | Indigo `#4F46E5` | indigo | trust / fintech |
| B | Emerald `#0E9F6E` | emerald | fresh / energetic |
| C | Violet `#7C5CFC` | violet | creative / expressive |
| D | Teal `#0E9AA7` | teal | clarity / modern |
| E | Charcoal `#1F2430` (+amber) | ink | premium / dark-led |

Spanning cool-blue (A), green (B), purple (C), cyan-teal (D), and neutral-mono (E) — no two share a primary hue family, and each rethinks the Daily/Joy relationship differently (cross-temp / same-family-weight / split-complement / cool-anchor+warm-pop / accent-pair-on-neutral).

---

## Selection

**Selected: Scheme D — Teal Clarity** (user, 2026-06-01, PALETTE-03 checkpoint). Rationale recorded in ADR-018. The teal primary gives the clearest, most modern identity with the strongest dual-ledger split (teal-navy Daily ↔ gold Joy) while honoring every guardrail (no red/coral primary; red only as `error`; light+dark; net-new semantics). Final hex (light + dark, every role) ratified in **ADR-018**.

---

*PALETTE-01 deliverable v2 — Phase 32 · 2026-06-01*
