# Phase 31: Terminology Rename - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** ~40 modified/renamed + 2 genuinely new + 1 tricky migration block
**Analogs found:** 2 NEW files mapped to exact analogs / 2; tricky migration mapped to 2 in-repo precedents

> **Phase nature:** This is a RENAME phase. The overwhelming majority of files are modified or `git mv`'d in place — **their own current code is the pattern**. Analog-mapping effort is concentrated on (1) the NEW migration test, (2) the NEW ADR-017, (3) the tricky v17→v18 Drift migration block, and (4) the Serena atomic-rename targets.
>
> **Scope note (D-16 OVERRIDES research A1):** `soul_satisfaction` is **IN scope, full widest ring** per CONTEXT.md D-16. The DB column `transactions.soul_satisfaction → joy_fullness`, the Freezed field `Transaction.soulSatisfaction → joyFullness`, the sync-mapper JSON key `'soulSatisfaction' → 'joyFullness'`, and ~50 call sites are all renamed. This means the v17→v18 migration carries a **THIRD** sub-step (column rename via `ALTER TABLE … RENAME COLUMN`) on top of the two enum-value sub-steps. RESEARCH §Pitfall 1 / A1 recommended OUT-of-scope; that recommendation is **superseded by the locked D-16 decision**.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/unit/data/migrations/ledger_type_v18_migration_test.dart` | test (migration) | transform / batch | `entry_source_v17_migration_test.dart` (raw-sqlite3 style) + `category_v14_migration_test.dart` (`_runVNMigrationSteps` contract + UPDATE assertions) | exact |
| `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` | config (doc) | n/a | `ADR-015_Lexical_Hierarchy_v1_1.md` (vocab-mapping subject) + `ADR-016_*` (full Context→Decision section skeleton) | exact |
| `lib/data/app_database.dart` — NEW `if (from < 18)` block | migration | transform | v14 step (data UPDATE, same file L162-241) + v8 sync_queue recreate (table-recreate for schema change, same file L91-119) | exact (in-file precedent) |
| `lib/data/tables/category_ledger_configs_table.dart` — CHECK literal | model (table def) | n/a | in-place edit — own current code (L12-14) is the pattern | in-place |
| `lib/data/tables/transactions_table.dart` — `soulSatisfaction` col rename | model (table def) | n/a | in-place edit (L35, L47) — own current code is the pattern | in-place |
| `lib/features/accounting/domain/models/transaction.dart` — `LedgerType` enum | model (domain enum) | n/a | Serena `rename_symbol` — atomic, no analog | n/a (atomic rename) |
| `lib/core/theme/app_colors.dart` / `app_colors_dark` symbols | config (theme) | n/a | Serena `rename_symbol` — atomic | n/a (atomic rename) |
| `lib/features/.../*soul*/*survival*` files + classes (~9 files, ~16 symbols) | mixed (use case / widget / model) | n/a | `git mv` (file) + Serena `rename_symbol` (class) | in-place rename |
| ARB files `app_{zh,ja,en}.arb` (25 keys + values + @description) | config (i18n) | n/a | in-place edit + `flutter gen-l10n` regen | in-place |
| Persistence-literal hand-edits (analytics_dao, use-cases, demo_data) | data / application | n/a | in-place targeted edit — NOT Serena-reachable string literals | in-place |
| `docs/arch/03-adr/ADR-015_*.md` — append pointer | config (doc) | n/a | append-only `## Update YYYY-MM-DD` (see ADR-016 L159, L192 precedent) | in-place |
| `docs/arch/03-adr/ADR-000_INDEX.md` — add ADR-017 row | config (doc) | n/a | existing entry format (L454, L480) | in-place |

---

## Pattern Assignments

### NEW: `test/unit/data/migrations/ledger_type_v18_migration_test.dart` (test, transform)

**Primary analog:** `test/unit/data/migrations/entry_source_v17_migration_test.dart` (raw-`sqlite3` in-memory style — preferred here because v18 needs precise control over table DDL including the CHECK constraint, which the raw-sqlite3 style gives directly).
**Secondary analog:** `test/unit/data/migrations/category_v14_migration_test.dart` (the `_runVNMigrationSteps`-as-contract pattern + data-UPDATE row-count/value assertions + the `AppDatabase.forTesting()` style).

