# Phase 49: Merchant Data Foundation - Research

**Researched:** 2026-06-23
**Domain:** Drift schema migration (v21→v22) + SQLCipher-encrypted executor + idempotent seed + hand-written Japanese text normalization
**Confidence:** HIGH (all findings grounded in repo files; one MEDIUM area — encrypted-executor test harness — has no existing precedent and is flagged explicitly)

## Summary

Phase 49 is a **pure data-layer additive change**: add a `merchants` + `merchant_match_keys` two-table pair at schema v22, seed ~400 Japanese merchants via a count-guarded post-open use case mirroring `SeedCategoriesUseCase`, and verify the full migration ladder on the SQLCipher-encrypted executor. Every decision is already LOCKED in `49-CONTEXT.md` (D-01..D-09). This research confirms the **exact existing patterns to mirror** and resolves the five genuine "how" unknowns.

The repo has a mature, **hand-rolled** migration story: 9 migration tests under `test/unit/data/migrations/`, all using `AppDatabase.forTesting()` (in-memory `NativeDatabase.memory()`, **unencrypted**), seeding old-version rows via raw `customStatement` SQL and asserting post-migration state via `PRAGMA`/`sqlite_master`. There is **no** drift exported-schema harness (`drift_schemas/` does not exist) and **no** existing test that opens the real `createEncryptedExecutor` SQLCipher path. Success Criterion #4 (encrypted-executor ladder) is therefore the highest-risk item and needs a **new minimal harness** — outlined below.

Normalization (D-03): the repo has **no** Unicode NFKC utility and **no** kana-folding code reusable for merchant match-keys (the `VoiceTextParser.normalize`/`_machine.normalize` hits are numeral tokenizers, unrelated). The current merchant lookup uses only `String.toLowerCase()`. Phase 49 must **introduce** a small hand-written normalizer; voice can adopt it later. The `characters` package (1.4.1, transitive) does grapheme clustering, **not** NFKC — do not expect it to fold width/case.

**Primary recommendation:** Mirror the v20/v21 migration-step shape exactly (`migrator.createTable(...)` + a `_createMerchantIndexes()` single-point helper called from BOTH onCreate and onUpgrade); mirror `SeedCategoriesUseCase`'s `findAll`→empty→batch guard for `SeedMerchantsUseCase`; derive `ledger_hint` from `category_id` using the **same** `DefaultCategories._defaultLedgerConfigs` map (L2-override-then-L1-parent fallback, matching `CategoryService.resolveLedgerType`); write a fresh hand-rolled normalizer in `lib/infrastructure/` and run the encrypted ladder as a **device/simulator `integration_test`** (not a host-VM `flutter test`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `merchants` / `merchant_match_keys` table definitions | Data (`lib/data/tables/`) | — | All Drift table defs live here (project "thin feature" rule) |
| v22 migration step + explicit index creation | Data (`lib/data/app_database.dart`) | — | `MigrationStrategy` and `_create*Indexes()` helpers already live here |
| `MerchantDao` (query/insert/batch) | Data (`lib/data/daos/`) | — | All DAOs live here |
| `MerchantRepositoryImpl` | Data (`lib/data/repositories/`) | — | All repo impls live here |
| `MerchantRepository` interface | Domain (`lib/features/accounting/domain/repositories/`) | — | Repo interfaces live in domain; domain imports neither data nor infrastructure |
| `DefaultMerchants` const seed list | Shared (`lib/shared/constants/`) | — | Mirrors `DefaultCategories` location |
| Match-key normalizer (NFKC + kana fold + width/case) | Infrastructure (`lib/infrastructure/`) | — | Pure technology/platform utility; reusable by voice/OCR later |
| `SeedMerchantsUseCase` (count-guarded seed) | Application (`lib/application/`) | — | Business-logic use case; mirrors `SeedCategoriesUseCase` |
| Seed wiring into boot | Application (`SeedAllUseCase`) | — | Real seed orchestration is `SeedAllUseCase`, NOT the AppInitializer `seedRunner` no-op (see Pitfall #1) |
| `ledger_hint` derivation | Application (seed-time) reusing Shared map | — | Single source of truth = `DefaultCategories._defaultLedgerConfigs` |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | **2.31.0** (locked, pubspec `^2.25.0`) | Type-safe SQL tables, migrator, DAOs | Already the project ORM; **MUST stay 2.31.0** — 2.32+ drops easy SQLCipher support for SQLite3MultipleCiphers [VERIFIED: pubspec.lock + drift.simonbinder.eu/platforms/encryption] |
| `drift_dev` | 2.31.0 | Code generation (`build_runner`) | Matches `drift` version |
| `sqlcipher_flutter_libs` | **0.6.8** (locked, pubspec `^0.6.7`) | SQLCipher AES-256 native lib for app targets | CLAUDE.md: NEVER `sqlite3_flutter_libs`; `0.7.0+eol` is a do-nothing package [VERIFIED: pubspec.lock] |
| `sqlite3` | 2.9.4 | Dart sqlite3 bindings | Transitive of drift/sqlcipher [VERIFIED: pubspec.lock] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `characters` | 1.4.1 (transitive) | Grapheme clustering | **NOT** for NFKC — only if you need correct codepoint iteration over combining sequences [VERIFIED: pubspec.lock] |
| `dart:core` `String` | SDK | `.toLowerCase()`, codepoint manipulation via `.runes`/`.codeUnits` | The hand-written normalizer's only dependency |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-written NFKC+kana fold | `kana_kit` package | LOCKED OUT by D-03 (zero-new-deps milestone constraint). Also less accurate for loanword brand romaji than hand-authored aliases (D-04). |
| Hand-rolled migration ladder | drift `schema generate` / `drift_dev schema steps` exported-schema harness | Repo has **never** adopted it (no `drift_schemas/`); introducing it now is out of scope and adds a generated-artifact surface. Mirror the existing hand-rolled style. |

**Installation:** No new packages. `flutter pub run build_runner build --delete-conflicting-outputs` after adding the two tables + DAO.

**Version verification:** `drift 2.31.0`, `drift_dev 2.31.0`, `sqlcipher_flutter_libs 0.6.8`, `sqlite3 2.9.4`, `characters 1.4.1` — all read directly from `pubspec.lock` [VERIFIED: pubspec.lock]. No registry lookup needed (no new packages).

## Package Legitimacy Audit

> No external packages are added in this phase. All dependencies already exist in `pubspec.lock`.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none added) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Priority Research Findings (the "HOW")

