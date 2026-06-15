# Project Research Summary

**Project:** Home Pocket v1.7 多币种支持 (Multi-Currency Transaction Entry)
**Domain:** Multi-currency accounting extension for local-first Flutter family finance app
**Researched:** 2026-06-12
**Confidence:** HIGH

---

## Executive Summary

Home Pocket v1.7 adds multi-currency transaction entry to an existing JPY-integer local-first accounting app. The research confirms this is achievable as a well-scoped additive increment: three nullable columns on the `transactions` table (Drift v20→v21), one new `exchange_rates` Drift table (see conflict note below for the SharedPreferences alternative), a new `lib/infrastructure/exchange_rate/` HTTP client, and presentation-layer changes confined to `SmartKeyboard`, `TransactionDetailsForm`, and `ListTransactionTile`. The existing analytics, list, hash chain, and sync infrastructure require zero structural changes — the canonical JPY `amount` column continues to serve all downstream consumers unchanged.

The recommended stack adds exactly two pub.dev packages (`currency_picker ^2.0.22` for the picker widget, `sealed_currencies ^3.2.0` for ISO 4217 metadata and localized names) and uses a dual-source exchange-rate strategy with no API key: Frankfurter (ECB feed, 30 currencies, full historical) as primary and fawazahmed0 (360+ currencies, 8-month history) as fallback for currencies outside the ECB set (primarily TWD). Both APIs are free, key-free, and privacy-safe — no user data enters any URL. Amount arithmetic uses double multiplication with a single shared `.round()` utility; the `decimal` package is explicitly excluded to avoid threatening the pinned `intl 0.20.2` constraint.

The most consequential design decisions requiring ADR resolution before Phase 1 begins are: (1) rate cache storage — STACK.md recommends SharedPreferences flat keys while ARCHITECTURE.md recommends a new Drift table (see explicit conflict section below); (2) float vs string storage for the `exchangeRate` Drift column — PITFALLS.md flags `RealColumn` (double) as "Never" acceptable technical debt while STACK.md uses it; and (3) the CNY/JPY `¥` symbol collision already confirmed in `NumberFormatter._getCurrencySymbol` must be fixed in Phase 1 to prevent a forced golden re-baseline mid-development. These three decisions block the data-layer migration and must be captured in ADRs first.

---

## Key Findings

### Recommended Stack

No new HTTP client is needed — the existing `http ^1.6.0` package (already used in `relay_api_client.dart`) handles all exchange-rate network calls. The two new packages are dependency-clean: `currency_picker ^2.0.22` depends only on `collection ^1.19.1` (already pinned), and `sealed_currencies ^3.2.0` has no intl in its transitive dependency chain, preserving the pinned `intl 0.20.2`. No `build_runner` regeneration is triggered by either package.

**Core technologies (new additions):**
- `currency_picker ^2.0.22`: ISO 4217 picker widget with flag icons and real-time search — actively maintained (published 2026-06-11), zero intl dependency
- `sealed_currencies ^3.2.0`: compile-time `FiatCurrency` objects with `subunitToUnit`, ISO codes, and ja/zh/en localized names — critical for correct decimal handling (JPY subunit=1, USD/CNY/TWD subunit=100) and KRW display override (ISO says 100, display convention is 0 decimals)
- Frankfurter API (`api.frankfurter.dev`): free, no API key, 30 currencies (CNY/KRW/HKD/SGD/THB confirmed), historical back to 1999-01-04, live-verified
- fawazahmed0 CDN (`@fawazahmed0/currency-api` npm, CC0 license): 360+ currencies including TWD, history from 2024-10-10 — fallback only when Frankfurter returns 404
- Drift v20→v21 schema migration: three nullable columns on `transactions`, one new exchange-rates cache entity (storage mechanism TBD — see conflict below)

**Explicitly excluded:**
- `dio`: `http` already present; adds ~300 KB bundle overhead with no benefit for 1–2 GET calls
- `decimal`: adds `intl >=0.19.0 <0.21.0` constraint; double + shared `.round()` is sufficient
- Any API requiring registration (conflicts with privacy-first, no-account architecture)

