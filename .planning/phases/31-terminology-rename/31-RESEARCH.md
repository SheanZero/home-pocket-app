# Phase 31: Terminology Rename - Research

**Researched:** 2026-06-01
**Domain:** Cross-cutting source/data rename (Flutter + Drift + ARB i18n + Dart symbols)
**Confidence:** HIGH (all findings verified by direct codebase grep; no external packages installed this phase)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Rename goes to the **widest ring** — all of: (a) ARB keys + values, (b) `AppColors.survival/.soul` + all derived color symbols, (c) the `LedgerType { survival, soul }` enum members, (d) the `soul*/survival*` Dart files and their class names. Nothing in the soul/survival vocabulary is left behind.
- **D-02:** **`LedgerType` enum is renamed** (`survival→daily`, `soul→joy`) despite being persisted by string name. Requires a **Drift schema migration v17→v18** that: (1) `UPDATE`s existing `transactions.ledger_type` and `category_ledger_configs.ledger_type` rows `'survival'→'daily'`, `'soul'→'joy'`; (2) updates the `category_ledger_configs` `CHECK(ledger_type IN ('survival','soul'))` constraint to `IN ('daily','joy')` (SQLite requires a table-recreate migration for a CHECK change).
- **D-03:** **No P2P sync backward-compat layer.** Pre-release (v0.1.0), no deployed peers. Clean upgrade — `transaction_sync_mapper` emits/reads new names; no dual-string acceptance path.
- **D-04:** **Hash chain is unaffected** — per-transaction hash is `SHA-256(transactionId|amount|timestamp|previousHash)` (`hash_chain_service.dart:18`); `ledger_type` is NOT hashed. Key safety fact enabling D-02.
- **D-05:** File + class renames use **Serena `rename_symbol`** (atomic cross-file) + **`git mv`** (preserve history). E.g. `SoulVsSurvivalCard → DailyVsJoyCard`, `soul_vs_survival_card.dart`, `per_category_soul_breakdown*`, `get_soul_vs_survival_snapshot[_across_books]_use_case`, `get_per_category_soul_breakdown[_across_books]_use_case`, `soul_celebration_overlay`.
- **D-06:** **REQUIREMENTS.md Out-of-Scope must be amended** to remove/qualify the "Migrating database column names/values … not schema" line, since D-02 now performs a source+data enum migration.
- **D-07:** Keys **redesigned semantically, not blind token-swap** — concept-token substitution preserving structure (`soul→joy`, `survival→daily`, keep prefix/case position), with targeted semantic corrections where the mechanical name is inaccurate.
- **D-08:** Specific correction: `soulSatisfaction → joyFullness` (value is 充盈度/fullness, not "satisfaction"). Correction propagates to color symbols (D-12).
- **D-09:** **Boundary:** apply to ledger-vocab keys **and their sibling keys in the same key-group** — NOT a global retaxonomy of all ~587 keys.
- **D-10:** The **full old→new key mapping table is surfaced in PLAN.md**. Per-key approval delegated to the D-07 principle (no per-key gate), but the complete table must be visible before execution.
- **D-11:** **Rename ALL derived color symbols now**: `survivalLight→dailyLight`, `soulLight→joyLight`, `soulRoiBg→joyRoiBg`, `soulRoiBorder→joyRoiBorder`, `soulSatisfactionBg→joyFullnessBg`, `soulSatisfactionBorder→joyFullnessBorder`. `tagGreen` keeps its name but its definition `= soulLight` becomes `= joyLight`.
- **D-12:** **Phase 33 coordination seam:** Phase 33 must treat these symbols as **already renamed** — only consolidates, does NOT re-rename.
- **D-13:** Create **new ADR-017 "Terminology Unification v1.5"** (next sequential; current max is ADR-016). Satisfies TERMID-04 via the successor path.
- **D-14:** ADR-017 records all three: (1) canonical locale vocab mapping, (2) identifier convention (D-07/D-08), (3) `LedgerType` enum-rename-with-migration schema decision incl. rationale (D-04 + D-03). Cross-link ADR-015.
- **D-15:** Append one-line pointer to ADR-015 ("extended by ADR-017 …") per append-only rule, and update `docs/arch/03-adr/ADR-000_INDEX.md`.

### Claude's Discretion
- **Migration / commit sequencing** delegated to planner — big-bang vs staged is a planner call. **Hard constraint:** every step keeps the build green (`flutter analyze` 0 issues, `build_runner` clean-diff, tests pass).
- Test fixtures / golden handling: tests hardcoding `'survival'/'soul'` and affected golden baselines must be updated to keep the suite green; full golden re-baseline is Phase 34's job, but Phase 31 must not leave the suite red.

### Deferred Ideas (OUT OF SCOPE)
- Global ARB key retaxonomy (re-prefixing/merging all ~587 keys) — only ledger-vocab key-groups (D-09).
- P2P sync backward-compat dual-string read path — deferred until a real release with mixed-version peers (D-03).
- Color token consolidation (duplicate constants, profile-dark dedup) — Phase 33's job (D-12).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TERM-01 | zh user-facing strings read 日常/悦己 everywhere | Stale-value inventory §"ARB Value-String Rewrite" — 22 zh value lines |
| TERM-02 | ja user-facing strings read 日常/ときめき everywhere | Stale-value inventory — 13 ja value lines (note: several ja values already correct, e.g. `homeSoulExpense`=ときめき支出) |
| TERM-03 | en user-facing strings read Daily/Joy everywhere | Stale-value inventory — 12 en value lines |
| TERM-04 | Grep over `lib/l10n/*.arb` values returns zero stale hits (excl @description) | Success-criterion grep §3; gate semantics analyzed in Validation Architecture |
| TERMID-01 | ARB keys renamed + call sites + `gen-l10n` clean | Old→New ARB Key Map (33 keys/locale); generated `S` getters regenerate from keys |
| TERMID-02 | Color symbols + dependent identifiers renamed, no stale refs | AppColors Symbol Rename Inventory (10 symbols + ~60 call sites) |
| TERMID-03 | `flutter analyze` 0 issues; generated regenerated; AUDIT-10 green | Validation Architecture; build_runner + gen-l10n sequence |
| TERMID-04 | ADR-015 or successor documents canonical mapping | ADR-017 creation surface §; D-13/D-14/D-15 |
</phase_requirements>

## Summary

Phase 31 is a **pure rename/refactor phase** — no new behavior, no external packages. The work spans five distinct surfaces that must all stay internally consistent and keep the build green at every commit: (1) **ARB keys** (33 keys per locale matching `soul`/`survival`), (2) **ARB user-facing values** (stale 生存/灵魂/魂/Survival/Soul strings), (3) **`AppColors` symbols** (10 symbols incl. derived, ~60 call sites), (4) the **`LedgerType` enum** (242 call sites + a Drift v17→v18 data+CHECK migration), and (5) **`soul*/survival*` file and class names** (9 files, ~16 class/symbol definitions, plus snapshot-model field names).

