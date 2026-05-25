# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — see [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — see [archive](milestones/v1.2-ROADMAP.md)
- 🚧 **v1.3 迭代帐本输入** — Phases 18-22 (active, started 2026-05-22)

## Phases

<details>
<summary>✅ v1.0 Codebase Cleanup Initiative (Phases 1-8) — SHIPPED 2026-04-29</summary>

- [x] Phase 1: Audit Pipeline + Tooling Setup (8/8 plans) — completed 2026-04-25
- [x] Phase 2: Coverage Baseline (4/4 plans) — completed 2026-04-26
- [x] Phase 3: CRITICAL Fixes (5/5 plans) — completed 2026-04-26
- [x] Phase 4: HIGH Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 5: MEDIUM Fixes (5/5 plans) — completed 2026-04-27
- [x] Phase 6: LOW Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 7: Documentation Sweep (6/6 plans) — completed 2026-04-28
- [x] Phase 8: Re-Audit + Exit Verification (8/8 plans) — completed 2026-04-28

**Outcome:** REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`. 4 permanent CI guardrails active. Full details: `.planning/milestones/v1.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.1 Happiness Metric & Display (Phases 9-12) — SHIPPED 2026-05-05</summary>

- [x] Phase 9: Happiness Domain & Formula Layer (14/14 plans) — completed 2026-05-02
- [x] Phase 10: HomePage SoulFullnessCard Redesign (13/13 plans) — completed 2026-05-03
- [x] Phase 11: AnalyticsScreen Unified Dashboard (8/8 plans) — completed 2026-05-04
- [x] Phase 12: UI Copy Rename Pass (5/5 plans) — completed 2026-05-04

**Outcome:** v1.1 delivered the happiness metric domain, integrated HomeHeroCard, Variant δ AnalyticsScreen, trilingual Joy/Daily ledger copy rename, and accepted ADR-015 lexical hierarchy. One Phase 11 human UAT verification item is acknowledged as deferred at close in `.planning/STATE.md`. Full details: `.planning/milestones/v1.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.2 Happiness Metric Refresh (Phases 13-17) — SHIPPED 2026-05-21</summary>

- [x] Phase 13: ADR-016 Backend Foundation (7/7 plans) — completed 2026-05-19
- [x] Phase 14: ADR-016 Frontend + ARB Reconciliation (6/6 plans) — completed 2026-05-19
- [x] Phase 15: Custom Time Windows (6/6 plans) — completed 2026-05-19
- [x] Phase 16: Per-Category Breakdown + Soul-vs-Survival (10/10 plans) — completed 2026-05-20
- [x] Phase 17: Manual-Only Joy Sub-Metric (8/8 plans) — completed 2026-05-21

**Outcome:** v1.2 migrated the Joy metric from density (Joy/¥) to cumulative `Σ joy_contribution` (ADR-016): HomeHero rebuilt with sage-green→gold target ring, Settings exposes user-configurable `monthly_joy_target` with 3-month median recommendation + fallback baseline 50, AnalyticsScreen Variant ε retired density and added Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison with anti-toxicity framing, and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) structurally enforced. Audit status `tech_debt` accepted at close — Phase 13/17 lack VERIFICATION.md; 3 Nyquist VALIDATION.md drafts; documentation-grade debt only. Full details: `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.

</details>

### 🚧 v1.3 迭代帐本输入 (Phases 18-22) — ACTIVE

- [x] **Phase 18: Shared Details Form Foundation** — Single shared details widget (INPUT-03/04 + EDIT-01/02 foundation): contract supports new/edit modes, OCR two-step architectural slot, edit-from-list entry path, `entry_source` preserved on save (completed 2026-05-22)
- [x] **Phase 19: Manual One-Step + Keypad Polish** — Manual entry collapses to single screen, no "下一步" button; numeric keypad enlarged to platform-min touch targets (KEYPAD-01, INPUT-01) (completed 2026-05-23)
- [x] **Phase 20: Voice Number Parser (zh + ja)** — Compound number state machine, intra-pause continued-listening window, locale-aware combining; per-locale corpus fixtures ≥95% accuracy (VOICE-01/02/03) (completed 2026-05-24)
- [x] **Phase 21: Voice Category Resolver Level-2 Enforcement** — Always-level-2 contract, level-1 → first-level-2 fallback, merchant DB + synonym dictionary data sources extensible without code changes (VOICE-04/05/06) (completed 2026-05-24)
- [x] **Phase 22: Voice One-Step Integration + Record Button UX** — Voice fills shared details form in-place on single screen; record button idle caption + recording-state visual change within 100ms (INPUT-02, REC-01, REC-02) — code goal achieved (5/5 SC), 2 BLOCKER gaps pending closure (G-01 recognizer self-termination, G-02 silent errors) (completed 2026-05-25)

