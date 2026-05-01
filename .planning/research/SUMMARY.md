# Project Research Summary

**Project:** Home Pocket — まもる家計簿
**Domain:** Privacy-first family accounting app (subsequent milestone v1.1: Happiness Metric & Display)
**Researched:** 2026-05-01
**Confidence:** HIGH

## Executive Summary

v1.1 is a brownfield, locked-scope milestone with no greenfield setup. All four researchers converged on a single core finding: **the formulas are correct in math but fragile in presentation**, and the build is dominated by careful integration work (extending `features/analytics/`, wiring 3 dormant DAOs + 1 new DAO query) rather than greenfield construction. **Stack-side, zero new dependencies are needed** — every capability already maps to an installed package (`fl_chart 0.69`, `intl 0.20.2`, `package:collection`).

The 9 micro-phases from ARCHITECTURE.md should consolidate into the 4 phases originally proposed in PROJECT.md (Phase 9 Domain+Data, Phase 10 HomePage, Phase 11 Statistics, Phase 12 ARB rename). Phase 9 is the linchpin — locks soul-only filter, ¥500 amount floor, empty-state contract, family aggregate-only return type, and a no-gamification ADR before any UI consumer can build on quicksand.

The dominant risks are not technical (Drift queries are trivial, Riverpod wiring is precedent-driven) but **semantic and cultural**: survival-row contamination (the `default=5` data hygiene issue), ¥10 candy domination of "Best Joy per ¥", voice-estimator's +0.3 upward bias compounding across all 4 metrics, default-5 cluster from East-Asian central-tendency bias, family-mode leaderboard toxicity, and `「幸福」` register-mismatch in JP UI copy. All addressable within the locked scope via DAO contracts, ADR bans, and translation register reviews.

## Key Findings

### Recommended Stack

**ZERO additions needed.** Every v1.1 capability — computing 4 personal indicators, 2 family indicators, joy-per-¥ trend line, satisfaction histogram, ARB rename, Riverpod wiring — maps onto already-locked dependencies. No `pub add` commands needed. See `STACK.md` for the full inventory of rejected candidates.

**Core technologies (existing, no changes):**
- `fl_chart ^0.69.0` — sufficient for both Joy-per-¥ trend line (`LineChart`) and satisfaction histogram (`BarChart` with one bar per bin). Stay on 0.69; 1.x has breaking changes that would force incidental sweep across existing AnalyticsScreen — track as `FUTURE-TOOL-fl_chart-1x`.
- `intl 0.20.2` (pinned by `flutter_localizations`) — handles Joy/¥ display via `NumberFormat`. Display-only ratio; **do not add `decimal`**.
- `package:collection ^1.19.1` — `groupBy`, `IterableExtension.maxBy`, `IterableExtension.average` cover all aggregation idioms. **Do not add `equatable` (conflicts with Freezed-only equality), `dartx`, `darq`, or stats helpers.**
- Riverpod 2.4+ (`@riverpod`), Freezed, Drift+SQLCipher, mocktail — all unchanged.

**Forbidden additions reaffirmed:** `sqlite3_flutter_libs` (CI-rejected), Riverpod 3.x (FUTURE-TOOL-01 deferred), `intl` change (pinned), Syncfusion/charts_flutter/mp_chart (cosmetic alternatives forcing cross-codebase chart migration).

### Expected Features

The locked feature list survives industry-practice validation. Direct prior art exists in JP market (Joy Money on CAMPFIRE — pre-launch, similar concept but no published satisfaction-per-yen formula). OsidOri's "shared + personal split" pattern is the JP-recognized best practice for couples-finance UX; our cooperative-only family aggregation respects this principle.

**Must have (table stakes — already locked):**
- Per-transaction satisfaction rating — exists (5-emoji input, soul ledger only)
- Monthly aggregations (avg, count, distribution, daily trend) — DAO methods exist, dormant
- Soul-vs-Survival visual differentiation — exists (color tokens locked)
- Time-window navigation — month-to-date already locked

**Should have (differentiators — v1.1 deliverables):**
- **Joy per ¥** (Σ satisfaction / Σ amount) — core insight encoder; needs unit-display strategy ("per ¥1,000" normalization recommended)
- **Best Joy per ¥** story card (Spotify Wrapped grammar) — highest-leverage UI polish; needs amount floor (~¥500) to prevent ¥10 candy from always winning
- **Family Highlights Sum** — single-Int return; NEVER `Map<MemberId, Int>` (privacy/abuse vector)
- **Shared Joy Insight** — top category by avg satisfaction across family; min-N=3 transactions/category guard required
- **UI rename pass** — taps into 推し活 / 自分へのご褒美 / 悦己消费 cultural conversations (likely a bigger adoption lever than any indicator formula)