The single largest risk is **scope-boundary ambiguity on `soulSatisfaction`/`soul_satisfaction`**. CONTEXT.md D-08 names `soulSatisfaction → joyFullness` only for **ARB keys and color symbols**. But there is also a **persisted DB column `soul_satisfaction`** (`transactions_table.dart:35`), a Freezed field `Transaction.soulSatisfaction`, a sync-mapper JSON key `'soulSatisfaction'`, and ~50 call sites across DAOs/use-cases/tests. The locked decisions do **not** clearly state whether the DB column / Dart field is in scope. This must be resolved before planning (see Assumptions Log A1 + Open Question 1). My recommendation: **keep the DB column `soul_satisfaction` and the Dart field name as-is** for Phase 31 — it is orthogonal to the ledger-vocab rename, renaming it would force a *second* schema migration (column rename = table recreate) plus a sync-payload key change with no backward-compat (D-03 risk), and it is not named in any success criterion. Renaming only the ARB key `soulSatisfaction→joyFullness` and color symbols `soulSatisfaction*→joyFullness*` (exactly D-08's literal text) is self-consistent and grep-clean.

A second important finding: the **D-01 "widest ring" class surface is larger than the ~7 files CONTEXT.md enumerated.** Beyond the listed files there are domain-model classes `SoulLedgerSnapshot`, `SurvivalLedgerSnapshot`, `SoulVsSurvivalSnapshot`, `SoulSatisfactionOverview`, `SoulRowSample`, `DailySoulRowSampleWithDay`, `PerCategorySoulRowRaw`, and snapshot **field names** `familySoul`/`familySurvival`/`soul`/`survival`. Under a literal D-01 reading these should all be renamed. The planner should enumerate them explicitly (full list below).

**Primary recommendation:** Stage the work as ordered commits, each green: (1) `LedgerType` enum rename via Serena + the v18 migration + persistence-literal updates, as one atomic commit; (2) ARB keys + values + `gen-l10n` + call sites; (3) AppColors symbols + call sites; (4) file/class `git mv` + `rename_symbol`; (5) ADR-017 + index. Run `build_runner` after the enum rename and after ARB renames. Treat `soul_satisfaction` DB column as OUT of scope pending confirmation.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| User-facing vocab (ARB values) | i18n (`lib/l10n/*.arb`) | Presentation (consumes `S`) | Strings live in ARB; UI reads via generated `S` |
| ARB key identifiers | i18n + codegen (`lib/generated/`) | All consumers of `S.xxx` | Keys generate `S` getters; renaming a key renames the getter |
| Color symbols | Theme (`lib/core/theme/`) | Presentation call sites | `AppColors`/`AppColorsDark` are the single source; UI references them |
| `LedgerType` enum + persistence | Domain (`transaction.dart`) | Data (tables, DAOs, repos), Application (use cases), Infra (sync mapper) | Enum is domain; its `.name` is persisted by Data tier → migration is a Data concern |
| `ledger_type` stored values | Data / Storage (Drift + SQLCipher) | — | DB owns the persisted string; v18 migration rewrites rows + CHECK |
| Class/file names | Cuts across Domain + Application + Presentation | — | Symbols span tiers; Serena `rename_symbol` is tier-agnostic |

## Standard Stack

No new packages this phase. Existing toolchain used:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | ^2.25.0 [VERIFIED: pubspec.yaml] | Schema migration v17→v18 (data UPDATE + table-recreate for CHECK) | Project DB layer; existing `MigrationStrategy.onUpgrade` pattern |
| `drift_dev` | ^2.25.0 [VERIFIED: pubspec.yaml] | Regenerates `app_database.g.dart` after enum/table touch | Codegen partner of drift |
| `flutter gen-l10n` | Flutter SDK ^3.10.8 [VERIFIED: pubspec.yaml] | Regenerates `S` localizations after ARB key renames | Project i18n pipeline (`l10n.yaml` → class `S`) |
| `build_runner` | (transitive) | Regenerates `.g.dart`/`.freezed.dart` after enum + class renames | Required after `@freezed`/`@riverpod`/Drift changes (CLAUDE.md) |
| `custom_lint` + `import_guard_custom_lint` | ^0.8.1 / ^1.0.0 [VERIFIED: pubspec.yaml] | `dart run custom_lint --no-fatal-infos` gate (success criterion #4) | Project arch/lint enforcement |

### Tooling (rename mechanics)
| Tool | Purpose | When to Use |
|------|---------|-------------|
| Serena `rename_symbol` | Atomic cross-file symbol rename (updates imports/refs/types) | `LedgerType` members (242 sites), AppColors symbols, the 16 class names |
| Serena `find_referencing_symbols` | Pre-rename reference audit | Verify call-site count before each rename |
| `git mv` | File rename preserving history | The 9 `soul*/survival*` `.dart` files + golden `.png` fixtures |

**Installation:** None. No `## Package Legitimacy Audit` required — phase installs zero external packages.

**Version verification:**
```
drift / drift_dev pinned ^2.25.0 (pubspec.yaml lines 62, 87) — confirmed
flutter SDK ^3.10.8 (pubspec.yaml line 7) — confirmed
custom_lint ^0.8.1, import_guard_custom_lint ^1.0.0 (lines 85, 94) — confirmed
```

## Architecture Patterns

### System Architecture Diagram (rename data-flow)

```
                 ┌─────────────────────────────────────────────┐
   ARB keys ───► │ flutter gen-l10n → lib/generated/S getters   │ ──► Presentation widgets (S.of(context).joyLedger)
   ARB values    │  (rename key ⇒ rename getter ⇒ update calls) │
                 └─────────────────────────────────────────────┘

   LedgerType { daily, joy }  (transaction.dart — Serena rename_symbol)
        │
        ├─ .name ──► transaction_sync_mapper (emit/read JSON, D-03 clean)
        ├─ .name ──► transaction_repository_impl (firstWhere e.name==row.ledgerType)
        ├─ .name ──► category_ledger_config_repository_impl (values.byName)
        └─ persisted string ──► Drift columns:
                  transactions.ledger_type          ┐
                  category_ledger_configs.ledger_type├─ v18 migration: UPDATE rows + recreate CHECK
                  CHECK(ledger_type IN ('daily','joy'))┘
                  analytics_dao raw SQL  "ledger_type='joy'/'daily'"  ← MUST update literals
                  default_categories.dart _config(..., LedgerType.daily/.joy)  ← regenerates v18 seed
                  app_database.dart:70 migration v5 literal 'survival'  ← see Pitfall 4

   AppColors.{survival,soul,+derived} (app_colors.dart / app_colors_dark)
        └─ Serena rename_symbol ──► ~60 call sites + app_theme_colors.dart getter bodies

   Hash chain: SHA-256(id|amount|timestamp|prevHash)  ← ledger_type NOT included (D-04 safe)
```

### Recommended Project Structure
No structure change. Renamed files stay in place:
```
lib/application/analytics/  get_daily_vs_joy_snapshot[_across_books]_use_case.dart
                            get_per_category_joy_breakdown[_across_books]_use_case.dart
lib/features/analytics/domain/models/  per_category_joy_breakdown.dart
lib/features/analytics/presentation/widgets/  daily_vs_joy_card.dart
lib/features/dual_ledger/presentation/widgets/  joy_celebration_overlay.dart
```

### Pattern 1: Drift data-rewrite migration (data UPDATE)
**What:** Inside `onUpgrade`, gate by `if (from < 18)`, wrap in `transaction(() async {...})`, issue `customStatement('UPDATE ...')`.
**When to use:** Rewriting `ledger_type` row values `'survival'→'daily'`, `'soul'→'joy'`.
**Example (verified pattern from this codebase, v14 migration `app_database.dart:185-195`):**
```dart
// Source: lib/data/app_database.dart (v14 step, lines ~185-195)
await transaction(() async {
  await customStatement(
    'UPDATE transactions SET category_id = ? WHERE category_id = ?',
    [entry.value, entry.key],
  );
});
// v18 analogue:
//   UPDATE transactions SET ledger_type = 'daily' WHERE ledger_type = 'survival'
//   UPDATE transactions SET ledger_type = 'joy'   WHERE ledger_type = 'soul'
//   (same two statements for category_ledger_configs)
```

### Pattern 2: SQLite table-recreate for CHECK-constraint change
**What:** SQLite cannot `ALTER` a CHECK constraint. Rename old table, `migrator.createTable(newDef)`, `INSERT...SELECT`, drop old.
**When to use:** Changing `CHECK(ledger_type IN ('survival','soul'))` → `IN ('daily','joy')` on `category_ledger_configs`.
**Critical ordering:** The `INSERT...SELECT` must run **after** the value `UPDATE`, OR re-create the table first then insert already-converted values. Cleanest: UPDATE values first under the OLD-but-compatible CHECK is impossible (old CHECK rejects 'daily'/'joy'). So the **table-recreate must come first** (new table has new CHECK), then copy rows applying the value substitution in the `SELECT`.
**Example (verified pattern, v8 sync_queue recreate `app_database.dart:91-119`):**
```dart
// Source: lib/data/app_database.dart (v8 step, lines 95-119)
await customStatement('ALTER TABLE category_ledger_configs RENAME TO category_ledger_configs_old');
await migrator.createTable(categoryLedgerConfigs);  // new def carries IN ('daily','joy')
await customStatement('''
  INSERT INTO category_ledger_configs (category_id, ledger_type, updated_at)
  SELECT category_id,
         CASE ledger_type WHEN 'survival' THEN 'daily' WHEN 'soul' THEN 'joy' ELSE ledger_type END,
         updated_at
  FROM category_ledger_configs_old
''');
await customStatement('DROP TABLE category_ledger_configs_old');
// NOTE: indices idx_category_ledger_configs_ledger_type / _updated_at must be re-created
//       after recreate (they were created in v15 step; createTable applies customIndices).
```
**Verification needed by planner:** confirm `migrator.createTable` re-applies `customIndices` (it does in Drift 2.x via the table's `customIndices` getter) — otherwise re-issue the two `CREATE INDEX IF NOT EXISTS` from the v15 step.

### Pattern 3: Persistence-literal co-update (NOT covered by Serena)
**What:** Serena `rename_symbol` renames the *enum member*, but **string literals** `'survival'`/`'soul'` embedded in raw SQL and demo/seed code are invisible to it.
**Must hand-edit alongside the enum rename:**
- `lib/data/tables/category_ledger_configs_table.dart:13` — CHECK literal
- `lib/data/daos/analytics_dao.dart:106,115` — `"ledger_type = 'soul'/'survival'"` raw SQL filters
- `lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart:56,58` + `_across_books:77,79` — `r.ledgerType == 'soul'/'survival'`
- `lib/application/analytics/get_monthly_report_use_case.dart:99,101` — `lt.ledgerType == 'survival'/'soul'`
- `lib/application/analytics/demo_data_service.dart:110,132,172` — seed/demo string literals
- `lib/data/app_database.dart:70` — **DO NOT change** the v5 migration literal (Pitfall 4)

### Anti-Patterns to Avoid
- **`Edit replace_all 'soul'→'joy'`:** catches false positives (`soulSatisfaction`, `@description` text, `SoulVsSurvival` substrings) and misses casing. Use Serena symbol-aware rename + targeted literal edits.
- **Renaming the `soul_satisfaction` DB column "for consistency":** out of scope (Assumption A1), forces a second migration + sync-key break.
- **Bumping `schemaVersion` without a `from < 18` guarded step:** AUDIT-10/migration test will fail; fresh installs get the new table def, but existing-DB upgrade silently no-ops.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rename enum member across 242 sites | sed/`Edit replace_all` | Serena `rename_symbol` | Symbol-aware; updates imports & generated-companion call shapes; avoids substring false hits |
| Verify zero stale refs | manual scan | the 4 ROADMAP grep gates + `flutter analyze` | Gates are the contract; analyzer catches missed call sites as compile errors |
| Regenerate `S` getters after key rename | hand-edit `lib/generated/*.dart` | `flutter gen-l10n` | Generated files are guardrail-checked (AUDIT-10); hand edits desync |
| Regenerate `.g.dart`/`.freezed.dart` | hand-edit | `build_runner build --delete-conflicting-outputs` | CLAUDE.md rule #1 + AUDIT-10 stale-diff gate |
| CHECK-constraint change | `ALTER TABLE ... ADD CONSTRAINT` | table-recreate (Pattern 2) | SQLite has no ALTER CONSTRAINT |

**Key insight:** Two classes of references exist — **symbols** (rename via Serena, compiler-verified) and **string literals in SQL/JSON/seed** (hand-edit, grep-verified). Missing either breaks a gate. The enum rename is the only place both coexist.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | `transactions.ledger_type` and `category_ledger_configs.ledger_type` store the literal strings `'survival'`/`'soul'` (persisted via `LedgerType.name`). Any existing dev/test DB at schema v17 holds old values. | **Data migration** (v18 UPDATE) — D-02. Both code edit (enum) AND data UPDATE (rows) required; they are separate steps. |
| **Live service config** | None — app is local-first, zero external service stores this string. No n8n/Datadog/cloud config. | None — verified by architecture (local-first, CLAUDE.md). |
| **OS-registered state** | None — no Task Scheduler / launchd / pm2 registrations embed "soul"/"survival". | None — verified (mobile Flutter app, no host-process registration). |
| **Secrets/env vars** | None — no SOPS/.env key references "soul"/"survival". Encryption keys are content-agnostic (Ed25519/HKDF). | None — verified. |
| **Build artifacts / generated** | `lib/generated/app_localizations*.dart` (gen-l10n output) carry old getter names; `lib/data/app_database.g.dart` carries enum-dependent code; `*.freezed.dart`/`*.g.dart` for Transaction + snapshot models. Golden `.png` fixtures in `test/golden/goldens/` named `soul_vs_survival_card_*`. | **Regenerate** (gen-l10n + build_runner). **`git mv`** the golden PNGs alongside the test rename (D-05); Phase 34 owns re-baseline of pixel content, but file *names* move now. |

**Canonical question — after every repo file is updated, what runtime systems still hold the old string?** Only a **pre-existing on-device/in-test SQLCipher DB** at v17. The v18 migration is the sole runtime-state rewrite. No caches, no external registries. D-04 confirms the hash chain does not need recomputation.

## Detailed Rename Inventories

### 1. Old→New ARB Key Map (33 keys, identical key set in all 3 locales)

> Applies D-07 (concept-token substitution preserving structure) + D-08 (`soulSatisfaction→joyFullness`). Line numbers from `app_zh.arb` (same in ja/en).

| # | Old key | New key | Note |
|---|---------|---------|------|
| 1 | `survivalLedger` | `dailyLedger` | L153 |
| 2 | `soulLedger` | `joyLedger` | L157 |
| 3 | `survival` | `daily` | L161 (bare concept label) |
| 4 | `soul` | `joy` | L165 |
| 5 | `homeSurvivalExpense` | `homeDailyExpense` | L602 |
| 6 | `homeSoulExpense` | `homeJoyExpense` | L606 |
| 7 | `homeSurvivalLedgerTag` | `homeDailyLedgerTag` | L623 |
| 8 | `homeSoulLedgerTag` | `homeJoyLedgerTag` | L627 |
| 9 | `homeSoulFullness` | `homeJoyFullness` | L644 (already "Fullness"-semantic) |
| 10 | `homeSoulPercentLabel` | `homeJoyPercentLabel` | L648 |
| 11 | `homeRecentSoulTransaction` | `homeRecentJoyTransaction` | L726 |
| 12 | `homeSoulChargeStatus` | `homeJoyChargeStatus` | L738 |
| 13 | `homeNoSoulDataLegend` | `homeNoJoyDataLegend` | L837 |
| 14 | `homeRecentSoulExpense` | `homeRecentJoyExpense` | L1652 |
| 15 | `survivalExpense` | `dailyExpense` | L937 |
| 16 | `soulExpense` | `joyExpense` | L941 |
| 17 | `soulSatisfaction` | `joyFullness` | L945 — **D-08 semantic correction** |
| 18 | `analyticsSurvivalVsSoul` | `analyticsDailyVsJoy` | L1721 |
| 19 | `analyticsCardTitlePerCategorySoul` | `analyticsCardTitlePerCategoryJoy` | L2025 |
| 20 | `analyticsCardTitlePerCategorySoulYou` | `analyticsCardTitlePerCategoryJoyYou` | L2026 |
| 21 | `analyticsCardTitlePerCategorySoulFamily` | `analyticsCardTitlePerCategoryJoyFamily` | L2027 |
| 22 | `analyticsLedgerColumnSoul` | `analyticsLedgerColumnJoy` | L2058 |
| 23 | `analyticsLedgerColumnSurvival` | `analyticsLedgerColumnDaily` | L2059 |
| 24 | `listLedgerSurvival` | `listLedgerDaily` | L2135 |
| 25 | `listLedgerSoul` | `listLedgerJoy` | L2139 |

> **D-09 sibling-group review:** keys #5–8 (`home*Expense`/`home*LedgerTag`), #15–17 (chip + slider group), #22–23 + #24–25 (column/filter pairs) are renamed as groups. Verified there are no *other* same-prefix neighbors carrying the old vocab beyond these. The `analyticsKpiJoyIndex*` / `best_joy` keys already use the new "joy" vocab in their **keys** (only their zh/ja **values** carry stale 魂 — see value rewrite below). **25 distinct key roots × per-locale = 25 keys/locale** (the `analyticsCardTitle*` set is 3 keys; total = 25 key renames). Each rename also renames the matching `@key` metadata block.

**Generated impact:** each renamed key renames the `String get <key>` getter in `lib/generated/app_localizations*.dart` (4 files) — regenerated by `gen-l10n`, then every `S.of(context).<oldKey>` call site updates. Call sites are compiler-verified (analyze fails on stale → safety net).

### 2. ARB Value-String Rewrite (stale user-facing values, EXCLUDING @description)

> Success-criterion grep #3 excludes `@description` metadata. These are the value lines that must change. ja note: several ja values are *already* correct (e.g. `homeSoulExpense`="ときめき支出"), so ja has fewer rewrites.

**zh (`app_zh.arb`) — values to rewrite:**
| Line | Key | Old value | → target vocab |
|------|-----|-----------|----------------|
| 161 | `survival`/`daily` | 生存 | 日常 |
| 165 | `soul`/`joy` | 灵魂 | 悦己 |
| 602 | homeDailyExpense | 生存支出 | 日常支出 |
| 606 | homeJoyExpense | 灵魂支出 | 悦己支出 |
| 648 | homeJoyPercentLabel | 本月灵魂支出占比 | 本月悦己支出占比 |
| 738 | homeJoyChargeStatus | 灵魂充盈度 … | 悦己充盈度 … |
| 845 | homeBestJoyEmptyBig | 记录第一笔魂账 | 记录第一笔悦己账 |
| 937 | dailyExpense | 生存支出 | 日常支出 |
| 941 | joyExpense | 灵魂支出 | 悦己支出 |
| 945 | joyFullness | 灵魂充盈度 | 悦己充盈度 |
| 1652 | homeRecentJoyExpense | 最近灵魂支出 | 最近悦己支出 |
| 1721 | analyticsDailyVsJoy | 生存 vs 灵魂 | 日常 vs 悦己 |
| 1898 | analyticsKpiJoyIndexEmptyCaption | 给魂账条目… | 给悦己账条目… |
| 2018 | analyticsFamilyEmpty | …多记几笔魂账试试 | …多记几笔悦己账试试 |
| 2019 | analyticsThinSampleFallbackHeading | 魂账记录不足 5 笔 | 悦己账记录不足 5 笔 |
| 2058 | analyticsLedgerColumnJoy | 灵魂 | 悦己 |
| 2059 | analyticsLedgerColumnDaily | 生存 | 日常 |
| 2135 | listLedgerDaily | 生存 | 日常 |
| 2139 | listLedgerJoy | 灵魂 | 悦己 |

**ja (`app_ja.arb`) — values to rewrite:**
| Line | Key | Old value | → target vocab |
|------|-----|-----------|----------------|
| 161 | daily | 生存 | 日常 |
| 165 | joy | 魂 | ときめき |
| 648 | homeJoyPercentLabel | 今月の魂支出の割合 | 今月のときめき支出の割合 |
| 738 | homeJoyChargeStatus | 魂の充実度 … | ときめきの充実度 …（or 充盈度 — match zh intent） |
| 937 | dailyExpense | 生存支出 | 日常支出（or 暮らしの支出 — match L602 style） |
| 941 | joyExpense | 魂支出 | ときめき支出 |
| 945 | joyFullness | 魂の充盈度 | ときめき充盈度 |
| 1652 | homeRecentJoyExpense | 最近の魂支出 | 最近のときめき支出 |
| 1721 | analyticsDailyVsJoy | 生存 vs 魂 | 日常 vs ときめき |
| 1898 | analyticsKpiJoyIndexEmptyCaption | 魂の記録に… | ときめきの記録に… |
| 2019 | analyticsThinSampleFallbackHeading | 魂帳の記録がまだ少ないよ | ときめき帳の記録がまだ少ないよ |
| 2059 | analyticsLedgerColumnDaily | 生活 | 日常 (currently 生活, not 生存 — normalize to 日常) |
| 2135 | listLedgerDaily | 生存 | 日常 |
| 2139 | listLedgerJoy | 魂 | ときめき |

> ja already-correct (no change): L602 暮らしの支出, L606 ときめき支出, L644 ときめき度, L2025-2027 ときめき·カテゴリ, L2058 ときめき. **Planner decision (D-07 discretion):** whether to normalize the existing ja "暮らしの" / "生活" phrasings to literal 日常 or keep the softer phrasing. TERM-02 says "reads 日常 (never 生存)" — 暮らし/生活 are not 生存 so they pass the *grep gate*, but normalizing to 日常 is the spirit. Flag for planner.

**en (`app_en.arb`) — values to rewrite:**
| Line | Key | Old value | → target |
|------|-----|-----------|----------|
| 161 | daily | Survival | Daily |
| 165 | joy | Soul | Joy |
| 648 | homeJoyPercentLabel | Soul spending ratio | Joy spending ratio (or Daily? — it's the joy ratio; "Joy") |
| 738 | homeJoyChargeStatus | Soul Fullness … | Joy Fullness … |
| 937 | dailyExpense | Survival | Daily |
| 941 | joyExpense | Soul | Joy |
| 945 | joyFullness | Soul Fullness | Joy Fullness |
| 1652 | homeRecentJoyExpense | Recent Soul Expense | Recent Joy Expense |
| 1721 | analyticsDailyVsJoy | Survival vs Soul | Daily vs Joy |
| 2058 | analyticsLedgerColumnJoy | Soul | Joy |
| 2059 | analyticsLedgerColumnDaily | Survival | Daily |
| 2135 | listLedgerDaily | Survival | Daily |
| 2139 | listLedgerJoy | Soul | Joy |

> en already-correct: L602 Living Expenses, L606 Joy Expenses, L644 Joy Index, L2025-2027 Joy·Categories, L623/627 S/J tags. **Planner note:** L602 "Living Expenses" contains no stale term (passes grep) — keep or normalize to "Daily Expenses" per D-07.

### 3. AppColors Symbol Rename Inventory (D-11)

**`lib/core/theme/app_colors.dart` (light) definitions:**
| Line | Old symbol | New symbol |
|------|-----------|-----------|
| 40 | `survival` | `daily` |
| 41 | `survivalLight` | `dailyLight` |
| 44 | `soul` | `joy` |
| 45 | `soulLight` | `joyLight` |
| 46 | `tagGreen = soulLight` | `tagGreen = joyLight` (name kept, def updated — D-11) |

**`AppColorsDark` (same file, lines 103-106) definitions:**
| Line | Old symbol | New symbol |
|------|-----------|-----------|
| 103 | `soulSatisfactionBg` | `joyFullnessBg` |
| 104 | `soulSatisfactionBorder` | `joyFullnessBorder` |
| 105 | `soulRoiBg` | `joyRoiBg` |
| 106 | `soulRoiBorder` | `joyRoiBorder` |

**Theme getter bodies referencing the dark symbols** (`app_theme_colors.dart:46,48,50,52,60,62`) — update RHS only; getter *names* (`wmRoiBg`, etc.) are not old-vocab and stay.

**Call sites (success-criterion #2 grep `AppColors\.survival|AppColors\.soul`):** ~60 references across 19 files. Serena `rename_symbol` on each `AppColors`/`AppColorsDark` const will update all. Full file list (verified): `ocr_review_screen`, `transaction_edit_screen`, `voice_input_screen`, `ocr_scanner_screen`, `transaction_details_form`, `smart_keyboard`, `satisfaction_emoji_picker`, `voice_waveform`, `amount_display`, `ledger_type_selector`, `home_screen`, `home_hero_card`, `home_transaction_tile`, `hero_header`, `list_screen`, `list_sort_filter_bar`, `list_transaction_tile`, `group_choice_screen`, `largest_expense_story_card`, `soul_vs_survival_card`, `best_joy_story_strip`, `monthly_spend_trend_bar_chart`, `joy_ledger_thin_sample_fallback`, `category_spend_donut_chart`, `total_spending_kpi_tile`, `satisfaction_distribution_histogram`, `joy_headline_kpi_tile`. Plus the doc-comment `app_theme_colors.dart:9` (`AppColors.survival` in a `///` comment — grep #2 will flag it; update the comment).

### 4. LedgerType Enum + Persistence Surface (D-02)

- **Definition:** `lib/features/accounting/domain/models/transaction.dart:10` — `enum LedgerType { survival, soul }` → `{ daily, joy }`.
- **Call sites:** 83 in `lib/`, 159 in `test/` = **242 total** (`LedgerType.survival`/`.soul`). Top files: `default_categories.dart` (28), `rule_engine.dart` (14), `merchant_database.dart` (12), `list_sort_filter_bar.dart` (12). Serena `rename_symbol` on the two members handles all.
- **`.name`-persistence read sites:** `transaction_repository_impl.dart:202` (`firstWhere((e) => e.name == row.ledgerType)`), `category_ledger_config_repository_impl.dart:65` (`LedgerType.values.byName(row.ledgerType)`). These read **whatever string is in the DB** — they work automatically once v18 has rewritten rows AND the enum members are renamed (`byName('daily')` resolves).
- **Sync mapper:** `transaction_sync_mapper.dart:19` emits `ledgerType.name`, `:50` reads `LedgerType.values.byName(data['ledgerType'])`. D-03 clean upgrade — no dual-string path.
- **CHECK constraint:** `category_ledger_configs_table.dart:13` `"NOT NULL CHECK(ledger_type IN ('survival', 'soul'))"` → `IN ('daily', 'joy')` (fresh-install def) + v18 table-recreate (existing DBs).
- **Raw-SQL literals (hand-edit):** `analytics_dao.dart:106,115`.
- **String-comparison literals (hand-edit):** `get_soul_vs_survival_snapshot_use_case.dart:56,58`, `_across_books:77,79`, `get_monthly_report_use_case.dart:99,101`, `demo_data_service.dart:110,132,172`.
- **Seed:** `default_categories.dart:1193-1200+` `_config('cat_x', LedgerType.survival/.soul)` — Serena renames the member refs; the v14 migration step that seeds via `cfg.ledgerType.name` will then emit `'daily'/'joy'` for fresh v14→v18 paths (consistent).
- **D-04 safety confirmed:** `hash_chain_service.dart:18` input = `'$transactionId|$amount|$timestamp|$previousHash'` — `ledger_type` absent. Rewriting stored values does NOT invalidate the chain.

### 5. File + Class Rename Inventory (D-05)

> **Wider than the ~7 files CONTEXT.md listed.** Full surface below. Use `git mv` for files + Serena `rename_symbol` for class/type names.

**Files to `git mv` (lib/):**
| Old path | New path |
|----------|----------|
| `application/analytics/get_soul_vs_survival_snapshot_use_case.dart` | `get_daily_vs_joy_snapshot_use_case.dart` |
| `application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart` | `get_daily_vs_joy_snapshot_across_books_use_case.dart` |
| `application/analytics/get_per_category_soul_breakdown_use_case.dart` | `get_per_category_joy_breakdown_use_case.dart` |
| `application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart` | `get_per_category_joy_breakdown_across_books_use_case.dart` |
| `features/analytics/domain/models/per_category_soul_breakdown.dart` (+ `.freezed.dart` regen) | `per_category_joy_breakdown.dart` |
| `features/analytics/presentation/widgets/soul_vs_survival_card.dart` | `daily_vs_joy_card.dart` |
| `features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart` | `joy_celebration_overlay.dart` |

**Test files + golden PNGs to `git mv`:**
- `test/golden/soul_vs_survival_card_golden_test.dart` → `daily_vs_joy_card_golden_test.dart`
- `test/golden/goldens/soul_vs_survival_card_{light,dark,group_light,group_dark}_ja.png` → `daily_vs_joy_card_*_ja.png` (4 files; pixel content re-baselined in Phase 34)
- `test/widget/.../soul_celebration_overlay_test.dart`, `soul_vs_survival_card_test.dart`, and the 4 `get_*soul*`/`per_category_soul*` unit test files → matching new names.

**Class / type names to `rename_symbol`:**
| Old | New | File |
|-----|-----|------|
| `SoulCelebrationOverlay` (+ `_SoulCelebrationOverlayState`) | `JoyCelebrationOverlay` | joy_celebration_overlay.dart |
| `PerCategorySoulBreakdownItem` | `PerCategoryJoyBreakdownItem` | per_category_joy_breakdown.dart |
| `PerCategorySoulBreakdown` | `PerCategoryJoyBreakdown` | " |
| `SoulVsSurvivalCard`, `_SoulCell`, `_SurvivalCell` | `DailyVsJoyCard`, `_JoyCell`, `_DailyCell` | daily_vs_joy_card.dart |
| `GetSoulVsSurvivalSnapshotUseCase` | `GetDailyVsJoySnapshotUseCase` | use case |
| `GetSoulVsSurvivalSnapshotAcrossBooksUseCase` | `GetDailyVsJoySnapshotAcrossBooksUseCase` | use case |
| `GetPerCategorySoulBreakdownUseCase` | `GetPerCategoryJoyBreakdownUseCase` | use case |
| `GetPerCategorySoulBreakdownAcrossBooksUseCase` | `GetPerCategoryJoyBreakdownAcrossBooksUseCase` | use case |
| `SoulLedgerSnapshot` | `JoyLedgerSnapshot` | ledger_snapshot.dart |
| `SurvivalLedgerSnapshot` | `DailyLedgerSnapshot` | ledger_snapshot.dart |
| `SoulVsSurvivalSnapshot` (+ fields `soul`,`survival`,`familySoul`,`familySurvival`) | `DailyVsJoySnapshot` (+ `joy`,`daily`,`familyJoy`,`familyDaily`) | ledger_snapshot.dart — **24 field refs** |
| `PerCategorySoulRowRaw` | `PerCategoryJoyRowRaw` | analytics_dao.dart:83 |
| `SoulSatisfactionOverview` | see Assumption A1 — likely `JoyFullnessOverview` (D-08 propagation) but uses `soul_satisfaction` data | analytics_aggregate.dart:36 |
| `SoulRowSample` | `JoyRowSample` | analytics_aggregate.dart:47 |
| `DailySoulRowSampleWithDay` | `DailyJoyRowSampleWithDay` | analytics_aggregate.dart:55 (note "Daily" prefix already means calendar-day — disambiguate) |

> **Planner caution:** `DailySoulRowSampleWithDay` — the leading `Daily` here means *calendar day*, not the survival-ledger. Renaming `Soul→Joy` gives `DailyJoyRowSampleWithDay` which is fine, but do NOT also touch the leading `Daily`. This is exactly the kind of substring trap that forbids blind replace.

### Test/Golden fixtures hardcoding `'survival'/'soul'` (keep-suite-green)

String-literal `'survival'`/`'soul'` (not `LedgerType.x`) appear in: `transaction_sync_mapper_test.dart:36`, `apply_sync_operations_use_case_test.dart` (9 sites), `shadow_book_service_test.dart:80`, `get_monthly_report_use_case_test.dart` (12 sites), `get_soul_vs_survival_snapshot_use_case_test.dart` + `_across_books` (`_ledger('soul'/'survival', …)` helpers). These assert serialized payloads / build fixtures with the literal string → **must flip to `'daily'/'joy'`** in lockstep with the enum + sync changes or the suite goes red. The `LedgerType.x` references (159 test sites) are handled by Serena. Golden PNG **pixel** re-baseline is Phase 34; Phase 31 only renames the golden **files** and updates any `'survival'/'soul'` string assertions so the suite compiles and non-golden tests pass.

## ADR-017 Creation Surface (D-13/D-14/D-15)

- **Next number:** current max is `ADR-016_Joy_Metric_Visualization_Redesign.md` → create `ADR-017_Terminology_Unification_v1_5.md` [VERIFIED: `ls docs/arch/03-adr/`].
- **Content (D-14):** (1) canonical locale table 日常/悦己/ときめき/Daily/Joy; (2) identifier convention `survival→daily`, `soul→joy`, `soulSatisfaction→joyFullness` (D-07/D-08); (3) the LedgerType enum-rename-with-v18-migration decision + rationale (D-04 hash-chain-safe, D-03 pre-release-no-peers). Cross-link ADR-015 + ADR-014 (the "satisfaction" metric being relabeled "fullness").
- **Append to ADR-015** (`ADR-015_Lexical_Hierarchy_v1_1.md`): one-line `## Update YYYY-MM-DD` pointer "extended by ADR-017 …" per the append-only rule (`.claude/rules/arch.md`). Do NOT edit ADR-015 body.
- **Update `ADR-000_INDEX.md`** with the ADR-017 entry.
- **ADR-014 wording check (D-14 cross-link):** ADR-014 is titled "Soul_Satisfaction_Unipolar_Positive_Scale" — its filename + body use "Soul Satisfaction". Per append-only ADR rule it is **not renamed**; ADR-017 notes the relabel of the *display* term to "fullness/充盈" while the ADR-014 *decision record* keeps its historical title.

## Common Pitfalls

### Pitfall 1: `soulSatisfaction` scope creep (HIGHEST RISK)
**What goes wrong:** Treating D-08 `soulSatisfaction→joyFullness` as license to rename the DB column `soul_satisfaction`, the Freezed field `Transaction.soulSatisfaction`, and the sync key `'soulSatisfaction'`.
**Why it happens:** Same token; "widest ring" (D-01) seems to imply it.
**How to avoid:** D-08's literal text scopes it to "ARB keys … propagates to color symbols too." The DB column / Dart field / sync key are **not** named anywhere in CONTEXT.md or the success criteria. Renaming the column = a *second* table-recreate migration + a sync-payload key break (no D-03 compat path) + ~50 more call sites. **Recommend OUT of scope** (Assumption A1, Open Question 1). Confirm with user before planning.
**Warning signs:** A plan task touching `transactions_table.dart:35` `IntColumn get soulSatisfaction`, `analytics_dao.dart` `AVG(soul_satisfaction)`, or `transaction_sync_mapper.dart:32` `'soulSatisfaction'`.

### Pitfall 2: CHECK migration ordering
**What goes wrong:** `UPDATE`ing `category_ledger_configs.ledger_type` to `'daily'/'joy'` *before* the CHECK is widened → old CHECK rejects the new value, migration throws.
**Why it happens:** Intuition says "update data, then schema."
**How to avoid:** Table-recreate FIRST (new table carries `IN ('daily','joy')`), copy rows applying the `CASE` substitution in the `INSERT...SELECT` (Pattern 2). For `transactions` (no CHECK on ledger_type) a plain `UPDATE` is fine.
**Warning signs:** Migration test failing with a CONSTRAINT error on the configs table.

### Pitfall 3: gen-l10n / build_runner ordering and the AUDIT-10 gate
**What goes wrong:** Committing renamed ARB keys without running `gen-l10n`, or renaming the enum without `build_runner` → stale `lib/generated/` and `*.g.dart` → AUDIT-10 stale-diff CI step fails (audit.yml:91-96).
**How to avoid:** After ARB key edits run `flutter gen-l10n`; after enum/class/Freezed edits run `build_runner build --delete-conflicting-outputs`; commit generated output in the same commit. Never hand-edit `lib/generated/*` (CLAUDE.md).
**Warning signs:** `git diff` shows generated files differ after a clean `build_runner` run.

### Pitfall 4: Historical migration literals (`app_database.dart:70`)
**What goes wrong:** "Fixing" the `'survival'` literal in the **v5** migration step to `'daily'` for consistency.
**Why it happens:** Grep for `'survival'` surfaces it.
**How to avoid:** That literal seeds rows during a v<5 → v5 upgrade. Those rows are later rewritten by the **v18** step. Changing the v5 literal rewrites *history* and is wrong — a device replaying v5 then v18 must see `'survival'` at v5, then converted at v18. **Leave v5/v14 historical literals untouched.** Only the **fresh-install table def** (CHECK literal) and the **v18 step** carry the new vocab. (`grep "'survival'" lib/data/app_database.dart` will still find the v5/v14 lines — this is intentional and NOT a success-criterion target; the gates only scan `lib/l10n/` and `AppColors.`.)
**Warning signs:** A diff touching `app_database.dart` lines below the new `if (from < 18)` block.

### Pitfall 5: Substring traps in blind rename
**What goes wrong:** `replace_all soul→joy` hits `soulSatisfaction`, `@description "Soul ledger label"`, `DailySoulRowSampleWithDay` (the `Daily` prefix), `Color.lerp(AppColors.survival, AppColors.soul, …)`.
**How to avoid:** Serena symbol-aware rename for symbols; per-line targeted edits for the literal/value/description sets enumerated above. The four ROADMAP grep gates are the final verification, not the editing tool.

## Validation Architecture

> nyquist_validation is enabled (config.json `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter SDK ^3.10.8) + `drift`/`sqlite3` for migration tests |
| Config file | none custom — standard `flutter test`; golden via `flutter_test` matchesGoldenFile |
| Quick run command | `flutter test test/unit/data/migrations/` (migration only) |
| Full suite command | `flutter test` then `flutter test --coverage` (≥80% per CLAUDE.md) |

### Phase Requirements → Test/Gate Map
| Req | Behavior | Type | Automated command | Exists? |
|-----|----------|------|-------------------|---------|
| TERM-04 (zh/ja/en values) | No stale vocab in ARB **values** | grep gate | `grep -nE '^\s*"[a-zA-Z][^"]*"\s*:\s*"[^"]*(生存\|灵魂\|魂\|ソウル\|Survival\|Soul)' lib/l10n/*.arb` ⇒ 0 hits (value lines only) | gate; **needs value-only filter** (see Note) |
| TERMID-01 | No `soul`/`survival` ARB **keys** | grep gate | `grep -rnE '"[^"]*(soul\|survival\|Soul\|Survival)[^"]*"\s*:' lib/l10n/*.arb` ⇒ 0 (excl @-metadata) | gate |
| TERMID-02 | No `AppColors.survival/.soul` refs | grep gate | `grep -rn 'AppColors\.survival\|AppColors\.soul' lib/` ⇒ 0 (also catches doc-comment L9 — update it) | gate |
| TERMID-02/03 | No derived stale color symbols | grep gate | `grep -rnE '\b(soulLight\|survivalLight\|soulRoi\|soulSatisfaction(Bg\|Border))\b' lib/` ⇒ 0 | gate |
| TERMID-03 | Build clean | analyzer | `flutter analyze` ⇒ 0 issues; `dart run custom_lint --no-fatal-infos` ⇒ 0 errors | gate |
| TERMID-03 | Generated consistent | codegen diff | `flutter gen-l10n && flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/generated lib/**/*.g.dart lib/**/*.freezed.dart` ⇒ clean (AUDIT-10) | gate |
| D-02 | v18 migration rewrites rows + CHECK | unit | `flutter test test/unit/data/migrations/` (new `ledger_type_v18_migration_test.dart` — Wave 0) | ❌ Wave 0 |
| D-02 | schemaVersion == 18 | unit | `flutter test test/unit/data/migrations/` (assert `db.schemaVersion == 18`) | ❌ Wave 0 |
| Suite green | No red tests from rename | full | `flutter test` ⇒ all pass (golden pixel diffs deferred to P34 — exclude/skip golden or accept temp baselines) | existing |

> **Note on TERM-04 grep semantics:** The ROADMAP criterion #3 grep `grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb` as literally written will ALSO match `@description` lines (e.g. "Survival ledger label") and is documented to *exclude* @description metadata. The **automatable** form must filter to value lines only (the regex above) OR the planner must rewrite the stale-sounding `@description` texts too (lowest-effort: update descriptions like "Soul ledger label" → "Joy ledger label" so even the naive grep passes — this is the safer, gate-proof choice). **Recommend updating @description texts as well** to make the naive grep zero-hit, even though TERM-04 technically permits leaving them.

### Sampling Rate
- **Per task commit:** the relevant grep gate(s) for that surface + `flutter analyze`.
- **Per wave merge:** `flutter gen-l10n` + `build_runner` + `git diff --exit-code` (generated), then `flutter test test/unit/data/migrations/`.
- **Phase gate:** all 4 ROADMAP greps zero, `flutter analyze` 0, `custom_lint` 0, full `flutter test` green, ADR-017 present.

### Wave 0 Gaps
- [ ] `test/unit/data/migrations/ledger_type_v18_migration_test.dart` — covers D-02: assert `schemaVersion == 18`; insert v17 rows with `'survival'/'soul'`, run `_runV18MigrationSteps`, assert rows now `'daily'/'joy'`, assert configs table accepts `'daily'/'joy'` and rejects `'survival'/'soul'` post-CHECK. Model on existing `entry_source_v17_migration_test.dart` + `category_v14_migration_test.dart` (`_runVNMigrationSteps` contract pattern).
- [ ] Bump `_targetSchemaVersion` constant in the other migration tests if they assert a global version (verify `entry_source_v17_migration_test.dart:4` uses a local `17` — a v18 bump may need a sibling, not a change to v17's test).
- No framework install needed — `flutter_test` + `sqlite3` already present.

## Security Domain

> `security_enforcement` not set false in config — included.

This is a label/identifier rename with one data migration. No new attack surface.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes (low) | CHECK constraint `IN ('daily','joy')` continues to constrain stored values; sync mapper `byName` throws on unknown — acceptable (D-03 clean upgrade, no untrusted old peers) |
| V6 Cryptography | yes (verify-only) | **Hash chain integrity (D-04):** confirmed `ledger_type` is NOT in `SHA-256(id\|amount\|timestamp\|prevHash)`. Rewriting stored values does NOT break chain verification. No crypto code changes. |
| V2/V3/V4 | no | No auth/session/access-control surface touched |

| Threat Pattern | STRIDE | Mitigation |
|----------------|--------|------------|
| Migration corrupts data / partial UPDATE | Tampering/DoS | Wrap v18 in `transaction(() async {…})` (atomic); migration unit test verifies row conversion |
| `byName` throws on a stray old value post-migration | DoS | v18 UPDATE covers all rows; CHECK recreate prevents new old-values; tests assert |
| Hash chain false-invalidation | Repudiation | D-04 — not in hashed payload; no recompute needed (verified `hash_chain_service.dart:18`) |

## Project Constraints (from CLAUDE.md / rules)

- **Generated files:** never hand-edit `.g.dart`/`.freezed.dart`/`lib/generated/*`; regenerate. AUDIT-10 CI blocks stale generated diffs.
- **build_runner mandatory** after `@riverpod`/`@freezed`/Drift/ARB changes and after merge/rebase.
- **Drift `TableIndex` syntax:** the configs table recreate must re-apply `customIndices` with `TableIndex(name: 'idx_…', columns: {#col})` syntax (no `Index()`, no `@override`).
- **Riverpod 3:** no provider rename expected this phase, but if a `*soul*`-named provider exists, the generated name strips `Notifier` and uses the symbol name — verify after rename. (No soul/survival-named providers found in this audit.)
- **i18n:** all 3 ARB files updated together; run `flutter gen-l10n`; UI text only via `S.of(context)`.
- **iOS pins:** untouched — no pubspec dependency changes this phase.
- **Zero analyzer warnings** before commit; don't suppress with `// ignore:`.
- **Serena preferred** for symbol renames (`rename_symbol`, `find_referencing_symbols`) per `rules/common/patterns.md`.
- **Worklog:** generate a `docs/worklog/YYYYMMDD_HHMM_*.md` on task completion (`.claude/rules/worklog.md`).
- **ADR rules** (`.claude/rules/arch.md`): next sequential number (017), append-only for ADR-015, update INDEX.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The DB column `soul_satisfaction` / Freezed field `Transaction.soulSatisfaction` / sync key `'soulSatisfaction'` are **OUT of scope** for Phase 31 (only the ARB key `soulSatisfaction→joyFullness` and color symbols `soulSatisfaction*→joyFullness*` per D-08 literal text). | Summary, Pitfall 1, Inventory 5 | If user intended the column renamed too: a second table-recreate migration, sync-payload key change (D-03 break), and ~50 extra call sites are missing from the plan. **HIGH — confirm before planning.** [ASSUMED] |
| A2 | D-01 "widest ring" includes the analytics snapshot **classes and field names** (`SoulLedgerSnapshot`, `familySoul`, etc.), not just the 7 files CONTEXT.md enumerated. | Inventory 5 | If only the 7 listed files are wanted, the plan over-scopes ~9 extra classes + 24 field refs. Lower risk (over-delivery), but changes effort estimate. [ASSUMED] |
| A3 | `@description` metadata texts should be rewritten too (Joy/Daily) to make the naive ROADMAP grep #3 zero-hit, even though TERM-04 permits leaving them. | Validation Architecture | If left, the literal ROADMAP grep returns non-zero on description lines → gate ambiguity. Recommend rewriting; low risk. [ASSUMED] |
| A4 | ja already-correct phrasings (暮らしの支出, 生活) and en "Living Expenses" may be normalized to 日常/Daily per D-07 spirit, but are not strictly required by the grep gate. | ARB Value Rewrite | Planner/user style call; no gate failure either way. [ASSUMED] |
| A5 | `migrator.createTable` re-applies the table's `customIndices` on recreate (Drift 2.25). | Pattern 2 | If not, the two `idx_category_ledger_configs_*` indices are lost after recreate → re-issue `CREATE INDEX IF NOT EXISTS` (cheap safeguard — recommend doing it unconditionally). [ASSUMED — verify against Drift 2.25 docs] |

## Open Questions

1. **Is the `soul_satisfaction` DB column / `Transaction.soulSatisfaction` field in scope?** (A1)
   - What we know: D-08 names `soulSatisfaction→joyFullness` for ARB keys + color symbols only. A persisted DB column + Dart field + sync key of the same token exist with ~50 call sites.
   - What's unclear: whether "widest ring" (D-01) pulls the column in.
   - Recommendation: **OUT of scope** — orthogonal concept (satisfaction metric, not ledger vocab), would force a second migration + sync break. Resolve in `/gsd-discuss-phase` or as the first planner gate.

2. **Normalize already-acceptable non-stale phrasings (ja 暮らし/生活, en "Living Expenses") to literal 日常/Daily?** (A4)
   - Recommendation: yes for consistency (D-07 spirit), but it's a style call — surface in PLAN.md, not a gate.

3. **Rewrite `@description` metadata to remove "Soul"/"Survival" wording?** (A3)
   - Recommendation: yes — makes the ROADMAP grep gate unambiguous and zero-hit under the naive form.

## Sources

### Primary (HIGH confidence)
- Direct codebase grep/read (this session): `lib/l10n/app_{zh,ja,en}.arb`, `lib/core/theme/app_colors.dart` + `app_theme_colors.dart`, `lib/features/accounting/domain/models/transaction.dart`, `lib/data/app_database.dart` (migration steps v5/v14/v8/v15/v16/v17), `lib/data/tables/{transactions,category_ledger_configs}_table.dart`, `lib/data/repositories/*`, `lib/features/accounting/domain/models/transaction_sync_mapper.dart`, `lib/infrastructure/crypto/services/hash_chain_service.dart`, `lib/data/daos/analytics_dao.dart`, `lib/features/analytics/domain/models/{ledger_snapshot,analytics_aggregate,per_category_soul_breakdown}.dart`, `lib/shared/constants/default_categories.dart`, `test/unit/data/migrations/*`, `docs/arch/03-adr/`, `.github/workflows/audit.yml`, `pubspec.yaml`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`.
- `.planning/phases/31-terminology-rename/31-CONTEXT.md` (locked decisions D-01..D-15).

### Secondary (MEDIUM confidence)
- Drift `MigrationStrategy`/table-recreate pattern inferred from this codebase's existing v8 sync_queue recreate + v14 data UPDATE (consistent with Drift 2.x docs). A5 should be confirmed against Drift 2.25 `createTable`/`customIndices` behavior if the planner wants HIGH confidence.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- ARB/color/enum/file inventories: HIGH — all line numbers and counts from direct grep.
- Migration pattern: HIGH for the existing-codebase patterns; MEDIUM on A5 (createTable index re-application) pending Drift-doc confirm.
- Scope of `soulSatisfaction`: the *finding* is HIGH (column exists, 50 sites); the *boundary decision* is an Open Question requiring user confirmation (A1).

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (stable — internal rename; only Drift version drift could affect A5)