### 1. Migration ladder on the SQLCipher-encrypted executor (Success Criterion #4) — HIGHEST RISK

**(a) How this repo currently tests migrations** — `[VERIFIED: test/unit/data/migrations/]`

All 9 migration tests (`category_v14_migration_test.dart`, `ledger_type_v18_migration_test.dart`, `schema_v21_migration_test.dart`, `entry_source_v17_migration_test.dart`, `migration_v15_to_v16_test.dart`, `migration_v16_to_v17_test.dart`, `category_v19_dining_out_first_test.dart`, `index_v15_migration_test.dart`, `shopping_items_v20_contract_test.dart`) follow ONE pattern:

```dart
// Source: test/unit/data/migrations/category_v14_migration_test.dart:14-24 (verbatim doc-comment)
// Test approach (no drift_schemas/ snapshots available):
//   1. Open a fresh AppDatabase.forTesting() (in-memory NativeDatabase).
//   2. Seed v13-era data via raw customStatement SQL.
//   3. Run the v14 migration SQL directly via [_runV14MigrationSteps] —
//      these statements mirror exactly what must live in onUpgrade (from < 14).
//   4. Assert the expected post-migration state.
```

`AppDatabase.forTesting()` = `super(NativeDatabase.memory())` — **unencrypted, in-memory** (`lib/data/app_database.dart:46`). `schema_v21_migration_test.dart` explicitly notes (lines 40-43) it only exercises the **fresh-install onCreate path**, not the onUpgrade ALTER path.

**(b) Exported-schema harness?** **NO.** `[VERIFIED: filesystem]`
- No `drift_schemas/` directory exists.
- No `VersionedSchema` / `schemaAt` / `SchemaVerifier` / `drift_dev/api/migrations` usage anywhere in `test/` or `lib/`.
- The only `*.drift_*.json` files are build-cache artifacts under `.dart_tool/build/generated/`, not committed schema snapshots.

→ **Mirror the hand-rolled style.** Do NOT introduce the drift schema-steps harness (out of scope).

**(c) Instantiating the ENCRYPTED executor in a test** — **MEDIUM confidence; NO PRECEDENT EXISTS** `[VERIFIED: grep over test/ + integration_test/]`

- `createEncryptedExecutor(MasterKeyRepository, {inMemory})` lives at `lib/infrastructure/crypto/database/encrypted_database.dart:21`. It calls `_setupEncryption()` which runs `PRAGMA key`, `PRAGMA cipher`, `PRAGMA kdf_iter` and **asserts `PRAGMA cipher_version` is non-empty**, throwing `StateError('SQLCipher not loaded')` otherwise (lines 40-51).
- **Critical blocker:** `sqlcipher_flutter_libs` ships native SQLCipher binaries for **app targets** (iOS/Android/macOS/Linux/Windows app bundles), loaded via `ensureNativeLibrary()` / `open.overrideFor(...)`. The **host Dart VM** that runs `flutter test` links the **system** `libsqlite3` (plain SQLite), so `PRAGMA cipher_version` returns empty → `createEncryptedExecutor` throws. `test/flutter_test_config.dart` does **no** SQLCipher override `[VERIFIED]`. No existing test loads SQLCipher (`master_key_repository_impl_test.dart` mocks `FlutterSecureStorage` and never opens a DB).
- The drift docs confirm SQLCipher native loading is platform-channel / app-target oriented `[CITED: drift.simonbinder.eu/platforms/encryption]`.

→ **Recommended harness for Criterion #4: run the encrypted ladder as a device/simulator `integration_test`**, not a host `flutter test`. There is currently **no `integration_test/` directory** — Phase 49 must create one. Outline:

```dart
// integration_test/merchant_migration_ladder_test.dart  (NEW — outline)
// Runs on a real device/simulator where sqlcipher_flutter_libs natives load.
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // For each old version in {3, 17, 21}: build an encrypted DB stamped at that
  // version, then reopen at v22 to drive onUpgrade through the real SQLCipher path.
  for (final fromVersion in [3, 17, 21]) {
    testWidgets('v$fromVersion -> v22 on encrypted executor', (tester) async {
      await ensureNativeLibrary();                       // loads SQLCipher
      final keyRepo = /* real MasterKeyRepositoryImpl with a known test key */;
      final executor = await createEncryptedExecutor(keyRepo, inMemory: true);
      // 1. open a _StampedDatabase(executor, schemaVersion: fromVersion) that
      //    onCreate-builds only the legacy tables, OR seed legacy rows via SQL.
      // 2. close, reopen as AppDatabase(executor) at v22 → onUpgrade fires.
      // 3. assert PRAGMA index_list(merchants) non-empty; row counts; categoryId∈L2.
    });
  }
  // fresh v22 on encrypted executor (onCreate path).
}
```