### Expected Features

**Must have (table stakes) — all P1 for v1.7:**
- Currency selector on SmartKeyboard: 4–6 pinned common currencies (JPY, USD, EUR, CNY, HKD, GBP) + "more" → full searchable ISO list
- Auto rate fetch by transaction date: Frankfurter `/v1/{date}` with per-day local cache; weekend/holiday shows actual rate date inline
- Live conversion preview below amount field: reactive to keypad input and date changes; spinner during fetch
- Manual rate override: editable rate field inline; recalculates JPY preview immediately
- Offline fallback: last cached rate + staleness label ("前回取得: YYYY-MM-DD"); manual override always available
- Drift schema v20→v21: three nullable transaction columns + exchange-rate cache
- JPY integer rounding: single shared `(originalAmount * appliedRate).round()` utility at both preview and persist sites
- Foreign-currency annotation in list rows: secondary text on `ListTransactionTile` for non-JPY rows only
- Detail/edit with full original info: originalCurrency, originalAmount, appliedRate visible and re-editable
- Family sync passthrough: three new nullable fields serialized/deserialized via `TransactionSyncMapper` (null-safe, no version negotiation)
- Voice currency words zh/ja: 美元/欧元/英镑/港币/澳元/加元 (zh) and ドル/ユーロ/ポンド/香港ドル/豪ドル (ja) → ISO codes

**Should have (competitive differentiators):**
- Weekend/holiday date label: shows actual rate date when Frankfurter `responseDate != requestedDate` — no competitor does this explicitly; low cost, high trust signal
- Active-currency session persistence: ephemeral Riverpod provider; no disk persistence needed
- Voice currency detection: unique capability — none of Toshl, Spendee, 随手记, 钱迹 have voice input

**Defer (v1.x after validation):**
- Three-field linked editing: editing jpyAmount back-calculates appliedRate; validate basic flow first
- "Remember this rate" per-transaction option (Spendee pattern)

**Defer to v2+:**
- Shopping list `estimatedPrice` multi-currency (SHOP-CURRENCY-V2)
- Per-user foreign-currency default (needs multi-profile settings)

### Architecture Approach

The v1.7 integration maps to seven integration surfaces, five requiring code changes and two (analytics DAOs, AppInitializer) confirmed requiring zero changes by direct source inspection. New components follow the established domain-specific subdirectory pattern from `lib/infrastructure/sync/relay_api_client.dart`: the HTTP client lives in `lib/infrastructure/exchange_rate/`, use cases in `lib/application/currency/`, domain models and repository interface in `lib/features/currency/domain/`, and the table/DAO/repository implementation in `lib/data/`. The `import_guard.yaml` `inherit: true` propagation ensures all new subdirectories automatically respect layer boundaries without config changes.

**Major new components:**
1. `ExchangeRateApiClient` (infrastructure/exchange_rate) — stateless HTTP wrapper; injectable `http.Client` constructor mirrors `RelayApiClient` for testability
2. `ExchangeRateCacheService` (infrastructure/exchange_rate) — cache-first orchestration: hit DAO, on miss call API, persist, return; on network failure return most-recent cached rate
3. `ExchangeRates` Drift table + DAO (data/tables, data/daos) — `(currency, rateDate)` composite primary key; exact-date and latest-for-currency query methods; explicit `CREATE INDEX` (not decorative `customIndices`)
4. `GetExchangeRateUseCase` + `ResolveRateForDateUseCase` (application/currency) — sealed `RateResult.fetched`/`.fallback` return type drives UI staleness disclaimer
5. `CurrencySelectorSheet` (features/accounting/presentation/widgets) — common + full ISO + search tabs; returns ISO 4217 code string
6. `TransactionDetailsForm` local state extension — four new private fields using existing `setState` pattern; no new Riverpod notifier needed

**Build order (ARCHITECTURE.md §h):** Data Foundation (Phase A) → Domain + Sync (Phase B) → Infrastructure Client (Phase C) → Application Use Cases (Phase D) → Voice (Phase E, parallel with F) + Presentation (Phase F, parallel with E, requires A–D complete).

