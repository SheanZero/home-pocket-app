# Stack Research

**Domain:** Offline-first voice ledger-entry recognition (category + Japanese merchant), Flutter / Drift+SQLCipher / Riverpod 3
**Researched:** 2026-06-23
**Confidence:** HIGH

> **Headline: v1.9 needs essentially ZERO new heavy dependencies.** The decoupled-recognizer + cross-validation + category-only logic is **pure in-house Dart** over the existing voice infra. The merchant library is a **new Drift table + curated seed data** (no external dataset import). The only candidate *new* package is one small, pure-Dart kana/romaji helper (`kana_kit`), and even that is **optional** — a roll-our-own normalizer covers the 80% case. **Do NOT add FTS5, do NOT add fuzzy-match libs, do NOT add ML/embeddings, do NOT bump drift past 2.31.0.**

---

## Recommended Stack

### Core Technologies (REUSE — already in `pubspec.yaml`, no version change)

| Technology | Version (installed) | Purpose in v1.9 | Why Recommended |
|------------|---------|---------|-----------------|
| `drift` | **2.31.0** (keep) | New `merchants` + `merchant_aliases` Drift table(s) for the ~600-800 JP merchant library, with `region` + locale-variant columns | Already the project's DB layer; schema bump v21→v22 follows the established pattern (v1.6 v19→v20, v1.7 v20→v21). **Do NOT bump to ≥2.32.0** — see *What NOT to Use*. |
| `sqlcipher_flutter_libs` | **0.6.8** (keep) | Encrypts the merchant table at rest (4-layer architecture) | Pinned by CLAUDE.md (`^0.6.x`, never `sqlite3_flutter_libs`). The merchant data is non-sensitive but lives in the same encrypted DB for free. |
| `speech_to_text` | **7.3.0** (keep) | en-US recognition already returns **Arabic digits** ("50 dollars" → `50 dollars`) | No spelled-out English number state machine needed (confirmed below). en-US locale routing already centralized in `SpeechRecognitionService`. |
| `flutter_riverpod` / `riverpod_annotation` | 3.1.0 / 4.0.0 (keep) | Wire the new `CategoryRecognizer` / `MerchantRecognizer` + cross-validator providers | Existing DI pattern; decoupled engines become two independent providers. |
| `freezed_annotation` | 3.0.0 (keep) | `RecognitionResult` / `MerchantMatch` / cross-validation verdict value objects | Existing immutability pattern. |

### Supporting Libraries (the ONLY new dependency to consider)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **`kana_kit`** | **^2.1.1** | Hiragana ⇄ Katakana ⇄ Romaji transliteration + script detection for merchant-name normalization (`スタバ`/`すたば`/`sutaba`/`Starbucks` collapse to a common matchable key) | **OPTIONAL but recommended.** Pure Dart, deps `checks`/`collection`/`meta` only, **Dart SDK `>=3.0.0 <4.0.0`** (compatible with project's `^3.10.8`), MIT license, no native code, all-platform. Port of WanaKana. Use it to build a normalized `match_key` column when seeding + at query time. If you'd rather not add a dep, a hand-rolled katakana→hiragana + fullwidth/halfwidth (`１２３`/`ＡＢＣ` → `123`/`abc`) + lowercase normalizer covers the dominant cases — kana_kit mainly adds **romaji** handling (`sutaba` typed/spoken in en-US). |

### In-house logic (NEW code, ZERO new deps)

| Component | Lives in | Notes |
|-----------|----------|-------|
| `CategoryRecognizer` | `lib/application/voice/` | Extracted from today's `VoiceCategoryResolver` minus the merchant short-circuit. Activity/object-keyword → L2 via the existing `category_keyword_preferences` + seed/substring path. This is the **category-only path** (「加油用了400块」). |
| `MerchantRecognizer` | `lib/application/voice/` | Queries the new Drift merchant table (normalized-key exact + alias + bounded substring). Returns a merchant + its *default* category as a **weak signal only** — never the final category. |
| Cross-validator | `lib/application/voice/` | Pure function: keyword-intent vs merchant-default. Agree → confidence boost; conflict → keyword wins (「在星巴克买了个杯子」→ 购物). No library — a `switch`/scoring function over two `RecognitionResult`s. |
| Merchant normalizer | `lib/infrastructure/` (or reuse `voice/`) | kana/fullwidth/lowercase normalization (kana_kit-backed or hand-rolled). Single source for both seed-time and query-time keys. |
| Drift `merchants` migration | `lib/data/tables/` + `app_database.dart` | Schema v21→v22; **emit explicit `CREATE INDEX`** in `onCreate`+`onUpgrade` (memory: `customIndices` getter is decorative/no-op). |

