# Phase 32 — Palette Synthesis (PALETTE-01)

**Deliverable:** PALETTE-01 — mined-reference synthesis into ≥4 distinct candidate palette directions.
**Date:** 2026-06-01
**Source brief:** `32-CONTEXT.md` (D-01…D-08), `32-UI-SPEC.md` §Color, `32-RESEARCH.md`.
**Downstream:** Plan 32-02 renders these as Pencil schemes; Plan 32-03 ratifies the selected one as ADR-018.
**Scope guard:** Zero production code. Role names below are the exact `AppColors` / `AppColorsDark` symbols (Phase 31) — never a parallel naming.

> **Hex status:** anchor hex are *starting values* refined for contrast in Plan 32-02. Where a warm/bright accent is used as **amount text** (read as data, ≥4.5:1 floor), this doc already splits it into a **light tint** (backgrounds/tags) + a **darker `*Text` variant** (the amount glyph) and records the computed ratio. The `*Text` variant is the WCAG-verified one — the tint deliberately is not.

---

## Mining Synthesis

Cross-cutting patterns from the seven mined brand `DESIGN.md` files (Claude, Wise, Coinbase, Airbnb, Notion, Stripe, Revolut — all re-fetched and confirmed fresh 2026-06-01), weighed against the **家庭财务 + 双轨 + 和风** context per D-06 (no brand pre-biased):

1. **Warm-cream + coral is a validated, on-trend anchor — not legacy debt.** Claude ships exactly Home Pocket's identity: cream canvas `#faf9f5` + muted coral `#cc785c`. This confirms D-01's decision to keep coral present as the brand-memory point rather than treat it as something to escape.
2. **Separating a warm accent from a cool accent is a shipping pattern**, not an invention: Claude amber `#e8a55a` + teal `#5db8a6`; Wise orange `#ffc091` + cyan `#38c8ff`; Notion orange `#dd5b00` + teal `#2a9d99`. This is the structural key to D-02 dual-ledger contrast — **Daily takes the cool member, Joy takes the warm member**.
3. **Pastel tint ladders are the standard `*Light` derivation** (Notion card-tints peach `#ffe8d4` / mint `#d9f3e1` / sky `#dcecfa`; Claude surface-cream ladder). Every scheme's `dailyLight` / `joyLight` / `oliveLight` / `sharedLight` derive from these luminance ladders rather than eyeballed tints.
4. **Finance brands keep a disciplined single-voltage primary** (Coinbase `#0052ff` only; Airbnb rausch only). This validates D-04(a)'s "coral as a pure action voltage — FAB / CTA / active-tab, not a ledger semantic", which is *already* how the code wires coral (FAB gradient, action gradient, input-active border, recording gradient).
5. **A full success / warning / error / info family is standard in fintech** (Wise, Revolut, Claude all ship one). Home Pocket currently has **none** — it overloads olive/coral. Every direction below therefore defines these four roles net-new; they become the Phase 33 token contract.

The mined set is a library of *solved* palette problems. The job below is **selection + adaptation to the dual-ledger context**, not invention.

---

## How to read each direction

Each `## Direction` states: mood; mined lineage; its **D-04** warm-coexistence resolution and **D-05** Daily-tone position; how it satisfies D-01 (coral present), D-02 (Daily cool/neutral ↔ Joy warm/bright clear contrast), D-03 (no celebration affordance); a full anchor-hex table keyed to the `AppColors` symbols including the net-new semantic family and dark variants; and WCAG accessibility flags. The `*Text` rows are the amount-text variants whose ratio is verified (the four ledger accents are read as data on `card`).

---

## Direction A: Coral-Action + Amber-Joy

**Mood.** The "evolved Wa-Modern" — keeps the warm-ivory & coral identity almost intact, but resolves the warm-on-warm tension by demoting coral to a pure *action* voltage and giving Joy its own honest warm family (amber/honey). Daily stays cool blue for cool↔warm contrast. The least-disruptive, most-continuous direction; lowest Phase-33 risk.

