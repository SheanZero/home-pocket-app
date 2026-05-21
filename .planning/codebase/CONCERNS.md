# Codebase Concerns

**Analysis Date:** 2026-05-21
**Codebase state:** Post-v1.2 milestone close. Previous map dated 2026-04-25 (3 milestones of drift: v1.0 cleanup, v1.1 Happiness Metric, v1.2 Joy Migration).

---

## Severity Index

| Severity | Meaning |
|----------|---------|
| BLOCKER | Must fix before shipping to users |
| HIGH | Serious issue — fix before next milestone ships |
| MEDIUM | Real debt with tangible consequence; schedule explicitly |
| LOW | Quality/consistency issue; fix opportunistically |
| INFO | Cosmetic, tracking, or forward-compat note only |

---

## Security Concerns

### FUTURE-ARCH-04 — `recoverFromSeed()` key-overwrite (HIGH)

**Issue:** `recoverFromSeed()` in `lib/infrastructure/crypto/repositories/key_repository_impl.dart` (line 53) unconditionally overwrites the stored private key, public key, and device ID without first checking `hasKeyPair()`. By contrast, `generateKeyPair()` (line 24-26) throws `StateError` if a key pair already exists. Calling `recoverFromSeed()` on a device that already has live encrypted data would silently replace the keys, making the SQLCipher-encrypted database permanently unreadable.

**Files:** `lib/infrastructure/crypto/repositories/key_repository_impl.dart` (lines 53-78), `lib/infrastructure/crypto/repositories/key_repository.dart` (interface), `lib/infrastructure/crypto/services/key_manager.dart` (call delegation)

**Trigger path:** Any UI or recovery flow that calls `KeyManager.recoverFromSeed()` on a device that has previously completed `generateKeyPair()`.

**Fix approach:** Add `if (await hasKeyPair()) throw StateError('Key pair already exists...')` guard at line 54, matching the `generateKeyPair()` pattern. Alternatively add an explicit `--force` / `ClearAndRecover` overload with strong confirmation semantics.

**Deferred at:** v1.0 close (FUTURE-ARCH-04). Status: v2 backlog. No production recovery UI exists yet, limiting exposure — but this must be fixed before the recovery flow ships.

---

## Test Debt

### test_debt — 6 stale `family_insight_card_test.dart` failures (MEDIUM)

**Issue:** `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` line 82 expects `'今月、家族の小確幸 23回'` but the ARB key `analyticsFamilyHighlightsSentence` (`lib/l10n/app_ja.arb` line 1943) was changed by Phase 15 commit `8d5f136` to `'家族の小確幸 {N}回'` (dropping `今月、` prefix). The test's expected string is stale relative to the live ARB. Confirmed not broken by running `flutter test test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` — all 7 tests pass at HEAD, but this resolution should be tracked: either the tests were already re-baselined in a subsequent commit or the test logic skips that assertion in current execution.

**Status as of v1.2 close:** Phase 16 `deferred-items.md` logged this as pre-existing; Phase 16 SUMMARY noted it does not break any v1.2 user-observable flow. Tests pass at HEAD (verified 2026-05-21), so either the re-baseline happened silently or the assertion is no longer triggered. Re-confirm at next test run audit.

**Files:** `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart`, `lib/l10n/app_ja.arb`

**Deferred at:** v1.2 close.

### test_debt — 10 coverage-gate-deferred files at <70% (MEDIUM)

**Issue:** 10 production files are explicitly exempted from the per-file 70% coverage gate (`.planning/audit/coverage-gate-deferred.txt`). These are real coverage gaps that will not surface as CI failures until the deferral entries are removed. The global gate is also at 70% (lowered from 80% on 2026-04-28), and FUTURE-TOOL-03 (coverage-baseline-review) is now actively triggered post-v1.2.

**Deferred files and their stated coverage:**
- `lib/application/ml/repository_providers.dart` — 40%
- `lib/application/profile/repository_providers.dart` — 0%
- `lib/application/voice/repository_providers.dart` — 40%
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — 63%
- `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` — 46%
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — 53%
- `lib/features/family_sync/presentation/screens/create_group_screen.dart` — 18%
- `lib/features/family_sync/presentation/providers/state_sync.dart` — 62%
- `lib/features/home/presentation/providers/state_shadow_books.dart` — 35%
- `lib/features/settings/presentation/widgets/appearance_section.dart` — 60%

