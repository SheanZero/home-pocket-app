# Codebase Concerns

**Analysis Date:** 2026-06-23

This codebase is in good health overall: 398 test files against 426 source files, `avoid_print` enforced, zero-analyzer-warnings gate in CI, and most historical debt is tracked through GSD phases (CRIT-NN / WR-NN fix markers visible in code). The concerns below are the genuine remaining gaps, ordered by impact.

## Tech Debt

**Dual-ledger classification is a 2-of-3-layer stub:**
- Issue: `ClassificationService.classify()` implements only Layer 1 (rule engine). Layer 2 (MerchantDatabase lookup) and Layer 3 (TFLite ML classifier) are `// TODO` no-ops. Any category not matched by a rule silently falls back to `LedgerType.daily` at `confidence: 0.5`.
- Files: `lib/application/dual_ledger/classification_service.dart:33-36`
- Impact: The "3-Layer Classification (Rule → Merchant → ML)" described in CLAUDE.md and MOD specs does not actually run end-to-end. The service is live — wired into `lib/application/accounting/create_transaction_use_case.dart` via `lib/application/dual_ledger/repository_providers.dart` — so real transactions get the daily-default classification. A standalone `MerchantDatabase` exists (`lib/infrastructure/ml/merchant_database.dart`, 181 lines) but is never called from the classifier.
- Fix approach: Inject `MerchantDatabase` into `ClassificationService` and call it for Layer 2; defer Layer 3 (no TFLite dependency or model ships — see "Missing Critical Features"). Tighten the fallback confidence so downstream UI can flag low-confidence guesses.

**TFLite / on-device ML is documented but absent:**
- Issue: CLAUDE.md, MEMORY, and MOD docs describe a TFLite classifier (85%+ accuracy) and ML/OCR infrastructure. No `tflite`, `google_ml_kit`, or OCR package is in `pubspec.yaml`. `lib/infrastructure/ml/` contains only `merchant_database.dart` and `merchant_name_normalizer.dart`.
- Files: `pubspec.yaml`, `lib/infrastructure/ml/`
- Impact: Doc/code drift. Anyone planning OCR (MOD-005) or ML classification work will assume scaffolding exists that does not.
- Fix approach: Treat ML/OCR as greenfield when those phases arrive; update MOD-005 status to reflect not-started.

**OCR module is spec-only:**
- Issue: `lib/application/ocr/` is referenced in CLAUDE.md architecture but no ML Kit / TextRecognizer dependency or implementation exists.
- Files: `pubspec.yaml` (no OCR deps), CLAUDE.md architecture section
- Impact: Receipt-scanning feature is unbuilt despite being listed in the layer map.
- Fix approach: Scope as a future milestone; do not let plan-phase load INTEGRATIONS expecting an OCR SDK.

**Oversized files exceed the 800-line house limit:**
- Issue: Four hand-written source files exceed the project's stated 800-line max (`.claude/rules/coding-style.md`).
  - `lib/shared/constants/default_categories.dart` (1268) — data table, low risk but hard to diff
  - `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (1171)
  - `lib/features/home/presentation/widgets/home_hero_card.dart` (1155)
  - `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` (1025)
- Impact: The two form/screen widgets concentrate a lot of stateful UI logic, raising merge-conflict and regression risk (the parallel-executor ARB/stub collision gotcha in MEMORY is more likely in files this large).
- Fix approach: Extract sub-widgets and validation helpers from the two accounting widgets. The constants file is acceptable as a generated-style data blob.

**Lingering migration TODO in theme:**
- Issue: `app_text_styles.dart` carries a `// TODO: Remove after all screens are migrated to Wa-Modern`.
- Files: `lib/core/theme/app_text_styles.dart:180`
- Impact: Dead-ish style path kept alive for an unfinished migration.
- Fix approach: Audit remaining non-migrated screens, then remove.

## Known Bugs

No open functional bugs surfaced in this scan. Recent commits (`fix(49) WR-01/WR-04`) show the team closes review-found issues per phase. One carried cosmetic item from MEMORY: dark `list_transaction_tile` golden renders its internal date in `ja` regardless of locale (locale not threaded into `ListTransactionTile`) — pre-existing, test-fidelity only, non-blocking.

## Security Considerations

**Crypto discipline is strong — treat the boundary as the risk:**
- Risk: The 4-layer encryption + key management is centralized in `lib/infrastructure/crypto/` and `lib/infrastructure/security/`, with `import_guard` denying `sqlite3_flutter_libs` and direct `flutter_secure_storage` access. The residual risk is a future contributor bypassing these wrappers.
- Files: `lib/infrastructure/crypto/`, `lib/infrastructure/security/secure_storage_service.dart`
- Current mitigation: custom_lint import_guard, AUDIT-09 CI guardrail, CLAUDE.md crypto rules.
- Recommendations: Keep the deny rules; add any new crypto entry points to the guard list rather than relying on review.

**iOS SQLCipher symbol-collision fix is review-gated only:**
- Risk: `ios/Podfile` `post_install` strips `-lsqlite3` so SQLCipher wins `dlsym` over the system lib. If a contributor regenerates the Podfile or removes the strip, `PRAGMA cipher_version` returns empty and the DB silently loses encryption (init-fail screen at best, plaintext-leaning failure mode at worst).
- Files: `ios/Podfile` post_install, `lib/infrastructure/crypto/database/encrypted_database.dart`
- Current mitigation: CLAUDE.md pitfall #7 + reviewer awareness. No lint.
- Recommendations: Add a CI assertion (grep the rendered xcconfigs or check `PRAGMA cipher_version` in an integration smoke test) so this is structurally enforced, not manual.