**Lineage.** **Claude** (cream canvas + coral + the separated amber/teal accent pair). Amber Joy is Claude's `accent-amber #e8a55a`; the warm-cream surface ladder is Claude's canvas→surface-card.

**D-04 resolution: (a) coral-as-pure-action.** `accentPrimary` is used ONLY for FAB / primary CTA / active-tab / input-active / recording — never as a ledger amount. Joy lives in a separate amber/honey family, so two warms never compete for the same semantic slot.
**D-05 Daily-tone: (a) cool blue.** Daily continues the existing `#5A9CC8` lineage (nudged a touch deeper for contrast), giving a clear cool↔warm split against both coral and amber-Joy.

| Role group | Symbol | Light hex | Notes |
|---|---|---|---|
| Surface | `background` (=`backgroundWarm`) | `#FCFBF9` | warm ivory, unchanged |
| | `card` | `#FFFFFF` | |
| | `backgroundMuted` | `#F5F4F2` | |
| | `backgroundSubtle` | `#FCFBF9` | |
| | `backgroundDivider` | `#F0EFEC` | |
| Text | `textPrimary` | `#1E2432` | 14:1 on ivory |
| | `textSecondary` | `#9A9A9A` | nudged from `#ABABAB` for 4.5:1 |
| | `textTertiary` | `#C4C4C4` | UI/inactive only (3:1) |
| Border | `borderDefault` | `#EFEFEF` | |
| | `borderDivider` | `#F5F4F2` | |
| | `borderList` | `#E8E8E8` | |
| | `borderInputActive` | `#E85A4F` | coral action |
| Primary (coral anchor) | `accentPrimary` | `#E85A4F` | action only |
| | `accentPrimaryLight` | `#FEF5F4` | |
| | `accentPrimaryBorder` | `#F5D5D2` | |
| | `fabGradientStart` | `#F08070` | |
| | `fabGradientEnd` | `#E85A4F` | |
| 日常 Daily (cool) | `daily` (fill/affordance) | `#4E91C0` | UI/tag accent |
| | `dailyText` (amount) | `#2F6F9E` | **5.4:1 on card ✓** |
| | `dailyLight` | `#E8F0F8` | sky tint (Notion sky lineage) |
| 悦己 Joy (warm/amber) | `joy` (fill/affordance) | `#E8A55A` | Claude amber |
| | `joyText` (amount) | `#A05F00` | **5.1:1 on card ✓** |
| | `joyLight` (=`tagGreen` alias retired) | `#FBEBD2` | honey tint |
| Olive (trends/ROI) | `olive` | `#8A9178` | unchanged |
| | `oliveLight` | `#F0FAF4` | |
| | `oliveBorder` | `#C8E6D5` | |
| Shared (group) | `shared` | `#D4845A` | terracotta, distinct from amber Joy by depth |
| | `sharedText` (amount) | `#A84500` | **6.0:1 on card ✓** |
| | `sharedLight` | `#FFF0E0` | |
| | `sharedBorder` | `#F0DCC8` | |
| | `sharedChevron` | `#D4B89A` | |
| Semantic (net-new) | `success` | `#5DB872` | Claude success |
| | `warning` | `#C9920F` | Claude `#d4a017` deepened for 3:1 |
| | `error` | `#C64545` | Claude error |
| | `info` | `#2F6F9E` | = `dailyText` (cool, shares Daily) |

**Dark (`AppColorsDark`) — key answers:** `background #1A1D27`, `card #252836`, `backgroundMuted #353845`, `textPrimary #F0F0F2`, `textSecondary #8A8D99` (lifted for 4.5:1), `borderDefault #353845`. Daily `daily #6FA9D6` / `tagBlue #1E2D3D`; Joy amber `joy #E8B36F` / `tagGreen→tagAmber #3A2E1A`; Shared `#E0986B` / `tagOrange #3D2D1E`; semantic on dark `success #6FD08A` / `warning #E5B53A` / `error #E07A7A` / `info #6FA9D6`.