### 📋 Next Milestone (Planned)

Use `/gsd:new-milestone` after v1.3 ships. Candidate themes carried in PROJECT.md:

- **MOD-005 OCR writer landing** — receipt → text → fields (v1.3 reserves the details-form slot; v1.4+ wires the writer)
- **Family privacy hardening (FAMILY-V2-01/02/03)** — strict consent gate, schema v17→v18 if needed
- **Release readiness QA (FUTURE-QA-01)** — owner-driven smoke tests before v1 release
- **Tooling/docs cleanup (FUTURE-TOOL-03, FUTURE-DOC-*)** — coverage threshold review, ADR/MOD numbering drift
- **fl_chart 1.x upgrade (TOOL-V2-01)** — bundle with any future Analytics chart-stack work

## Phase Details

### Phase 18: Shared Details Form Foundation

**Goal**: Consolidate the entry-details surface into one Freezed-backed widget that serves manual single-screen, voice single-screen, OCR two-step, and edit-existing flows — with `entry_source` preservation on edit and the OCR architectural slot reserved.
**Depends on**: Nothing (first v1.3 phase; foundation for 19/22)
**Requirements**: INPUT-03, INPUT-04, EDIT-01, EDIT-02
**Success Criteria** (what must be TRUE):

  1. A single `TransactionDetailsForm` widget renders all editable fields (amount, category, note, merchant, date, ledger type) and is consumed by the manual entry screen, the future voice integration point, the OCR two-step container, and the edit-existing entry path — same widget, configured via a mode parameter (`new` vs `edit`) and an optional `Transaction` seed
  2. User can tap any existing transaction in the home recent-tx list and the shared details form opens pre-populated with that transaction's current field values; cancel returns to the list with no DB write
  3. User can modify any editable field in edit mode, tap save, and the underlying Drift row is updated atomically (single transaction, no partial writes verified by integration test); `entry_source` value present before the edit is preserved verbatim (does not flip to `'manual'` on edit) — enforced by a Drift DAO test exercising all three `EntrySource` literals
  4. OCR flow code path exposes a two-step container (capture stub → details review) whose step 2 mounts the same shared widget; no OCR writer is implemented — only the architectural slot is reserved and a TODO-marker test asserts the integration seam exists
  5. No new Drift schema migration introduced; current v17 schema (`entry_source` column) suffices for edit/save path

**Plans**: 8 plans

- [x] 18-01-PLAN.md — Freezed domain models (OcrParseDraft + TransactionDetailsFormConfig + TransactionDetailsFormResult)
- [x] 18-02-PLAN.md — UpdateTransactionUseCase + TransactionChangeTracker.trackUpdate + updateTransactionUseCaseProvider
- [x] 18-03-PLAN.md — 5 new ARB keys (transactionEditTitle, ocrReviewTitle, ocrReviewEmptyDraftBanner, transactionUpdated, failedToUpdate) × ja/zh/en + flutter gen-l10n
- [x] 18-04-PLAN.md — TransactionDetailsForm widget (load-bearing — extracts confirm-screen body, exposes submit())
- [x] 18-05-PLAN.md — Refactor TransactionConfirmScreen to thin .new host wrapping TransactionDetailsForm
- [x] 18-06-PLAN.md — New TransactionEditScreen (.edit host) + new OcrReviewScreen (.new host with MOD-005 marker)
- [x] 18-07-PLAN.md — Wire HomeTransactionTile.onTap → TransactionEditScreen + OCR shutter onTap → OcrReviewScreen
- [x] 18-08-PLAN.md — Test suite (form widget tests, use case unit, DAO entry_source round-trip, home tap-to-edit, OCR two-step seam D-14)

**UI hint**: yes

### Phase 19: Manual One-Step + Keypad Polish

**Goal**: Collapse manual entry into one screen reusing Phase 18's shared form, and polish the numeric keypad so digit taps register reliably at thumb reach on iOS/Android minimum touch targets.
**Depends on**: Phase 18 (consumes shared details form)
**Requirements**: KEYPAD-01, INPUT-01
**Success Criteria** (what must be TRUE):

  1. Manual entry flow renders amount + category (二级) + note + merchant + date + ledger type (悦己/生存) all inline on a single screen with no "下一步" navigation button anywhere in the manual path — verified by widget test asserting the absence of a "next/下一步" button and presence of all six field surfaces
  2. Each amount-keypad digit key meets the platform-minimum touch target (iOS HIG 44pt × 44pt / Material 48dp × 48dp), measured by widget test querying rendered button constraints
  3. Adjacent keypad keys are visually discriminable (spacing/divider/contrast) per a golden test covering ja/zh/en locale renders in both light and dark themes
  4. User can save a manual entry from the single screen and the resulting Transaction row has `entry_source = 'manual'` (DAO-level integration test)
  5. All new UI strings (any keypad helper text, save button label changes) are routed through `S.of(context)` with parity across ja/zh/en ARB files; `flutter gen-l10n` runs clean

