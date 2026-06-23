---
phase: 50
slug: decoupled-recognizers
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-23
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Instantiated from 50-RESEARCH.md §"Validation Architecture" (the real test map, framework, and Wave-0 list).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (+ `integration_test` for any encrypted-DB ladders; none new this phase) |
| **Config file** | none — default flutter test discovery (existing infrastructure; no install) |
| **Quick run command** | `flutter test test/unit/application/voice/recognition/ test/unit/application/voice/parse_voice_input_use_case_test.dart test/unit/shared/constants/default_synonyms_categoryid_test.dart test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | quick ~20-40s (scoped recognizer/seed tests); full ~6-10 min (whole suite + analyze) |

> Code generation prerequisite: `flutter pub run build_runner build --delete-conflicting-outputs` after any `@freezed`/`@riverpod` change (Plan 01 models, Plan 05 VoiceParseResult + provider rename). Force-add gitignored-yet-tracked generated files (`git add -f lib/**/*.freezed.dart lib/**/*.g.dart`).

---

## Sampling Rate

- **After every task commit:** Run the **Quick run command** (scoped recognizer + seed + orchestrator tests).
- **After every plan wave merge:** Run the **FULL suite command** — `flutter analyze` (0 issues) **then** `flutter test` (whole suite). This is MANDATORY per MEMORY.md (`gsd-post-merge-gate-flutter-mismatch` / `gsd-parallel-executor-arb-and-gate-gotchas`): scoped tests miss architecture tests like `hardcoded_cjk_ui_scan`, `provider_graph_hygiene_test`, `domain_import_rules_test`; the post-merge gate must run the full suite via `flutter`, never `xcodebuild` or a trivial `true`.
- **Before `/gsd-verify-work`:** Full suite green + `flutter analyze` 0 issues.
- **Max feedback latency:** ~40 seconds (quick) per task; full suite at each of the 3 wave boundaries.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | DECOUP-03 | T-50-02 | Domain value objects, no outer-layer import, no PII | unit (analyze) | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze lib/features/accounting/domain/models/merchant_candidate.dart lib/features/accounting/domain/models/merchant_match_entry.dart` | ✅ created here | ⬜ pending |
| 50-01-02 | 01 | 1 | DECOUP-03 | T-50-01 | Parameterized Drift read only; point-in-time join | unit | `flutter test test/unit/data/repositories/merchant_repository_loadallformatching_test.dart` | ❌ W0 | ⬜ pending |
| 50-02-01 | 02 | 1 | DECOUP-02 | T-50-03 | Orphan-categoryId hard gate (silent-null prevention) | unit | `flutter test test/unit/shared/constants/default_synonyms_categoryid_test.dart` | ❌ W0 (clone of merchants gate) | ⬜ pending |
| 50-02-02 | 02 | 1 | DECOUP-02 | T-50-02 | zh+ja public seed literals only; no English; no PII | unit | `flutter test test/unit/shared/constants/default_synonyms_categoryid_test.dart test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart` | ⚠️ extends seed (file exists) | ⬜ pending |
| 50-02-03 | 02 | 1 | DECOUP-02 | T-50-08 | Speakable-L2 set-completeness machine gate (D-04) | unit | `flutter test test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart` | ❌ W0 | ⬜ pending |
| 50-02-04 | 02 | 1 | DECOUP-02 | T-50-02 | Human word-quality + exclusion-set spot-check (D-04 mandate) | manual | (blocking `checkpoint:human-verify` — see Manual-Only Verifications) | n/a | ⬜ pending |
| 50-03-01 | 03 | 2 | DECOUP-03 | T-50-04 / T-50-05 | Adversarial corpus RED; floor + script-min-length defined | unit (RED) | `flutter test test/unit/application/voice/recognition/merchant_recognizer_test.dart` (expected RED) | ❌ W0 | ⬜ pending |
| 50-03-02 | 03 | 2 | DECOUP-03 | T-50-04 / T-50-05 | Anchored scoring; no-log discipline (V7); DECOUP-01 independence | unit (GREEN) | `flutter test test/unit/application/voice/recognition/merchant_recognizer_test.dart test/unit/application/voice/recognition/merchant_false_positive_test.dart` | ❌ W0 | ⬜ pending |
| 50-04-01 | 04 | 1 | DECOUP-01, DECOUP-02 | T-50-04 | Keyword-only engine; constructional independence; no merchant coupling | unit (analyze) | `flutter analyze lib/application/voice/recognition/category_recognizer.dart` | ✅ created here | ⬜ pending |
| 50-04-02 | 04 | 1 | DECOUP-01, DECOUP-02 | T-50-06 | Ported keyword/substring/_ensureL2 cases; no merchant-step assertions | unit | `flutter test test/unit/application/voice/recognition/category_recognizer_test.dart` | ❌ W0 | ⬜ pending |
| 50-05-01 | 05 | 3 | DECOUP-01/02/03 | T-50-01 | D-05 + resolver retirement; provider rewiring; no raw SQL from input | unit (build) | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze` | ⚠️ rewires/deletes | ⬜ pending |
| 50-05-02 | 05 | 3 | DECOUP-01/02/03 | T-50-07 | Thin merge + 0.85 floor; ledger = pure fn; no line-106 short-circuit | unit (analyze) | `flutter analyze lib/application/voice/parse_voice_input_use_case.dart lib/features/accounting/domain/models/voice_parse_result.dart` | ⚠️ rewrite | ⬜ pending |
| 50-05-03 | 05 | 3 | DECOUP-01/02/03 | T-50-05 / T-50-07 | Four-quadrant + ledger-invariant + learning-key identity (260526-pg6) | unit | `flutter test test/unit/application/voice/parse_voice_input_use_case_test.dart` | ⚠️ rewrite (exists for old shape) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Invariant / regression cross-checks (run inside the above tests, not separate tasks):**
- `normalizeMerchantKey('スタバ')` == the Starbucks seed matchKey — asserted in `merchant_recognizer_test.dart` (Pitfall 1; reuse `test/unit/infrastructure/ml/merchant_name_normalizer_test.dart` for the normalizer invariant).
- `resolvedKeyword` write-key == recognizer read-key (260526-pg6) — asserted in `parse_voice_input_use_case_test.dart` (50-05-03).

---

## Wave 0 Requirements

These test files/fixtures must be created **before or as the first step of** their owning task (the `<verify><automated>` of several tasks references them). Owning task is in parentheses.

- [ ] `test/unit/data/repositories/merchant_repository_loadallformatching_test.dart` — join-correctness for `loadAllForMatching()` (50-01-02)
- [ ] `test/unit/shared/constants/default_synonyms_categoryid_test.dart` — orphan-categoryId hard gate, clone of `default_merchants_categoryid_test.dart` extended to allow `_ensureL2`-resolvable L1 ids (50-02-01)
- [ ] `test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart` — D-04 speakable-L2 set-completeness gate (level-2 ids MINUS documented exclusion set; ≥1 zh + ≥1 ja per id; kana-presence zh/ja classifier; names uncovered ids) (50-02-03)
- [ ] `test/fixtures/merchant_false_positive_corpus.dart` — the ~40 adversarial entries (お米 / 杉並区 / comment-words / generic substrings that collide with chain names at scale) (50-03-01)
- [ ] `test/unit/application/voice/recognition/merchant_recognizer_test.dart` — scoring tiers (exact/prefix/containment) + four surface forms (スタバ / ｽﾀﾊﾞ / マクド / Starbucks ≥0.85) + ranking/dedupe + normalize-equality invariant (50-03-01)
- [ ] `test/unit/application/voice/recognition/merchant_false_positive_test.dart` — ~40-entry adversarial gate (each yields empty OR best score < 0.85 floor); validates A1 floor + A2 script-min-length thresholds (50-03-01)
- [ ] `test/unit/application/voice/recognition/category_recognizer_test.dart` — ported from `voice_category_resolver_test.dart`, drop merchant-step-1 assertions (50-04-02)
- [ ] `test/unit/application/voice/parse_voice_input_use_case_test.dart` — REWRITE for two-engine + keyword-priority + 0.85 floor + four-quadrant (merchant✓keyword✓ / merchant✓keyword✗ / merchant✗keyword✓ / merchant✗keyword✗) + ledger invariant + learning-key identity (50-05-03)
- [ ] Architecture confirmation (no new file): `provider_graph_hygiene_test.dart` + `domain_import_rules_test.dart` still pass after the provider rename (`voiceCategoryResolverProvider` → `categoryRecognizerProvider`) and the new domain models — verified by the FULL-suite wave gate, not a new test.

> No framework install needed — `flutter_test` is already the project test harness.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Authored keyword-list word QUALITY + exclusion-set intent (D-04 spot-check) | DECOUP-02 / D-04 | Word naturalness/register and "is this L2 actually speakable" are authoring judgments a machine gate cannot make; the two machine gates (orphan-id + speakable-L2 coverage) already prove MEMBERSHIP, so the human pass is QUALITY-only. Blocking `checkpoint:human-verify` (50-02-04). | 1. Review the full authored zh+ja list (Plan 02 Task 2 output). 2. Spot-check 10-15 categories across L1 groups for natural zh + ja words and correct categoryId mapping. 3. Confirm the documented exclusion set in `default_synonyms_speakable_coverage_test.dart` (pure `_other`/fallback + `cat_asset_*`/`cat_insurance_*`/`cat_special_*`/`*_tax`) matches intent; flag any to include/exclude. 4. Run both seed gates green. 5. Type "approved" or list corrections. Do NOT commit the seed until approved. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or a Wave 0 dependency (only 50-02-04 is manual — it is a D-04-mandated human spot-check on top of two machine gates, not an automation gap)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every code-producing task has an automated command; the one manual task sits between fully-gated tasks)
- [x] Wave 0 covers all MISSING references (8 test/fixture files enumerated above; each maps to an owning task)
- [x] No watch-mode flags (no `--watch`; per-wave gate uses one-shot `flutter analyze && flutter test`)
- [x] Feedback latency < 40s for the quick scoped command
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-23