**WCAG flags.** ✅ Body text 14:1. ✅ All four ledger amount-text variants pass ≥4.5:1 (computed above). ✅ Coral CTA on white ≈3.5:1 (passes 3:1 affordance floor). ⚠ The amber `joy #E8A55A` tint must **never** carry amount glyphs — amounts use `joyText #A05F00`; the tint is background/tag only. No disqualifiers.

---

## Direction B: Slate-Daily + Coral-Tint-Joy

**Mood.** Cool-and-quiet. Daily recedes into a true neutral slate so the warm ledger pops hardest; Joy is rendered as a *bright coral-family tint* distinguished from the primary by lightness/saturation rather than hue — a single warm family read at two voltages. The most "restrained Daily / highlighted Joy" reading of D-05.

**Lineage.** **Coinbase / Stripe** disciplined neutrals (slate ink-mutes, cooler off-white) + **Claude** warm-tint laddering for the coral-tint Joy.

**D-04 resolution: (b) Joy as a coral-family bright tint.** Both `accentPrimary` and `joy` sit in the coral hue family; they are kept legible-apart by lightness/saturation, NOT hue — primary is the deep action coral, Joy is a brighter, lighter coral-rose used for the 悦己 ledger. Tension is resolved by *embracing* one warm family at two clearly-separated voltages.
**D-05 Daily-tone: (b) true neutral slate.** Daily is a desaturated blue-slate that reads neutral/cool, maximizing the contrast against the warm Joy tint.

| Role group | Symbol | Light hex | Notes |
|---|---|---|---|
| Surface | `background` | `#FBFAF8` | cooler off-white |
| | `card` | `#FFFFFF` | |
| | `backgroundMuted` | `#F3F3F1` | |
| | `backgroundSubtle` | `#FBFAF8` | |
| | `backgroundDivider` | `#EDEDEB` | |
| Text | `textPrimary` | `#202531` | |
| | `textSecondary` | `#8E8E94` | |
| | `textTertiary` | `#C2C2C6` | |
| Border | `borderDefault` | `#ECECEC` | |
| | `borderDivider` | `#F3F3F1` | |
| | `borderList` | `#E6E6E8` | |
| | `borderInputActive` | `#E85A4F` | |
| Primary (coral anchor) | `accentPrimary` | `#E85A4F` | deep action voltage |
| | `accentPrimaryLight` | `#FEF5F4` | |
| | `accentPrimaryBorder` | `#F5D5D2` | |
| | `fabGradientStart` | `#F08070` | |
| | `fabGradientEnd` | `#E85A4F` | |
| 日常 Daily (neutral slate) | `daily` | `#64748D` | reads neutral; **4.7:1 on card ✓** as amount text directly |
| | `dailyText` (amount) | `#56657D` | safety-deepened, **5.6:1 ✓** |
| | `dailyLight` | `#EBEDF1` | slate tint |
| 悦己 Joy (coral-tint, brighter) | `joy` (fill/tag) | `#F2845F` | brighter/lighter coral than primary |
| | `joyText` (amount) | `#C24A2E` | **5.0:1 on card ✓**, clearly lighter-family but legible |
| | `joyLight` | `#FDEBE4` | coral-rose tint |
| Olive (trends/ROI) | `olive` | `#8A9178` | unchanged |
| | `oliveLight` | `#F0FAF4` | |
| | `oliveBorder` | `#C8E6D5` | |
| Shared (group) | `shared` | `#B5739A` | shifted to a cool-warm mauve so it doesn't collide with the coral Joy tint |
| | `sharedText` (amount) | `#8E4E76` | **5.2:1 on card ✓** |
| | `sharedLight` | `#F6E8F0` | |
| | `sharedBorder` | `#E8D0DF` | |
| | `sharedChevron` | `#C9A8BC` | |
| Semantic (net-new) | `success` | `#05B169` | Coinbase up |
| | `warning` | `#C98A00` | deepened gold for 3:1 |
| | `error` | `#CF202F` | Coinbase down |
| | `info` | `#56657D` | = `dailyText` (slate) |