**Pattern A — schemaVersion guard test** (`entry_source_v17_migration_test.dart:5-13`):
```dart
const _targetSchemaVersion = 17;   // → bump local const to 18 in the new test

void main() {
  test('AppDatabase schemaVersion includes v18 ledger_type migration', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    expect(db.schemaVersion, _targetSchemaVersion);   // 18
  });
  // ...
}
```
> **RESEARCH Wave-0 note:** do NOT edit `entry_source_v17_migration_test.dart:5`'s local `17` — add a sibling const `18` in the new file. v17 test keeps asserting against its own version-era table.

**Pattern B — raw-sqlite3 setup of v(N-1) table + insert old-value rows** (`entry_source_v17_migration_test.dart:16-26, 85-152`):
```dart
late Database rawDb;
setUp(() {
  rawDb = sqlite3.openInMemory();
  _createV17Tables(rawDb);   // create transactions + category_ledger_configs
                             // with the OLD CHECK(ledger_type IN ('survival','soul'))
});
tearDown(() => rawDb.dispose());

// _createV17... seeds the pre-migration schema; insert rows with old values:
//   ledger_type = 'survival' / 'soul'
//   category_ledger_configs.ledger_type = 'survival' / 'soul'
//   soul_satisfaction column present (will be renamed → joy_fullness)
```

**Pattern C — `_runVNMigrationSteps` is the contract; assert post-state** (`entry_source_v17_migration_test.dart:31-39, 63-70, 113-118` + `category_v14:103-189` data-UPDATE precedent):
```dart
test('rewrites survival→daily, soul→joy in transactions', () {
  _insertV17Tx(rawDb, 'tx_old', ledgerType: 'survival');
  _runV18MigrationSteps(rawDb);

  final rows = rawDb.select(
    "SELECT ledger_type FROM transactions WHERE id = 'tx_old'");
  expect(rows.first['ledger_type'], equals('daily'));
});

test('configs table accepts daily/joy and REJECTS survival/soul post-CHECK', () {
  _runV18MigrationSteps(rawDb);
  // accepts new vocab:
  _insertConfig(rawDb, 'cat_x', 'joy');   // no throw
  // rejects old vocab (table-recreate widened CHECK to IN('daily','joy')):
  expect(() => _insertConfig(rawDb, 'cat_y', 'soul'),
         throwsA(isA<SqliteException>()));
});

test('renames soul_satisfaction column to joy_fullness (D-16), data preserved', () {
  _insertV17Tx(rawDb, 'tx_sat', soulSatisfaction: 7);
  _runV18MigrationSteps(rawDb);
  final col = rawDb.select('PRAGMA table_info(transactions)')
      .where((r) => r['name'] == 'joy_fullness');
  expect(col.length, 1);
  final v = rawDb.select("SELECT joy_fullness FROM transactions WHERE id='tx_sat'");
  expect(v.first['joy_fullness'], equals(7));
});
```
> **`_runV18MigrationSteps(rawDb)` MUST mirror exactly the SQL placed in `onUpgrade` `if (from < 18)`** — this is the "contract" the v14 test header (L91-95) documents. Keep the two in lockstep.

**Row-count-invariant assertion to copy** (`category_v14_migration_test.dart:471-545`): assert `SELECT COUNT(*)` before == after to prove the value-rewrite + column-rename does not add/drop rows.

---

### NEW: `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` (config/doc)

**Analog (subject + cross-link target):** `ADR-015_Lexical_Hierarchy_v1_1.md` — same domain (locale vocab register). **Analog (section skeleton):** `ADR-016_Joy_Metric_Visualization_Redesign.md` — fullest recent ADR showing the project's Context → Considered Options → Decision append structure.

**Header block pattern** (`ADR-016` L1-13 / `ADR-015` L1-9). This project uses CN section headers + a mix of emoji section markers:
```markdown
# ADR-017: Terminology Unification v1.5 (词汇统一 v1.5)

**文档编号:** ADR-017
**文档版本:** 1.0
**创建日期:** 2026-06-01
**最后更新:** 2026-06-01
**状态:** ✅ 已接受 (Accepted — 2026-06-01)
**决策者:** zxsheanjp@gmail.com (project owner) + Claude (planning agent)
**影响范围:** v1.5 ledger vocab (ARB keys+values+@description), AppColors survival/soul + derived, LedgerType enum + v18 migration, soul*/survival* class/file names, soul_satisfaction→joy_fullness column (D-16)
**相关 ADR:** ADR-015 (Lexical Hierarchy — extended by this ADR), ADR-014 (Soul Satisfaction — display term relabeled to "fullness/充盈", record title preserved)
```