**Confirmed zero-change paths:** `analytics_dao.dart` (all SUM/ORDER BY use `amount` only), `AppInitializer` (rate fetch is lazy/on-demand), `ApplySyncOperationsUseCase`, `TransactionChangeTracker`.

### Critical Pitfalls

1. **Float precision for stored exchange rate** — PITFALLS.md: storing `exchangeRate` as Drift `REAL` (double) is "Never" acceptable; precision loss on re-multiplication causes preview-vs-stored divergence and subtle hash chain audit gaps. STACK.md's schema uses `RealColumn`. ADR required before Phase 1: store as `TextColumn` (string) or accept double with a mandatory unit test asserting `preview_amount == stored_amount` for 10 edge cases. Recommendation: `TextColumn` for audit integrity.

2. **CNY/JPY `¥` symbol collision — existing bug in `number_formatter.dart`** — `_getCurrencySymbol` returns `'¥'` for both JPY and CNY. Confirmed by direct file inspection and golden test review (133 goldens include CNY tests with same symbol). Fix (`'CN¥'` for CNY) must go in Phase 1 before any UI work to control golden re-baseline timing.

3. **Hash chain: new fields must NOT enter the hash formula** — adding the three new columns to `HashChainService.calculateTransactionHash` would require recomputing every existing `currentHash`/`prevHash` (full chain re-seal). ADR decision: keep new columns outside the hash boundary; JPY `amount` is the financially material field; metadata integrity is provided by E2EE transport.

4. **Edit semantics: silent rate change on date edit** — when a user edits a transaction's date, re-fetching the rate silently changes the JPY booking amount. Policy needed in ADR: show confirmation toast when date change causes >1% JPY amount difference. Direct JPY editing for foreign-currency transactions requires an "override conversion" confirmation that clears original-currency metadata.

5. **Offline-first: rate resolution is pre-save, not post-save backfill** — `CreateTransactionUseCase` must never contain an HTTP call. Domain invariant: if any one of (`originalCurrency`, `originalAmount`, `exchangeRate`) is non-null, all three must be non-null — `Result.error` on partial state prevents silent `amount = 0` rows that corrupt analytics `SUM`.

6. **SmartKeyboard decimal gate** — `onDot` must be enabled only for currencies with `subunitToUnit > 1` and capped at 2 decimal places. JPY must never gain a decimal point. Without this, entering `149.99 USD` is impossible and entering it for JPY would break the integer-only flow.

---

## Conflict: Rate Cache Storage and Infrastructure Directory Name

Two concrete disagreements between STACK.md and ARCHITECTURE.md require a decision before Phase 1.

### (a) Rate Cache: SharedPreferences vs Drift Table

**STACK.md:** SharedPreferences flat keys (`"exrate:YYYY-MM-DD:CURRENCY"` → double). Rationale: cache is reconstructible, never synced, already initialized before DB, flat structure needs no joins.

**ARCHITECTURE.md:** New Drift `exchange_rates` table with `(currency, rateDate)` composite primary key. Rationale: structured/queryable, `ORDER BY rate_date DESC LIMIT 1` for offline fallback, SQLCipher encrypted at rest, TTL via `fetchedAt`, consistent with existing persistence patterns.

**PITFALLS.md tiebreaker:** Explicitly flags SharedPreferences as a security concern ("reveals which currencies the user accesses if device is compromised") and recommends "Use Drift table for structured, queryable, TTL-expirable cache."

**Recommendation: Drift table wins.** Three reasons dominate: (a) the "latest cached rate for any date" offline fallback query is naturally a single SQL `ORDER BY` against the table rather than an iteration loop over SharedPreferences keys; (b) SQLCipher encryption keeps rate metadata (which indirectly reveals travel/spending patterns) inside the encrypted database; (c) the `customIndices`-is-decorative lesson from v1.6 is already correctly incorporated in the ARCHITECTURE.md design (explicit `CREATE INDEX` in both `onCreate` and `onUpgrade`). The STACK.md argument that SharedPreferences is "already initialized before the DB" is not a real constraint — the rate cache is only accessed during transaction entry, well after `AppInitializer` completes.