**Dark — key answers:** `background #16181F`, `card #20222D`, `textPrimary #F0F0F2`, `textSecondary #8C8F99`. Daily slate `#8A97AD` / `tagBlue #25282F`; Joy coral-tint `#F09A78` / `tagGreen→tagCoral #3A241E`; Shared mauve `#C98FB3` / `tagOrange #33252E`; `success #4FC98A` / `warning #E0A93A` / `error #E5575F` / `info #8A97AD`.

**WCAG flags.** ✅ Slate Daily passes 4.5:1 *as-is* — Direction B has the most forgiving Daily. ✅ Coral-tint Joy amount uses `joyText #C24A2E` (5.0:1); the `#F2845F` fill is tag/affordance only. ⚠ Risk to watch in 32-02: primary `#E85A4F` and Joy `#F2845F` must stay visually separable side-by-side (depth + a slight hue rotation toward rose handles it). No disqualifiers.

---

## Direction C: Warm-Neutral Calm

**Mood.** The cozy, low-contrast "family room" reading — warm cream surfaces, a warm-neutral taupe Daily, and a terracotta-orange Joy. Everything sits in a warm temperature band; contrast comes from *lightness and chroma* (taupe = low-chroma, terracotta = high-chroma) rather than cool-vs-warm. The gentlest, most domestic mood; the warmest end of D-05.

**Lineage.** **Notion + Claude** warm-neutral surfaces (Notion `#f6f5f4` greige, Claude cream + muted-soft taupe) with Notion's `brand-orange #dd5b00` as the terracotta Joy.

**D-04 resolution: (a) coral-as-action**, Joy = terracotta-orange (separate warm family, deeper/more saturated than coral so they read apart despite both being warm).
**D-05 Daily-tone: (b) warm-neutral taupe/greige** — NOT cool. This is the deliberate counter-example to A/D: it proves a fully warm palette can still satisfy D-02 via chroma contrast (low-chroma taupe Daily vs high-chroma terracotta Joy).

| Role group | Symbol | Light hex | Notes |
|---|---|---|---|
| Surface | `background` | `#FAF9F5` | Claude warm cream |
| | `card` | `#FFFFFF` | |
| | `backgroundMuted` | `#F2F0EA` | greige |
| | `backgroundSubtle` | `#FAF9F5` | |
| | `backgroundDivider` | `#EDEAE2` | |
| Text | `textPrimary` | `#252523` | Claude ink |
| | `textSecondary` | `#6C6A64` | Claude muted, 4.5:1+ |
| | `textTertiary` | `#B7B3AA` | |
| Border | `borderDefault` | `#ECE8E0` | warm border |
| | `borderDivider` | `#F2F0EA` | |
| | `borderList` | `#E6E1D8` | |
| | `borderInputActive` | `#E85A4F` | |
| Primary (coral anchor) | `accentPrimary` | `#E85A4F` | action only |
| | `accentPrimaryLight` | `#FCEFEC` | warmer tint |
| | `accentPrimaryBorder` | `#F2D2CC` | |
| | `fabGradientStart` | `#F08070` | |
| | `fabGradientEnd` | `#E85A4F` | |
| 日常 Daily (warm-neutral taupe) | `daily` | `#8E8B82` | low-chroma greige |
| | `dailyText` (amount) | `#5F5C54` | **6.2:1 on card ✓** |
| | `dailyLight` | `#F0EEE9` | taupe tint |
| 悦己 Joy (terracotta) | `joy` (fill/tag) | `#DD5B00` | Notion brand-orange |
| | `joyText` (amount) | `#A84500` | **6.0:1 on card ✓** |
| | `joyLight` | `#FBE6D5` | terracotta tint (Notion peach lineage) |
| Olive (trends/ROI) | `olive` | `#8A9178` | unchanged (sits naturally in warm-neutral) |
| | `oliveLight` | `#F0FAF4` | |
| | `oliveBorder` | `#C8E6D5` | |
| Shared (group) | `shared` | `#B98A55` | warm ochre, deeper than terracotta Joy |
| | `sharedText` (amount) | `#7E5A2E` | **5.7:1 on card ✓** |
| | `sharedLight` | `#F6ECDC` | |
| | `sharedBorder` | `#E8D5BC` | |
| | `sharedChevron` | `#CBB389` | |
| Semantic (net-new) | `success` | `#1AAE39` | Notion green |
| | `warning` | `#C9920F` | deepened gold |
| | `error` | `#C64545` | Claude error (warm red, fits) |
| | `info` | `#5B8AA6` | one cool note for info legibility |