**Fix approach:** At FUTURE-TOOL-03 review: add widget/notifier tests for the large UI screens, or formalize a per-area threshold split. The analytics screen (`53%`) and transaction entry screen (`46%`) are the highest-risk gaps given their complexity.

**Deferred at:** v1.0 close (Phase 8 amendment). FUTURE-TOOL-03 triggered post-v1.2.

### test_debt — Phase 11 human UAT outstanding (LOW)

**Issue:** `test/` pass at HEAD but Phase 11's `11-VERIFICATION.md` carries `status: human_needed` for two scenarios: (1) visual layout coherence of AnalyticsScreen variant on real device, and (2) month chip + pull-to-refresh on real app data. The month chip was retired in v1.2 Phase 15 (replaced by `TimeWindowChip`), so item (2) is partially obsolete. Item (1) — visual layout coherence on a real device — is still valid for the new `TimeWindowChip` surface.

**Files:** `.planning/milestones/v1.1-phases/11-statistics-surface-for/11-VERIFICATION.md`, `lib/features/analytics/presentation/widgets/time_window_chip.dart`

**Deferred at:** v1.1 close.

---

## Documentation / Process Debt

### verification_gap — Phase 13 + 17 missing VERIFICATION.md (LOW)

**Issue:** Phases 13 and 17 have no `*-VERIFICATION.md` artifact in their milestone directories:
- `.planning/milestones/v1.2-phases/13-adr-016-backend-foundation/` — no `13-VERIFICATION.md`
- `.planning/milestones/v1.2-phases/17-manual-only-joy-sub-metric-happy-v2-03/` — no `17-VERIFICATION.md`

Phases 14, 15, 16 all have VERIFICATION.md. Live code for 13 and 17 is wired and integration-verified transitively via Phase 14 and at audit close. The gap is documentation-grade only.

**Remedy:** Run `/gsd:verify-work 13` and `/gsd:verify-work 17` to backfill the artifacts. Optional before next-milestone planning; required before v1 release audit.

**Deferred at:** v1.2 close (accepted as documentation-grade).

### nyquist_gap — Phases 13/14/17 VALIDATION.md stuck at `draft` / `nyquist_compliant: false` (LOW)

**Issue:** Three VALIDATION.md files have `status: draft, nyquist_compliant: false, wave_0_complete: false` despite the planner-checker step running for each phase:
- `.planning/milestones/v1.2-phases/13-adr-016-backend-foundation/13-VALIDATION.md`
- `.planning/milestones/v1.2-phases/14-adr-016-frontend-arb-reconciliation-tool-v2-02/14-VALIDATION.md`
- `.planning/milestones/v1.2-phases/17-manual-only-joy-sub-metric-happy-v2-03/17-VALIDATION.md`

Mirrors the v1.0 FUTURE-DOC-06 pattern. No functional gap.

**Deferred at:** v1.2 close (accepted as FUTURE-DOC equivalent).

### FUTURE-DOC-01 through FUTURE-DOC-06 — Documentation drift (LOW)

**Issues (6 items):**
1. MOD-numbering drift in `docs/arch/02-module-specs/MOD-002`, MOD-006, MOD-007, MOD-008 internal headers
2. `docs/arch/01-core-architecture/ARCH-008` cites ADR-006 where it should cite ADR-007
3. Doc-sweep verifiers exist in `scripts/` but are not wired into CI (`.github/workflows/audit.yml`)
4. Phase 02-VALIDATION.md and 04-VALIDATION.md not backfilled (v1.0-phases)
5. Phase 03/06/08 missing canonical VERIFICATION.md (substitute evidence in audit)
6. `/gsd:validate-phase 07` reports `nyquist_compliant: false`

**Deferred at:** v1.0 close. Status: v2 backlog.

### metadata_drift — `gsd-sdk audit-open` false-positive on 3 quick tasks (INFO)

**Issue:** `gsd-sdk audit-open` reports `260518-kyr`, `260518-pf5`, `260518-v4v` as `missing` while STATE.md confirms all 3 `Verified` with commit refs. Tool reads internal quick-task slug metadata, not STATE.md. Cosmetic only.

**Files:** `.planning/STATE.md`, `.planning/quick/260518-*/`

**Deferred at:** v1.2 close.

---

## Architecture / Technical Debt

