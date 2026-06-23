# Feature Research

**Domain:** Voice expense-entry recognition (category + merchant decoupled, cross-validated) for a Japanese-market local-first kakeibo (家計簿) app
**Researched:** 2026-06-23
**Confidence:** MEDIUM-HIGH (chain coverage & spend dominance HIGH from store-count rankings; UX patterns MEDIUM — general AI-UX literature, no kakeibo-specific voice competitor; ADR-012 boundary HIGH — first-party constraint)

> Scope note: This file covers ONLY the v1.9 redesign features (decoupled `CategoryRecognizer` + `MerchantRecognizer`, cross-validation, ~600-800 JP merchant DB, recognition UX, EN voice pragmatic path, daily/joy rule rework). It assumes the existing voice infra (`speech_to_text` v7, zh/ja number state machines, `VoiceTextParser` amount/date extraction, `category_keyword_preferences` / `merchant_category_preferences` learning tables, 19 L1 / 103 L2 taxonomy) is reused, not rebuilt.

---

## 0. Anchor Mental Model (the two cases this milestone exists for)

The whole redesign is judged against two utterances. Everything below serves these.

**Case A — merchant+category cross-check (conflict → keyword wins):**
> 「在星巴克买了个杯子」 ("bought a cup at Starbucks")
> - Merchant engine: 星巴克/スタバ → `cat_food_cafe` (cafe), high merchant-confidence.
> - Category engine (keyword-intent): 买…杯子 ("bought…a cup") → 购物 / `cat_daily_household` (a physical-good purchase), independent of merchant.
> - **Cross-validation: keyword-intent has priority → result is shopping, NOT cafe.** Merchant is demoted to an alternative chip.
> - Mental model the user expects: *"I told you what I bought; the place is secondary."*

**Case B — merchant-less, category-only path:**
> 「加油用了400块」 ("spent 400 on gas")
> - Merchant engine: no merchant token → no hit.
> - Category engine: 加油 ("refuel") activity keyword → `cat_car_fuel`. Amount 400 from existing parser.
> - **Result must arrive WITHOUT any merchant hit.** This is the case the current merchant-first short-circuit (`VoiceCategoryResolver`) structurally cannot serve well, because it leads with merchant lookup.

These two cases define the engine contract: **category recognition must stand alone, and when both fire, activity/object keywords outrank the merchant's default category.** The "agreement → boost confidence" path (e.g. 「在吉野家吃了牛丼」 — merchant=吉野家→dining, keyword=吃牛丼→dining) is the easy case and mostly serves the confidence display, not correctness.