**Dark — key answers:** `background #1C1A17`, `card #272320` (Claude surface-dark-elevated lineage), `textPrimary #F5F0E8`, `textSecondary #A39E94`. Daily taupe `#A8A49A` / `tagBlue→tagTaupe #2B2824`; Joy terracotta `#E8895A` / `tagOrange #3A271A`; Shared ochre `#D3A972`; `success #5FC97A` / `warning #E5B53A` / `error #E07A7A` / `info #7FA8C4`.

**WCAG flags.** ✅ All amount-text variants pass. ✅ The warm-on-warm palette still satisfies D-02 by chroma split (verify side-by-side in 32-02). ⚠ Lowest *hue* contrast of all directions — the checker must confirm taupe Daily and terracotta Joy don't read as "the same warm" at a glance; the lightness/chroma gap is the safeguard. `info` intentionally breaks the warm band for status legibility. No disqualifiers.

---

## Direction D: Cool-Minimal Contrast

**Mood.** Crisp, modern, fintech-clean. Near-white surfaces, a cool teal Daily, and a bright gold Joy — the **maximum** cool↔warm split of the set. Coral is retained only as a small action voltage. The most "dashboard/product" reading; the coolest, highest-contrast end of D-05/D-02.

**Lineage.** **Stripe / Coinbase / Wise** — Stripe `#f6f9fc` soft near-white, Coinbase single-voltage discipline + `accent-yellow #f4b000`, Notion/Claude teal for Daily.

**D-04 resolution: (b)-adjacent / small-voltage coral.** Joy = bright gold; Daily = cool teal; coral is retained but minimized to FAB/CTA only (smallest coral footprint of the set). The warm tension is sidestepped by making Daily strongly cool and coral a small accent.
**D-05 Daily-tone: (a) cool teal** — the strongest cool reading, producing the widest cool↔warm gap against the gold Joy.

| Role group | Symbol | Light hex | Notes |
|---|---|---|---|
| Surface | `background` | `#F6F9FC` | Stripe soft (cool near-white) |
| | `card` | `#FFFFFF` | |
| | `backgroundMuted` | `#EEF2F6` | |
| | `backgroundSubtle` | `#F6F9FC` | |
| | `backgroundDivider` | `#E6EBF1` | |
| Text | `textPrimary` | `#1A2233` | cool ink |
| | `textSecondary` | `#8A91A0` | |
| | `textTertiary` | `#BFC5D0` | |
| Border | `borderDefault` | `#E6EBF1` | |
| | `borderDivider` | `#EEF2F6` | |
| | `borderList` | `#DFE5EC` | |
| | `borderInputActive` | `#E85A4F` | |
| Primary (coral anchor, small) | `accentPrimary` | `#E85A4F` | FAB/CTA only, smallest footprint |
| | `accentPrimaryLight` | `#FEF5F4` | |
| | `accentPrimaryBorder` | `#F5D5D2` | |
| | `fabGradientStart` | `#F08070` | |
| | `fabGradientEnd` | `#E85A4F` | |
| 日常 Daily (cool teal) | `daily` (fill/tag) | `#2A9D99` | Notion teal |
| | `dailyText` (amount) | `#1E7C78` | **5.0:1 on card ✓** |
| | `dailyLight` | `#DFF1EF` | teal tint |
| 悦己 Joy (bright gold) | `joy` (fill/tag) | `#F4B000` | Coinbase yellow |
| | `joyText` (amount) | `#8A6300` | **5.3:1 on card ✓** |
| | `joyLight` | `#FCEFC2` | gold tint |
| Olive (trends/ROI) | `olive` | `#7E8A6E` | cooled olive to fit |
| | `oliveLight` | `#EEF5E8` | |
| | `oliveBorder` | `#C6DBB6` | |
| Shared (group) | `shared` | `#5B8AA6` | desaturated steel-blue (cool family, distinct from teal Daily by hue) |
| | `sharedText` (amount) | `#3F6883` | **5.1:1 on card ✓** |
| | `sharedLight` | `#E6EEF3` | |
| | `sharedBorder` | `#CBDBE6` | |
| | `sharedChevron` | `#A3BBCB` | |
| Semantic (net-new) | `success` | `#2EAD4B` | Wise positive |
| | `warning` | `#C98A00` | deepened gold (separated from Joy by use) |
| | `error` | `#D03238` | Wise negative |
| | `info` | `#2A7FB8` | cool blue |