**Plans**: 5 plans

- [x] 19-01-PLAN.md — ARB keyboardToolbarDone + AmountEditBottomSheet extraction + TransactionDetailsForm externalize-amount refactor (Wave 1, D-14/D-22)
- [x] 19-02-PLAN.md — SmartKeyboard responsive height + 48dp clamp + actionLabel rename + 6 golden baselines (Wave 1, D-06/07/08/09 + SC-2/SC-3)
- [x] 19-03-PLAN.md — KeyboardToolbar + ManualOneStepScreen + voice/router/shell repoints + widget tests (Wave 2, D-01..D-13/D-16/D-24 + SC-1)
- [x] 19-04-PLAN.md — D-14 spillover: TransactionEditScreen + OcrReviewScreen adopt host-owned AmountDisplay + AmountEditBottomSheet (Wave 2)
- [x] 19-05-PLAN.md — Delete TransactionEntryScreen/ConfirmScreen + stale tests, re-target merchant-learning test, SC-4 integration test, D-16 voice regression test, phase-wide gate (Wave 3)

**UI hint**: yes

### Phase 20: Voice Number Parser (zh + ja)

**Goal**: Rebuild the voice number recognition state machine so compound numbers across 千/百/十/零/万 combine correctly without digit dropping, handle intra-number pauses via a continued-listening window, and reach ≥95% accuracy on per-locale committed corpora.
**Depends on**: Nothing structural (independent of Phase 18 UI work; can run in parallel with Phase 19)
**Requirements**: VOICE-01, VOICE-02, VOICE-03
**Success Criteria** (what must be TRUE):

  1. `voice_number_parser_corpus_test.dart` (zh corpus) reports ≥95% accuracy on a committed fixture covering 千/百/十/零 combinations, with and without intra-pauses; per-case results are emitted so failing cases are inspectable
  2. `voice_number_parser_corpus_test.dart` (ja corpus) reports ≥95% accuracy on a committed fixture covering 千/百/十/万 combinations including 万-scale amounts (e.g. 一万二千 → 12000), with and without intra-pauses; per-locale accuracy reported separately from zh
  3. Specific anchor cases verified: zh "2千2百零4元" → 2204, zh "1千8百4十元" with pause-before-4十 → 1840, ja 「にせんにひゃくよん」 → 2204, ja 「せんはっぴゃくよんじゅう」 with pause-before-よんじゅう → 1840 (each as a named test case, not just corpus aggregate)
  4. A locale-aware numeral-combining state machine + continued-listening window implementation lives in `lib/infrastructure/` (parser-tech, not feature code) per "Thin Feature" rule; consumed by feature voice flow via Application use case
  5. `flutter analyze` 0 issues; per-file coverage ≥70% on new parser files; no Drift schema change

**Plans**: TBD

### Phase 21: Voice Category Resolver Level-2 Enforcement

**Goal**: Guarantee voice-driven Transactions always carry a level-2 category by enforcing the always-level-2 contract — falling back to a level-1's first level-2 sub-category when no exact level-2 match exists — and make the resolution data sources (merchant database + synonym dictionary) extensible without code changes.
**Depends on**: Phase 20 (consumes the strengthened voice parser pipeline; shares test infrastructure)
**Requirements**: VOICE-04, VOICE-05, VOICE-06
**Success Criteria** (what must be TRUE):

  1. Voice category resolver returns a level-2 category whenever the spoken phrase matches any level-2 entry in the merchant database or synonym dictionary — verified by a corpus test with mixed level-2-direct-match cases
  2. When voice resolves only to a level-1 category (no level-2 entry matched), the resolver returns that level-1's first level-2 sub-category — verified by a corpus test specifically covering level-1-only inputs; the resulting `Transaction.categoryId` value is asserted to always reference a level-2 row in the categories table (DAO integration test)
  3. Resolver consults both (a) the merchant database AND (b) a synonym dictionary for common spoken-form variants before any fallback; lookup order documented in code and verified by unit test that mocks each data source independently
  4. Both data sources are extensible by adding entries (rows / YAML / ARB-adjacent format — implementation choice) without modifying resolver code; verified by a test that adds an entry to a fixture data source and asserts the new mapping resolves end-to-end
  5. `flutter analyze` 0 issues; per-file coverage ≥70% on new resolver files; resolver placement honors "Thin Feature" rule (lives in `lib/application/` or `lib/infrastructure/`, not inside `lib/features/`)