---

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Decoupled CategoryRecognizer + MerchantRecognizer** | Without it, Case A & B can't be served; it's the milestone's premise | MEDIUM | Refactor of 207-LOC `VoiceCategoryResolver`. Remove the merchant short-circuit. Two pure engines returning `(categoryId, confidence)` + `(merchantId, defaultCategoryId, confidence)` independently. Depends on: existing keyword/synonym dict + merchant DB. |
| **Keyword-intent-priority cross-validation** | This IS the user-confirmed rule; agreement boosts, conflict → keyword wins | MEDIUM | A small deterministic resolver, NOT ML. Inputs: two `(id, confidence)` tuples. Output: chosen category + ranked alternatives + a final confidence. The conflict rule (keyword > merchant) is the hard-coded policy. |
| **Category-only path (no merchant)** | 「加油用了400块」 / 「ガソリン400円」 / "spent 400 on gas" must work | LOW-MEDIUM | Falls out of decoupling — CategoryRecognizer simply runs without merchant input. Mostly free once decoupled. Needs activity/object-verb keyword coverage (加油/ガソリン/refuel→fuel; 吃饭/食事/lunch→dining; 打车/タクシー/taxi→taxi). |
| **JP merchant DB covering everyday-spend categories** | 13 hardcoded entries is not a product; daily JP spend is chain-dominated | HIGH | The ~600-800 build. Must cover the konbini/super/牛丼/cafe/ファミレス/ドラッグストア/100円/家電/fashion/transit/gas/delivery/subscription spine (see §JP Coverage below). Migrate from in-memory list → Drift table with `region` + multi-language name variants. |
| **Confidence display on the recognized result** | User must know when to trust vs. verify; finance demands transparency | LOW-MEDIUM | Per AI-UX literature: color-coded (green/amber/red) + the chosen category shown prominently. NOT a raw 0.0–1.0 number — a 3-tier band ("確実/たぶん/要確認" or just chip styling). |
| **Alternative-candidate chips (category + merchant)** | When recognition is wrong, one-tap correction must be visible, not buried in a picker | MEDIUM | Show the demoted-but-plausible alternatives as tappable chips (e.g. Case A shows 咖啡/cafe as an alt). Reuses the ranked alternatives the resolver already produces. The merchant's category is a natural alt source. |
| **Inline correction feeding the existing learning tables** | The whole point of `category_keyword_preferences` / `merchant_category_preferences` is closing the loop | LOW-MEDIUM | Tapping a correction must persist the FULL extracted keyword (the prior research flagged the current code only stores the matched substring — fix that). This is the cheapest compounding win. |
| **EN voice pragmatic path** | EN STT already returns Arabic digits; trilingual parity expected | LOW-MEDIUM | No EN dictated-number state machine (explicitly out of scope). Add EN merchant aliases (Starbucks, McDonald's, Uniqlo…), EN category keywords (gas, lunch, taxi, groceries), EN currency words. Reuses the same two engines. |
| **Daily/Joy ledger classification driven by the resolved category** | The ledger split is the app's core identity; it must follow the corrected category, not a stale merchant guess | MEDIUM | Rework the rule engine so 日常/悦己 is derived from the FINAL cross-validated category (+ `CategoryLedgerConfig` L1/L2 overrides already in `default_categories.dart`). Case A's 购物 → 日常; a 推し/oshikatsu hit → 悦己. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Conflict-aware resolution (keyword beats merchant)** | Most receipt/auto-classify apps (Zaim, MF ME) classify by *merchant only* — they'd book the Starbucks cup as cafe. Beating the merchant default is genuinely better | MEDIUM | This is the headline differentiator. Zaim/MF are merchant-keyed; they have no utterance to cross-check against. A voice app *does* — it hears intent. Lean into it. |
| **Region-tagged, multi-variant merchant schema (future-proof)** | `region` field + multi-language store-name variants lets the DB later extend to CN/other markets and be reused by OCR (MOD-005) without re-architecting | MEDIUM | Schema design now, payoff later. PROJECT.md explicitly wants OCR-reusable schema. Variants matter for JP: katakana スタバ vs スターバックス, 漢字 vs かな, 半角/全角. |
| **Confidence that drives behavior, not decoration** | "Easy to ignore when it works, actionable when it doesn't" — high-confidence auto-fills silently; low-confidence surfaces the chips proactively | MEDIUM | The AI-UX guides converge on: don't nag on high confidence. Only escalate the chips/"please confirm" affordance when the band is amber/red. Avoids correction fatigue. |
| **Learning that generalizes the keyword, not the merchant** | Correcting 「在星巴克买了杯子」→shopping should teach "买杯子=shopping" (reusable everywhere), not "星巴克=shopping" (would wreck the next coffee entry) | MEDIUM | Subtle but important: the correction must write to `category_keyword_preferences` keyed on the activity/object phrase, NOT pollute `merchant_category_preferences`. Mis-routing corrections is a real footgun. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Any scoring/streak/badge/leaderboard around recognition accuracy** ("you classified 30 days in a row!", "95% recognition streak") | Gamification is the reflex engagement lever; "make corrections fun" | **Violates ADR-012 permanently.** Finance gamification is documented as harmful — fixation on streaks over financial health, celebratory cues distorting risk perception, shame on broken streaks. Recognition is a *utility*, not a game. | Silent correctness. The reward for a good correction is the right number, full stop. No counters, no celebration animation on a correct guess. |
| **Confidence as a precise percentage ("87.3% sure")** | Looks rigorous; engineers love exposing the score | False precision; users can't act on 87 vs 84; invites distrust ("why was it 62% and still wrong?") | 3-tier band (high/med/low) via chip color/label only. |
| **Auto-commit low-confidence guesses without review** | "Frictionless one-tap entry" | A wrong silent classification is worse than a prompt — it corrupts the ledger and the daily/joy split invisibly, and finance errors compound | Low confidence → surface chips/confirm before save. Bias toward precision on the uncertain tail (the prior research's open Q3 — answer: precision on low-confidence). |
| **Cloud NLU / LLM API for recognition** | Would crush accuracy on novel phrasing | Violates zero-knowledge architecture; sends utterances off-device. Non-starter without per-user opt-in | On-device only. (Embedding-similarity is the future ceiling per prior research, but out of v1.9 scope — v1.9 stays dict+rules.) |
| **Exhaustive merchant DB (every store in Japan)** | "Coverage = quality" | Curation cost grows linearly with the long tail; 10k+ entries bloat the asset and barely move accuracy past the top chains | Cover the chain spine (~600-800) that captures the bulk of *daily* spend; let learning + category-only path absorb the tail. |
| **Punitive/judgmental copy on悦己 or any spend** ("you overspent again", "another impulse buy?") | Some budgeting apps shame to "motivate" | ADR-012 §forbids; the app's thesis is *celebrate* 悦己 spending. Shame around recognition would poison the whole tone | Neutral, descriptive language. Recognition UX never editorializes about the *amount* or the ledger. |
| **Per-merchant rich profiles (logos, addresses, hours, maps)** | "Make merchants feel premium" | Scope explosion irrelevant to recognition; pulls toward a POI database, not a classifier | Store only what recognition/OCR needs: canonical id, name variants, default category, region. |

---

## Japanese Merchant DB Coverage (concrete, for the ~600-800 build)

**Key fact: daily JP spend is chain-dominated.** The top-3 konbini alone (7-Eleven / FamilyMart / Lawson) hold ~90% of the konbini market (~51,700 stores), and konbini are ~8% of all Japanese retail sales. Each everyday category is similarly concentrated in a handful of names. This means a few hundred well-chosen chains capture the overwhelming majority of *spoken everyday* expenses — the long tail is genuinely a tail.

Coverage priority is by **frequency of everyday spend**, not store count alone. The spine below is the MUST-cover set; named chains are the anchors (store counts ~2025-2026).

| Category | MUST-cover anchor chains (default category) | Why it matters / notes |
|----------|---------------------------------------------|------------------------|
| **コンビニ konbini** | セブン-イレブン (7-Eleven), ファミリーマート (FamilyMart), ローソン (Lawson) + ミニストップ, デイリーヤマザキ, セイコーマート(北海道) | ~90% in top-3; highest-frequency spend. Default → `cat_food`/`cat_daily` (ambiguous — konbini is BOTH; lean `cat_food_other` or rely on keyword). **Konbini is the prime Case-A trap: merchant says "food" but 「コンビニで電池買った」=日用品.** |
| **スーパー supermarket** | イオン/AEON, まいばすけっと, イトーヨーカドー, 西友/SEIYU, ライフ, 業務スーパー, マルエツ, サミット, OK, トライアル | Default → `cat_food_groceries`. Small-format (まいばすけっと, TRIAL GO) is the growth area. |
| **牛丼/定食 gyudon** | すき家 (Sukiya, ~2000), 吉野家 (Yoshinoya, ~1287), 松屋 (Matsuya, ~1185), なか卯 | Default → `cat_food_dining_out`. Solo-meal staple; very high spoken frequency. |
| **ファストフード fast food** | マクドナルド (McDonald's), モスバーガー, ケンタッキー/KFC, ロッテリア, サブウェイ, フレッシュネス | Default → `cat_food_dining_out`. |
| **ラーメン/うどん/そば** | 一蘭, 一風堂, 餃子の王将, 日高屋, リンガーハット, 丸亀製麺, はなまるうどん, 富士そば, ゆで太郎 | Default → `cat_food_dining_out`. |
| **カフェ cafe** | スターバックス/スタバ (~2077), ドトール (~1079), コメダ珈琲 (~1095), タリーズ, サンマルク, 星乃珈琲, PRONTO | Default → `cat_food_cafe`. **The Case-A canonical example lives here.** Need katakana+漢字 variants (スタバ/スターバックス). |
| **ファミレス family restaurant** | ガスト, サイゼリヤ, ジョイフル, ジョナサン, デニーズ, ココス, ロイヤルホスト, バーミヤン, 夢庵 | Default → `cat_food_dining_out`. |
| **ドラッグストア drugstore** | ウエルシア, ツルハ, マツモトキヨシ/マツキヨ, スギ薬局, ココカラファイン, サンドラッグ, コスモス, クスリのアオキ | ~10兆円 / ~23,000店. Default → `cat_daily_drugstore`. Sells food+cosmetics+medicine → another Case-A trap. |
| **100円ショップ** | ダイソー/DAISO, セリア/Seria, キャンドゥ/Can★Do, ワッツ | Default → `cat_daily_household`. |
| **家電量販店 electronics** | ヤマダ電機/YAMADA, ビックカメラ, ヨドバシカメラ, ケーズデンキ, エディオン, ノジマ, ジョーシン | Default → `cat_housing_appliances` / `cat_communication`. Often 悦己-adjacent (hobby gear). |
| **ファッション fashion** | ユニクロ/UNIQLO (~770), GU, しまむら (~1423), 無印良品/MUJI, ZARA, H&M, ABCマート(shoes), 西松屋(kids) | Default → `cat_clothing_clothes`. MUJI is a Case-A trap (clothes+household+food). |
| **交通 transit** | Suica, PASMO, ICOCA(関西), manaca, JR各社, 東京メトロ, 都営, 阪急/阪神/京阪/近鉄(関西), 私鉄, 各バス | Default → `cat_transport_train`/`cat_transport_bus`. IC-card top-up vs ride is ambiguous; voice usually says 電車/バス/切符. |
| **ガソリンスタンド gas** | ENEOS, 出光/apollostation, コスモ石油/COSMO, キグナス, SOLATO | All-47-pref coverage (ENEOS/出光/コスモ). Default → `cat_car_fuel`. **Case-B anchor (加油/ガソリン).** |
| **デリバリー delivery** | Uber Eats, 出前館, Wolt, menu | Default → `cat_food_delivery`. |
| **サブスク subscriptions** | Netflix, Spotify, Amazon Prime, YouTube Premium, Apple/iCloud, Disney+, dアニメ, Hulu, U-NEXT, Kindle Unlimited | Default → `cat_hobbies_subscription`/`cat_daily_subscription`. Spoken as service names, not stores. |
| **EC/総合** | Amazon (アマゾン), 楽天/Rakuten, Yahoo!ショッピング, メルカリ, ヨドバシ.com | Highly ambiguous (sells everything) → strong Case-A trap; should LEAN on keyword, low merchant-confidence. |

**Tokyo/Osaka-specific & depachika (regional, lower priority but real):**
- **デパ地下 depachika** (food halls): 高島屋, 三越伊勢丹, 大丸, 松坂屋, そごう・西武 — default `cat_food_groceries`/`cat_food_other`.
- **関西/Osaka-leaning:** 阪急/阪神百貨店, 近商ストア, ライフ(関西強い), 関西スーパー, 玉出(激安スーパー大阪), 551蓬莱 — and 関西 IC = ICOCA, 阪急/阪神/京阪/近鉄/南海.
- **東京/Kanto-leaning:** まいばすけっと(首都圏), 成城石井(高級スーパー), オーケー, 東急ストア, 東京メトロ/都営.
- These belong in the DB tagged `region` (Kanto/Kansai/national) so the schema's region field earns its keep, but they are NOT where the bulk of spend is — the national chains above dominate.

**Coverage strategy verdict:** ~150-250 national chains (the spine above, with variants) likely capture the large majority of *spoken everyday* JP expenses; the remaining budget (toward 600-800) buys regional chains, depachika, and secondary names for tail robustness and OCR reuse. Merchant DB quality is "did we get the top chains per everyday category," not "how many rows."

---

## Recognition UX Patterns: Table Stakes vs Delightful

| Pattern | Tier | Notes |
|---------|------|-------|
| Show the chosen category prominently after recognition | Table stakes | The result must be visible and editable before save. |
| 3-tier confidence band (color/label), not a raw % | Table stakes | green=trust/auto, amber=glanceable, red=please-confirm. |
| Tappable alternative chips (category + the merchant's default category) | Table stakes | One-tap correction is the minimum viable repair UX. |
| Inline correction (no modal detour) that persists to learning tables | Table stakes | Correction must be in-flow and must teach the system. |
| Proactively surface chips/confirm ONLY when confidence is low | Delightful | "Easy to ignore when right" — don't nag on high confidence. |
| Show merchant + category as two separate, separately-correctable facets | Delightful | Reflects the decoupling to the user; lets them fix the merchant without re-picking category and vice-versa. |
| Multimodal echo (chip appears as STT lands) | Delightful | Visual confirmation in noisy environments; pairs with the existing record-button UX. |
| Brief "why" affordance (e.g. "matched 加油 → 燃料") | Delightful (optional) | Transparency tooltip; low priority, can defer. |

---

## Feature Dependencies

```
Decoupled CategoryRecognizer + MerchantRecognizer
    └──requires──> existing keyword/synonym dict + JP merchant DB
Keyword-intent-priority cross-validation
    └──requires──> Decoupled recognizers (two (id,confidence) tuples)
Category-only path
    └──requires──> Decoupled recognizers (CategoryRecognizer runnable w/o merchant)
JP merchant DB (~600-800)
    └──requires──> Drift table migration (region + name-variant schema)
    └──enhances──> MerchantRecognizer, and (future) OCR MOD-005
Alternative-candidate chips
    └──requires──> cross-validation producing ranked alternatives
Inline correction → learning
    └──requires──> chips + the existing preferences tables
    └──enhances──> both recognizers over time
Daily/Joy rule rework
    └──requires──> cross-validation producing a FINAL category
    └──requires──> CategoryLedgerConfig (already exists)
EN voice pragmatic path
    └──requires──> EN aliases/keywords/currency words in both engines
Confidence display
    └──requires──> cross-validation emitting a confidence band

Confidence display ──conflicts──> raw-percentage display (pick the band)
Any gamification ──conflicts──> ADR-012 (hard block, structurally tested)
```

### Dependency Notes

- **Cross-validation requires decoupling first:** you cannot apply "keyword wins on conflict" until the two engines emit independent results. Decoupling is the foundational phase; everything else stacks on it.
- **JP merchant DB requires the Drift migration first:** the `region` + name-variant schema must land before bulk-loading ~600-800 rows, or the data gets re-migrated.
- **Daily/Joy rework requires the final category:** the ledger split must read the cross-validated result, not the merchant default — otherwise Case A books 购物 into the wrong ledger. Reuses existing `CategoryLedgerConfig` L1/L2 overrides.
- **Learning enhances both engines but must route corrections correctly:** correcting a *conflict* case teaches the keyword table, NOT the merchant table (see differentiator note) — a wiring mistake here regresses unrelated entries.

---

## MVP Definition (within v1.9)

### Launch With (v1.9 core)

- [ ] **Decoupled CategoryRecognizer + MerchantRecognizer** — premise of the milestone; nothing works without it.
- [ ] **Keyword-intent-priority cross-validation** — the user-confirmed correctness rule; serves Case A.
- [ ] **Category-only path** — serves Case B; mostly falls out of decoupling.
- [ ] **JP merchant DB migration + spine load (~national chains)** — Drift table w/ region + variants; load the §coverage spine.
- [ ] **Confidence band + alternative chips + inline correction → learning** — the table-stakes recognition UX, with the keyword-not-merchant correction routing.
- [ ] **Daily/Joy rule rework reading the final category** — keep the core ledger identity correct.
- [ ] **EN pragmatic path** — aliases/keywords/currency words; no EN number state machine.

### Add After Validation (v1.9.x / next)

- [ ] **Regional/depachika DB rows toward 600-800** — robustness tail; load after the spine proves out.
- [ ] **"Why this category" transparency tooltip** — nice, not essential.
- [ ] **Two-facet separate correction (fix merchant vs category independently)** — delightful refinement.

### Future Consideration (v2+ — explicitly out of v1.9)

- [ ] **On-device embedding-similarity fallback** (prior research Option D) — the real accuracy ceiling, but adds a ~40MB asset; defer until correction-loop data justifies it.
- [ ] **OCR (MOD-005) consuming the merchant DB** — schema is designed for it now; integration is its own milestone.
- [ ] **EN dictated-number state machine** — deliberately excluded; EN STT returns digits.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Decoupled recognizers | HIGH | MEDIUM | P1 |
| Keyword-priority cross-validation | HIGH | MEDIUM | P1 |
| Category-only path | HIGH | LOW | P1 |
| JP merchant DB migration + spine | HIGH | HIGH | P1 |
| Confidence band + chips + correction loop | HIGH | MEDIUM | P1 |
| Daily/Joy rule rework | HIGH | MEDIUM | P1 |
| EN pragmatic path | MEDIUM | LOW-MEDIUM | P1/P2 |
| Regional/depachika tail to 600-800 | MEDIUM | MEDIUM | P2 |
| Two-facet independent correction | MEDIUM | MEDIUM | P2 |
| "Why this category" tooltip | LOW | LOW | P3 |
| Embedding-similarity fallback | HIGH | HIGH | P3 (v2) |

---

## Competitor Feature Analysis

| Feature | Zaim (くふう Zaim) | マネーフォワード ME | Our v1.9 Approach |
|---------|--------------------|----------------------|-------------------|
| Auto-classification basis | Card-link + receipt OCR; classifies by **merchant/line-item** | Account-link; auto-buckets by **merchant** | **Voice utterance** cross-checked: keyword intent overrides merchant default |
| Conflict resolution (place vs item) | None — merchant keyed (Starbucks→cafe regardless) | None — merchant keyed | **Keyword wins on conflict** (the differentiator) |
| Correction learning | Re-categorize; Zaim noted as needing few re-corrections | Sub-category editable (free tier) | Inline chip → `category_keyword_preferences`, keyword-generalized |
| Input modality | Receipt photo + manual + auto-link | Auto-link + receipt + manual | **Voice-first** + manual; local-first, no account link |
| Privacy model | Cloud account aggregation | Cloud account aggregation | **Zero-knowledge on-device**; no cloud NLU |
| Gamification | Minimal/utility | Minimal/utility | **Explicitly none** (ADR-012) — recognition is pure utility |

Note: Neither major JP competitor does *voice* category recognition with utterance-level cross-validation; their auto-classify is merchant-keyed off linked transactions. The Case-A behavior (keyword beats merchant) is something they structurally cannot do because they have no utterance — this is the v1.9 edge.

---

## Sources

- [Convenience stores in Japan — statistics & facts (Statista)](https://www.statista.com/topics/8484/convenience-stores-in-japan/) — top-3 konbini ~90% share; ~8% of retail sales; market ¥13.5T
- [コンビニ店舗数ランキング2026 (日本ソフト販売)](https://www.nipponsoft.co.jp/blog/analysis/chain-conveniencestore2026/) — top-3 = 51,702店 = 90.5% of chains
- [How Convenience Stores Dominate in Japan (ULPA)](https://www.ulpa.jp/post/how-convenience-stores-dominate-in-japan-a-complete-guide) — konbini dominance, small-format super growth (まいばすけっと, TRIAL GO)
- [牛丼チェーン店舗数ランキング2026 (JAPAN WANDERER)](https://japan-wanderer.com/gyudon-chain-ranking/) — すき家~2000 / 吉野家~1287 / 松屋~1185
- [喫茶店・カフェチェーン店舗数ランキング2026 (FC比較ネット)](https://www.fc-hikaku.net/dokuritsu_kaigyo/3127) — スタバ~2077 / ドトール~1079 / コメダ~1095
- [カジュアル衣料4社既存店売上 (流通ニュース)](https://www.ryutsuu.biz/sales/s041442.html) — ユニクロ770直営 / しまむら1423
- [ドラッグストア売上・店舗数ランキング2026 (登販ナビ)](https://www.touhan-navi.com/contents/column/cat2/002864.php) — ウエルシア/ツルハ/マツキヨ; ~23,000店 / ~¥10兆
- [100円ショップ店舗数ランキング (memorva)](https://memorva.jp/ranking/sales/100yen_shop_daiso_seria_cando_tenposuu_pref.php) — ダイソー/セリア/キャンドゥ
- [飲食店チェーン店舗数ランキング2026 (日本ソフト販売)](https://www.nipponsoft.co.jp/blog/analysis/chain-restaurant2026/) — ファミレス/ラーメン/FF chains
- [ENEOS 電子マネー・モバイル決済](https://www.eneos.co.jp/consumer/ss/card/electronic_money/) — ENEOS/出光/コスモ all-47-pref; Suica/PASMO IC at gas
- [家計簿アプリ Zaim と マネーフォワード ME 比較 (warau)](https://www.warau.jp/style/article/) — competitor auto-classification & receipt behavior
- [家計簿アプリZaimとは (カケイクジャーニー)](https://kakeiku-journey.com/whats-zaim/) — Zaim category auto-split, receipt line-item
- [Designing a Confidence-Based Feedback UI (Bootcamp/Medium)](https://medium.com/design-bootcamp/designing-a-confidence-based-feedback-ui-f5eba0420c8c) — confidence card + alt suggestions + "easy to ignore when right"
- [Confidence Visualization — AI UX Design Patterns](https://www.aiuxdesign.guide/patterns/confidence-visualization) — green/amber/red banding, avoid false precision
- [Voice User Interface (VUI) Design Principles 2026 (Parallel)](https://www.parallelhq.com/blog/voice-user-interface-vui-design-principles) — multimodal echo, suggestion chips, hybrid form+voice confirmation
- [Gamification Gone Wrong: When Streaks Become the Point (NerdSip)](https://nerdsip.com/blog/gamification-gone-wrong-when-streaks-become-the-point) — finance gamification harms
- [Gamification in fintech: Financial literacy or just engagement? (11FS)](https://www.11fs.com/article/gamification-in-fintech-financial-literacy-or-just-engagement) — celebratory cues distort risk perception
- [From play to pay: systematic review of gamification in finance (ScienceDirect)](https://www.sciencedirect.com/science/article/pii/S0001691826005810) — gamified cues + financial bias interaction
- `.planning/research/voice-category-recognition-improvements.md` — prior first-party research (13-entry merchant DB, dict scaling limits, on-device embedding ceiling, precision-vs-recall open Q)
- `lib/shared/constants/default_categories.dart` — 19 L1 / 103 L2 taxonomy + `CategoryLedgerConfig` daily/joy defaults

---
*Feature research for: v1.9 voice category+merchant recognition redesign (Home Pocket / まもる家計簿)*
*Researched: 2026-06-23*