**Two viable encrypted-test shapes (planner picks one):**
1. **Full ladder (preferred, matches Criterion #4 literally):** stamp an encrypted DB at vN using a test-only `GeneratedDatabase` whose `schemaVersion` getter returns N and whose `onCreate` builds only the legacy subset, then reopen the same encrypted file/in-memory handle as `AppDatabase` (v22). NOTE: `NativeDatabase.memory()` does not persist across two executor instances, so the **on-disk encrypted file path** (a temp file) is required to reopen-and-upgrade. Use `createEncryptedExecutor(keyRepo, inMemory: false)` pointed at a temp directory, or open the raw `sqlite3.Database` directly with the cipher PRAGMAs.
2. **Migration-SQL-mirror (cheaper, matches existing repo style):** keep the v3/v17/v21→v22 ladder assertions in **host `flutter test`** against `AppDatabase.forTesting()` (memory, unencrypted) — exactly like the existing 9 tests — AND add ONE encrypted **smoke** `integration_test` that opens a fresh v22 encrypted DB and asserts `PRAGMA cipher_version` non-empty + `merchants` table + indexes exist. This proves "the v22 schema builds under SQLCipher" without re-deriving the whole ladder on-device.

→ **Recommendation:** Criterion #4 says "matching real upgrades", so prefer shape 1 for at least the v21→v22 step (the only step a real v1.8 user hits) on the encrypted path, and use the cheap host-VM ladder (shape 2 style) for the v3→v22 / v17→v22 deep-history steps. Flag the on-device portion as a **`checkpoint:human-verify`** if simulator CI is unavailable (see Pitfall #3).

**(d) Assertion patterns** — `[VERIFIED: schema_v21_migration_test.dart:30-38]`:
```dart
// index presence (Criterion #2)
final rows = await db.customSelect(
  "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='merchants'").get();
expect(rows.map((r) => r.read<String>('name')).toSet(),
       containsAll(['idx_merchant_match_keys_key', /* ... */]));
// PRAGMA index_list form (Criterion #2, alternate)
final idx = await db.customSelect('PRAGMA index_list(merchants)').get();
expect(idx, isNotEmpty);
// idempotency (Criterion #3): seed twice, assert row count unchanged
// categoryId ∈ L2 (Criterion #1): see Validation Architecture
```

### 2. Hand-written normalization (D-03) — `[VERIFIED: lib grep — no existing NFKC]`

**There is NO reusable Unicode normalizer in the repo.** The only `normalize(...)` calls are `ChineseNumeralStateMachine.normalize` / `JapaneseNumeralStateMachine.normalize` (`lib/application/voice/voice_chunk_merger.dart:153,174`) — those **tokenize numerals**, not fold text. Current merchant matching uses only `query.toLowerCase()` (`merchant_database.dart:132`).

**Dart core offers NO built-in NFKC.** `String` has no `.normalize()`; `dart:core` / `characters` (grapheme clustering only) do not provide Unicode normalization. With D-03 forbidding new deps, the normalizer must be **hand-rolled and scoped to merchant match-keys** (not full linguistic NFKC).

**Recommended match-key normalization pipeline (seed-time precompute + Phase-50 query-time, same function):**
1. **Fullwidth→halfwidth (ASCII range):** map U+FF01..U+FF5E → U+0021..U+007E (offset −0xFEE0); fullwidth space U+3000 → U+0020. Covers `ＳＴＡＲＢＵＣＫＳ`→`STARBUCKS`, `７`→`7`.
2. **Katakana→hiragana fold:** for codepoints in U+30A1..U+30F6, subtract 0x60 to land in hiragana U+3041..U+3096. This is the documented offset. Handles `マック`↔`まっく`, `セブン`↔`せぶん`.
3. **Lowercase:** `.toLowerCase()` after width-fold so `McDonald`→`mcdonald`.
4. **Optional: strip/normalize 長音符・中黒・spaces** for matching (e.g. `ー` U+30FC, `・` U+30FB, whitespace) — recommend stripping `・` and ASCII/fullwidth spaces from the match-key but **keeping** `ー` (dropping it merges `コーヒー`/`コヒー` which is usually desirable but lossy — leave as Claude's-discretion, document the choice).

**Pitfalls (call out explicitly):**
- **NFKC alone does NOT fold kana case** (katakana↔hiragana). True NFKC leaves カ and か distinct. The kana fold (step 2) is a separate, deliberate step — do not assume an "NFKC" label covers it.
- **Half-width katakana (U+FF61..U+FF9F)** is a separate block; if seed data or STT ever emits ｾﾌﾞﾝ, a full solution would NFKC-expand it to セブン first. For **seed-time** (authored data) you control the source, so you can require seed `surface` strings to be in standard width — but the **query-time** normalizer (Phase 50) will need half-width-kana handling. Note this boundary; Phase 49's seed normalizer can be the simpler version IF the Phase-50 query normalizer is the SAME function (so build it complete now).
- **濁点/半濁点 (combining vs precomposed):** `が` may arrive as base か + U+3099 combining dakuten. NFKC would compose these; without NFKC, normalize combining marks U+3099/U+309A by composing or stripping. For authored seed data this is unlikely; flag for query-time.
- **小書き (small kana ァィゥェォッャュョ):** leave as-is — they are meaningful (`マック` ≠ `マク`).

→ **Recommendation:** introduce a single `MerchantNameNormalizer` (or top-level `normalizeMerchantKey(String)`) in `lib/infrastructure/` (technology utility tier). Build it complete (steps 1-3 mandatory, half-width-kana + combining-mark handling included so Phase 50 reuses it unchanged). Unit-test each transform in isolation.

### 3. Reusable-normalizer discovery (Claude's Discretion) — `[VERIFIED]`

Inspected `lib/infrastructure/ml/` (only `merchant_database.dart`), `lib/application/voice/voice_text_parser.dart`, `lib/application/voice/voice_category_resolver.dart`:
- `VoiceTextParser` does **regex-based amount/date/merchant extraction** and `.toLowerCase()` only — **no Unicode normalization** to reuse.
- `voice_category_resolver.dart` "normalize" refers to **L2-category normalization** (`normalizeToL2` / `_ensureL2`), not text. Not reusable.
- `_machine.normalize(...)` = numeral tokenizer. Not reusable.

→ **Conclusion: no existing routine to reuse.** Phase 49 should **introduce** the shared `MerchantNameNormalizer` as the single source of truth; **voice can adopt it later** (Phase 50's `MerchantRecognizer` will be its first query-side consumer). This is the "introduce a shared normalizer that voice can later adopt" branch the CONTEXT anticipated.

### 4. `ledger_hint` derivation (D-09) — `[VERIFIED]`

The authoritative category→ledger mapping is **`DefaultCategories._defaultLedgerConfigs`** (`lib/shared/constants/default_categories.dart:1192-1222`), exposed via `DefaultCategories.defaultLedgerConfigs`. It is a `List<CategoryLedgerConfig>` of L1 defaults + L2 overrides (e.g. `_config('cat_clothing', LedgerType.joy)` with override `_config('cat_clothing_clothes', LedgerType.daily)`).

The runtime resolver is **`CategoryService.resolveLedgerType(categoryId)`** (`lib/application/accounting/category_service.dart:26-41`), whose rule is: direct config (L1 or L2-override) → else L2 inherits parent L1's config → else null.

→ **Recommendation:** the seed-time `ledger_hint` derivation must reuse this **same map** (not a new hardcoded one). Since seed runs against an L2 `categoryId`, replicate `resolveLedgerType`'s precedence **purely against the const list** (no DB round-trip needed at seed time):
1. Look up `categoryId` directly in `_defaultLedgerConfigs` (catches L2 overrides like `cat_clothing_clothes`→daily).
2. Else find the L2's parent L1 (via `DefaultCategories.all` / `_l2(...).parentId`) and look up the L1 in `_defaultLedgerConfigs`.

This keeps a single source of truth and pre-empts the Phase-51 ledger-desync the CONTEXT warns about (`resolveLedgerType` becomes authoritative). **Do NOT** hand-write a per-merchant ledger column. The existing 12 merchants' `ledgerType` values (`merchant_database.dart`) are a **cross-check**, not the source — and note one mismatch to surface: `Amazon`→`cat_daily_other` is tagged `LedgerType.joy` in the old list, but `cat_daily`/`cat_daily_other` derives to `daily`; `ヤマダ電機`→`cat_housing_appliances` tagged `joy` derives to `daily` (cat_housing→daily). **The derived value should win** (D-09 single-source); flag these as expected diffs from the old hand-tagged list so a reviewer isn't surprised.

### 5. Drift table-def + migration-step + explicit-index conventions in THIS repo — `[VERIFIED]`

**Table definition shape** (mirror `lib/data/tables/exchange_rates_table.dart`):
- `@DataClassName('MerchantRow')` annotation, `class Merchants extends Table`.
- Columns via `text()()`, `text().nullable()()`, `integer()()`, etc. `region` → `text().withDefault(const Constant('JP'))()` or handle default in companion (Drift expresses defaults at companion layer per the v16 note in `app_database.dart:344-350`).
- `Set<Column> get primaryKey => {id};` (stable string id).
- `List<TableIndex> get customIndices => [...]` **with a doc-comment stating it is DECORATIVE** — copy the exact warning from `exchange_rates_table.dart:67-70` / `shopping_items_table.dart`. NOTE: `TableIndex(name: 'idx_...', columns: {#colName})` Symbol syntax; no `@override` (CLAUDE.md pitfall #11).
- For `merchant_match_keys`: `merchant_id` FK column (`text()()`), `match_key` (indexed), `surface`, `kind`. **`match_key` index is NOT unique** (cross-merchant collisions are allowed — see #6).

**Migration step shape** (mirror v20/v21 in `app_database.dart:437-463`):
```dart
if (from < 22) {
  await migrator.createTable(merchants);
  await migrator.createTable(merchantMatchKeys);
  await _createMerchantIndexes();   // single-point helper
}
```
And register both tables in `@DriftDatabase(tables: [...])` (`app_database.dart:25-41`) and bump `schemaVersion => 22` (`app_database.dart:49`).

**Explicit-index encapsulation** (mirror `_createShoppingItemIndexes()` / `_createExchangeRateIndexes()` at `app_database.dart:473-506`):
```dart
Future<void> _createMerchantIndexes() async {
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_merchant_match_keys_key '
    'ON merchant_match_keys (match_key)');
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_merchant_match_keys_merchant '
    'ON merchant_match_keys (merchant_id)');
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_merchants_region '
    'ON merchants (region)');
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_merchants_category '
    'ON merchants (category_id)');
}
```
**Call `_createMerchantIndexes()` from BOTH** `onCreate` (after `createAll()`, alongside the existing `_createShoppingItemIndexes()`/`_createExchangeRateIndexes()` calls at `app_database.dart:59-61`) **AND** the `if (from < 22)` onUpgrade block. This is the `customIndices`-is-decorative gotcha (MEMORY.md `drift-customindices-is-decorative`, CR-01 Phase 36).

**DAO registration** (mirror `exchange_rate_dao.dart`): `class MerchantDao { MerchantDao(this._db); final AppDatabase _db; ... }` — plain class taking `AppDatabase`, NOT a `@DriftAccessor` (the repo's recent DAOs are plain wrappers; `group_dao`/`group_member_dao` are the only `@DriftAccessor` ones with `.g.dart`).

**Repo interface vs impl placement:**
- Interface: `lib/features/accounting/domain/repositories/merchant_repository.dart` (mirror `category_repository.dart` shape: `findAll()`, `findById(String)`, `insertBatch(...)`).
- Impl: `lib/data/repositories/merchant_repository_impl.dart` (mirror `category_repository_impl.dart`).
- Provider wiring: `lib/features/accounting/presentation/providers/repository_providers.dart` `@riverpod MerchantRepository merchantRepository(Ref ref) { final db = ref.watch(...appAppDatabaseProvider); return MerchantRepositoryImpl(dao: MerchantDao(db)); }` (mirror lines 70-74).

### 6. Stable string id scheme + match-key collision awareness — `[VERIFIED: DefaultCategories id style]`

- `DefaultCategories` ids are `cat_<domain>_<leaf>` snake_case (e.g. `cat_food_dining_out`, `cat_clothing_clothes`). The merchant_category_preferences and other tables use `mer_`-style elsewhere? — confirmed merchants have no existing id scheme (current `_MerchantEntry` has no id).
- **Recommendation:** `mer_<ascii_slug>` snake_case, deterministic from the canonical name (e.g. `mer_seven_eleven`, `mer_mcdonalds`, `mer_starbucks`, `mer_yoshinoya`). Keep slugs ASCII (romaji) so the id is stable and greppable regardless of JP name. Idempotency depends on these ids being **stable across runs** (D-05 `INSERT OR IGNORE` keys on them), so the slug must be authored as data in `DefaultMerchants`, **not** generated from the JP name at seed time (generation risk: a normalizer tweak silently changes ids → re-seed doubles).
- **Match-key collisions:** two merchants CAN normalize to the same `match_key` (e.g. multiple `すき家`/`すきや` variants, or short brand tokens). The schema must tolerate this: `merchant_match_keys.match_key` index is **non-unique**; `merchant_id` is the FK to the subtable; a Phase-50 lookup may return multiple `merchant_id`s for one key (scoring/disambiguation is **Phase 50's** job — Phase 49 only stores them). **Do NOT** put a UNIQUE constraint on `match_key`. The seed inserter should also tolerate the same `(merchant_id, match_key)` pair appearing twice (e.g. name == alias after normalization) via `INSERT OR IGNORE` on a composite key or a primary key over the subtable row id.

---

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────┐
  App boot (main.dart)    │  HomePocketApp._initialize()             │
  ──────────────────────► │    └─ seedAllUseCaseProvider.execute()   │
                          │         ├─ SeedCategoriesUseCase  (exists)│
                          │         ├─ SeedVoiceSynonymsUseCase(exists)│
                          │         └─ SeedMerchantsUseCase   (NEW)   │◄── plug in here
                          └───────────────────┬─────────────────────-─┘   (SeedAllUseCase),
                                              │                            NOT AppInitializer
                                              │ findAll() empty?           seedRunner no-op
                                              ▼
       DefaultMerchants (const)   ──expand──► for each merchant:
       (lib/shared/constants/)                 ├─ insert merchants row (id, name_ja/zh/en,
         id, name_ja, aliases[],               │     region='JP', category_id, ledger_hint)
         category_id, ...                       │        └─ ledger_hint = deriveFrom(category_id)
                                                │             via DefaultCategories._defaultLedgerConfigs
                                                └─ for each surface form (name + aliases + locale names):
                                                     insert merchant_match_keys row
                                                       (merchant_id FK, surface, match_key, kind)
                                                         └─ match_key = MerchantNameNormalizer(surface)  (NEW, infra)
                                              │
                                              ▼  (single transaction, INSERT OR IGNORE)
              ┌──────────── SQLCipher-encrypted Drift DB (v22) ────────────┐
              │  merchants            merchant_match_keys                   │
              │   PK id                FK merchant_id ─────────────────────►│
              │   idx region,category  idx match_key (NON-unique), merchant │
              └────────────────────────────────────────────────────────────┘
                                              ▲
   Phase 50 (NOT this phase):  normalize(query) → match_key idx lookup → merchant_id → join merchants
```

### Recommended Project Structure
```
lib/
├── data/
│   ├── tables/
│   │   ├── merchants_table.dart              # NEW (mirror exchange_rates_table.dart)
│   │   └── merchant_match_keys_table.dart    # NEW
│   ├── daos/
│   │   └── merchant_dao.dart                 # NEW (mirror exchange_rate_dao.dart)
│   ├── repositories/
│   │   └── merchant_repository_impl.dart     # NEW
│   └── app_database.dart                     # EDIT: register 2 tables, schemaVersion 22,
│                                             #       from<22 block, _createMerchantIndexes()
├── features/accounting/domain/repositories/
│   └── merchant_repository.dart              # NEW (interface)
├── application/
│   └── accounting/
│       └── seed_merchants_use_case.dart      # NEW (mirror seed_categories_use_case.dart)
├── infrastructure/
│   └── <ml|text>/merchant_name_normalizer.dart  # NEW (hand-written NFKC-lite + kana fold)
└── shared/constants/
    └── default_merchants.dart                # NEW (const DefaultMerchants, ~400 rows;
                                              #       may split by category into multiple files)
test/unit/data/migrations/
    └── merchant_v22_migration_test.dart      # NEW (host VM, memory — mirror existing 9)
integration_test/                             # NEW DIR
    └── merchant_migration_ladder_test.dart   # NEW (encrypted executor, device/sim)
```

### Pattern 1: Count-guarded idempotent seed (mirror exactly)
**What:** `findAll`→empty-check→single-transaction batch insert.
**When to use:** All post-open seeding.
**Example:**
```dart
// Source: lib/application/accounting/seed_categories_use_case.dart:20-29 (verbatim)
Future<Result<void>> execute() async {
  final existing = await _categoryRepo.findAll();
  if (existing.isNotEmpty) return Result.success(null);
  await _categoryRepo.insertBatch(DefaultCategories.all);
  await _configRepo.upsertBatch(DefaultCategories.defaultLedgerConfigs);
  return Result.success(null);
}
```
For merchants: `findAll()` on `merchantRepository`; if empty, expand `DefaultMerchants` into merchant rows + match-key rows and `insertBatch` inside ONE transaction with `INSERT OR IGNORE`. Register `SeedMerchantsUseCase` into `SeedAllUseCase` (after categories, since `category_id` must validate against seeded categories — though categories are also const, ordering keeps the invariant explicit).

### Pattern 2: Single-point explicit-index helper (mirror exactly)
See finding #5 — `_createMerchantIndexes()` called from onCreate AND from<22.

### Anti-Patterns to Avoid
- **Relying on `customIndices` to build indexes.** It is decorative; Drift's migrator never reads it. Indexes MUST be explicit `customStatement('CREATE INDEX IF NOT EXISTS ...')` in BOTH paths. (MEMORY.md gotcha; CLAUDE.md pitfall #11.)
- **Wiring seed into the `AppInitializer` seedRunner.** That callback is a **no-op by design** (`main.dart:64`, `app_initializer.dart:108`); real seeding runs in `HomePocketApp._initialize()` via `SeedAllUseCase` (`main.dart:112-113`). D-06's "main.dart:65" framing is slightly off — wire `SeedMerchantsUseCase` into **`SeedAllUseCase`** (see Pitfall #1).
- **UNIQUE on `match_key`.** Cross-merchant collisions are legal; uniqueness would crash seed and is Phase-50's scoring concern.
- **Generating merchant ids from names at seed time.** Author stable ids as data; generation risks re-seed doubling if the slug algorithm changes.
- **Hand-writing per-merchant `ledger_hint`.** Derive from `category_id` (D-09 single source).
- **Reading `rootBundle` in the migrator.** D-05 forbids it; seed is post-open const-data only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Category→ledger mapping | A second hardcoded merchant→ledger map | `DefaultCategories._defaultLedgerConfigs` + `resolveLedgerType` precedence | Single source of truth; pre-empts Phase-51 desync (D-09) |
| Idempotent seed plumbing | Custom "already seeded?" flag/pref | `findAll()`-empty guard (mirror `SeedCategoriesUseCase`) | Proven pattern; tested |
| Explicit index creation | Inline ad-hoc `CREATE INDEX` per path | A `_createMerchantIndexes()` single-point helper | Prevents onCreate/onUpgrade drift (CR-01 lesson) |
| Migration test scaffolding | New harness | Copy the raw-SQL-seed + PRAGMA-assert shape from `category_v14_migration_test.dart` | Repo has 9 working examples |

**Key insight:** Almost everything in this phase is a **copy-and-adapt of an existing pattern**. The ONE genuinely new artifact with no precedent is the encrypted-executor migration test (finding #1c) and the hand-written normalizer (finding #2).

## Runtime State Inventory

> This is an **additive greenfield-table** phase (new tables only, no rename/refactor of existing data), so most categories are N/A. Listed for completeness.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — `merchants`/`merchant_match_keys` are brand-new tables; no existing rows reference them. The old in-memory `MerchantDatabase._entries` is NOT a datastore (compiled const). | None |
| Live service config | None — no external service stores merchant data. | None |
| OS-registered state | None. | None |
| Secrets/env vars | None — seed data is public, non-sensitive (CONTEXT: "seed list is公开非敏感data, 绝不 log 原文"). DB key derivation unchanged. | None |
| Build artifacts | `app_database.g.dart` (Drift codegen) + `*_use_case`/provider `.g.dart` will regenerate after adding tables/`@riverpod`. **Must run `build_runner` and `git add -f lib/generated/` if any ARB touched** (none expected — merchant names are DATA, not ARB). | Run build_runner |

**Nothing found in categories 1-4** — verified by grep over `lib/`/`test/` and CONTEXT scope (additive, zero-behavior-change, consumers stay on old `MerchantDatabase` until Phase 50).

## Common Pitfalls

### Pitfall 1: Wiring seed into the wrong hook
**What goes wrong:** Following D-06 literally ("main.dart:65 seedRunner") wires `SeedMerchantsUseCase` into `AppInitializer`'s `seedRunner`, which is a **deliberate no-op** — seeds never run.
**Why it happens:** The CONTEXT/ROADMAP note predates the Phase-23 `SeedAllUseCase` refactor. Real seeding moved into `HomePocketApp._initialize()` → `seedAllUseCaseProvider.execute()` (`main.dart:112-113`).
**How to avoid:** Add `SeedMerchantsUseCase` as a third leaf in **`SeedAllUseCase`** (`lib/application/seed/seed_all_use_case.dart`) and its provider (`seed_providers.dart`). Update `seed_all_use_case_test.dart`. The `seedRunner: (_) async {}` stays a no-op.
**Warning signs:** `merchants` table empty after first launch despite seed code "running".

### Pitfall 2: Encrypted ladder test silently passing on plain SQLite
**What goes wrong:** Running the migration ladder in host `flutter test` "passes" but never exercised SQLCipher (host links plain libsqlite3), so a real cipher-path regression ships undetected.
**Why it happens:** `createEncryptedExecutor` throws if `cipher_version` is empty, but tests using `AppDatabase.forTesting()` bypass it entirely.
**How to avoid:** Put the encrypted assertion in an `integration_test` (device/sim) and assert `PRAGMA cipher_version` is non-empty inside the test, not just that migration ran. (Finding #1c.)
**Warning signs:** Test green on CI ubuntu host with no simulator; `cipher_version` never asserted.

### Pitfall 3: index/seed not replicated across onCreate AND onUpgrade
**What goes wrong:** Indexes created only in the `from<22` block → fresh installs (Criterion #2) have no merchant indexes; or seed only on fresh install → upgraders never get merchants.
**Why it happens:** The `customIndices`-is-decorative trap; forgetting fresh-install onCreate.
**How to avoid:** `_createMerchantIndexes()` in both paths. Seed is **post-open count-guarded** (runs on every launch, inserts only when empty), so it covers both fresh + upgrade uniformly — that is exactly why D-05 chose post-open seed over migrator-seed.
**Warning signs:** `PRAGMA index_list(merchants)` empty on the fresh-install test (Criterion #2 fails).

### Pitfall 4: Re-seed doubling
**What goes wrong:** Double-launch or version-upgrade re-runs seed and inserts duplicate match-key rows.
**Why it happens:** Non-stable ids, or missing `INSERT OR IGNORE`, or seeding outside the count guard.
**How to avoid:** Stable authored `mer_*` ids + `INSERT OR IGNORE`/upsert + the `findAll()`-empty guard + single transaction (D-04/D-05). Test: seed twice, assert row count unchanged (Criterion #3).

### Pitfall 5: `categoryId` pointing at a non-existent or L1 category
**What goes wrong:** A merchant maps to `cat_shopping` (removed) or an L1 → silent null on lookup (the exact D-04 bug class the 12-entry list already fixed).
**How to avoid:** The `seed-categoryId-is-real-L2` integration test is a HARD GATE: every `DefaultMerchants.categoryId` must be in the set of L2 ids from `DefaultCategories` (139 `_l2(...)` entries). (Validation Architecture.)

## Code Examples

### Match-key normalizer core (hand-written, zero deps)
```dart
// Source: synthesized from Unicode block offsets (no repo precedent — NEW).
// Fullwidth ASCII U+FF01..U+FF5E → halfwidth (offset 0xFEE0); katakana
// U+30A1..U+30F6 → hiragana (offset 0x60); then lowercase.
String normalizeMerchantKey(String input) {
  final buf = StringBuffer();
  for (final rune in input.runes) {
    var r = rune;
    if (r >= 0xFF01 && r <= 0xFF5E) {
      r -= 0xFEE0;                 // fullwidth ASCII → halfwidth
    } else if (r == 0x3000) {
      r = 0x20;                    // ideographic space → ASCII space
    } else if (r >= 0x30A1 && r <= 0x30F6) {
      r -= 0x60;                   // katakana → hiragana
    }
    buf.writeCharCode(r);
  }
  return buf.toString()
      .toLowerCase()
      .replaceAll('・', '')    // 中黒 ・ removed for matching
      .replaceAll(RegExp(r'\s+'), ''); // collapse/strip whitespace
  // NOTE: half-width katakana (U+FF61..FF9F) + combining dakuten (U+3099/309A)
  // handling to be added (see Pitfall in finding #2) so Phase 50 reuses unchanged.
}
```

### ledger_hint seed-time derivation (reuse the const map)
```dart
// Source: precedence mirrors lib/application/accounting/category_service.dart:26-41
// but evaluated against the const list (no DB round-trip at seed time).
LedgerType deriveLedgerHint(String categoryId) {
  final configs = DefaultCategories.defaultLedgerConfigs;
  // 1. direct (L1 or L2-override)
  final direct = configs.where((c) => c.categoryId == categoryId);
  if (direct.isNotEmpty) return direct.first.ledgerType;
  // 2. L2 inherits parent L1
  final cat = DefaultCategories.all.firstWhere((c) => c.id == categoryId);
  final parent = configs.firstWhere((c) => c.categoryId == cat.parentId);
  return parent.ledgerType;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| In-memory `List<_MerchantEntry>` (12 rows) + `query.contains` bidirectional substring match | Drift `merchants`+`merchant_match_keys` tables, indexed normalized match-key | Phase 49 (this) | Persistent, indexed, idempotent-seeded, region-tagged base for ~600-800 cap |
| `sqlcipher_flutter_libs` 0.6.x + drift ≤2.31 easy SQLCipher | drift 2.32+ + sqlite3 3.x + SQLite3MultipleCiphers | (NOT adopted — pinned out) | Project deliberately stays on 0.6.8 / drift 2.31.0 to keep SQLCipher easy-support [CITED: drift.simonbinder.eu/platforms/encryption] |

**Deprecated/outdated:** `sqlcipher_flutter_libs 0.7.0+eol` is a do-nothing package — do NOT bump to it (CLAUDE.md). `kana_kit` — locked out by D-03.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Host `flutter test` cannot load SQLCipher (plain libsqlite3 only); encrypted ladder needs a device/sim `integration_test`. | Finding #1c | If a host SQLCipher binary CAN be loaded (e.g. via a `sqlite3` open-override pointing at a vendored `libsqlcipher`), the cheaper host-VM encrypted test becomes viable. Verify by attempting `createEncryptedExecutor` in a throwaway test; if `cipher_version` is non-empty, A1 is wrong (favorably). MEDIUM risk — affects test placement, not schema. |
| A2 | Katakana→hiragana via −0x60 offset and fullwidth−0xFEE0 are sufficient for authored seed surfaces. | Finding #2 | If seed data contains half-width katakana or combining dakuten, match-keys mismatch. Mitigated by authoring seed in standard width + building the complete normalizer now. LOW risk for seed-time; flagged for Phase-50 query-time. |
| A3 | `region` default `'JP'` is best expressed via companion default (Drift defaults are companion-layer per `app_database.dart:344-350`), not a SQL DEFAULT constraint. | Finding #5 | If a raw SQL DEFAULT is needed for upgrade-path backfill, use `customStatement` with inline DEFAULT (like entry_source v17, `app_database.dart:359-362`). LOW risk. |
| A4 | The 12 existing merchants' hand-tagged `ledgerType` values that disagree with category-derived values (Amazon, ヤマダ電機) are intentional to override toward derived. | Finding #4 | If product intends those joy tags to win, D-09's "derive from category" needs an exception list. LOW risk — surface to user at commit-time review (D-08 spot-check). |

## Open Questions

1. **Encrypted ladder test depth** — full v3→v22/v17→v22 on-device, or full host-VM ladder + one encrypted v22 smoke?
   - What we know: Criterion #4 says "matching real upgrades"; only v21→v22 is a real v1.8-user path.
   - What's unclear: whether CI has a simulator/device runner.
   - Recommendation: full host-VM ladder (memory) for all four steps (mirrors existing 9 tests) + encrypted `integration_test` covering at least fresh-v22 and v21→v22 with `PRAGMA cipher_version` asserted. If no simulator CI, gate the on-device test behind `checkpoint:human-verify`.

2. **`DefaultMerchants` file split** (Claude's Discretion) — single file vs per-category.
   - Recommendation: split by category group (`default_merchants_convenience.dart`, `_food.dart`, etc.) aggregated by a `DefaultMerchants.all` getter, mirroring how readable `DefaultCategories` stays at ~1268 lines for 158 categories. ~400 merchants × multi-field will exceed the 800-line guideline in one file.

3. **長音符 (ー) in match-key** — strip or keep?
   - Recommendation: KEEP `ー` in the match-key (stripping over-merges); document the choice. Phase 50 scoring can add tolerance.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `drift` / `drift_dev` | tables, migrator, codegen | ✓ | 2.31.0 | — |
| `sqlcipher_flutter_libs` (app target natives) | encrypted executor | ✓ (iOS/Android/desktop app) | 0.6.8 | — |
| SQLCipher in host `flutter test` VM | encrypted-ladder host test | ✗ | — | Run as `integration_test` on device/sim (A1) |
| `integration_test` package | encrypted-executor test | unverified in pubspec dev_deps | — | Add `integration_test:` (Flutter SDK package, no pub fetch) to dev_dependencies if absent |
| `build_runner` | regenerate `.g.dart` | ✓ | (project standard) | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** host-VM SQLCipher → device/sim `integration_test` (the standard Flutter approach for native-backed DB tests). Verify `integration_test` is in `dev_dependencies`; if not, add `integration_test: sdk: flutter`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (unit/widget) + `integration_test` (device/sim, NEW for encrypted path) + `mocktail` for use-case mocks |
| Config file | `test/flutter_test_config.dart` (golden platform gate only; no SQLCipher setup) |
| Quick run command | `flutter test test/unit/data/migrations/merchant_v22_migration_test.dart test/unit/application/accounting/seed_merchants_use_case_test.dart` |
| Full suite command | `flutter test` (host) + `flutter test integration_test/` (on a booted simulator/device) |

### Phase Requirements → Test Map
| Req / Criterion | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| Crit #1 / MERCH-01,02 | Fresh + upgrade load ~400 merchants; every `categoryId` ∈ L2 set | integration (seed) + unit (categoryId guard) | `flutter test test/unit/.../seed_merchants_use_case_test.dart` | ❌ Wave 0 |
| Crit #1 guard | `seed-categoryId-is-real-L2`: assert each `DefaultMerchants.categoryId` is in `{DefaultCategories L2 ids}` | unit | `flutter test test/unit/.../default_merchants_categoryid_test.dart` | ❌ Wave 0 |
| Crit #2 / MERCH-04 | `PRAGMA index_list(merchants)` AND `merchant_match_keys` non-empty on fresh-install DB | unit (memory, onCreate) | `flutter test test/unit/data/migrations/merchant_v22_migration_test.dart` | ❌ Wave 0 |
| Crit #2 / MERCH-04 | Same indexes non-empty on **migrated** DB (v21→v22 onUpgrade) | unit (memory) + integration (encrypted) | as above + `flutter test integration_test/` | ❌ Wave 0 |
| Crit #3 / MERCH-04 | Re-seed convergence: seed twice → merchant + match-key row counts unchanged | unit | `flutter test test/unit/.../seed_merchants_use_case_test.dart` | ❌ Wave 0 |
| Crit #4 / MERCH-04 | Full ladder (v3→v22, v17→v22, v21→v22, fresh v22) on **encrypted** executor; `cipher_version` non-empty | integration (device/sim) | `flutter test integration_test/merchant_migration_ladder_test.dart` | ❌ Wave 0 |
| Crit #5 / MERCH-05 | Schema carries region(JP default) + name_ja/zh/en + match_key + L2 categoryId + ledger_hint; names in Drift columns not ARB | unit (PRAGMA table_info) | `flutter test test/unit/data/migrations/merchant_v22_migration_test.dart` | ❌ Wave 0 |
| Normalizer (D-03) | width-fold, kana-fold, lowercase per transform | unit (property-style table of pairs) | `flutter test test/unit/infrastructure/.../merchant_name_normalizer_test.dart` | ❌ Wave 0 |
| ledger_hint (D-09) | derived value == `CategoryService.resolveLedgerType` precedence for every seeded categoryId | unit | `flutter test test/unit/.../ledger_hint_derivation_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the relevant unit test file(s) above (`flutter test test/unit/data/migrations/merchant_v22_migration_test.dart`, etc.).
- **Per wave merge:** full host `flutter test` + `flutter analyze` (0 issues) — per MEMORY.md gotcha, GSD auto-gates sniff `xcodebuild`; run `flutter test` manually as orchestrator.
- **Phase gate:** full host suite green + `integration_test/` green on a booted simulator before `/gsd-verify-work`. If no simulator, `checkpoint:human-verify` on the encrypted ladder.

### Wave 0 Gaps
- [ ] `test/unit/data/migrations/merchant_v22_migration_test.dart` — Crit #2, #5 (fresh-install onCreate, PRAGMA index_list + table_info)
- [ ] `test/unit/application/accounting/seed_merchants_use_case_test.dart` — Crit #1, #3 (count guard, idempotency)
- [ ] `test/unit/.../default_merchants_categoryid_test.dart` — Crit #1 hard gate (categoryId ∈ L2)
- [ ] `test/unit/infrastructure/.../merchant_name_normalizer_test.dart` — D-03 transforms
- [ ] `test/unit/.../ledger_hint_derivation_test.dart` — D-09 parity with `resolveLedgerType`
- [ ] `integration_test/merchant_migration_ladder_test.dart` — Crit #4 (encrypted executor; NEW `integration_test/` dir)
- [ ] Verify `integration_test:` in `dev_dependencies` (Flutter SDK package); add if absent
- [ ] Update `test/unit/application/seed/seed_all_use_case_test.dart` for the new third leaf

**Held-out / property-based flags:** the normalizer test should be **property-style** (a table of (input, expected) pairs across width/kana/case/combining cases) rather than a few examples — this is the component most likely to have edge-case regressions and the one with no existing precedent.

## Security Domain

> `security_enforcement` is enabled (CLAUDE.md crypto rules). This phase touches the encrypted DB but adds only public, non-sensitive seed data.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface touched |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes (light) | Seed data is authored const (trusted); `categoryId`-∈-L2 hard gate is the validation. No external/user input enters this phase. |
| V6 Cryptography | yes | Use the EXISTING `createEncryptedExecutor` (SQLCipher AES-256-CBC, PBKDF2 256k) unchanged — NEVER implement custom crypto, NEVER access `flutter_secure_storage` directly (CLAUDE.md crypto rules). Merchant tables live INSIDE the already-encrypted DB. |
| V7 Logging | yes | CONTEXT: seed list is public/non-sensitive but **never log raw matched merchant names** (audit logger discipline). |

### Known Threat Patterns for Drift/SQLCipher + Dart const seed
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via seed string interpolation | Tampering | Seed values are authored const, but build `merchant_match_keys` inserts via Drift companions / parameterized `insertBatch`, NOT string-interpolated `customStatement` (the v14 block interpolates category fields — do NOT copy that for merchant DATA; prefer companions). |
| Master-key mishandling breaking DB open | DoS / data loss | Reuse `createEncryptedExecutor` + `AppInitializer` data-loss guard unchanged; do not add a second key path. |
| Plain-SQLite fallback masking encryption regression | Info disclosure (unencrypted data at rest) | `_setupEncryption` already throws on empty `cipher_version`; the integration test asserts it (Crit #4). |

## Sources

### Primary (HIGH confidence) — repo files
- `lib/data/app_database.dart` (schemaVersion 21, MigrationStrategy, `_createShoppingItemIndexes`/`_createExchangeRateIndexes`, v14/v18/v20/v21 step shapes)
- `lib/data/tables/exchange_rates_table.dart` + `shopping_items_table.dart` (table-def + decorative `customIndices` pattern)
- `lib/data/daos/exchange_rate_dao.dart` (DAO shape)
- `lib/application/accounting/seed_categories_use_case.dart` (count-guarded seed)
- `lib/application/seed/seed_all_use_case.dart` + `seed_providers.dart` + `lib/main.dart:109-142` (REAL seed orchestration; seedRunner no-op)
- `lib/application/accounting/category_service.dart:26-41` (resolveLedgerType precedence)
- `lib/shared/constants/default_categories.dart` (`_defaultLedgerConfigs` map, L1/L2 ids, 139 L2s)
- `lib/infrastructure/crypto/database/encrypted_database.dart` (createEncryptedExecutor, cipher PRAGMAs)
- `lib/infrastructure/ml/merchant_database.dart` (12-entry seed core, aliases, D-04 categoryId fixes)
- `lib/application/voice/voice_text_parser.dart` + `voice_category_resolver.dart` (confirmed NO reusable normalizer)
- `test/unit/data/migrations/category_v14_migration_test.dart` + `schema_v21_migration_test.dart` (hand-rolled migration-test pattern, PRAGMA assertions)
- `test/flutter_test_config.dart` (no SQLCipher setup); `pubspec.lock` (exact versions)

### Secondary (MEDIUM confidence)
- `.planning/ROADMAP.md` §Phase 49; `.planning/REQUIREMENTS.md` MERCH-01..05; `49-CONTEXT.md` D-01..D-09
- MEMORY.md `drift-customindices-is-decorative`

### Tertiary (LOW confidence)
- drift.simonbinder.eu/platforms/encryption + pub.dev/packages/sqlcipher_flutter_libs (version-pin rationale; host-VM SQLCipher caveat → drives A1)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — exact versions from `pubspec.lock`, no new deps.
- Architecture / migration & seed patterns: HIGH — direct copies of working repo code with line cites.
- Normalization: HIGH on "no reuse exists"; MEDIUM on edge-case completeness (A2).
- Encrypted-executor test: MEDIUM — no precedent; harness is a reasoned outline, A1 flagged for empirical verification.
- ledger_hint derivation: HIGH — source map + resolver both located.

**Research date:** 2026-06-23
**Valid until:** 2026-07-23 (stable; drift/sqlcipher pinned, repo patterns established). Re-verify only if drift is unpinned from 2.31.0.