**Required content (D-14) — three sections to author:**
1. **Canonical locale vocab table** (mirror the CONTEXT.md table; same shape as ADR-015 §"三层 lexical hierarchy"):

   | Concept | zh | ja | en | identifier |
   |---|---|---|---|---|
   | Survival ledger | 日常 | 日常 (にちじょう) | Daily | `daily` |
   | Soul ledger | 悦己 | ときめき | Joy | `joy` |
2. **Identifier convention:** `survival→daily`, `soul→joy`, `soulSatisfaction→joyFullness` (D-07/D-08). Note the ja asymmetry (`joy` identifier ↔ ja value `ときめき`, coherent with `ときめき指数`).
3. **`LedgerType` enum-rename-with-v18-migration schema decision** + rationale: D-04 (hash-chain does NOT cover `ledger_type` — `hash_chain_service.dart:18` `SHA-256(id|amount|timestamp|prevHash)`) + D-03 (pre-release v0.1.0, no deployed peers → clean upgrade, no dual-string compat) + D-16 (soul_satisfaction column folded into same v18 migration).

**Decision-section / Status-flip convention** (`ADR-016` L12-13): once `✅ 已接受`, the doc enters append-only mode (`## Update YYYY-MM-DD: <topic>` only). Per `.claude/rules/arch.md`. Since ADR-017 is born accepted, include the append-only banner from the start.

**ADR-014 cross-link caveat** (RESEARCH §ADR-017 Creation Surface, ADR-014 wording check): ADR-014's filename + body keep "Soul Satisfaction" (historical record, append-only). ADR-017 only notes the *display-term* relabel to fullness/充盈; do NOT rename ADR-014.

---

### NEW MIGRATION BLOCK: `lib/data/app_database.dart` — `if (from < 18)` (migration, transform)

> Bump `schemaVersion => 17` to `18` (L45). Add a `from < 18` block at the end of `onUpgrade` (after the L270 `from < 17` block). The block has **THREE** sub-steps; ordering is critical (RESEARCH Pitfall 2).

**Sub-step 1 — table-recreate FIRST for the CHECK change** (analog: v8 sync_queue recreate, **same file L91-119**). Required because SQLite cannot `ALTER` a CHECK; the old CHECK `IN('survival','soul')` rejects `'daily'/'joy'`, so the new table must exist before inserting converted values:
```dart
// Source pattern: lib/data/app_database.dart:95-119 (v8 sync_queue recreate)
await customStatement(
  'ALTER TABLE category_ledger_configs RENAME TO category_ledger_configs_old');
await migrator.createTable(categoryLedgerConfigs);   // new def carries IN('daily','joy')
await customStatement('''
  INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
  SELECT category_id,
         CASE ledger_type WHEN 'survival' THEN 'daily'
                          WHEN 'soul'     THEN 'joy'
                          ELSE ledger_type END,
         updated_at
  FROM category_ledger_configs_old
''');
await customStatement('DROP TABLE category_ledger_configs_old');
```
> **A5 safeguard (RESEARCH):** verify `migrator.createTable` re-applies `customIndices`. If unsure, re-issue the two `CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_{ledger_type,updated_at}` from the v15 step (**same file L256-261**) unconditionally — cheap and idempotent.

**Sub-step 2 — plain data UPDATE for `transactions.ledger_type`** (analog: v14 data UPDATE, **same file L186-192**; `transactions` has no CHECK on `ledger_type`, so no recreate needed):
```dart
// Source pattern: lib/data/app_database.dart:187-192 (v14 UPDATE … WHERE)
await customStatement(
  "UPDATE transactions SET ledger_type = 'daily' WHERE ledger_type = 'survival'");
await customStatement(
  "UPDATE transactions SET ledger_type = 'joy'   WHERE ledger_type = 'soul'");
```

**Sub-step 3 — soul_satisfaction column rename (D-16)** via SQLite `ALTER TABLE … RENAME COLUMN` (data preserved, no recreate):
```dart
await customStatement(
  'ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness');
```
> The table-level CHECK in `transactions_table.dart:47` `CHECK(soul_satisfaction BETWEEN 1 AND 10)` references the OLD column name — it must be updated to `joy_fullness` in the fresh-install def. SQLite carries column-name references in CHECK through `RENAME COLUMN` automatically for existing DBs (verify in the migration test), but the **fresh-install table def** string must read `joy_fullness`.