**Dark — key answers:** `background #0E1420` (deep cool), `card #1A2230`, `textPrimary #EEF2F8`, `textSecondary #8A93A4`. Daily teal `#3FBDB6` / `tagBlue #16302E`; Joy gold `#F4C13A` / `tagOrange #332A12`; Shared steel `#7FA8C4`; `success #4FC97A` / `warning #E5B53A` / `error #E5575F` / `info #5AA8E0`.

**WCAG flags.** ✅ Strongest contrast story; all amount-text variants pass. ⚠ Gold Joy `#F4B000` is the lightest accent in the set — amounts MUST use `joyText #8A6300`; the gold tint is background/tag/affordance only (the classic Pitfall 2 trap, pre-mitigated here). ⚠ `warning` (gold) and `joy` (gold) share a hue family — kept apart by role/placement, but the checker should confirm they never appear adjacent in the analytics frame. No disqualifiers.

---

## Direction E: Sage-Neutral + Honey-Joy

**Mood.** "Evolution, not revolution" — the only direction that keeps a *whisper of the current green identity* by re-tasking the existing sage/olive family as a neutral-leaning Daily, paired with a honey-amber Joy on a sage-tinted ivory. Reads calm and organic; bridges A's continuity with C's warmth. A genuinely distinct mood (neutral-green Daily exists in no other direction), included as the 5th option for users who want the least identity break from today's green Daily/Joy.

**Lineage.** **Wise + Claude** — Wise sage canvas-soft `#e8ebe6`, Claude honey-amber + cream.

**D-04 resolution: (a) coral-as-action**, Joy = honey/amber (separate warm family).
**D-05 Daily-tone: (b) neutral-leaning sage** — a desaturated sage-green-gray that reads as a restrained neutral but retains a faint green cast, distinct from both A's cool blue and C's warm taupe.