**Plans**: 6 plans

- [x] 21-01-PLAN.md — Architecture invariant test for D-03 L1 → ${l1Id}_other (with cat_other_expense override)
- [x] 21-02-PLAN.md — Synonym dict infrastructure (DAO + repo + DefaultVoiceSynonyms + SeedVoiceSynonymsUseCase + Riverpod + AppInitializer)
- [x] 21-03-PLAN.md — VoiceCategoryResolver class + unit tests (mocktail, per-step VOICE-06 coverage)
- [x] 21-04-PLAN.md — MerchantDatabase 12-entry L2 enrichment + D-04 ID drift fixes
- [x] 21-05-PLAN.md — Wire resolver into ParseVoiceInputUseCase, swap Riverpod provider, delete FuzzyCategoryMatcher + levenshtein + stale tests
- [x] 21-06-PLAN.md — Voice category corpus tests (zh + ja) + fixtures + VOICE-06 runtime-insert test + VOICE-SCANNER-ALLOWLIST extension

### Phase 22: Voice One-Step Integration + Record Button UX

**Goal**: Wire the strengthened voice parser + level-2 category resolver into the shared details form on the same single screen as manual entry, and polish the record button so its idle caption unambiguously communicates the interaction model and its recording state is visibly distinct within 100ms.
**Depends on**: Phase 18 (shared details form), Phase 20 (voice number parser), Phase 21 (level-2 category resolver)
**Requirements**: INPUT-02, REC-01, REC-02
**Success Criteria** (what must be TRUE):

  1. Voice-driven ledger entry completes on the same single screen as manual entry — voice parser output fills amount, category, note, merchant fields in-place in the shared details form (Phase 18 widget); user can edit any auto-filled field before saving — verified by widget integration test simulating a voice transcript and asserting field values + post-edit save path
  2. Saved voice entry produces a Transaction row with `entry_source = 'voice'` (DAO integration test)
  3. Record button's idle-state caption text unambiguously communicates the interaction model (tap-to-toggle vs hold-to-record); the chosen model is consistent app-wide — verified by widget test asserting caption string presence + an integration test that exercises the chosen interaction on at least one other voice surface (if any exists) or documents the single-surface choice in a Decision Record
  4. While recording, the record button visibly changes (color/shape/icon) AND caption text changes to "录音中…" (zh) / equivalent for ja/en — verified by widget test asserting both visual diff (golden) and caption text change; perceived state change within 100ms enforced by a timing test (`expect(stopwatch.elapsedMilliseconds, lessThan(100))` between record-start trigger and rebuild completion)
  5. All new/changed UI strings (record button captions, recording status text) routed through `S.of(context)` with ja/zh/en parity; `flutter gen-l10n` clean; `flutter analyze` 0 issues

**Plans**: 10 plans (7 shipped + 3 gap closure for G-01/G-02 elevated from code review)

- [x] 22-01-PLAN.md — ARB key swap (tapToRecord → holdToRecord + recording × ja/zh/en) + flutter gen-l10n (Wave 0)
- [x] 22-02-PLAN.md — TransactionDetailsForm D-07 extension (3 new public setters: updateCategory / updateMerchant / updateNote) + 9 widget tests (Wave 0)
- [x] 22-03-PLAN.md — AppColors recordingGradientStart / recordingGradientEnd constants (Wave 0)
- [x] 22-04-PLAN.md — voice_input_screen.dart body rewrite: embed TransactionDetailsForm, hold-to-record gesture (RawGestureDetector + Duration.zero), AnimatedContainer shape morph, AnimatedSwitcher caption swap, Save CTA, FocusNode auto-stop, WidgetsBindingObserver lifecycle cancel (Wave 1)
- [x] 22-05-PLAN.md — voice_input_screen_test.dart major rewrite (8 tests: REC-01/REC-02/D-08/D-09/INPUT-02 happy path) + new idle golden harness + delete obsolete voice_to_manual_one_step_screen_test.dart (Wave 2)
- [x] 22-06-PLAN.md — NEW voice_save_entry_source_test.dart integration test (SC-2 DAO round-trip with real Drift DB + real CreateTransactionUseCase) (Wave 2)
- [x] 22-07-PLAN.md — Phase verification + closure SUMMARY (analyze 0, custom_lint 0, gen-l10n clean, test pass, coverage ≥70%, no schema/pubspec drift) (Wave 2)
- [x] 22-08-PLAN.md — Gap closure G-02 i18n foundation: add 4 voice-recognition error ARB keys (voiceRecognitionErrorNetwork/NoMatch/Audio/Unknown × ja/zh/en) + flutter gen-l10n (Wave 0)
- [x] 22-09-PLAN.md — Gap closure G-01 + G-02 code fix: voice_input_screen.dart _onStatus drives commit on recognizer self-termination (CR-01); _onError surfaces localized SoftToast + permanent-flag mic gate (CR-02 + WR-05) (Wave 1)
- [x] 22-10-PLAN.md — Gap closure G-01 + G-02 widget tests: +3 tests (status-driven commit, transient-error toast, permanent-error mic gate) in voice_input_screen_test.dart (Wave 2)

