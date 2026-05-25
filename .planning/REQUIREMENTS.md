# Requirements: Home Pocket — まもる家計簿

**Defined:** 2026-05-22
**Milestone:** v1.3 迭代帐本输入
**Core Value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes survival spending from soul spending so families can have honest money conversations.

**Milestone goal:** 把账本录入从「多步、易误按、语音不准」打磨成「单屏、稳准、语音可信」的核心体验，并复用同一 details 表单作为已存账本的编辑入口。

---

## v1.3 Requirements

### Numeric Keypad

- [x] **KEYPAD-01**: User can tap each amount-input digit key with the intended digit registering ≥95% of taps; key height/touch-target meets platform minimum (iOS HIG 44pt / Material 48dp) and visual hierarchy makes adjacent keys discriminable at thumb reach

### One-Step Recording

- [x] **INPUT-01**: User can complete a manual ledger entry on a single screen — amount, category (二级), note, merchant, date, and ledger type (悦己/生存) all editable inline without a "下一步" navigation
- [x] **INPUT-02**: User can complete a voice-driven ledger entry from the same single screen — voice parser fills amount, category, note, merchant fields in-place; user can edit any field before saving
- [ ] **INPUT-03**: Details form is implemented as a single shared widget consumed by both manual/voice single-screen flow AND the future OCR two-step flow (capture → details review). Widget contract supports both "new entry" and "edit existing" modes
- [ ] **INPUT-04**: OCR-flow code path preserves a two-step UX (capture → details) but the details step reuses the INPUT-03 shared widget; OCR writer itself remains out of v1.3 scope, only the architectural slot is reserved

### Voice Number Recognition (Chinese)

- [ ] **VOICE-01**: Voice parser correctly converts compound numbers without digit dropping —
  - zh: "2千2百零4元" → 2204
  - ja: "にせんにひゃくよん（円）" → 2204
- [ ] **VOICE-02**: Voice parser correctly combines intra-number pauses (no fragmenting into separate numeric tokens) via continued-listening window + locale-aware numeral combining state machine —
  - zh: "1千8百4十元" with pause before "4十" → 1840 (not 1800 + 40)
  - ja: "せんはっぴゃくよんじゅう（円）" with pause before "よんじゅう" → 1840 (not 1800 + 40)
- [ ] **VOICE-03**: Voice parser correctness reaches ≥95% accuracy on EACH of two committed test corpora:
  - zh corpus: 千/百/十/零 combinations, with and without intra-pauses
  - ja corpus: 千/百/十/万 combinations (incl. 万-scale amounts like 一万二千 = 12000), with and without intra-pauses
  - both corpora committed as test fixtures; per-locale accuracy reported separately

### Voice Category Recognition

- [ ] **VOICE-04**: Voice category resolver resolves to a level-2 (sub-)category whenever the spoken phrase is matchable to a level-2 entry in the merchant database or synonym dictionary
- [ ] **VOICE-05**: When voice resolves only to a level-1 category (no level-2 match), the resolver returns that level-1's first level-2 sub-category as the chosen value — the resulting Transaction always has a level-2 category, never bare level-1
- [ ] **VOICE-06**: Voice category resolver consults (a) merchant database lookups AND (b) a synonym dictionary for common spoken-form variants before falling back; both data sources are extensible by adding entries without code changes

### Record Button UX

- [x] **REC-01**: Record button's idle-state caption unambiguously communicates the interaction model (tap-to-toggle vs. hold-to-record); chosen model is consistent app-wide
- [x] **REC-02**: While recording, the record button visibly changes (color/shape/icon) AND the caption text changes to "录音中…" (i18n: ja/zh/en three locales); state change is perceivable within 100ms of recording start

### Details Form as Edit Entry

- [ ] **EDIT-01**: User can tap an existing transaction from the home recent-tx list (or other transaction list views) and open the INPUT-03 shared details form in "edit" mode pre-populated with the current transaction's field values
- [ ] **EDIT-02**: User can modify any editable field in edit mode and save the change; the underlying Drift row is updated atomically; `entry_source` is preserved (does not flip to 'manual' on edit)

---

## v1.4+ Requirements (deferred)

### OCR (MOD-005)

- **OCR-01**: User can capture a receipt photo and the system OCRs it into a draft details form (INPUT-03 shared widget) ready for user confirmation — `entry_source='ocr'` schema slot already reserved in v1.2

### Family Privacy Hardening (carry-forward from v1.0+)

- **FAMILY-V2-01**: Strict per-member family analytics consent gate
- **FAMILY-V2-02**: Granular consent management UI
- **FAMILY-V2-03**: Schema/settings work for opt-in family data sharing (possibly schema v17→v18)

### Release-Readiness QA