### FUTURE-ARCH-01 — `CategoryLocaleService` static map (MEDIUM)

**Issue:** `lib/infrastructure/category/category_locale_service.dart` is a 735-line `abstract final class` with a hardcoded static string map for category locale resolution. Adding new categories requires modifying this file directly rather than updating ARB files. The map is not driven from the i18n infrastructure.

**Impact:** Every category name change requires two edits — one in ARB files (for UI strings) and one in `category_locale_service.dart` (for programmatic resolution). Risk of drift between the two grows with each new category.

**Fix approach:** Drive `CategoryLocaleService.resolve()` from ARB keys at runtime. This is a non-trivial refactor that requires the locale infrastructure to be accessible from the `lib/infrastructure/` layer.

**Deferred at:** v1.0 close (FUTURE-ARCH-01). Status: v2 backlog.

### FUTURE-ARCH-02 — Residual committed `.mocks.dart` files (LOW)

**Issue:** The v1.0 cleanup largely closed this, but the CI coverage filter at `.github/workflows/audit.yml` line 123 still excludes `*.mocks.dart` from lcov, implying some files remain. The stale-suppressions architecture test (`test/architecture/stale_suppressions_scan_test.dart` line 62) also treats `.mocks.dart` as a special suffix. Mocktail is the approved pattern (inline `class _MockFoo extends Mock implements Foo`).

**Files:** Search with `find test/ -name "*.mocks.dart"` to confirm current count.

**Deferred at:** v1.0 close (largely closed in Phase 4). Status: confirm at next audit.

### FUTURE-ARCH-03 — Audit pipeline on `custom_lint` not DCM (LOW)

**Issue:** The CI audit pipeline uses `dart run custom_lint` with `--no-fatal-infos`. The paid DCM (Dart Code Metrics) tool would provide deeper analysis (complexity metrics, unused parameters, dead-code surface). No blocking consequence; current tools are adequate for current scale.

**Deferred at:** v1.0 close. Status: v2 backlog.

### import_guard WARNING drift — 10 violations post-v1.2 (MEDIUM)

**Issue:** `dart run custom_lint` reports 10 WARNING-level `import_guard` violations. These are NOT caught by `flutter analyze` and are not currently fatal in CI (`--no-fatal-infos`). They represent v1.1/v1.2 model files added after their parent import_guard whitelists were written, with the whitelists never updated:

- `lib/features/accounting/domain/models/transaction.dart` — imports `entry_source.dart` (not in `import_guard.yaml`)
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — imports `entry_source.dart`
- `lib/features/analytics/domain/models/family_happiness.dart` — imports `metric_result.dart`, `shared_joy_insight.dart`
- `lib/features/analytics/domain/models/happiness_report.dart` — imports `best_joy_moment_row.dart`, `metric_result.dart`
- `lib/features/analytics/domain/repositories/analytics_repository.dart` — imports `entry_source.dart`, `best_joy_moment_row.dart`, `ledger_snapshot.dart`, `per_category_soul_breakdown.dart`

`entry_source.dart` was added in Phase 17 commit `335965a` (`feat(17-03): add transaction entry source model`). The v1.1 analytics model additions pre-date that. The import_guard YAML files at `lib/features/accounting/domain/models/import_guard.yaml` and `lib/features/analytics/domain/models/import_guard.yaml` need new `allow:` entries.

**Impact:** Import violations that should be structurally enforced are silently passing. If a true architectural violation were introduced, it might be masked by the noise of these known false positives.

**Fix approach:** Add the legitimately-needed imports to the respective `import_guard.yaml` allow lists. Then tighten the CI to treat `import_guard` WARNINGs as fatal (re-enable `--fatal-infos` once clean).

### Dual ledger classification: Layers 2 + 3 are stubs (MEDIUM)

**Issue:** `lib/application/dual_ledger/classification_service.dart` documents a 3-layer classification system (Rule Engine → Merchant Database → ML Classifier) but Layers 2 and 3 are marked `// TODO:` stubs:

```dart
// Layer 2: Merchant Database (stub for MVP)
// TODO: Implement MerchantDatabase lookup when lib/infrastructure/ml/ is built

// Layer 3: ML Classifier (stub for MVP)
// TODO: Implement TFLiteClassifier when model is available
```