### Development Tools (REUSE)

| Tool | Purpose | Notes |
|------|---------|-------|
| `build_runner` + `drift_dev` 2.31.0 | Regenerate Drift + Freezed after the new table/models | Run `flutter pub run build_runner build --delete-conflicting-outputs` after table/model edits. |
| `import_guard_custom_lint` | Keep `MerchantRecognizer` in application layer, table in `data/`, model interface in domain | The merchant DB moves OUT of `lib/infrastructure/ml/` (it's not ML) into proper data/domain placement — add import-guard coverage like v1.6 did for `shopping_items`. |

## Installation

```yaml
# pubspec.yaml — the ONLY add (and it's optional):
dependencies:
  kana_kit: ^2.1.1   # pure-Dart kana/romaji normalization for merchant matching
```

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # after new Drift table + Freezed models
```

Everything else is new Dart source + a Drift schema migration (v21→v22) + curated seed data — **no other package additions.**

---

## Japanese merchant data sourcing (concrete)

**Recommendation: MANUAL CURATION of ~600-800 entries. Do NOT import an external dataset.** There is no clean, license-safe, taxonomy-aligned open dataset of Japanese merchants. The realistic options:

| Source | Name / where | Size | License | Format | Verdict |
|--------|--------------|------|---------|--------|---------|
| **Wikipedia / Wikidata** | `Category:Convenience stores of Japan`, `Category:Retail companies of Japan`, Wikidata SPARQL (chain entities w/ `instance of` retail) | Hundreds of *chains* (not stores) | **CC-BY-SA 4.0** | HTML / JSON via SPARQL | **Reference only, do NOT bundle raw.** CC-BY-SA is share-alike/attribution — risky to embed verbatim in a closed-source app. Use as a *checklist* to hand-write entries (facts like "Starbucks is a café" aren't copyrightable; the prose/structured dump is). Best source for the **chain shortlist**. |
| **OpenStreetMap POI** | Overpass API `shop=*`/`amenity=*` in Tokyo/Osaka | Tens of thousands of POIs | **ODbL** | JSON/PBF | **Reject.** ODbL share-alike + attribution obligations; per-store POI granularity is wrong (we want *chains*, not branches); noisy `name`/`brand` tagging. Overkill for offline-first. |
| **Kakeibo competitor help docs / app category lists** | (e.g. Zaim, MoneyForward public help pages) | Varies | Proprietary | HTML | **Reference only** for taxonomy-mapping ideas; never copy. |
| **Manual curation (RECOMMENDED)** | Author in a Dart/CSV seed file, taxonomy-mapped by hand | **~600-800** | Project-owned | Dart seed list / asset CSV → seeded into Drift | **Chosen.** ~600-800 entries × {canonical name, kana, romaji/en alias, region, L2 categoryId, ledgerType} is a 1-2 day curation task. Each row is a *fact assignment* to the app's 19 L1 / 103 L2 taxonomy — no source's categories map to ours anyway, so import wouldn't save the hard part. |

**Why manual wins:** the expensive work is **mapping each merchant to one of the 103 L2 categories** + ledger (daily/joy) — no external dataset carries that mapping. Import would still require a full manual relabel pass, while adding license risk and noise. Curation also lets us seed **multi-locale name variants** (`スターバックス`/`スタバ`/`Starbucks`) and the `region: jp` field the milestone wants for future CN/other expansion.

**Curation shortlist (use Wikipedia/Wikidata as the index):** big-3 conbini + Daily Yamazaki/Ministop/Seicomart/Poplar; major supermarkets (イオン/イトーヨーカドー/西友/ライフ/マルエツ/業務スーパー/オーケー); drugstores (マツキヨ/ウエルシア/スギ薬局/ココカラ); 100-yen (ダイソー/セリア/キャンドゥ); apparel (ユニクロ/GU/しまむら/無印); electronics (ヤマダ/ビックカメラ/ヨドバシ); furniture (ニトリ/IKEA); restaurant chains (マクドナルド/吉野家/すき家/松屋/サイゼリヤ/ガスト/スタバ/ドトール/coco壱); transport (JR各社/各私鉄/Suica/PASMO/ETC); fuel (ENEOS/出光/コスモ); online (Amazon/楽天/Yahoo); subscriptions (Netflix/Spotify/Apple). 600-800 covers the long tail of regional Tokyo/Osaka names.

---

## Merchant storage & matching (decision)

**Storage: a dedicated Drift table; schema v21→v22.** Suggested shape (region-ready, OCR-reusable):

```
merchants:        id (text PK) · canonicalName (text) · matchKey (text, normalized) ·
                  defaultCategoryId (text, L2) · defaultLedgerType (text) ·
                  region (text, default 'jp') · isSystem (bool)
merchant_aliases: merchantId (FK) · alias (text) · aliasKey (text, normalized) · locale (text nullable)
   -- indices: idx_merchants_match_key, idx_merchant_aliases_alias_key  (explicit CREATE INDEX — customIndices is a no-op)
```

**Matching: normalized exact → alias exact → bounded substring, ALL in-memory.** With only ~600-800 merchants (+ aliases), load once into an in-memory map keyed by `matchKey` and linear-scan for substring. This is microseconds and is exactly how today's 13-entry `findMerchant` already works — just bigger and normalized. Keep the existing `length < 3` substring guard (avoids `a`→`amazon` false positives) and longest-match-wins.

**FTS5: explicitly REJECTED for this use case.** It is *available* (SQLCipher bundles FTS5), but:
- **CJK tokenization is broken by default.** FTS5's `unicode61` tokenizer treats each CJK char as a token but query `文` won't match indexed `中文`; the `trigram` tokenizer over-generates and mis-handles CJK word boundaries. Correct CJK support needs a **custom C tokenizer** (e.g. better-trigram / ICU) that **`sqlcipher_flutter_libs` does not ship** and we cannot register from Dart without native code — a non-starter for offline-first/no-new-native-deps.
- **The dataset is tiny.** 600-800 rows do not need an inverted index; in-memory scan is faster than crossing the SQLite boundary per query.
- Adds a virtual table + build-option (`fts5` in `sqlite_module`) + migration complexity for zero benefit at this scale.

→ **Normalize at write+read time instead of indexing for search.** `kana_kit` (or hand-rolled) produces the `matchKey`; exact-on-key handles `スタバ`/`すたば`/`Starbucks` collisions; substring handles embedded names. No tokenizer, no FTS5.

**Fuzzy/edit-distance libs: REJECTED.** v1.3 already *deleted* `FuzzyCategoryMatcher` + Levenshtein (Phase 21 D-08) as net-negative. Normalized-exact + bounded-substring + the existing correction-learning loop (`merchant_category_preferences`) is the validated approach; don't reintroduce fuzzy scoring.

---

## English voice (confirmed — no new state machine)

- **`speech_to_text` 7.3.0 en-US returns Arabic digits**, not spelled-out words. The native engines (iOS Speech framework, Android `SpeechRecognizer`) format quantities as digits ("twenty dollars" → "20 dollars", "fifty" → "50"). **No spelled-out English numeral state machine is needed** — the existing zh/ja state machines exist precisely because CJK numerals (五十/千二百) are *not* auto-converted; English doesn't have that problem. (The zh/ja machines confirm this asymmetry: they were built because STT returns 漢数字.)
- **English tokenization need is minimal:** lowercase + trim + split on whitespace/punctuation for keyword/merchant lookup — plain Dart `String` ops, no package. The work is **data, not code**: add English merchant aliases + English category keywords + English currency words (`dollars`, `euros`, `pounds`) into the seed sets so the en path reaches parity with zh/ja. The existing `VoiceTextParser` foreign-currency token detection already handles 10+ currencies.

> ⚠️ **Caveat to verify on-device (not blocking stack choice):** digit-vs-word formatting is engine/locale/OS-version dependent. The recommendation stands (don't pre-build a state machine), but a roadmap UAT should confirm en-US digit output on the target iOS/Android versions; if a regional engine ever returns words, that's a *small* fallback parser scoped to en, not a reason to add a dependency now.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| In-memory normalized merchant match | Drift FTS5 virtual table | Only if the merchant set grew to 10K+ **and** a CJK-capable custom tokenizer could be bundled — neither is true here. |
| `kana_kit` for normalization | Hand-rolled katakana→hiragana + fullwidth/lowercase normalizer | If you want **zero** new deps and can live without romaji (`sutaba`) handling. Fine fallback; kana_kit's main value is romaji + robust script detection. |
| Manual curation of merchants | Wikidata SPARQL import + manual relabel | Never worth it — relabel is the cost, and CC-BY-SA bundling is risky. Use Wikidata only as the shortlist index. |
| Pure in-house cross-validation | Any NLU/intent library | Never — two scored signals + a tie-break rule is ~30 lines; a library adds weight and indirection. |
| Reuse `speech_to_text` en digits | English numeral state machine | Only if on-device UAT proves a target engine returns spelled-out words; scope to en, no dep. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Drift FTS5** for merchant search | CJK tokenization needs a custom C tokenizer SQLCipher doesn't ship; can't register from Dart; dataset too small to benefit | In-memory normalized exact + alias + substring scan |
| **Bumping `drift` to ≥2.32.0** | 2.32.0 drops straightforward SQLCipher support (moves to SQLite3MultipleCiphers); CLAUDE.md pins `sqlcipher_flutter_libs ^0.6.x` and explicitly defers the sqlite3 3.x / cipher migration | Keep `drift 2.31.0` + `sqlcipher_flutter_libs 0.6.8` |
| **`sqlite3_flutter_libs`** (pulled by `drift_flutter`) | Conflicts with SQLCipher; structurally banned (import_guard + AUDIT-09) | `sqlcipher_flutter_libs` only |
| **Levenshtein / fuzzy-match packages** | v1.3 deleted `FuzzyCategoryMatcher`+Levenshtein as net-negative (false positives, threshold churn) | Normalized-exact + bounded-substring + correction learning |
| **TFLite / ONNX / embeddings / on-device LLM** | Violates "no heavy ML" + 30-40MB→2GB asset cost; the prior voice-recognition research recommended deferring these (option C/D/E) and v1.9 scope is explicitly the decoupled-rules + data path, NOT the embedding path | Curated data + cross-validation + learning loop |
| **Any cloud NLU API** (OpenAI/Google NL/Azure) | Sends utterances over network — breaks zero-knowledge / offline-first / no-network-for-recognition constraint | On-device only |
| **OpenStreetMap / Overpass POI import** | ODbL share-alike + per-branch granularity (wrong unit) + noise | Manual chain-level curation |
| **Bundling raw Wikipedia/Wikidata dumps** | CC-BY-SA attribution/share-alike risk in a closed app | Use as shortlist index; hand-author entries |
| **English numeral state machine** | en-US STT already returns Arabic digits | Reuse existing digit path; add en *data* only |
| New federated/P2P model-weight sync | Existing P2P sync is for preference rows, not models; out of scope | Keep correction learning in existing `*_preferences` tables |

## Stack Patterns by Variant

**If app-size / dep-count must stay minimal:**
- Skip `kana_kit`; hand-roll the normalizer (katakana→hiragana, fullwidth→halfwidth, lowercase).
- Because the only thing lost is romaji transliteration (`sutaba`→`スタバ`), which is an edge case for en-US-typed/spoken Japanese names.

**If future OCR (MOD-005) reuse is prioritized:**
- Put `region` + `matchKey` + `aliasKey` on the table now (already recommended), and keep the matcher signature merchant-string-in → MerchantMatch-out so OCR can call the same `MerchantRecognizer`.
- Because the milestone explicitly wants the schema OCR-reusable even though OCR is out of v1.9 scope.

**If merchant set later exceeds ~5K rows:**
- Revisit indexed lookup — but prefer a Dart-side prefix/suffix index (e.g. sorted `matchKey` + binary search) over FTS5, to stay CJK-correct without native tokenizers.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `kana_kit ^2.1.1` | Dart `>=3.0.0 <4.0.0` | Project SDK `^3.10.8` ✓. Pure Dart, no native build impact, no win32/intl interaction (unrelated to the pinned `file_picker`/`package_info_plus`/`share_plus` trio or `intl 0.20.2`). |
| `drift 2.31.0` | `sqlcipher_flutter_libs 0.6.8`, `sqlite3 2.9.4` | **Hold here.** ≥2.32.0 changes the encryption story. |
| New Drift table (v21→v22) | existing migration chain | Follow v1.6/v1.7 pattern; explicit `CREATE INDEX` in `onCreate`+`onUpgrade` (customIndices is decorative). |
| `speech_to_text 7.3.0` | iOS Speech / Android SpeechRecognizer | en-US digit output is engine-dependent — verify on target OS versions in UAT (non-blocking). |

## Sources

- pub.dev API (`/api/packages/kana_kit`) — **kana_kit 2.1.1**, sdk `>=3.0.0 <4.0.0`, deps checks/collection/meta, MIT — HIGH
- [kana_kit on pub.dev](https://pub.dev/packages/kana_kit) — purpose (hiragana/katakana/romaji transliteration + detection), pure Dart, all-platform — HIGH
- `pubspec.lock` (in-repo) — installed: drift 2.31.0, speech_to_text 7.3.0, sqlite3 2.9.4, sqlcipher_flutter_libs 0.6.8 — HIGH
- [Drift extensions / FTS5 docs](https://drift.simonbinder.eu/sql_api/extensions/) — FTS5 available, must enable `fts5` in `sqlite_module` build option — HIGH
- [Drift FTS5 + sqlcipher conflict, drift_flutter issue #3702](https://github.com/simolus3/drift/issues/3702) + web search — **drift ≥2.32.0 drops easy SQLCipher** (SQLite3MultipleCiphers) — HIGH (cross-checked, informs the "don't bump" rule)
- [SQLite FTS5 unicode61 does not support CJK](https://sqlite-users.sqlite.narkive.com/N5MOmskp/sqlite-why-sqlite-fts5-unicode61-tokenizer-does-not-support-cjk-chinese-japanese-krean) + [better-trigram tokenizer](https://github.com/streetwriters/sqlite-better-trigram) — CJK needs a custom tokenizer SQLCipher doesn't ship — HIGH
- [speech_to_text on pub.dev](https://pub.dev/packages/speech_to_text) / [csdcorp/speech_to_text](https://github.com/csdcorp/speech_to_text) — number formatting delegated to native engine; en-US returns digits (engine-dependent) — MEDIUM (verify on-device)
- [Wikidata convenience store Q7361709](https://www.wikidata.org/wiki/Q7361709) / [Category:Convenience stores of Japan](https://en.wikipedia.org/wiki/Category:Convenience_stores_of_Japan) — chain shortlist source, **CC-BY-SA** (reference, not bundle) — HIGH
- In-repo: `lib/infrastructure/ml/merchant_database.dart` (13 entries), `lib/application/voice/voice_category_resolver.dart`, `lib/data/tables/categories_table.dart`, `lib/shared/constants/default_categories.dart` (19 L1 / 103 L2), prior `voice-category-recognition-improvements.md` (no-cloud / no-LLM constraints) — HIGH
- MEMORY: `customIndices` is decorative (emit explicit CREATE INDEX); CLAUDE.md drift/sqlcipher pins — HIGH

---
*Stack research for: offline-first voice category + JP-merchant recognition (Home Pocket v1.9)*
*Researched: 2026-06-23*
