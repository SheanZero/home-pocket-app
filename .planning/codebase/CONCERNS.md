# Codebase Concerns

**Analysis Date:** 2026-06-23

This codebase is in good health overall: 409 test files against 430 source files, `avoid_print` enforced, a zero-analyzer-warnings gate in CI, and most historical debt is tracked through GSD phases (CRIT-NN / WR-NN fix markers visible in code). No swallowed `catch {}` blocks were found. The concerns below are the genuine remaining gaps, ordered by impact. The biggest live one is a merchant-system migration that is half-built (schema landed at v22, seed + wiring deferred).

## Tech Debt

**Two parallel merchant systems exist mid-migration:**
- Issue: A legacy in-memory `MerchantDatabase` (`lib/infrastructure/ml/merchant_database.dart`) coexists with a new Drift-backed merchant system added in Phase 49 — tables `merchants` + `merchant_match_keys` (schema v22), plus `MerchantDao`, `MerchantCategoryPreferenceDao`. The new tables were created schema-only; seeding is deferred to a later plan (Plan 05 per `docs/worklog/20260623_0538_merchant_schema_v22_foundation.md`). Everything currently consuming merchants — `LookupMerchantUseCase` (`lib/application/ml/lookup_merchant_use_case.dart`), voice parsing (`lib/application/voice/voice_category_resolver.dart`, `parse_voice_input_use_case.dart`) — still imports the **old** in-memory `MerchantDatabase`, not the new Drift tables.
- Files: `lib/infrastructure/ml/merchant_database.dart`, `lib/data/tables/merchants_table.dart`, `lib/data/tables/merchant_match_keys_table.dart`, `lib/data/daos/merchant_dao.dart`, `lib/application/ml/lookup_merchant_use_case.dart`, `lib/application/voice/voice_category_resolver.dart`
- Impact: Two sources of truth for "what merchants exist." Until the cutover completes, the new `merchants` table is empty dead weight and all real merchant lookups go through the legacy in-memory path. Doc drift risk: CLAUDE.md still says schema v21 (it is now v22 in `lib/data/app_database.dart:53`).
- Fix approach: Finish the migration — seed the Drift tables, repoint `LookupMerchantUseCase` and the voice resolvers at `MerchantDao`, then delete the in-memory `MerchantDatabase`. Update CLAUDE.md to schema v22.

**Dual-ledger classification is still a 1-of-3-layer stub:**
- Issue: `ClassificationService.classify()` implements only Layer 1 (rule engine). Layer 2 (Merchant DB lookup) and Layer 3 (TFLite ML) are explicit `// TODO` no-ops (`classification_service.dart:32,35`). Any category not matched by a rule silently falls back to `LedgerType.daily` at `confidence: 0.5`.
- Files: `lib/application/dual_ledger/classification_service.dart:25-49`
- Impact: The "3-Layer Classification (Rule → Merchant → ML)" described in CLAUDE.md and MOD specs does not run end-to-end. The service is live (wired via `lib/application/accounting/create_transaction_use_case.dart`), so real transactions get the daily-default classification. Notably, neither the legacy `MerchantDatabase` nor the new `MerchantDao` is injected into the classifier — Layer 2 is wired into *voice* resolution but not into *classification*.
- Fix approach: Inject the merchant lookup (prefer the new `MerchantDao` once seeded) into `ClassificationService` for Layer 2; defer Layer 3 (no TFLite dependency or model ships — see below). Surface low-confidence guesses to the UI rather than masking them as daily.

**TFLite / on-device ML is documented but absent:**
- Issue: CLAUDE.md, MEMORY, and MOD docs describe a TFLite classifier (85%+ accuracy) and ML/OCR infrastructure. No `tflite`, `google_ml_kit`, `mlkit`, or OCR package is in `pubspec.yaml`. `lib/infrastructure/ml/` contains only `merchant_database.dart` and `merchant_name_normalizer.dart`.
- Files: `pubspec.yaml`, `lib/infrastructure/ml/`
- Impact: Doc/code drift. Anyone planning OCR (MOD-005) or ML classification work will assume scaffolding exists that does not.
- Fix approach: Treat ML/OCR as greenfield when those phases arrive; update MOD-005 status to not-started.

**OCR module is spec-only:**
- Issue: `lib/application/ocr/` is referenced in the CLAUDE.md architecture layer map but the directory does not exist, and no ML Kit / TextRecognizer dependency is present.
- Files: `pubspec.yaml` (no OCR deps), CLAUDE.md architecture section
- Impact: Receipt-scanning feature is unbuilt despite appearing in the layer map.
- Fix approach: Scope as a future milestone; do not let plan-phase load INTEGRATIONS expecting an OCR SDK.

