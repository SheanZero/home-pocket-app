# Pitfalls Research

**Domain:** Voice category + Japanese-merchant recognition redesign (decoupled engines, cross-validation, 600-800-entry Drift merchant DB) for a local-first dual-ledger kakeibo Flutter app
**Researched:** 2026-06-23
**Confidence:** HIGH (grounded in this codebase's actual wiring; CJK/STT failure modes verified against current `merchant_database.dart`, `voice_category_resolver.dart`, `parse_voice_input_use_case.dart`, `rule_engine.dart`, `app_database.dart`)

> **Phase mapping note:** v1.9's ROADMAP is not yet written (this file feeds it). Phases are referenced by their *logical role* in the obvious decomposition: **(P-Schema)** Drift v21→v22 merchant table + seed; **(P-Merchant)** `MerchantRecognizer` engine; **(P-Category)** `CategoryRecognizer` engine + rule-engine rework; **(P-CrossValidate)** cross-validation/arbitration + category-only path; **(P-UX)** recognition UX (confidence/chips/inline correction→learning); **(P-EN)** English STT/parser; **(P-i18n)** ARB parity + golden re-baseline. The synthesizer should renumber to actual phase IDs.

---

## Critical Pitfalls

### Pitfall 1: Bidirectional substring matching produces silent merchant false-positives at 600-800 scale

**What goes wrong:**
The current matcher (`merchant_database.dart:157-168`) does `lowerQuery.contains(entry.name) || entry.name.contains(lowerQuery)` AND the same both-ways for every alias, guarded only by `length < 3`. At 13 entries this is tolerable. At 600-800 entries with short kana aliases (`マック`, `ファミマ`, `スギ` [Sugi Pharmacy], `コメ` [Komeda], `成城` [Seijo Ishii]), the bidirectional `contains` will fire on incidental character overlap: a transcript fragment containing `スギ` (cedar/Mr. Sugi) hits Sugi Pharmacy; `コメ` (rice/コメント) hits Komeda; an alias like `丸` or `亀` collides with dozens of place-names. Each false-positive then *short-circuits the whole pipeline* (`parse_voice_input_use_case.dart:93`) and silently forces a wrong category + wrong ledger.

**Why it happens:**
Substring containment is O(scale) in false-positive surface area — every new short alias is a new way to wrongly match. Developers extend the seed list 50× without revisiting the matcher, because at 13 entries it "worked." The `< 3` guard was tuned for a 13-row table, not 800.

**How to avoid:**
- In `MerchantRecognizer`, replace bidirectional `contains` with a **directional, anchored** strategy: exact (full-/half-width + case normalized) → alias exact → **token/word-boundary** containment only (query must contain alias as a delimited token, not a raw substring). Never do `alias.contains(query)`.
- Set a **minimum alias length per script**: kana aliases must be ≥3 chars OR explicitly flagged `shortAliasOk` in the seed data (so `マック` is allowed but a 2-char accidental alias is not auto-generated).
- Return a **ranked candidate list with scores**, not first-match-wins, so cross-validation (Pitfall 5) can veto a weak merchant hit instead of it silently winning.
- Add a regression corpus: a `merchant_false_positive_test.dart` with ~40 adversarial transcripts (rice, cedar, place-names, comment-words) asserting `findsNothing` or low score.

**Warning signs:**
A test transcript like 「お米を買った」 resolving to Komeda Coffee; 「杉並区で」 resolving to Sugi Pharmacy; rising "wrong category" corrections in the learning tables clustered on short-alias merchants.

**Phase to address:** P-Merchant (matcher design) + P-CrossValidate (veto path).

---

### Pitfall 2: Removing the merchant short-circuit without re-homing ledgerType breaks dual-ledger routing

**What goes wrong:**
Today the merchant branch (`parse_voice_input_use_case.dart:106`) does `ledgerType = merchantMatch.ledgerType` — the merchant's *hardcoded* `LedgerType` wins outright and bypasses `RuleEngine`. v1.9 decouples the engines and makes "keyword intent wins on conflict." If the rework removes the merchant short-circuit for *category* but leaves merchant `ledgerType` flowing through unchanged, you get an inconsistent record: category resolved to (say) `cat_shopping` (joy) by the keyword path, but ledger stamped `daily` because the merchant entry said so. The donut, the joy-fullness metric, and the daily/joy split all read `ledgerType` — a desync here is invisible in the entry UI but corrupts every downstream aggregate.

**Why it happens:**
There are *two* sources of truth for ledger: each `_MerchantEntry.ledgerType` (infrastructure) and `RuleEngine`'s category→ledger map (`rule_engine.dart:16-31`). The decoupling refactor naturally focuses on the category engines and forgets ledger has its own merchant override.

**How to avoid:**
- Make **`ledgerType` a pure function of the *final* categoryId**, derived through `RuleEngine`/`CategoryService.resolveLedgerType` *after* cross-validation picks the winning category. Drop `_MerchantEntry.ledgerType` as a routing input (keep it only as optional seed metadata, never as the authority).
- Add an invariant test: for every resolution path, `result.ledgerType == ruleEngine.classify(result.categoryId)` (or the category's configured ledger). No path may stamp a ledger that contradicts its own category.
- Rework `RuleEngine` to cover all 19 L1 / 103 L2 categories (it currently maps ~14 IDs; anything not in the map returns `null` → silent fallback). Missing L2s are a latent daily/joy misclassification today and a guaranteed one once category coverage widens.

**Warning signs:**
A transaction whose category is a joy category but whose row is daily (or vice-versa); analytics joy totals that don't reconcile with category-filtered sums; `ruleEngine.classify()` returning `null` for newly-reachable L2 categories.

**Phase to address:** P-Category (RuleEngine rework + ledger-as-derived) + P-CrossValidate (arbitration stamps ledger last).

---

### Pitfall 3: Cross-validation arbitration mis-fires when one signal is weak or both are weak

**What goes wrong:**
The headline case 「在星巴克买了个杯子」→ 购物 (not coffee) is easy to state and hard to get right at the edges. Failure modes the naïve "keyword wins on conflict" rule introduces:
- **Strong merchant, no real keyword:** 「スタバ」alone — keyword path finds nothing, so "keyword wins" must *not* mean "keyword's null wins." Merchant must win when keyword is absent/weak. If the rule is literally "keyword beats merchant," a bare merchant utterance now resolves to nothing.
- **Weak keyword false-trigger:** 「スタバでコップ買った」where `コップ` (cup) weakly maps to a generic 日用品 category — should it really override a 0.90 Starbucks→cafe hit? Only if the keyword signal clears a confidence floor. A weak keyword should *not* veto a strong merchant.
- **Both weak:** generic verbs (`買った`/`使った`) + an ambiguous merchant. Picking either at high confidence is wrong; this is the case that should fall to the manual-pick affordance, not silently auto-resolve.
- **Keyword and merchant agree but on different L2s under the same L1:** 杯子→`cat_daily_*` vs Starbucks→`cat_food_cafe` — "agree" must be defined at the right taxonomy level or you'll mis-label "agreement" as "conflict."

**Why it happens:**
"Keyword wins on conflict" is a one-line spec that ignores signal strength and the null/absent case. Confidence thresholds and the absent-signal branch are where the real logic lives, and they're easy to under-specify.

**How to avoid:**
- Define arbitration as a small **explicit truth table** over `(merchantScore band, keywordScore band)` → `{merchant, keyword, ask-user}`, not an if-chain. Bands: none / weak / strong. Document each cell. Bake it into `cross_validation_test.dart` as the spec.
- "Keyword wins on conflict" applies **only when both are ≥ strong and they disagree**. Weak keyword never overrides strong merchant. Absent keyword never overrides anything.
- "Both weak" and "strong-vs-strong genuine conflict the user must break" → return a *low-confidence result with alternates*, surfaced as chips, never an auto-stamped high-confidence category.
- Define agreement at **L1 (or ledger) granularity** for the "agree → boost confidence" rule; same-L1 different-L2 is "compatible," not "conflict."

**Warning signs:**
Bare-merchant utterances resolving to nothing; the 杯子 case over-correcting so that *every* Starbucks visit becomes 购物; users repeatedly re-correcting the same merchant because a weak keyword keeps hijacking it.

**Phase to address:** P-CrossValidate (the entire pitfall is this phase's reason to exist).

---

### Pitfall 4: The category-only path mis-fires on merchant-less utterances and on merchant utterances with no keyword

**What goes wrong:**
The new category-only path (「加油用了400块」→ transport/fuel without any merchant) is meant for merchant-less utterances. Two mis-fires:
- It **fails to trigger** when a merchant *was* mentioned but didn't match the DB (a 600-800 list still misses the long tail). If the code says "merchant mentioned but unmatched → give up," the user gets nothing even though `加油`/`给油` keyword would have nailed it. The category-only path must run on *every* utterance regardless of whether a merchant token was present, as an independent engine — that's the whole point of decoupling.
- It **over-triggers** on activity verbs that are also merchant-name fragments (`給油` near a station brand, `クリーニング` as both activity and shop-type), double-counting the same span as both a category keyword and a merchant.

**Why it happens:**
Teams wire the category-only path as a *fallback* ("if no merchant…") instead of a *parallel engine* ("always run, then arbitrate"). The decoupling requirement is explicitly that both engines run independently; a fallback wiring re-couples them.

**How to avoid:**
- Run `CategoryRecognizer` **unconditionally** on the full utterance, in parallel with `MerchantRecognizer`. Arbitration (Pitfall 3) consumes both outputs. Never gate the category engine on merchant absence.
- Keep the keyword/activity lexicon (`加油`/`給油`/`定期`/`家賃` etc.) decoupled from merchant aliases so the same span can be scored by both engines and the arbiter decides — instead of one engine consuming the span first.
- Test the four quadrants explicitly: (merchant✓ keyword✓), (merchant✓ keyword✗), (merchant✗ keyword✓ — the 加油 case), (merchant✗ keyword✗ → ask).

**Warning signs:**
「加油400」resolving to "unknown" because no merchant matched; a fuel-station-brand utterance double-scored; the category engine's output never appearing in logs when a merchant token is present.

**Phase to address:** P-Category (independent engine) + P-CrossValidate (parallel-not-fallback wiring).

---

### Pitfall 5: Japanese name-variant gaps — kana/kanji/romaji/abbrev/voiced/full-width all miss

**What goes wrong:**
STT returns wildly different surface forms for the same merchant and the matcher must normalize all of them: スタバ / スターバックス / Starbucks / starbucks / ｽﾀﾊﾞ (half-width kana); ファミマ / ファミリーマート / FamilyMart; マック / マクド (Kansai!) / McDonald's; voiced/sokuon variants (ガスト vs カスト, さっぽろ vs サッポロ); full-width vs half-width digits and Latin (ＡＥＯＮ vs AEON vs イオン vs 永旺). A 600-800 list that stores only the canonical kanji + a couple aliases will miss most spoken forms, and the misses are *invisible* (resolve to null → category-only path or manual pick), so coverage looks fine in a demo with curated inputs and collapses on real speech.

**Why it happens:**
Japanese has 4+ writing systems for the same token plus regional abbreviations; STT is non-deterministic about which it returns. Curators seed the form *they* type, not the forms STT emits. Half-width katakana and full-width ASCII are easy to forget because they look identical when rendered.

**How to avoid:**
- **Normalize before matching, on both sides:** NFKC (collapses full/half-width + composed/decomposed), lowercase, katakana↔hiragana fold, and a long-vowel/sokuon-tolerant key. Store a normalized match-key column alongside the display name so matching never depends on the curator's chosen surface form.
- Treat the seed schema as **(canonicalName, region, list-of-aliases, normalizedKeys[])**; generate normalizedKeys at seed time, not at query time, so the index is searchable.
- Seed **known regional abbreviations** (マクド for Kansai) and **romaji** for every chain — these are the highest-frequency misses.
- Lean on the learning loop (`merchant_category_preferences`) to capture the tail you can't pre-seed, but don't treat learning as a substitute for NFKC normalization — normalization is a fixed cost that fixes a whole class at once.

**Warning signs:**
Goldens pass with kanji inputs but device testing with real STT misses the same merchant; half-width-kana transcripts never matching; Kansai users reporting マクド never works.

**Phase to address:** P-Schema (normalizedKeys column + region) + P-Merchant (NFKC normalize on query) + P-EN (romaji coverage).

---

### Pitfall 6: `customIndices` is decorative — the merchant table ships unindexed and re-seed is non-idempotent

**What goes wrong:**
Two distinct schema traps, both already burned this project once:
1. **The decorative-`customIndices` trap (documented in MEMORY.md + `app_database.dart:56-61`):** declaring `customIndices` on the new `merchants` table does nothing. `migrator.createAll()` does NOT emit them. The table ships with no index on the normalized-key column → every utterance does a full table scan of 800 rows. Indices must be created with explicit `CREATE INDEX` in **both** `onCreate` AND the `onUpgrade` v21→v22 branch.
2. **Non-idempotent seeding:** seeding 600-800 rows in the `onUpgrade` block, if written as plain `INSERT`, double-inserts when a migration path re-runs or when `onCreate` (fresh install) *and* a later corrective migration both seed. SQLCipher adds no protection here. Re-seeding on every app version bump (to ship merchant-list updates) without `INSERT OR REPLACE` / upsert-by-stable-id duplicates the whole table.

**Why it happens:**
The `customIndices` getter looks like a real Drift API and reads as if it works. Seeding is usually written as a one-shot and nobody plans for "ship an updated merchant list in v2.0" until they need to.

**How to avoid:**
- Emit `CREATE INDEX idx_merchants_normkey ...` (and any region/category index) **explicitly** in onCreate and in the v21→v22 onUpgrade step. Add an arch test that opens a fresh-install DB and a migrated DB and asserts the index exists (`PRAGMA index_list`).
- Give every seed row a **stable string id** (e.g. `mer_starbucks`) and seed with **`INSERT OR IGNORE` / upsert**, not bare INSERT, so re-running is idempotent. Treat the merchant list as data shippable on any future version: a re-seed must converge, not duplicate.
- Use **batched inserts in a single transaction** (Drift `batch`) for 800 rows — not 800 separate awaited statements (migration time + WAL pressure).
- Test the **full migration ladder** (v3→v22, v17→v22, v21→v22, fresh v22) against real sqlite3, as v1.5's CR-01 and v1.6's CR-01 both proved necessary. SQLCipher key must be available during migration test (the encrypted-executor path), not just `NativeDatabase.memory()`.

**Warning signs:**
`PRAGMA index_list(merchants)` empty after upgrade; duplicate merchant rows after a second launch; migration test only covers v21→v22 and skips older bases; seed written as a loop of `await into(merchants).insert(...)`.

**Phase to address:** P-Schema (the entire pitfall is this phase).

---

### Pitfall 7: English STT returns number-words and ambiguous currency words, and locale isn't threaded

**What goes wrong:**
v1.9 chooses to *not* build an English spoken-number state machine and rely on STT returning Arabic digits. But English STT frequently returns words: "fifty", "a hundred", "a buck fifty", "twenty bucks", "twelve fifty" (= 12.50 or 1250?). If the parser only regexes `\d+`, "fifty dollars" extracts *no amount* and the user silently gets a zero/empty amount. Currency words are ambiguous: "buck"/"quid"/"grand"/"a hundred". Plus a latent **locale-not-threaded bug** (this project's exact prior gotcha, and the v1.8 golden WR-04 `currentLocaleProvider` miss): if `localeId` isn't passed to the English path, English utterances route through the ja-then-zh fallback (`parse_voice_input_use_case.dart:49`) and CJK numeral logic mangles them.

**Why it happens:**
"STT returns digits" is true *often* but not *always* — short round numbers and informal speech come back as words. The decision to skip the state machine is reasonable but creates an under-spec'd "what if it's a word" gap. Locale threading bugs are this codebase's recurring failure (documented in MEMORY.md voice gotchas).

**How to avoid:**
- Add a **bounded English number-word fallback** (not a full state machine): a fixed map for one…twenty, thirty…ninety, hundred/thousand, "a"/"an"→1, and the "X fifty" → X.50 idiom, applied only when the digit regex finds nothing. This is ~30 lines, not the zh/ja machine.
- Seed an **English currency-word lexicon** (dollar/dollars/buck/bucks/USD/$, pound/quid/£, euro/€…) into the same longest-first currency scan already in `_detectCurrency` (`parse_voice_input_use_case.dart:65`), reusing the v1.7 currency pipeline rather than forking it.
- **Thread `localeId` end-to-end** for en-US and add a test that asserts an English utterance never enters the ja/zh numeral path. Reuse the locale plumbing already proven in zh/ja.
- Decide "twelve fifty" semantics explicitly (treat as 12.50 only with a decimal cue, else 1250) and test it; don't leave it to chance.

**Warning signs:**
"fifty dollars" → amount 0/empty; "twenty bucks" → no currency; English utterances producing CJK-flavored parses; any English test that omits `localeId`.

**Phase to address:** P-EN (number-word fallback + currency lexicon + locale threading).

---

### Pitfall 8: Recognition UX leaks ADR-012 anti-gamification violations (score, streak, accuracy %)

**What goes wrong:**
Confidence + alt-chips + inline-correction→learning is exactly the surface where gamification creeps in: showing confidence as a **"95% score"** number, a **"recognition accuracy"** stat, a **"corrections streak"** ("you've taught the app 7 times!"), badges for teaching the app, a leaderboard of "smartest household." ADR-012 is a *permanent* contract structurally locked by `anti_toxicity_*_test` + `home_screen_isolation_test`; any of these will fail those gates (or worse, slip past if the new strings aren't in the sweep) and violate the project's core value.

**Why it happens:**
"Show confidence" naturally suggests a percentage badge; "learning improves over time" naturally suggests progress/streak framing. The recognition feature is *new UI surface* the existing anti-toxicity sweeps don't yet cover, so violations can land un-caught.

**How to avoid:**
- Express confidence **qualitatively and privately**: a quiet default-vs-alternatives affordance (the top guess pre-selected, others as tappable chips), **not** a numeric score, gauge, meter, or color-coded "accuracy." Confidence drives *ordering and whether to auto-select*, never a displayed number.
- **No streaks, counts, badges, or cross-session "you taught me N times" framing** on corrections. A correction is a silent edit that improves future suggestions; it is not an achievement.
- **Extend the anti-toxicity test sweep** to the new recognition UI (chips, correction sheet, confidence affordance) across ja/zh/en × all states, with a banned-token list that includes score/streak/accuracy/正确率/連続/ストリーク/達成. v1.8's WR-02 already flagged the token list was missing streak/target/cross-period — start from the *complete* list.
- Keep the correction→learning write **invisible and immediate** (it already feeds `category_keyword_preferences` / `merchant_category_preferences`); don't surface the learning event to the user as a reward.

**Warning signs:**
A "%", gauge, or progress bar next to the category guess; any copy with 連続/streak/正確率/accuracy/レベルアップ; a "corrections" counter anywhere; new recognition strings absent from the anti-toxicity sweep.

**Phase to address:** P-UX (design the affordance ADR-012-safe) + P-i18n (extend anti-toxicity sweep before merge).

---

### Pitfall 9: ARB parity breaks — proper-noun merchant names get translated, category labels don't

**What goes wrong:**
Two opposite i18n errors collide in this milestone:
1. **Under-translation:** new UI strings (confidence affordance label, "選び直す"/"alternatives", correction sheet, English voice hints) added to only `app_ja.arb` and not zh/en → breaks the trilingual parity requirement and `flutter gen-l10n`, and the project's grep-ban/parity tests fail (every UI string must exist in ja+zh+en).
2. **Over-translation:** merchant **proper nouns** (スターバックス, ユニクロ, ニトリ) must **not** go through ARB/translation — they're identity data living in the Drift `merchants` table with per-locale *display variants* (the schema's multi-locale-name field), surfaced via region/locale lookup, NOT via `S.of(context)`. Conversely, **category labels** (食費/餐饮/Dining) ARE translated and live in ARB. Mixing these — putting merchant names in ARB, or category labels in the merchant table — corrupts both systems.

**Why it happens:**
"Everything user-visible is text → put it in ARB" is the project's correct default (CLAUDE.md i18n rule), but merchant names are the exception: they're *data*, not *UI copy*. The multi-locale-name schema field exists precisely to hold them, and it's easy to conflate the two text systems.

**How to avoid:**
- **Rule:** category labels & all chrome → ARB (`S`), updated in all 3 files + `flutter gen-l10n`. Merchant display names → `merchants` table multi-locale columns, resolved by `currentLocaleProvider`. Document this split in the phase plan.
- Run the existing **parity check** (key counts equal across ja/zh/en, no orphan keys) as a gate before merge; v1.8 Phase 47 and v1.7 both had to clean orphan keys at close — do it inline.
- For merchant display: store at minimum the native form + a romaji/Latin form; do **not** attempt to "translate" a brand name into the third locale — show the native or romaji form. A merchant with no zh display variant shows its ja/romaji name, it does not fall back to an ARB key.
- Remember `lib/generated/` is gitignored-yet-tracked — `git add -f` regenerated l10n or the executor leaves stale Dart (MEMORY.md gotcha).

**Warning signs:**
`flutter gen-l10n` errors / unequal key counts; スターバックス appearing as an ARB key; a category label hardcoded in the merchant seed; a missing-zh-name merchant rendering an empty string instead of its romaji.

**Phase to address:** P-Schema (multi-locale merchant columns) + P-i18n (ARB parity gate + the split rule) + P-UX (new chrome strings).

---

### Pitfall 10: Low-confidence thrash — the UI flickers/auto-changes as STT partials stream in

**What goes wrong:**
STT emits partial results that change word-by-word; if `MerchantRecognizer` + `CategoryRecognizer` re-run on every partial and the UI re-selects the top chip each time, the category selection **flickers and reorders** while the user is still speaking, and a late-arriving weak signal can flip an already-good guess. Combined with the project's one-shot-listen iOS gotcha and `error_no_match` handling, re-running recognition on unstable text wastes cycles and confuses the user.

**Why it happens:**
Recognition is naturally wired to "text changed → recompute," but STT text is unstable until final. The cross-validation arbiter amplifies this because small score changes can cross a band boundary and flip the winner.

**How to avoid:**
- Run full recognition/arbitration on the **final** transcript (or a debounced stable partial), not every partial. Show partials as raw text only; commit a category guess once.
- Make arbitration **hysteretic**: once a guess is shown and the user hasn't corrected, don't silently replace it with a marginally-higher alternate — require a clear margin to change.
- Reuse the v1.3 `VoiceChunkMerger` 2.5s continued-listening window as the natural "stable enough to resolve" boundary.

**Warning signs:**
Category chip visibly changing while speaking; selection flipping on the last word; recognition CPU spiking per keystroke-equivalent partial.

**Phase to address:** P-CrossValidate (resolve-on-final + hysteresis) + P-UX (partial vs committed rendering).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep bidirectional `contains` matcher, just add more rows | No matcher rewrite | False-positive surface grows linearly; silent miscategorization that learning *can't* fix (it's the matcher, not the data) | Never at 600-800 scale — rewrite the matcher in P-Merchant |
| Seed merchants with plain `INSERT` in onUpgrade | Fastest to write | Non-idempotent; can't ship list updates without dup; re-run duplicates table | Never — use upsert-by-stable-id from day 1 |
| Leave `ledgerType` flowing from `_MerchantEntry` | Less to change | Two sources of truth → silent ledger desync corrupting analytics | Never — derive ledger from final category |
| Wire category-only path as merchant-absent fallback | Simpler control flow | Re-couples the engines; misses on merchant-mentioned-but-unmatched | Never — it defeats the milestone's decoupling premise |
| Show confidence as a number "for clarity" | Looks informative | ADR-012 violation; fails permanent anti-toxicity gate | Never |
| Skip NFKC normalization, rely on aliases | No normalization code | Curators must hand-seed every script variant; half-width kana silently misses | Only for a throwaway spike, never shipped |
| Test only v21→v22 migration | Faster test | Older-base devices (v3–v20) crash or skip seed on real upgrade | Never — test the full ladder against real sqlite3 |
| Put merchant names in ARB | Reuses i18n plumbing | Brand proper-nouns get "translated"; parity bloat; can't carry region | Never — merchant names are data, not copy |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Drift `customIndices` getter | Assuming it creates indices | Decorative — emit explicit `CREATE INDEX` in BOTH onCreate and onUpgrade; verify via `PRAGMA index_list` test |
| SQLCipher + migration test | Test only against `NativeDatabase.memory()` | Migration/seed must be exercised on the encrypted-executor path with the key available, per the real upgrade |
| `speech_to_text` v7 partials | Recompute recognition on every partial | Resolve on final/debounced-stable transcript; show partials as raw text only |
| iOS STT `error_no_match` | Treat as permanent failure | Classify by error code (MEMORY.md gotcha); one-shot listen + sync status |
| v1.7 currency pipeline | Fork a new English currency parser | Extend the existing longest-first `_detectCurrency` scan with English currency words |
| `category_keyword_preferences` / `merchant_category_preferences` learning tables | Write a divergent correction key | Write the *exact* canonical key the recognizer looked up (the 260526-pg6 orphan-key lesson) |
| `lib/generated/` l10n | `git add` rejected (gitignored-tracked) → stale Dart committed | `git add -f lib/generated/` after `flutter gen-l10n` |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full table scan of 800 merchants per utterance | Recognition lag on entry; jank on low-end Android | Index normalized-key column (explicit CREATE INDEX); match against indexed key, not in-Dart linear scan of all rows | Noticeable by ~few-hundred rows on API-24 devices |
| In-memory linear scan ported from 13-row design | Works in tests, slow on device | Query Drift with an indexed WHERE / prefix lookup; don't load all 800 rows into Dart per utterance | At 600-800 rows × per-partial recompute |
| Re-running recognition on every STT partial | CPU spike, battery, UI flicker | Debounce to stable/final transcript (Pitfall 10) | Immediately on real streaming STT |
| Generating normalizedKeys at query time | Repeated NFKC cost per row per query | Precompute normalizedKeys at seed time, store + index them | At scale × frequency |
| 800 separate awaited inserts during migration | Slow upgrade, WAL bloat, perceptible launch delay | Batched insert in one transaction (Drift `batch`) | On the v21→v22 upgrade for every existing user |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Logging raw utterances / recognized merchant+amount to debug recognition | Leaks financial + behavioral data; violates zero-knowledge architecture | Never log transcript/amount/merchant; gate any recognition debug log behind a compile-time off flag; CLAUDE.md "never log sensitive data" |
| Merchant DB as plaintext asset implying transactions reveal merchants | Merchant *seed list* is public data (fine), but resolved merchant on a transaction is private | Seed list ships as bundled data (non-sensitive); resolved merchant stored in the already-encrypted transaction field — keep it there, don't add a plaintext "last merchant" cache |
| Correction-learning rows synced to family in plaintext | Behavioral inference from another member's corrections | Treat learning tables under the same E2EE/privacy gates as other synced data; confirm they're not newly exposed by recognition UI |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Auto-stamping a wrong high-confidence category with no easy override | User saves wrong data, distrusts voice | Pre-select top guess but make alternates one-tap; inline correction always reachable |
| Confidence shown as a number/gauge | Feels like a test score (ADR-012) + anxiety | Qualitative affordance: top guess selected, alternates as chips, no number |
| Flicker/auto-change while speaking (Pitfall 10) | Disorienting; user can't tell what was captured | Commit guess on final transcript; hysteresis |
| Merchant-less utterance ("加油400") forced to pick a merchant | Friction; voice feels broken for common cases | Category-only path resolves without a merchant; never require a merchant |
| Missing merchant shows empty string in non-native locale | Looks like a bug | Fall back to native/romaji display form, never blank |
| Correction framed as "teaching" achievement | Gamifies a chore; ADR-012 risk | Silent edit that quietly improves suggestions |

## "Looks Done But Isn't" Checklist

- [ ] **Merchant matcher:** Often missing — NFKC/half-width-kana/katakana-hiragana normalization; verify a half-width-kana and a Kansai-abbrev (マクド) transcript both match.
- [ ] **Drift v22 migration:** Often missing — explicit CREATE INDEX (customIndices is decorative) and idempotent upsert seeding; verify `PRAGMA index_list` non-empty and a double-launch doesn't duplicate rows.
- [ ] **Migration ladder:** Often missing — older-base coverage; verify v3→v22 and v17→v22 (not just v21→v22) against real sqlite3 with SQLCipher key.
- [ ] **Decoupling:** Often missing — category engine running on merchant-present utterances; verify the (merchant✓ keyword✓) quadrant shows both engine outputs, not a short-circuit.
- [ ] **Ledger consistency:** Often missing — `ledgerType` derived from final category; verify no path stamps a ledger contradicting its category; RuleEngine covers all reachable L2s.
- [ ] **Cross-validation truth table:** Often missing — the absent-keyword and both-weak cells; verify bare 「スタバ」 still resolves and 「both weak」 falls to ask-user.
- [ ] **English path:** Often missing — number-word fallback ("fifty"), currency words ("bucks"), locale threading; verify no English utterance enters CJK numeral logic.
- [ ] **ADR-012:** Often missing — new recognition UI in the anti-toxicity sweep; verify ja/zh/en × all states with the *complete* banned-token list (incl. streak/accuracy/正確率).
- [ ] **i18n parity:** Often missing — zh/en for every new key + the merchant-name-as-data vs category-label-as-ARB split; verify equal key counts, no orphan keys, `git add -f lib/generated/`.
- [ ] **Performance:** Often missing — indexed query instead of in-Dart 800-row scan; verify recognition latency on an API-24-class device.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Bidirectional-substring false positives shipped | MEDIUM | Rewrite matcher to anchored/token; add adversarial corpus; learning tables can't fix matcher bugs, so this is a code fix + re-test |
| Ledger desync written to real transactions | HIGH | Data already corrupted in encrypted rows; need a one-off repair migration re-deriving ledger from category for affected rows (hash-chain implications — coordinate with ADR-021/crypto rules) |
| Non-idempotent seed duplicated merchant rows | MEDIUM | Add a dedup migration (delete-by-stable-id keeping one) + switch to upsert; verify counts |
| Missing index shipped | LOW | Add CREATE INDEX in a v22→v23 corrective migration; cheap and safe |
| ADR-012 violation merged | LOW–MEDIUM | Revert the offending affordance; the structural test would normally catch it pre-merge — extend the sweep first so it can't recur |
| ARB parity broken at close | LOW | Add missing zh/en keys, remove orphans, `flutter gen-l10n`, re-run parity test (v1.7/v1.8 did this at close — cheaper inline) |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Substring false-positives | P-Merchant + P-CrossValidate | `merchant_false_positive_test.dart` adversarial corpus asserts no/low match |
| 2. Ledger desync on decouple | P-Category + P-CrossValidate | Invariant test: `ledgerType == classify(final categoryId)` on every path; RuleEngine covers all L2 |
| 3. Cross-validation arbitration edges | P-CrossValidate | `cross_validation_test.dart` truth-table: bare-merchant, weak-keyword, both-weak, strong-conflict |
| 4. Category-only path mis-fire | P-Category + P-CrossValidate | Four-quadrant test incl. merchant✗-keyword✓ (加油) and merchant✓-keyword✗ |
| 5. JP name-variant gaps | P-Schema + P-Merchant + P-EN | Half-width-kana + Kansai-abbrev + romaji each match in test |
| 6. customIndices/idempotent seed/migration | P-Schema | `PRAGMA index_list` non-empty (fresh+upgrade); double-seed converges; full ladder vs real sqlite3 + SQLCipher |
| 7. English STT words/currency/locale | P-EN | "fifty dollars"→amount+USD; English never enters CJK path |
| 8. ADR-012 in recognition UX | P-UX + P-i18n | Anti-toxicity sweep covers new UI, ja/zh/en × states, complete banned tokens |
| 9. ARB parity / proper-noun split | P-Schema + P-i18n + P-UX | Equal key counts, no orphans; merchant names in table not ARB; gen-l10n clean |
| 10. Low-confidence thrash | P-CrossValidate + P-UX | Resolve-on-final test; hysteresis margin test; no flicker on partials |

## Sources

- This codebase (HIGH): `lib/infrastructure/ml/merchant_database.dart` (13-entry bidirectional-substring matcher), `lib/application/voice/voice_category_resolver.dart` (short-circuit pipeline), `lib/application/voice/parse_voice_input_use_case.dart` (merchant-wins ledger short-circuit at :93-106), `lib/application/dual_ledger/rule_engine.dart` (partial category→ledger map), `lib/data/app_database.dart` (schema v21, decorative-customIndices handling, full migration ladder)
- Project memory / gotchas (HIGH): MEMORY.md — drift-customindices-is-decorative, voice-entry-ios-recognition-gotchas, executor-l10n-generated-uncommitted, golden-ci-platform-gate; CLAUDE.md i18n rules + Drift TableIndex syntax + crypto rules
- Prior research (HIGH): `.planning/research/voice-category-recognition-improvements.md` — confirms the "3-layer / 500-merchant" pipeline is documentation-only; dict-as-label-set principle; learning-loop infrastructure
- Milestone history (HIGH): v1.3 (voice number parser, VoiceCategoryResolver L2 contract, ChunkMerger), v1.5/v1.6 migration CR-01 regressions, v1.7 currency pipeline + voice currency detection, v1.8 anti-toxicity sweep WR-02 (incomplete banned-token list) — all in PROJECT.md
- Japanese text normalization (MEDIUM): NFKC for full/half-width + katakana/hiragana folding is the standard JP-matching preprocessing; regional brand abbreviations (マクド/マック) and 4-script variance are well-known CJK STT-matching hazards

---
*Pitfalls research for: voice category + Japanese-merchant recognition redesign (Home Pocket v1.9)*
*Researched: 2026-06-23*