`lib/infrastructure/ml/merchant_database.dart` exists (171 lines) with the `MerchantMatch` model and query interface, but `lib/infrastructure/ml/` contains only that one file — no TFLite classifier, no populated merchant data, no OCR pipeline.

**Impact:** Every transaction classification falls through to Layer 1 (Rule Engine) only. The 500+ merchant database and 85%+ ML accuracy described in architecture docs are not yet operational. This is expected at the current development stage (MOD-005 OCR is a later milestone), but the stub is a firm dependency before the full dual-ledger UX is complete.

**Files:** `lib/application/dual_ledger/classification_service.dart` (lines 8, 33-36), `lib/infrastructure/ml/merchant_database.dart`

**Deferred to:** MOD-005 OCR milestone.

### forward_compat — `EntrySource.ocr` declared but no write site (INFO)

**Issue:** Drift schema v17 and the DAO entry_source filter in `lib/data/daos/analytics_dao.dart` accept `EntrySource.ocr`, but no production write site stamps `EntrySource.ocr` on any transaction. The enum value and DB CHECK constraint are reserved.

**Files:** `lib/data/tables/transactions_table.dart` (line 48), `lib/data/app_database.dart` (line 280), `lib/features/accounting/domain/models/transaction.dart` (EntrySource enum), `lib/data/daos/analytics_dao.dart`

**Deferred to:** MOD-005 OCR milestone.

---

## Tooling / Dependency Debt

### FUTURE-TOOL-01 — `riverpod_lint` 3.x blocked by `json_serializable` analyzer conflict (MEDIUM)

**Issue:** `riverpod_lint: ^3.1.0` is present in `pubspec.yaml` but the audit CI runs `dart run custom_lint --no-fatal-infos` specifically because riverpod_lint INFO diagnostics would otherwise break CI. This is a workaround for an upstream `json_serializable` / `analyzer` version conflict. Until resolved, architectural lint violations from riverpod_lint may surface as non-fatal INFOs and be silently ignored.

**Files:** `pubspec.yaml`, `.github/workflows/audit.yml` (lines 51-55 comment)

**Deferred at:** v1.0 close. Status: v2 backlog — watch upstream for `json_serializable` + `analyzer 7.x` compatibility fix.

### FUTURE-TOOL-02 — No Drift-column unused-detection script (LOW)

**Issue:** No automated tooling detects unused Drift column definitions in `lib/data/tables/`. As schema evolves, stale columns (e.g., pre-v17 vestiges) will not be caught. A custom Dart script was planned but not built.

**Deferred at:** v1.0 close. Status: v2 backlog.

### FUTURE-TOOL-03 — Coverage baseline review now triggered (MEDIUM)

**Issue:** The CI coverage gate is at 70% global (lowered from 80% on 2026-04-28 per Phase 8 amendment). v1.2 added ~6.5k LOC of tests alongside ~16k LOC of new `lib/` code. The global ratio likely moved but was not measured at v1.2 close. The 10 deferred-coverage files (see test_debt section above) compound this.

**Fix approach:** Run `flutter test --coverage` + `coverde filter` + baseline script post-v1.2, then decide: (a) raise threshold back to 80% across-the-board, or (b) split into per-area thresholds (e.g., 90% for `lib/application/`, 70% for UI screens). Close FUTURE-TOOL-03 with an ADR amendment documenting the chosen threshold policy.

**Files:** `.github/workflows/audit.yml` (lines 100-148), `.planning/audit/coverage-gate-deferred.txt`

**Deferred at:** v1.0 close (Phase 8 amendment). Triggered post-v1.2.

### FUTURE-TOOL-03 — `fl_chart ^0.69` / `^1.2` tracking (INFO)

**Issue:** `pubspec.yaml` pins `fl_chart: ^1.2.0`. Planning docs (`ROADMAP.md`, `PROJECT.md`) still reference "TOOL-V2-01: fl_chart 1.x upgrade" as a backlog item, suggesting this was the planned upgrade target and it has now been adopted. Confirm the upgrade is complete and close TOOL-V2-01 from the backlog.

**Files:** `pubspec.yaml` (line 44), `.planning/PROJECT.md`, `.planning/ROADMAP.md`

---

## Fragile Areas

### iOS build — Podfile `post_install` strip (BLOCKER if removed)