**Oversized files exceed the 800-line house limit:**
- Issue: Several hand-written source files exceed the project's stated 800-line max (`.claude/rules/coding-style.md`):
  - `lib/shared/constants/default_categories.dart` (1268) — data table, low risk but hard to diff
  - `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (1171)
  - `lib/features/home/presentation/widgets/home_hero_card.dart` (1155)
  - `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` (1025)
  - `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` (793) — borderline
- Impact: The form/screen widgets concentrate a lot of stateful UI logic, raising merge-conflict and regression risk (the parallel-executor ARB/stub collision gotcha in MEMORY is more likely in files this large).
- Fix approach: Extract sub-widgets and validation helpers from the accounting widgets. The constants file is acceptable as a generated-style data blob.

**Scattered small UI TODOs:**
- Issue: Unfinished UI wiring left as `// TODO`:
  - `lib/core/theme/app_text_styles.dart:180` — "Remove after all screens are migrated to Wa-Modern" (dead-ish style path kept alive for an unfinished migration)
  - `lib/features/home/presentation/screens/home_screen.dart:241` — "Wire GroupBar with actual group data when available"
  - `lib/features/settings/presentation/widgets/about_section.dart:29` — "Navigate to privacy policy" (no-op nav)
- Impact: Minor placeholder behavior; the privacy-policy stub is user-visible in a privacy-focused app.
- Fix approach: Wire each when the backing data/route lands; remove the Wa-Modern style path after auditing remaining non-migrated screens.

## Known Bugs

No open functional bugs surfaced in this scan. Recent commits (`fix(49) WR-01`/`WR-04`) show the team closes review-found issues per phase. One carried cosmetic item from MEMORY: dark `list_transaction_tile` golden renders its internal date in `ja` regardless of locale (locale not threaded into `ListTransactionTile`) — pre-existing, test-fidelity only, non-blocking.

## Security Considerations

**Crypto discipline is strong — treat the wrapper boundary as the risk:**
- Risk: The 4-layer encryption + key management is centralized in `lib/infrastructure/crypto/` and `lib/infrastructure/security/`, with `import_guard` denying `sqlite3_flutter_libs` and direct `flutter_secure_storage` access. The residual risk is a future contributor bypassing these wrappers.
- Files: `lib/infrastructure/crypto/`, `lib/infrastructure/security/secure_storage_service.dart`
- Current mitigation: custom_lint import_guard, AUDIT-09 CI guardrail, CLAUDE.md crypto rules.
- Recommendations: Keep the deny rules; add any new crypto entry points to the guard list rather than relying on review.

**iOS SQLCipher symbol-collision fix is review-gated only:**
- Risk: `ios/Podfile` `post_install` strips `-lsqlite3` so SQLCipher wins `dlsym` over the system lib. If a contributor regenerates the Podfile or removes the strip, `PRAGMA cipher_version` returns empty and the DB silently loses encryption (init-fail screen at best, a plaintext-leaning failure mode at worst).
- Files: `ios/Podfile` post_install, `lib/infrastructure/crypto/database/encrypted_database.dart`
- Current mitigation: CLAUDE.md pitfall #7 + reviewer awareness. No lint.
- Recommendations: Add a CI assertion (grep the rendered xcconfigs, or check `PRAGMA cipher_version` in an integration smoke test) so this is structurally enforced.

**Sync transport secret/endpoint handling unaudited here:**
- Risk: `lib/infrastructure/sync/` contains a real network stack — `websocket_service.dart`, `relay_api_client.dart`, `apns_push_messaging_client.dart`, `e2ee_service.dart`, `push_notification_service.dart`. These cross the trust boundary (relay endpoints, push tokens, E2EE handshake) and were not deep-audited in this scan.
- Files: `lib/infrastructure/sync/relay_api_client.dart`, `lib/infrastructure/sync/websocket_service.dart`, `lib/infrastructure/sync/e2ee_service.dart`
- Current mitigation: E2EE service exists; FirebaseMessaging is already handled in the Podfile sqlite strip.
- Recommendations: Run a focused security pass (`gsd-secure-phase` / security-reviewer) on the relay + E2EE path: endpoint config source, token storage, replay/handshake validation, and that no secrets are logged.

## Performance Bottlenecks