### (b) Infrastructure Directory Name: `currency/` vs `exchange_rate/`

**STACK.md:** `lib/infrastructure/currency/`

**ARCHITECTURE.md:** `lib/infrastructure/exchange_rate/`

**Recommendation: `exchange_rate/` wins.** The directory houses the exchange-rate HTTP client and cache orchestration service — not the currency picker widget or ISO 4217 metadata, which belong in presentation and domain layers respectively. The name `exchange_rate/` is specific to the concern (fetching and caching exchange rates) and mirrors the `sync/` naming convention in `lib/infrastructure/sync/` (named after the technical concern, not the business domain).

---

## Implications for Roadmap

Based on combined research, the suggested phase structure:

### Phase 1: Data Foundation + ADR Decisions

**Rationale:** All downstream work depends on the Drift schema and three ADR decisions being locked. Getting rate precision or hash scope wrong requires an expensive re-seal migration; getting the CNY symbol wrong mid-development forces an unplanned golden re-baseline.

**Delivers:** ADRs for rate precision / hash scope / edit policy, `NumberFormatter` CNY symbol fix, Drift v20→v21 migration (`exchange_rates` table + index + three nullable `transactions` columns), `ExchangeRates` table + `ExchangeRateDao` + `ExchangeRateRepositoryImpl`.

**Addresses features:** Drift schema prerequisite, JPY integer rounding, CNY disambiguation

**Avoids pitfalls:** Float precision (Pitfall 1), CNY symbol collision (Pitfall 2), dual-field storage invariant (Pitfall 3), hash chain integrity (Pitfall 7)

**Gate:** Migration tests — v20→v21 executes; v1→v21 clean install works; existing transactions gain three null columns without data loss; `HashChainService.verifyChain` passes on mixed v20/v21 dataset.

### Phase 2: Domain Models + Sync Protocol

**Rationale:** Freezed model changes and sync mapper updates are low-risk and must precede use-case development. Backward-compat sync tests are a hard gate before any PR lands.

**Delivers:** `Transaction` Freezed model + three nullable fields, `ExchangeRate` Freezed model, `ExchangeRateRepository` interface, `TransactionSyncMapper` null-safe extension (conditional emit + null-safe reads), `CreateTransactionParams` optional field extension.

**Addresses features:** Family sync passthrough

**Avoids pitfalls:** Family sync version skew (Pitfall 8)

**Gate:** Sync round-trip tests — new-to-old wire (extra keys ignored), old-to-new wire (absent keys → null). `build_runner` clean.

### Phase 3: Infrastructure Client + Offline Fallback

**Rationale:** The exchange-rate service with cache-first logic and offline fallback is the most technically novel component. It must be fully tested before UI is wired, so presentation tests can rely on mocked behavior in goldens.

**Delivers:** `ExchangeRateApiClient` (Frankfurter primary + fawazahmed0 fallback), `ExchangeRateCacheService` (cache-first, online/offline/fallback/weekend paths), dual-source lookup strategy, privacy verification.

**Uses stack:** `http ^1.6.0` (existing), injectable `MockClient` pattern from `relay_api_client.dart`

**Avoids pitfalls:** API gaps/weekends/TWD coverage (Pitfall 5), offline-first/blocking save (Pitfall 6)

**Gate:** Unit tests with `MockClient` — cache-hit (no network call), cache-miss (API called + DAO upserted), offline fallback (API throws → latest cached row), weekend-date (Saturday → Friday rate), TWD routing to fawazahmed0, privacy assertion (URL contains no user data).

### Phase 4: Application Use Cases

**Rationale:** Use cases wire the infrastructure service to domain logic and enforce the pre-save rate resolution rule. Must be stable before presentation is built.

**Delivers:** `GetExchangeRateUseCase`, `ResolveRateForDateUseCase` (sealed `RateResult`), `repository_providers.dart` Riverpod wiring, domain invariant in `CreateTransactionUseCase` (partial-triple → `Result.error`), edit semantics enforcement per ADR.

**Avoids pitfalls:** Edit semantics (Pitfall 4), offline-first rate resolution (Pitfall 6)