**Fragility:** `ios/Podfile` `post_install` block (lines 56-66) strips `-l"sqlite3"` from every Pod xcconfig. Removing this causes `FirebaseMessaging` (and any pod declaring `s.libraries = 'sqlite3'`) to link the system `libsqlite3.tbd`, which wins `dlsym(RTLD_DEFAULT, "sqlite3_open")` over SQLCipher at runtime — `PRAGMA cipher_version` returns empty and `lib/infrastructure/database/encrypted_database.dart` throws `Bad state: SQLCipher not loaded - encryption unavailable`. The entire encrypted database is inaccessible.

**Why fragile:** No automated test enforces Podfile structure. The comment is thorough but relies on reviewer discipline. Pod updates or Podfile regeneration could silently lose the strip.

**Safe modification:** Any edit to `ios/Podfile` `post_install` must preserve both the `-lsqlite3` strip loop AND (wherever it exists) the `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` ML Kit fix. Verify with `flutter build ios --debug --no-codesign` + `PRAGMA cipher_version` check after any Podfile change.

**Files:** `ios/Podfile` (lines 43-66)

### Pinned dependency cluster — transitive `win32` constraint (HIGH if bumped in isolation)

**Fragility:** Three packages are pinned together via a transitive `win32` constraint and cannot be bumped in isolation:
- `file_picker: ^11.0.2` — `^12.0.0-beta.*` has a broken iOS Swift module
- `package_info_plus: ^9.0.1` — `^10.x` requires `win32 ^6.0.1`
- `share_plus: ^12.0.2` — `^13.x` requires `win32 ^6.0.1`

Bumping any one causes `flutter pub get` failure or iOS native build breakage. Must upgrade all three together and verify `flutter build ios --debug --no-codesign` succeeds.

**Files:** `pubspec.yaml`, `pubspec.lock`

### HomeHero isolation invariant — ADR-016 §3 (BLOCKER if violated)

**Invariant:** `lib/features/home/` has zero references to `selectedTimeWindowProvider`, `state_time_window`, `state_joy_metric_variant`, or `joyMetricVariant`. HomeHero ring is single-month accumulation only. Enforced by `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart`.

**Why fragile:** Future analytics or home feature work may be tempted to wire the time window provider into HomeHero for "consistency." This would violate ADR-016 §3. Any contributor touching `lib/features/home/` must read ADR-016 first.

**Files:** `lib/features/home/` (entire feature directory), `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart`, `docs/arch/03-adr/ADR-016_*.md`

### No-gamification contract — ADR-012 + ADR-014 (BLOCKER if violated)

**Invariant:** No streaks, badges, achievement unlocks, cross-period deltas, leaderboards, public sharing, or 100%-threshold congratulations. Anti-toxicity sweep covers en/ja/zh × 4 widget states. Enforced by `test/widget/features/analytics/anti_toxicity_phase16_test.dart` and `test/widget/features/analytics/analytics_no_delta_ui_test.dart`.

**Why fragile:** Happiness-metric work naturally invites gamification language. Each new ARB entry must be reviewed against ADR-012's forbidden substring list. String additions to `lib/l10n/app_*.arb` should be run through the anti-toxicity test before commit.

**Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, `test/widget/features/analytics/anti_toxicity_phase16_test.dart`, `test/widget/features/analytics/analytics_no_delta_ui_test.dart`

### Code-generation gates — stale diff breaks PR (MEDIUM)

**Fragility:** CI guardrail AUDIT-10 (`.github/workflows/audit.yml` lines 91-98) runs `flutter pub run build_runner build` and fails the PR if `lib/` has any diff. Forgetting to regen after any `@riverpod`, `@freezed`, Drift table, or ARB change is the most common developer workflow mistake. This is enforced but not prevented — the gap between "write the annotation" and "remember to regenerate" is manual.

**Safe practice:** Run `flutter pub run build_runner build --delete-conflicting-outputs` before every commit that touches `@riverpod`, `@freezed`, or Drift table definitions, or ARB files.

**Files:** `lib/**/*.g.dart`, `lib/**/*.freezed.dart`, `.github/workflows/audit.yml`

---

## Missing Features (Deferred Scope)

### FAMILY-V2-01/02/03 — Family privacy hardening not shipped (MEDIUM)

**Issue:** Three family-privacy items are still v2 backlog. No strict consent gate exists for family analytics:

- **FAMILY-V2-01:** SQL-side `category × avg satisfaction` aggregation DAO method
- **FAMILY-V2-02:** Family conversation-prompt cards (opt-in)
- **FAMILY-V2-03:** Strict FAMILY-03 consent gate (`familyConsentProvider`, group settings UI, new ADR Privacy Consent Gate)

As the family sync module (MOD-004) ships without a consent gate, family analytics data sharing is not gated per-member. This is acceptable pre-launch but is a MEDIUM concern before the app goes to production family users.

**Files:** `lib/features/family_sync/` (no consent provider), `lib/data/daos/analytics_dao.dart`

**Deferred at:** v1.2 close. Status: candidate for next milestone.

### FUTURE-QA-01 — Owner-driven smoke test not run (LOW)

**Issue:** No owner-driven smoke test has been executed on a real device. All verification to date is automated test + widget test. Final device UAT for the full user flow (onboarding → record transaction → view analytics → sync) is reserved for the pre-v1 release gate.

**Deferred at:** v1.0 close. Status: v2 backlog — must complete before any production release.

---

## Minor / Informational

### TODO markers in production code (LOW)

Seven `// TODO:` comments remain in `lib/`:

| File | Line | Content |
|------|------|---------|
| `lib/core/theme/app_text_styles.dart` | 171 | "Remove after all screens migrated to Wa-Modern" |
| `lib/core/theme/app_colors.dart` | 69 | "Remove after all screens migrated to Wa-Modern" |
| `lib/features/settings/presentation/widgets/about_section.dart` | 29 | "Navigate to privacy policy" |
| `lib/features/home/presentation/screens/home_screen.dart` | 232 | "Wire GroupBar with actual group data when available" |
| `lib/features/home/presentation/screens/home_screen.dart` | 261 | "Navigate to full transaction list" |
| `lib/application/dual_ledger/classification_service.dart` | 33 | "Implement MerchantDatabase lookup when lib/infrastructure/ml/ is built" |
| `lib/application/dual_ledger/classification_service.dart` | 36 | "Implement TFLiteClassifier when model is available" |

The Wa-Modern migration TODOs are design-system cleanup. The classification TODOs are intentional stubs for future modules. The navigation TODOs represent unimplemented navigation targets.

### `debugPrint()` calls in sync/infrastructure (LOW)

39 `debugPrint()` calls exist in `lib/`, concentrated in the family sync and infrastructure layers:

- `lib/application/family_sync/sync_orchestrator.dart` — 8 calls
- `lib/application/family_sync/sync_engine.dart` — 6 calls
- `lib/application/family_sync/full_sync_use_case.dart` — 4 calls
- `lib/application/family_sync/pull_sync_use_case.dart` — 3 calls
- `lib/application/family_sync/transaction_change_tracker.dart` — 1 call
- `lib/infrastructure/sync/websocket_service.dart` — 5 calls
- `lib/infrastructure/sync/relay_api_client.dart` — 2 calls
- `lib/infrastructure/sync/push_notification_service.dart` — 10 calls (most concentrated)
- `lib/infrastructure/sync/sync_scheduler.dart` — 1 call
- `lib/infrastructure/sync/sync_lifecycle_observer.dart` — 1 call

These are operational debug logs for the sync subsystem. `debugPrint` is stripped in release builds by Flutter, so there is no security or performance impact in production. However, they should be replaced with a structured logger before a v1 release to maintain clean release output.

### `amount_display.dart` absent from `cleanup-touched-files.txt` (INFO)

**Issue:** `lib/features/accounting/presentation/widgets/amount_display.dart` is not listed in `.planning/audit/cleanup-touched-files.txt`, as noted in Plan 08-04 `deferred-items.md`. This means the per-file coverage gate does not check this file. Its coverage is unknown relative to the 70% threshold.

**Files:** `lib/features/accounting/presentation/widgets/amount_display.dart`, `.planning/audit/cleanup-touched-files.txt`

**Deferred at:** v1.0 close.

### Tech-debt nit — 2 INFO-level warnings in shadow_books characterization test (INFO)

**Issue:** `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart` lines 57 and 73 had 2 INFO-level analyzer warnings noted at v1.0 close. Running `flutter analyze` on 2026-05-21 reports 0 issues. Either the warnings were resolved in a subsequent commit or they are suppressed by `--no-fatal-infos`. No action required unless re-confirmed.

---

*Concerns audit: 2026-05-21*