No measured bottlenecks surfaced. Watch items:
- `lib/data/daos/analytics_dao.dart` (746 lines) drives reports/overview aggregates; analytics queries over large transaction sets are the most likely future hot path. The fl_chart donut badge crash was already mitigated (MEMORY).
- The non-unique `match_key` index on `merchant_match_keys` is deliberate; once the table is seeded, verify lookup queries actually hit the index (`PRAGMA index_list` is tested at migration time, not at query time).

## Fragile Areas

**Voice entry / speech recognition:**
- Files: `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart`, `lib/features/accounting/presentation/screens/voice_input_screen.dart`, `lib/application/voice/voice_text_parser.dart`, `lib/application/voice/voice_category_resolver.dart`
- Why fragile: A long chain of recent fixes (worklog r3–r8, MEMORY voice gotchas) — iOS `error_no_match` misclassification, one-shot vs continuous re-arm, recognizer-buffer reset deadlocks (假死), and a zh/ja multi-digit Arabic numeral parse bug. Platform speech APIs are inconsistent across iOS/Android.
- Safe modification: Classify by error code not the permanent flag; keep one-shot listen + synchronous status; always `cancel()` on reset. Re-run on-device UAT after any change here — unit tests do not catch the platform behavior.
- Test coverage: Parser logic is unit-tested; the platform lifecycle is not (device-only).

**Drift migrations / index creation:**
- Files: `lib/data/app_database.dart` (`schemaVersion => 22`, `_createMerchantIndexes()`)
- Why fragile: `customIndices` is decorative (MEMORY) — indexes must be emitted as explicit `CREATE INDEX IF NOT EXISTS` in BOTH `onCreate` and the `onUpgrade` block. A new table added without touching both paths ships an un-indexed table to upgrading users.
- Safe modification: Mirror the v22 pattern — add the index helper call to onCreate and the new `from < N` block, and add a host-VM migration test asserting `PRAGMA index_list` is non-empty.
- Test coverage: Good — `test/unit/data/migrations/merchant_v22_migration_test.dart` guards the v22 contract.

## Scaling Limits

Local-first single-device app; the scaling axis is family P2P sync (relay + websocket + E2EE), which is early. No hard limits identified; revisit once sync carries real multi-device traffic.

## Dependencies at Risk

**Pinned dependency trio (do not bump in isolation):**
- Risk: `file_picker ^11.0.2`, `package_info_plus ^9.0.1`, `share_plus ^12.0.2` are locked together by a transitive `win32` constraint (CLAUDE.md). Bumping one alone fails `flutter pub get` or breaks the iOS native build (`file_picker 12.x` ships a broken iOS Swift module).
- Impact: Security/feature updates to these three are blocked until they can be bumped together and an iOS build verified.
- Migration plan: Upgrade the trio together; verify `flutter build ios --debug --no-codesign`.

**SQLCipher libs pin:**
- Risk: Must stay on `sqlcipher_flutter_libs ^0.6.x`; `0.7.0+eol` is a deliberate no-op and the project hasn't migrated to `sqlite3` 3.x. `sqlite3_flutter_libs` is import-guard denied.
- Impact: Stuck on the 0.6.x line until a planned sqlite3 3.x migration; security patches there require that migration first.
- Migration plan: Track upstream; plan a dedicated migration phase before any forced bump.

## Missing Critical Features

- **ML classification (Layer 3)** and **OCR receipt scanning (MOD-005)** are documented in the architecture but have no dependencies or implementation. Blocks the full dual-ledger auto-classification promise and any receipt-capture flow.
- **Merchant seed data** — the v22 `merchants` table exists but is empty; the "500+ merchants" claim in CLAUDE.md is served by the legacy in-memory list, not the DB, until the seed lands.

## Test Coverage Gaps

- **Voice/speech platform lifecycle** (`voice_ptt_session_mixin.dart`): device-only behavior is not covered by automated tests; regressions surface only in on-device UAT. Priority: High (most fragile area).
- **Classifier Layer 2/3 paths**: stubbed, so untested by definition; when wired, add coverage for merchant-hit and ML-hit branches plus the low-confidence fallback. Priority: Medium.
- **Sync relay/E2EE network paths** (`lib/infrastructure/sync/`): integration-level coverage of the relay handshake and reconnection is thin relative to the surface area. Priority: Medium-High (security-adjacent).
- **Golden tests are macOS-baselined** (MEMORY): CI on ubuntu uses a baseline-existence comparator, so pixel regressions are only caught when baselines are regenerated on macOS. Priority: Low (known, mitigated).

---

*Concerns audit: 2026-06-23*