**Sync transport secret/endpoint handling unaudited here:**
- Risk: `lib/infrastructure/sync/` ships a real `websocket_service.dart`, `relay_api_client.dart`, and `push_notification_service.dart` (Firebase). Relay endpoints and auth handling were not deeply inspected in this scan.
- Files: `lib/infrastructure/sync/relay_api_client.dart`, `websocket_service.dart`
- Current mitigation: Project claims TLS 1.3 + E2EE for transport.
- Recommendations: Run a focused `gsd-secure-phase` over the family-sync transport before that milestone ships.

## Performance Bottlenecks

No measured bottlenecks found. Watch the large accounting widgets (`transaction_details_form.dart`, `manual_one_step_screen.dart`) for rebuild cost as more `ref.watch` providers accumulate; consider `select` narrowing if profiling shows churn.

## Fragile Areas

**Family sync subsystem (64 files) — youngest, most coupled:**
- Files: `lib/application/family_sync/`, `lib/infrastructure/sync/`, `lib/features/family_sync/`
- Why fragile: It is the largest cross-cutting subsystem (CRDT + WebSocket + relay + push + offline queue), and it carries the only concentration of `debugPrint` logging in the codebase (sync_engine, sync_orchestrator, pull/push/full sync use cases — ~40 of 51 total debugPrint calls). Heavy ad-hoc print logging usually marks code that was hard to get right.
- Safe modification: Change one sync flow (push / pull / apply) at a time; run the full `flutter test` (not scoped) per the MEMORY gotcha about architecture tests being missed by scoped runs. ARB/stub collisions between same-wave executors also concentrate here.
- Test coverage: `test/integration/sync/shopping_sync_round_trip_test.dart` has a `.skip(...)` branch — confirm what scenario is being skipped before relying on round-trip coverage.

**Drift onUpgrade migration chain (v1 → v22):**
- Files: `lib/data/app_database.dart` (`schemaVersion => 22`, onUpgrade ~line 70+)
- Why fragile: A long, mostly-unconditional `if (from < N)` ladder. The v4 step interacts with an unconditional `from < 18` RENAME COLUMN (noted inline), and `customIndices` is decorative (MEMORY gotcha) so indices must be emitted explicitly in both onCreate and onUpgrade.
- Safe modification: Add new steps only as `if (from < 23)`; never reorder existing steps; test migration from each prior version (the WR-01 fix in Phase 49 added a real onUpgrade migrator drive in the host-VM v22 test — keep that pattern).
- Test coverage: Migration tests exist; verify each `from < N` rung is exercised.

## Scaling Limits

Not applicable for a local-first mobile app at this stage. The relay/sync server side (out of this repo) would be the scaling surface; not assessable here.

## Dependencies at Risk

**Three-way win32-pinned trio is a known landmine:**
- Risk: `file_picker ^11.0.2`, `package_info_plus ^9.0.1`, `share_plus ^12.0.2` are mutually pinned via a transitive `win32` constraint. Bumping any one in isolation breaks `flutter pub get` or the iOS native build.
- Impact: Security patches to any of the three are blocked unless all three move together.
- Migration plan: Upgrade as a set, then verify `flutter build ios --debug --no-codesign` (documented in CLAUDE.md). Schedule a deliberate trio-bump phase rather than ad-hoc.

**intl hard-pinned at 0.20.2:**
- Risk: Pinned by `flutter_localizations`; cannot float.
- Impact: Low, but locks formatting behavior to one version.
- Migration plan: Moves only with the Flutter SDK.

**sqlcipher_flutter_libs pinned at ^0.6.x:**
- Risk: `0.7.0+eol` is intentionally a no-op; project has not migrated to `sqlite3` 3.x.
- Impact: A future forced migration to sqlite3 3.x is deferred debt.
- Migration plan: Plan a dedicated DB-stack migration phase when 0.6.x is truly EOL.

## Missing Critical Features

**ML classifier (Layer 3):** No TFLite dependency or model. Dual-ledger classification cannot reach its documented 85%+ accuracy path. Blocks the full MOD-003 dual-ledger value prop from being automatic.

**OCR receipt scanning (MOD-005):** No ML Kit / OCR dependency. Receipt-scan feature unbuilt.

**Privacy policy navigation:** `// TODO: Navigate to privacy policy` stub in `lib/features/settings/presentation/widgets/about_section.dart:29` — a shipping app typically needs this wired for store review.

**Home GroupBar real data:** `// TODO: Wire GroupBar with actual group data when available` at `lib/features/home/presentation/screens/home_screen.dart:241` — group bar renders without live data.

## Test Coverage Gaps

**Sync round-trip has a skipped branch:**
- What's not tested: A `.skip(...)` scenario in `test/integration/sync/shopping_sync_round_trip_test.dart:87`.
- Files: `test/integration/sync/shopping_sync_round_trip_test.dart`
- Risk: A real round-trip path may be unverified; given how fragile family_sync is, this matters.
- Priority: High

**Classification fallback path:**
- What's not tested: Whether the daily-default fallback (confidence 0.5) is intentional behavior or a placeholder — no test asserts the Layer-2/3 absence is acceptable.
- Files: `lib/application/dual_ledger/classification_service.dart`
- Risk: Silent mis-classification of joy-ledger spending as daily.
- Priority: Medium

**Removed-helpers home screen test gated on a plan:**
- What's not tested: `test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart` notes it stays `skip:`-gated until "Plan 10-08 lands."
- Files: same
- Risk: Low — intentional, but verify the plan actually landed.
- Priority: Low

---

*Concerns audit: 2026-06-23*