**Atomicity wrapper** (analog: v13/v14 steps, **same file L142, L162**): wrap all three sub-steps in `await transaction(() async { ... });` so a partial migration cannot corrupt data (RESEARCH Security §Tampering mitigation).

**Pitfall 4 — DO NOT TOUCH historical literals:** the v5 step (`app_database.dart:70` `SELECT id, 'survival', …`) and the v14 seed (`L233 cfg.ledgerType.name`) must keep emitting the era-correct string. A device replaying v5→v18 must see `'survival'` at v5, then converted at v18. Only the **fresh-install table CHECK def** and the **new v18 block** carry the new vocab.

---

### MODIFY (atomic rename — no analog): Serena `rename_symbol` targets

These are **not** analog-based new code — they are atomic LSP-backed renames. Per CLAUDE.md / `rules/common/patterns.md`, **prefer Serena `rename_symbol`** (updates imports, refs, generated-companion call shapes) over `Edit replace_all` (which hits substring traps — RESEARCH Pitfall 5). Run `find_referencing_symbols` first to confirm site counts.

| Symbol | Old → New | Definition site | Notes |
|--------|-----------|-----------------|-------|
| `LedgerType` members | `survival→daily`, `soul→joy` | `transaction.dart:10` | 242 sites (83 lib + 159 test). Persisted by `.name` → MUST pair with the v18 migration + literal hand-edits below |
| `AppColors` (light) | `survival→daily`, `survivalLight→dailyLight`, `soul→joy`, `soulLight→joyLight` | `app_colors.dart:40-45` | `tagGreen` KEEPS its name; only its body `= soulLight` → `= joyLight` (D-11, hand-edit RHS) |
| `AppColorsDark` | `soulSatisfactionBg→joyFullnessBg`, `soulSatisfactionBorder→joyFullnessBorder`, `soulRoiBg→joyRoiBg`, `soulRoiBorder→joyRoiBorder` | `app_colors.dart:103-106` | `app_theme_colors.dart:46,48,50,52,60,62` getter BODIES update; getter names (`wmRoiBg`) stay |
| `Transaction.soulSatisfaction` field | `→ joyFullness` (D-16) | `transaction.dart` (Freezed) | pairs with DB column rename + sync-key change; build_runner regen |
| `SoulVsSurvivalCard`, `_SoulCell`, `_SurvivalCell` | `DailyVsJoyCard`, `_JoyCell`, `_DailyCell` | `soul_vs_survival_card.dart` | + `git mv` file → `daily_vs_joy_card.dart` |
| `SoulCelebrationOverlay` (+ State) | `JoyCelebrationOverlay` | `soul_celebration_overlay.dart` | + `git mv` |
| `PerCategorySoulBreakdown[Item]` | `PerCategoryJoyBreakdown[Item]` | `per_category_soul_breakdown.dart` | + `git mv` (+ `.freezed.dart` regen) |
| `GetSoulVsSurvivalSnapshot[AcrossBooks]UseCase` | `GetDailyVsJoySnapshot[AcrossBooks]UseCase` | use-case files | + `git mv` |
| `GetPerCategorySoulBreakdown[AcrossBooks]UseCase` | `GetPerCategoryJoyBreakdown[AcrossBooks]UseCase` | use-case files | + `git mv` |
| `SoulLedgerSnapshot`/`SurvivalLedgerSnapshot`/`SoulVsSurvivalSnapshot` (+ fields `soul/survival/familySoul/familySurvival`) | `JoyLedgerSnapshot`/`DailyLedgerSnapshot`/`DailyVsJoySnapshot` (+ `joy/daily/familyJoy/familyDaily`) | `ledger_snapshot.dart` | 24 field refs — A2 widest-ring |
| `PerCategorySoulRowRaw`, `SoulSatisfactionOverview`, `SoulRowSample`, `DailySoulRowSampleWithDay` | `PerCategoryJoyRowRaw`, `JoyFullnessOverview`, `JoyRowSample`, `DailyJoyRowSampleWithDay` | `analytics_dao.dart:83`, `analytics_aggregate.dart:36,47,55` | **TRAP:** `DailySoulRowSampleWithDay` leading `Daily` = calendar-day; rename ONLY `Soul→Joy` |

---

## Shared Patterns