**Gate:** Unit tests — fresh fetch, offline fallback with `RateResult.fallback` carrying `cachedDate`, manual override pass-through, domain invariant rejection of partial state.

### Phase 5: Presentation (parallel with Phase 6 after Phases 1–4)

**Rationale:** All infrastructure is tested and stable. Presentation changes are purely additive following established patterns.

**Delivers:** `onCurrencyTap` callback on `SmartKeyboard`, `CurrencySelectorSheet` (common + full ISO + search), four currency state fields on `TransactionDetailsFormState` (existing `setState` pattern), converted-amount preview row (spinner / rate / JPY result), `ManualOneStepScreen` wiring, read-only currency info in edit mode, foreign-currency annotation on `ListTransactionTile`, decimal-input gate on `SmartKeyboard` (dot for `subunitToUnit > 1` only, 2dp cap).

**Addresses features:** Currency selector, live preview, manual override, offline staleness label, list annotation, detail/edit full info

**Avoids pitfalls:** i18n decimal separator (Pitfall 9)

**Gate:** Goldens for keypad (tappable currency cell), form (converted-preview row ja/zh/en × light/dark), list tile (annotation variant). Integration smoke test: USD 50 at 148.30 → `amount=7415`, `original_currency='USD'`. JPY golden verifies dot remains non-functional.

### Phase 6: Voice Parser Extension (parallel with Phase 5)

**Rationale:** Voice parser changes are independent of Phase 5 presentation work. The `VoiceParseResult` contract extension (adding `detectedCurrency`) does not affect any Phase 5 code paths. Parallel reduces wall-clock time.

**Delivers:** Extended `VoiceCurrencySuffixes.all` (zh/ja currency words, longest-first), `_extractCurrencyCode` + `_currencyTokenToIso` in `ParseVoiceInputUseCase`, `detectedCurrency` field in `VoiceParseResult`, `VoiceInputScreen` passing `initialCurrency` to form config, `元` ambiguity policy (zh locale = CNY, ja locale = JPY).

**Addresses features:** Voice currency words zh/ja (unique differentiator vs all competitors)

**Avoids pitfalls:** Voice ambiguity / vocabulary gaps (Pitfall 10)

**Gate:** Voice corpus tests — `「50ドル」` → `{amount:50, detectedCurrency:'USD'}`, `「五十美元」` → `{amount:50, detectedCurrency:'USD'}`, `「1000円」` → `{detectedCurrency:null}`. Minimum 5 cases per currency per locale. Existing corpus tests pass unchanged.

### Phase Ordering Rationale

- Data before domain before application before presentation matches the 5-layer dependency flow and the six-phase A→F build order from ARCHITECTURE.md.
- ADR decisions in Phase 1 are non-negotiable: rate precision and hash scope are expensive to reverse once data exists in the schema.
- CNY symbol fix in Phase 1 controls when goldens are re-baselined — doing it mid-development would cause an unplanned and confusing golden diff.
- Infrastructure client fully tested before UI wiring ensures presentation tests can mock the rate service reliably without network dependencies.
- Voice parser parallel with presentation because neither depends on the other.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Infrastructure Client):** Confirm fawazahmed0 CDN date-versioned npm URL format and Cloudflare fallback URL `{date}.currency-api.pages.dev` are still operative with a live TWD test before implementation. The STACK.md confirms live verification as of 2026-06-12; re-verify at planning time.
- **Phase 5 (Presentation):** `SmartKeyboard` decimal input state machine (tracking `'149'` → `'149.'` → `'149.99'` with 2dp cap, without breaking JPY integer-only flow) has no direct precedent in the codebase. Needs careful design before implementation.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Data Foundation):** Drift migration pattern (`from < N` + `customStatement`) is well-established from v1.6; `customIndices` lesson incorporated in ARCHITECTURE.md design.
- **Phase 2 (Domain + Sync):** `TransactionSyncMapper` extension follows the exact `if (x != null) 'field': x` / `data['field'] as T?` pattern already present for `note`, `merchant`, `photoHash`.
- **Phase 4 (Use Cases):** `Result<T>`, Riverpod ONE-file wiring, and `CreateTransactionUseCase` extension all follow established project patterns.
- **Phase 6 (Voice):** `VoiceCurrencySuffixes` extension point is well-defined; longest-first invariant is documented in source.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All packages live-verified on pub.dev; both APIs live-tested via curl with actual responses; `intl` constraint confirmed safe; no training-data assertions |
| Features | HIGH | Core UX patterns verified against Toshl, Spendee, 随手记, 钱迹; edge cases (weekend rates, offline, edit semantics) cross-confirmed across multiple sources |
| Architecture | HIGH | All conclusions from direct source-code inspection of 15 project files; layer boundary compliance verified against actual `import_guard.yaml`; zero-change paths confirmed by reading actual DAO query code |
| Pitfalls | HIGH | All critical pitfalls confirmed by reading actual codebase files (`number_formatter.dart`, `hash_chain_service.dart`, `transactions_table.dart`, `amount_display_golden_test.dart`) — not theoretical |