- **FUTURE-QA-01**: Owner-driven smoke test execution before any public v1 release

### Documentation / Tooling Cleanup

- **FUTURE-DOC-01..06**: MOD-numbering drift, ARCH-008 ADR citation, missing VALIDATION/VERIFICATION docs, doc-sweep verifier CI wiring
- **FUTURE-TOOL-03**: Coverage threshold review (currently 70% post-v1.0; re-evaluate raising to 80%)

### Chart Stack Upgrade

- **TOOL-V2-01**: fl_chart 1.x upgrade (bundle with next analytics chart work)

---

## Out of Scope (v1.3)

Explicitly excluded to keep the milestone focused on the input-flow axis.

| Feature | Reason |
|---------|--------|
| MOD-005 OCR writer landing (real photo → text → fields) | Schema slot already reserved in v1.2; v1.3 only reserves the architectural details-form slot, writer pipeline left for v1.4+ |
| FAMILY-V2-01/02/03 family privacy hardening | Orthogonal to input flow; large independent module |
| FUTURE-QA-01 release smoke tests | Release-axis work, not input-axis |
| FUTURE-DOC / FUTURE-TOOL docs cleanup | Doc/tooling drift not on critical path for input UX |
| fl_chart 1.x upgrade | Analytics-stack work, no input-flow dependency |
| Joy metric semantic changes | ADR-016 closed in v1.2; all `Σ joy_contribution`, HomeHero isolation, and reset semantics frozen |
| New gamification surfaces (streaks, achievement toasts, leaderboards, cross-period delta) | Hard-blocked by ADR-012 and ADR-016 §5 — permanent cross-milestone boundaries |
| HomeHero ring behavior change | Hard-blocked by ADR-016 §3 isolation invariant — input-flow work must not touch HomeHero rendering or provider graph |
| New Drift schema migration | Avoid unless EDIT-01/02 requires; voice/keypad/UX changes should not require schema work |
| English (en) voice input | v1.3 scope is zh + ja voice parsing only; English voice parser deferred |

---

## Traceability

Mapped by roadmapper on 2026-05-22.

| Requirement | Phase | Status |
|-------------|-------|--------|
| KEYPAD-01 | Phase 19 | Complete |
| INPUT-01 | Phase 19 | Complete |
| INPUT-02 | Phase 22 | Complete |
| INPUT-03 | Phase 18 | Pending |
| INPUT-04 | Phase 18 | Pending |
| VOICE-01 | Phase 20 | Pending |
| VOICE-02 | Phase 20 | Pending |
| VOICE-03 | Phase 20 | Pending |
| VOICE-04 | Phase 21 | Pending |
| VOICE-05 | Phase 21 | Pending |
| VOICE-06 | Phase 21 | Pending |
| REC-01 | Phase 22 | Complete |
| REC-02 | Phase 22 | Complete |
| EDIT-01 | Phase 18 | Pending |
| EDIT-02 | Phase 18 | Pending |

**Coverage:**
- v1.3 requirements: 15 total
- Mapped to phases: 15 / Unmapped: 0 ✓
- Phase distribution: Phase 18 (4 reqs), Phase 19 (2 reqs), Phase 20 (3 reqs), Phase 21 (3 reqs), Phase 22 (3 reqs)

---

## Cross-cutting Constraints (carried from prior milestones, apply to all v1.3 work)

- **i18n parity**: All new/changed UI text via `S.of(context)`; ARB ja/zh/en three locales updated atomically; `flutter gen-l10n` must succeed without warnings
- **Quality gates (permanent)**: `flutter analyze` 0 issues; `dart run custom_lint --no-fatal-infos` 0 errors; `import_guard` 0 violations; `riverpod_lint` 0 violations; per-file coverage ≥70% on touched files; global coverage ≥70%; `build_runner` clean diff; `sqlite3_flutter_libs` rejected
- **Architecture**: 5-layer Clean Architecture + "Thin Feature" rule (no `application/`, `infrastructure/`, `data/tables/`, `data/daos/` inside `lib/features/`)
- **Immutability**: Use `copyWith` on Freezed classes; never mutate
- **ADR-012 / ADR-016 boundaries**: No gamification, no cross-period delta surfaces, no HomeHero semantic change; permanent cross-milestone
- **Drift schema**: No new schema migration unless absolutely required by EDIT-01/02 (current = v17 `entry_source`)
- **Tech-stack pins**: intl 0.20.2, `sqlcipher_flutter_libs`, Mocktail; pubspec dependency trio (file_picker/package_info_plus/share_plus) per CLAUDE.md

---

*Requirements defined: 2026-05-22*
*Last updated: 2026-05-22 — traceability populated, 15/15 mapped to Phases 18-22*