**UI hint**: yes

## Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.0 Codebase Cleanup Initiative | 1-8 | 48/48 | Complete | 2026-04-29 |
| v1.1 Happiness Metric & Display | 9-12 | 40/40 | Complete | 2026-05-05 |
| v1.2 Happiness Metric Refresh | 13-17 | 37/37 | Complete | 2026-05-21 |
| v1.3 迭代帐本输入 | 18-22 | 0/0 | Not started | — |

### v1.3 Phase Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 18. Shared Details Form Foundation | 8/8 | Complete   | 2026-05-22 |
| 19. Manual One-Step + Keypad Polish | 5/5 | Complete    | 2026-05-23 |
| 20. Voice Number Parser (zh + ja) | 9/9 | Complete   | 2026-05-24 |
| 21. Voice Category Resolver Level-2 Enforcement | 6/6 | Complete   | 2026-05-24 |
| 22. Voice One-Step Integration + Record Button UX | 10/10 | Complete    | 2026-05-25 |

### Phase 23: v1.3 cleanup: scanner allow-lists + voice flow polish

**Goal:** Close v1.3 by absorbing carried tech-debt: Phase 22 voice-flow surgical polish (D-05 intra-session guard, D-07 cold-start race, D-08 popUntil deferral, D-09 listener-leak regression, D-10 mixin extraction, D-11 G-02 localized assert), Phase 21 mechanical polish (D-12 constant dedup, D-13 substring guard, D-14 SeedAllUseCase, D-15 その他/其他/other seed), documentation reconciliation (D-04 REQUIREMENTS.md + 7 SUMMARY frontmatter backfills), and 9 carried device UATs (Phase 19 + 20 + 22). Cleanup-only — no new user-visible capabilities.
**Requirements**: None — phase_req_ids is null. CONTEXT.md D-01..D-20 are the authoritative scope record. The 10 v1.3 REQ-IDs flipped in D-04 belong to Phases 18/20/21 functionally; Phase 23 only reconciles documentation metadata.
**Depends on:** Phase 22
**Plans:** 5/8 plans executed

Plans:
**Wave 1**

- [x] 23-01-PLAN.md — D-12 IN-01+IN-05 constant dedup (kVoiceSynonymSeedEpoch + kCategoryOtherIdOverrides) + D-13 MerchantDatabase 3-char substring guard + regression tests (Wave 1)
- [x] 23-02-PLAN.md — D-14 SeedAllUseCase wrapper + Riverpod provider + main.dart collapse + ordering/short-circuit unit tests (Wave 1)
- [x] 23-04-PLAN.md — D-10 IN-02 VoiceRecognitionEventHandlerMixin extraction (screen drops <800 LOC) + VoiceChunkMerger.lastFinalAt public getter prep for D-05 (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 23-03-PLAN.md — D-15 その他/其他/other seed expansion + voice_category_corpus zh/ja anchor tests + new voice_corpus_en hedge skeleton (Wave 2)
- [x] 23-05-PLAN.md — D-05 WR-NEW-01 intra-session guard in mixin onStatus + per-mixin unit tests + D-09 Open Q2 listener-leak regression test (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 23-06-PLAN.md — D-07 WR-01 voiceLocaleId cold-start race fix + D-08 WR-04 popUntil deferral via waitForCelebrationDismissed + D-11 G-02 localized assert (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 23-07-PLAN.md — D-04 REQUIREMENTS.md 10 checkbox flips + 10 traceability-row flips + 7 SUMMARY frontmatter backfills (Wave 4, doc-only)

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 23-08-PLAN.md — D-03 device UAT runbook aggregating 9 carried items (Phase 19 + 20 + 22); accepts-deferral per Phase 11/13/17 precedent (Wave 5, non-autonomous)