| Role group | Symbol | Light hex | Notes |
|---|---|---|---|
| Surface | `background` | `#FBFBF8` | sage-tinted ivory |
| | `card` | `#FFFFFF` | |
| | `backgroundMuted` | `#EFF1EC` | sage-soft (Wise lineage) |
| | `backgroundSubtle` | `#FBFBF8` | |
| | `backgroundDivider` | `#E8EBE3` | |
| Text | `textPrimary` | `#222820` | warm-neutral ink |
| | `textSecondary` | `#797E72` | |
| | `textTertiary` | `#BBBFB4` | |
| Border | `borderDefault` | `#E8EBE3` | |
| | `borderDivider` | `#EFF1EC` | |
| | `borderList` | `#E1E5DA` | |
| | `borderInputActive` | `#E85A4F` | |
| Primary (coral anchor) | `accentPrimary` | `#E85A4F` | action only |
| | `accentPrimaryLight` | `#FCEFEC` | |
| | `accentPrimaryBorder` | `#F2D2CC` | |
| | `fabGradientStart` | `#F08070` | |
| | `fabGradientEnd` | `#E85A4F` | |
| 日常 Daily (neutral sage) | `daily` | `#7E8A72` | reuses olive family, shifted to Daily |
| | `dailyText` (amount) | `#56604C` | **6.4:1 on card ✓** |
| | `dailyLight` | `#EDF1E8` | sage tint |
| 悦己 Joy (honey-amber) | `joy` (fill/tag) | `#E8A55A` | Claude honey |
| | `joyText` (amount) | `#A05F00` | **5.1:1 on card ✓** |
| | `joyLight` | `#FBEBD2` | honey tint |
| Olive→Trends note | `olive` | `#9AA382` | lifted so trends stay distinct from the now-sage Daily |
| | `oliveLight` | `#F2F6EA` | |
| | `oliveBorder` | `#D2DEBE` | |
| Shared (group) | `shared` | `#C98A5A` | warm caramel, distinct from honey Joy by depth |
| | `sharedText` (amount) | `#8A5A2E` | **5.6:1 on card ✓** |
| | `sharedLight` | `#F6ECDD` | |
| | `sharedBorder` | `#E8D6BE` | |
| | `sharedChevron` | `#CBB18C` | |
| Semantic (net-new) | `success` | `#2EAD4B` | Wise positive |
| | `warning` | `#C9920F` | deepened gold |
| | `error` | `#C64545` | Claude error |
| | `info` | `#5B8AA6` | cool info note |

**Dark — key answers:** `background #181B17`, `card #232722`, `textPrimary #F0F2EC`, `textSecondary #9A9E92`. Daily sage `#9AA68C` / `tagBlue→tagSage #262A22`; Joy honey `#E8B36F` / `tagOrange #3A2E1A`; Shared caramel `#D49E6E`; `success #5FC97A` / `warning #E5B53A` / `error #E07A7A` / `info #7FA8C4`.

**WCAG flags.** ✅ Sage Daily has the highest amount-text contrast headroom of the set (6.4:1). ✅ Honey Joy amount uses `joyText #A05F00`. ⚠ Daily (sage) and `olive` (trends) both green-family — separated by lightness (`#7E8A72` Daily vs `#9AA382` trends); checker must confirm they read apart in the analytics frame where both appear. No disqualifiers.

---

## Accessibility Verification

> Computed at synthesis time via the WCAG 2.1 relative-luminance formula (SC 1.4.3 normal text ≥4.5:1; SC 1.4.11 non-text/UI ≥3:1). Surface for amounts = `card #FFFFFF`. The **`*Text` (amount) variant** is the verified one — the matching fill/tint is intentionally lighter and is restricted to backgrounds/tags/affordances. Plan 32-02 Task 3 re-runs this per scheme against the live Pencil variables and appends the authoritative pass/fail table; this table is the synthesis-time anchor.

| Scheme | `dailyText`/card | `joyText`/card | `sharedText`/card | coral CTA/white (≥3:1) | body text (≥4.5:1) | Disqualifier? |
|---|---|---|---|---|---|---|
| A Coral-Action + Amber-Joy | `#2F6F9E` 5.4:1 ✓ | `#A05F00` 5.1:1 ✓ | `#A84500` 6.0:1 ✓ | ≈3.5:1 ✓ | 14:1 ✓ | none |
| B Slate-Daily + Coral-Tint-Joy | `#56657D` 5.6:1 ✓ | `#C24A2E` 5.0:1 ✓ | `#8E4E76` 5.2:1 ✓ | ≈3.5:1 ✓ | 13:1 ✓ | none |
| C Warm-Neutral Calm | `#5F5C54` 6.2:1 ✓ | `#A84500` 6.0:1 ✓ | `#7E5A2E` 5.7:1 ✓ | ≈3.5:1 ✓ | 12:1 ✓ | none |
| D Cool-Minimal Contrast | `#1E7C78` 5.0:1 ✓ | `#8A6300` 5.3:1 ✓ | `#3F6883` 5.1:1 ✓ | ≈3.5:1 ✓ | 14:1 ✓ | none |
| E Sage-Neutral + Honey-Joy | `#56604C` 6.4:1 ✓ | `#A05F00` 5.1:1 ✓ | `#8A5A2E` 5.6:1 ✓ | ≈3.5:1 ✓ | 13:1 ✓ | none |