**Defer (v1.2+):**
- Per-member breakdown / leaderboard surfaces (privacy/toxicity)
- Cross-period delta on home tile (comparison anti-pattern)
- Public sharing UI (consent + comparison risks)
- Streaks / badges / daily targets (Goodhart's Law — v1.1 ADR ban)
- 4th DAO method for SQL-side `category × avg satisfaction` (in-memory in v1.1 is fine at expected data volumes)
- Custom time windows (week / year / arbitrary)

### Architecture Approach

**Extend `features/analytics/`, do NOT create `features/happiness/`.** Existing project pattern scopes feature modules by user-perceived surface area (home, analytics, accounting), not by metric category. The `voice` precedent confirms this: `application/voice/` exists without `features/voice/` because voice surfaces inside `accounting`.

**Major components:**
1. **3 use cases (split by audience boundary)** — `GetHappinessReportUseCase` (4 personal metrics, scoped by `bookId`), `GetBestJoyMomentUseCase` (single argmax story card), `GetFamilyHappinessUseCase` (2 family metrics, scoped by `groupId`). Different inputs, different aggregation shapes — keeping them separate respects the existing analytics-module pattern.
2. **1 NEW DAO query** for Best Joy per ¥ — SQL `argmax(satisfaction / amount)` with `WHERE amount >= 500 AND ledger_type = 'soul'`. Cannot be derived from existing 3 dormant methods (they `GROUP BY` and discard transaction identity). In-memory derivation would defeat `<2s` performance principle and pull every soul tx through field decryption.
3. **HomePage helper migration** — Both `_computeSatisfaction` and `_computeHappinessROI` move from `home_screen.dart` into `GetHappinessReportUseCase`. The current `_computeHappinessROI` is the misleading "budget-share" formula PROJECT.md flags as a bug; `_computeSatisfaction` reads today instead of month-to-date.
4. **ARB blast radius is small** — 7 source files + 2 test files. **Change values only, NOT keys** (avoids ARB-parity CI gate churn). `homeHappinessROI` becomes a slightly misleading key name but renaming forces wider edits; defer key rename to v1.2+.
5. **Build order** — canonical Clean Architecture: Domain → Data (DAO + repo impl) → Application (use cases + providers) → Presentation providers → widgets → screen wire-up → ARB → verification. `build_runner` between each Dart-codegen-touching phase.

### Critical Pitfalls

Top items the roadmap MUST encode (full inventory in `PITFALLS.md`):

1. **Survival-row contamination** — `soul_satisfaction` defaults to 5 even on Survival ledger transactions. Every aggregator MUST filter `WHERE ledger_type = 'soul'`; without a centralized `_soulOnly()` SQL fragment, individual aggregators will silently leak survival contamination, dragging Joy per ¥ down ~40% in realistic family-finance mixes.
2. **¥10 candy domination of "Best Joy per ¥"** — Density spans 4 orders of magnitude (¥10 candy at sat=10 → 1.0; ¥80,000 ticket at sat=10 → 0.000125). A snack always wins without an amount floor. Required: ~¥500 floor for the "Best" highlight selection only, plus always rendering amount alongside.
3. **Family-mode aggregate-only contract** — `FamilyHighlightsSum` MUST return `int` (aggregate-only), NEVER `Map<MemberId, int>`. Per-member breakdown enables intimate-partner emotional surveillance (Oxford 2020) and sibling-comparison harm (Wolter 2003 IZA).
4. **East-Asian central-tendency clustering at sat=5** — Documented demographic effect (Japan Cabinet Office wellbeing-research, Keio SDM 2014 thesis). Combined with the existing `5` default for missed/OCR/quick-add inputs, the histogram will be a single tall midpoint bar. **Annotate** the `5` bar ("中央値・含未評価"), don't try to "fix".
5. **No-gamification ADR needed in Phase 9** — Goodhart's Law defense. The milestone is currently silent on streaks/badges/daily targets; that silence will be filled by someone's enthusiasm. Explicit `ADR-XXX_No_Gamification_v1_1.md`.
6. **`「幸福」` register mismatch in JP UI** — In Japanese, 幸福 carries philosophical / wellbeing-research weight. Use `ときめき` / `小確幸` for in-product copy; reserve 幸福 for documentation. CN family-mode must use 「家族的小确幸」, NOT 「家族悦己」 (collision with personal account name).
7. **Voice estimator +0.3 upward bias** — quantified; could systematically inflate metrics. Phase 9 should add bias-quantification test. If `transactions.entry_source` exists (verify in 9.0), a manual-only sub-metric is feasible.
8. **5-emoji ↔ 1-10 mapping** — Picker is 5 emoji, column is 1-10. Pin the mapping in tests (likely 1-2 / 3-4 / 5-6 / 7-8 / 9-10 buckets).
9. **Median + coverage caption alongside mean as headline** — Mean is fragile against the default-5 cluster. Recommend Phase 9 product decision: keep mean as headline, add median as tooltip + "n=k rated" coverage caption.

## Implications for Roadmap

Based on research, suggested phase structure (consolidating ARCHITECTURE's 9 micro-phases into 4):

### Phase 9: Happiness Domain & Formula Layer
**Rationale:** Linchpin. Locks formulas, contracts, and defenses against pitfalls 1-9 BEFORE any UI consumer builds on them. Combines architecture-A+B+C since they form one inseparable layered slice.
**Delivers:** Domain models (`HappinessReport`, `BestJoyMoment`, `FamilyHappinessReport`, sealed `MetricResult` with empty/thinSample/value variants) + `_soulOnly()` SQL fragment + 1 new DAO query (Best Joy argmax with ¥500 floor) + 3 use cases + repository wiring + bias-quantification tests + `ADR-XXX_No_Gamification_v1_1.md`.
**Addresses:** All 4 personal + 2 family indicator computations (foundational layer)
**Avoids:** Pitfalls 1, 2, 3, 5, 7, 8, 9

### Phase 10: HomePage SoulFullnessCard Redesign
**Rationale:** Thin consumer once Phase 9 formulas are locked. Drops the misleading `_computeHappinessROI`. UI for the 4 personal indicators + family card with consent gate.
**Delivers:** New SoulFullnessCard (replaces existing), Best Joy per ¥ story card, family card (group mode + consent), ≤2 `ⓘ` info icons (voice bias + hedonic adaptation), coverage caption, no daily-target / streak copy.
**Uses:** `GetHappinessReportUseCase`, `GetBestJoyMomentUseCase`, `GetFamilyHappinessUseCase`, fl_chart for sparkline if any.
**Implements:** Presentation layer over Phase 9 contracts; reuses existing AppTextStyles + theme color tokens.

### Phase 11: Statistics Surface (悦己账本统计 / Joy Ledger Statistics)
**Rationale:** Must come AFTER Phase 9 (DAO methods + use cases) and AFTER Phase 10 (validates UI patterns). First sub-task is integration footprint audit, NOT wiring code (countering 30-50% under-estimation typical for "just wire it up" work).
**Delivers:** Sub-region in AnalyticsScreen: Joy per ¥ trend line (month-to-date) + satisfaction distribution histogram (with `5` bar annotation) + headline mean (with median tooltip + coverage caption). New ARB namespace `analyticsSoul*`. Internal-only rating-entropy health-check (NOT user-surfaced).
**Avoids:** Pitfall 4 (histogram annotation), integration-footprint under-estimation.

### Phase 12: ARB Rename Pass (UI 文案重命名)
**Rationale:** Last because value-only and decoupled; doing earlier risks merge churn against Phases 10/11 widget edits.
**Delivers:** `survivalLedger` → 日常账本 / 日々の帳 / Daily Ledger; `soulLedger` → 悦己账本 / ときめき帳 / Joy Ledger; `homeHappinessROI` value → 幸福密度 / ハピネス密度 / Joy per ¥; `homeSoulFullness` value → 悦己充盈 / ときめき度 / Joy Index. **Values only — keys stay** (avoids ARB-parity CI churn). `ADR-XXX_Lexical_Hierarchy_v1_1.md`. Native-speaker register review.
**Avoids:** Pitfall 6 (`「幸福」` register mismatch + 「家族悦己」 collision).

### Phase Ordering Rationale

- **9 → 10/11 → 12**: Formulas/contracts before consumers; UI before rename to keep ARB diff small and reviewable.
- **10 before 11**: HomePage surfaces a smaller subset of the same metrics; doing it first validates the use-case API shape before AnalyticsScreen extension consumes it more broadly.
- **12 last**: ARB churn during widget edits causes merge friction; isolate to its own phase.
- **No stack-prep phase**: Zero dependency additions — Phase 9 starts directly on domain + DAO.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 11**: Family-mode book enumeration via `shadowBooksProvider` was MEDIUM-confidence in ARCHITECTURE research. Integration footprint audit IS the deeper-research moment for this phase. Flag for `/gsd-research-phase 11` if requirements step doesn't resolve it.

Phases with standard patterns (skip research-phase):
- **Phase 9**: Mirrors `GetMonthlyReportUseCase` precisely; HIGH-confidence research already done.
- **Phase 10**: Container Widget With Async Provider pattern already established in existing HomePage code.
- **Phase 12**: Mechanical; CI guardrail enforces ARB key parity.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | "No additions" rationale grounded in 9 specific package rejections; verified `pubspec.yaml` 2026-05-01; fl_chart 0.69 vs 1.x analyzed against changelog |
| Features | MEDIUM-HIGH | HIGH on JP competitors (OsidOri, Zaim, マネーフォワード ME) and CN UX patterns (iCost, 叨叨记账); MEDIUM on direct competitor (Joy Money is pre-launch, marketing material only); anti-feature reasoning grounded in Gilovich + self-report bias research |
| Architecture | HIGH | All path/symbol claims grounded in source reads; ARB blast radius from `grep -rn`; 3 dormant DAO methods verified at lines 230-327 of `analytics_dao.dart` |
| Pitfalls | HIGH | Formula edges grounded in arithmetic (worked examples); cultural/behavioural pitfalls in published research (Japan Cabinet Office, Keio SDM, Oxford 2020, Wolter IZA); Goodhart + hedonic adaptation are textbook |

**Overall confidence:** HIGH

### Gaps to Address

- **`transactions.entry_source` column existence** — resolve in Phase 9 substep 9.0 (single grep on `transactions_table.dart`). If exists, manual-only sub-metric is feasible in v1.1 without schema change. If not, defer to v1.2.
- **Family-mode book enumeration** — `shadowBooksProvider` exists in `home_screen.dart` line 18 but cross-book aggregation wiring needs Phase 9 design decision. Likely deeper-research moment for Phase 11 planning.
- **Median vs mean headline** — Phase 9 product decision. Spec says "mean," but mean is fragile against default-5 cluster. Recommend mean-as-headline + median-as-tooltip + coverage caption ("n=k rated").
- **`Result<T>` vs `throw` envelope** — Project-wide rule prefers `Result<T>`, but existing analytics module uses `throw` + `AsyncValue.when(error:)`. Phase 9 substep 9.8: pick one path for v1.1 to avoid mid-module inconsistency. Recommend matching the existing analytics convention (`throw`).

## Sources

### Primary (HIGH confidence)
- [pub.dev/packages/fl_chart](https://pub.dev/packages/fl_chart) + changelog — version compatibility
- `pubspec.yaml` — existing dependency inventory
- `lib/data/daos/analytics_dao.dart` lines 230-327 — verified 3 dormant methods
- `lib/features/home/presentation/screens/home_screen.dart` lines 345, 362 — verified `_computeSatisfaction` / `_computeHappinessROI` bug
- CLAUDE.md Placement Decision Rule + STRUCTURE.md decision tree
- [Gilovich et al. — Experiential consumption and pursuit of happiness](https://static1.squarespace.com/static/5394dfa6e4b0d7fc44700a04/t/547d589ee4b04b0980670fee/1417500830665/Gilovich+Kumar+Jampol+(in+press)+A+Wonderful+Life+JCP.pdf)
- Japan Cabinet Office — wellbeing measurement methodology
- Keio SDM 2014 thesis — JP/KR/CN central-tendency clustering documentation
- Oxford 2020 — intimate-partner emotional-data abuse via shared apps

### Secondary (MEDIUM confidence)
- [Joy Money — CAMPFIRE](https://camp-fire.jp/projects/883660/view) — direct concept competitor (pre-launch)
- OsidOri shared+personal split rationale — JP couples-finance UX baseline
- [Daylio Journal](https://daylio.net/) — multi-dimensional wellbeing dashboard reference
- 少数派 / 人人都是产品经理 — CN UX patterns (iCost, 叨叨记账, Fortune City)

### Tertiary (LOW confidence)
- Voice estimator +0.3 upward bias number — sourced from milestone context, not independently verified; consequence analysis is HIGH confidence

---
*Research completed: 2026-05-01*
*Ready for roadmap: yes*