**Overall confidence:** HIGH

### Gaps to Address

- **Rate precision ADR (Phase 1 gate):** Must choose between `TextColumn` (string, full precision) and `RealColumn` (double, STACK.md default but PITFALLS.md flags as "Never"). Recommendation is `TextColumn`; decision blocks the Drift migration.

- **fawazahmed0 historical edge case:** Transactions dated before 2024-10-10 in TWD and other Frankfurter-unsupported currencies have no resolvable rate from either API. UX for this case (likely "no cached rate available, please enter manually") should be specified in Phase 3 planning.

- **`元` (zh) ambiguity policy:** Documented in PITFALLS.md as a policy decision (not inference). Must be captured in an ADR addendum or explicit code comment during Phase 6.

- **KRW decimal display override:** `sealed_currencies` reports `subunitToUnit = 100` (ISO standard) but KRW display convention is 0 decimal places. The `NumberFormatter` needs a KRW special case matching the existing JPY zero-decimal handling. Confirmed in STACK.md; not yet in any project code.

---

## Sources

### Primary (HIGH confidence — live-verified or direct codebase inspection)
- `lib/data/tables/transactions_table.dart` — schema v20 structure, column types, nullable conventions
- `lib/data/app_database.dart` — schemaVersion=20, migration pattern, `customStatement` rationale
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — hash formula inputs confirmed
- `lib/infrastructure/i18n/formatters/number_formatter.dart` — CNY/JPY symbol collision bug confirmed
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — sync payload structure, null-safe fallback pattern
- `lib/shared/constants/voice_currency_suffixes.dart` — current suffix set is JPY-only (8 tokens)
- `lib/data/daos/analytics_dao.dart` — all SUM/ORDER BY use `amount` only; zero-change confirmed
- `test/golden/amount_display_golden_test.dart` — 133 goldens; CNY tests confirmed use `¥` symbol
- `https://api.frankfurter.dev/v1/currencies` — live-verified; 30 currencies; TWD absent; CNY/KRW/HKD/SGD/THB present
- `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2024-10-10/v1/currencies/jpy.min.json` — live-verified; TWD/CNY/KRW present
- `https://pub.dev/api/packages/currency_picker` — version 2.0.22; deps: `collection ^1.19.1` only
- `https://pub.dev/api/packages/sealed_currencies` — version 3.2.0; no intl in transitive chain

### Secondary (MEDIUM confidence)
- Toshl Finance currency UX — recently-used currencies, session persistence, 3-field linked editing, historical rates back to 1999
- Spendee exchange rate help center — manual rate override pattern; "updated every 24 hours" (confirms Home Pocket's date-aware rate is a differentiator)
- Frankfurter docs (`frankfurter.dev/docs/`) — "free for commercial use, no quotas"; no formal ToS
- fawazahmed0 GitHub LICENSE — CC0 1.0 Universal; commercial use explicitly allowed

### Tertiary (MEDIUM-LOW confidence — UX reference only)
- 钱迹 multi-currency guide — UX reference
- V2EX multi-currency design discussion — community perspective on expected feature set

---

*Research completed: 2026-06-12*
*Ready for roadmap: yes*