**Cross-scheme rule (Pitfall 2):** every bright/warm accent (amber, gold, terracotta, honey, coral-tint) is split into a light tint (background/tag) + a darker `*Text` variant. Amount glyphs ALWAYS use the `*Text` variant. No direction has an un-fixable load-bearing contrast failure, so **no direction is a selection-disqualifier** at synthesis time. Final ratios are re-verified per scheme in Plan 32-02.

**Pencil render confirmation (Plan 32-02):** all 5 directions were rendered in `home-pocket-palette.pen` (4–5 scheme groups × 6 frames: home-hero / txn-list / analytics × light/dark) with each scheme's palette stored as a `get_variables`-readable variable collection keyed by the exact `AppColors`/`AppColorsDark` symbol names (light + dark per the `{scheme}×{mode}` theme axes) — seeded from the hex above, so the variable record IS this table. `get_screenshot` per scheme confirmed: amounts use the dark `*Text` variant and read legibly on `card`; coral is present every scheme (satisfaction tile + active tab); Daily reads cool/neutral and Joy warm/bright with clear separation (D-02); the analytics Joy KPI shows an ambient number only — no glow/sparkle/badge/>100% (D-03). No new disqualifiers surfaced during rendering.

---

## Distinctness Check

Mapping the directions onto the **D-04 (warm-coexistence) × D-05 (Daily-tone)** matrix proves ≥4 genuinely distinct corners (ROADMAP Success Criterion #1):

| | **D-05 cool Daily** | **D-05 neutral Daily** | **D-05 warm Daily** |
|---|---|---|---|
| **D-04(a) coral-action + separate warm Joy** | **A** Coral-Action + Amber-Joy (cool blue Daily) · **D** Cool-Minimal Contrast (cool teal Daily, gold Joy) | **E** Sage-Neutral + Honey-Joy (neutral sage Daily) | **C** Warm-Neutral Calm (warm taupe Daily, terracotta Joy) |
| **D-04(b) Joy as coral-family bright tint** | — | **B** Slate-Daily + Coral-Tint-Joy (neutral slate Daily) | — |

- **A vs D** both sit in the (a)×cool corner but are clearly distinct moods: A is the continuous "evolved Wa-Modern" (warm ivory, amber Joy, blue Daily); D is the crisp fintech reading (cool near-white, teal Daily, bright gold Joy, maximum cool↔warm split). They bracket the *low-disruption* and *high-contrast* ends.
- **B** is the sole D-04(b) resolution — Joy and primary share the coral hue family at two voltages; structurally unique.
- **C** is the warm-Daily counter-example — proves D-02 contrast can come from chroma, not temperature.
- **E** is the neutral-sage bridge — the only direction preserving a whisper of the current green identity.

**Four matrix corners are occupied (A/D, B, C, E span both D-04 resolutions × all three D-05 tones).** Distinctness satisfied with margin.

---

## 4-vs-5 Decision

**Decision: ship all 5 directions to Plan 32-02.**

Rationale: the brief required ≥4 distinct directions (A/B/C/D already occupy the matrix corners and satisfy Success Criterion #1 on their own). Direction **E** earns its place — it is not noise: it is the only option that keeps continuity with today's green ledger identity by re-tasking the existing sage/olive family as a neutral Daily, giving the user a genuine "least identity break" choice distinct from A's cool-blue and C's warm-taupe neutrals. Because the selection step (32-03) is a single side-by-side comparison with no per-scheme build cost beyond Pencil rendering, the marginal cost of E is low and it widens the user's decision space meaningfully. A and D were retained as separate directions (not merged) because they bracket the disruption↔contrast extremes of the same matrix corner and read as distinct moods.

If 32-02 rendering reveals E reads as redundant against A in practice, it can be dropped to 4 at that stage without affecting the matrix-corner coverage.

---

*PALETTE-01 deliverable — Phase 32 · 2026-06-01*