### Persistence-literal co-update (NOT Serena-reachable — RESEARCH Pattern 3)
**Apply to:** every string literal `'survival'`/`'soul'`/`'soulSatisfaction'` embedded in raw SQL / JSON / seed that Serena's symbol rename does NOT see. These break a grep/test gate if missed.
**Sites (hand-edit, in lockstep with the enum + column rename):**
- `lib/data/tables/category_ledger_configs_table.dart:13` — CHECK literal `IN('survival','soul')` → `IN('daily','joy')` (fresh-install def)
- `lib/data/tables/transactions_table.dart:35,47` — `soulSatisfaction` column + `CHECK(soul_satisfaction …)` → `joyFullness` / `joy_fullness`
- `lib/data/daos/analytics_dao.dart:106,115` — raw SQL `ledger_type = 'soul'/'survival'`; plus any `AVG(soul_satisfaction)` → `AVG(joy_fullness)` (D-16)
- `lib/application/analytics/get_*_use_case.dart` (`:56,58`, `_across_books:77,79`), `get_monthly_report_use_case.dart:99,101` — `r.ledgerType == 'soul'/'survival'`
- `lib/application/analytics/demo_data_service.dart:110,132,172` — seed/demo literals
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart:19,50` (`ledgerType.name`) + the `'soulSatisfaction'` JSON key (D-16, D-03 clean — no dual-string path)
- Test fixtures with literal `'survival'/'soul'`: `transaction_sync_mapper_test.dart:36`, `apply_sync_operations_use_case_test.dart` (9), `shadow_book_service_test.dart:80`, `get_monthly_report_use_case_test.dart` (12), `get_soul_vs_survival_snapshot_use_case_test[_across_books]` → flip to `'daily'/'joy'` to keep suite green

### ADR append-only update
**Source pattern:** `ADR-016.md:159` (`> **2026-05-19 update:** …`) and L192 (`## Update 2026-05-19: Superseded by …`); rule in `.claude/rules/arch.md`.
**Apply to:** `ADR-015_Lexical_Hierarchy_v1_1.md` — append a one-line `## Update 2026-06-01: Extended by ADR-017` pointer at file end; do NOT edit the ADR-015 body.

### ADR INDEX entry
**Source pattern:** `ADR-000_INDEX.md:454, 480` entry format (`### [ADR-NNN: Title](./ADR-NNN_*.md)` + summary bullets) and the review-table row block (L556-566).
**Apply to:** add the ADR-017 entry + a review-table row.

### Codegen regeneration (RESEARCH Pitfall 3 — AUDIT-10 gate)
**Apply to:** after ARB key edits → `flutter gen-l10n`; after enum/Freezed/Drift edits → `flutter pub run build_runner build --delete-conflicting-outputs`. Commit generated output in the SAME commit. Never hand-edit `lib/generated/*`, `*.g.dart`, `*.freezed.dart`. `git diff --exit-code` on generated dirs must be clean.

### Drift TableIndex syntax (CLAUDE.md)
**Apply to:** the `category_ledger_configs` recreate — `customIndices` use `TableIndex(name: 'idx_…', columns: {#col})` (see `category_ledger_configs_table.dart:21-30`). No `Index()` constructor, no `@override`, `#`-symbol columns. Naming `idx_{table}_{columns}`.

---

## No Analog Found

None. Every NEW file has a strong in-repo analog; every modification is either in-place (own code is the pattern) or an atomic Serena rename. The phase introduces zero new behavior, so no novel role/data-flow appears.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | — |

---

## Metadata

**Analog search scope:** `test/unit/data/migrations/`, `lib/data/app_database.dart` (migration steps v5/v8/v14/v15/v17), `lib/data/tables/{category_ledger_configs,transactions}_table.dart`, `docs/arch/03-adr/ADR-{014,015,016,000-INDEX}.md`.
**Files scanned (read in full or targeted ranges):** 7.
**Key precedents identified:**
- Migration tests follow a `_runVNMigrationSteps(db)`-as-contract pattern — the test's helper SQL must mirror `onUpgrade`'s `if (from < N)` block verbatim.
- Two distinct migration shapes coexist in `app_database.dart`: plain data `UPDATE … WHERE` (v14) and table-rename → `createTable` → `INSERT…SELECT` → drop (v8) for schema-level changes; v18 needs BOTH plus an `ALTER … RENAME COLUMN`.
- ADRs use CN section headers, an append-only banner once `✅ 已接受`, and a fixed header metadata block (编号/版本/状态/影响范围/相关 ADR).
- Symbol renames are Serena-atomic; string literals in SQL/JSON/seed are invisible to Serena and need targeted hand-edits — missing either side breaks a gate.

**Pattern extraction date:** 2026-06-01
