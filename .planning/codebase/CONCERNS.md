# Codebase Concerns

**Analysis Date:** 2026-06-27

> Scope: full-repo scan. This document re-verifies the three carried concerns from the
> prior map (2026-06-23, mid-v1.9 ~Phase 49) against current HEAD and adds new findings
> from the v1.9 voice/merchant work.

## Prior-Concern Verification (2026-06-23 → 2026-06-27)

| # | Prior concern | Status | Evidence |
|---|---------------|--------|----------|
| 1 | Dual merchant source of truth (in-memory `MerchantDatabase` vs Drift `merchants`/`merchant_match_keys`) | **RESOLVED** | `lib/infrastructure/ml/merchant_database.dart` no longer exists. No `.dart` file imports it. `MerchantRecognizer` (`lib/application/voice/recognition/merchant_recognizer.dart`) takes only a `MerchantRepository`, which is Drift-backed via `MerchantDao`. Seeding done by `SeedMerchantsUseCase` (`lib/application/accounting/seed_merchants_use_case.dart`) over `default_merchants.dart`. |
| 2 | Doc drift: CLAUDE.md says schema v21, code at v22 | **STILL-PRESENT** | `app_database.dart:53` → `schemaVersion => 22`. `CLAUDE.md:249` still says "**v21**". See Tech Debt below. |
| 3 | OCR SDK absence despite MOD-005 | **STILL-PRESENT (intentional)** | No OCR/ML Kit/TFLite dep in `pubspec.yaml` (only `image_picker`). `ocr_scanner_screen.dart` is a documented stub ("Shutter button currently just pops back"). Gated off by `kOcrEntryEnabled = false`. |

## Tech Debt

**CLAUDE.md schema version drift:**
- Issue: `CLAUDE.md:249` documents Drift schema "v21" with the v20→v21 migration as the latest, but the code is at v22.
- Files: `CLAUDE.md` (line 249), `lib/data/app_database.dart` (line 53, `schemaVersion => 22`)
- Impact: Onboarding/agent confusion about current schema; migration authoring may target the wrong baseline (v22 added `merchants` + `merchant_match_keys` for the Phase 49 merchant spine).
- Fix approach: Update the CLAUDE.md iOS-build note to v22 and record the v21→v22 migration (merchant tables). Cheap doc-only fix.

**OCR feature is a UI-only stub:**
- Issue: `OcrScannerScreen` and `OcrReviewScreen` render camera-style UI but perform no recognition; `OcrParseDraft` model exists with no producer. Hidden behind `kOcrEntryEnabled = false`.
- Files: `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart`, `ocr_review_screen.dart`, `lib/features/accounting/domain/models/ocr_parse_draft.dart`, `lib/core/constants/feature_flags.dart`
- Impact: Dead UI surface + model carried in the tree; MOD-005 unfulfilled. Low risk while flag is off, but the stub can rot against the rest of the accounting flow.
- Fix approach: Either implement with an on-device OCR SDK (ML Kit text recognition) honoring the local-first/zero-knowledge constraint, or quarantine the stub until the feature is scheduled.

**Legacy text style migration marker:**
- Issue: `// TODO: Remove after all screens are migrated to Wa-Modern` left in a shared style file.
- Files: `lib/core/theme/app_text_styles.dart:180`
- Impact: Indicates an incomplete design-system migration; stale style branch may be referenced by un-migrated screens.
- Fix approach: Audit remaining consumers, complete migration, drop the legacy branch.

**Unwired UI placeholders:**
- Issue: Privacy-policy navigation and home GroupBar wiring are TODO stubs.
- Files: `lib/features/settings/presentation/widgets/about_section.dart:29`, `lib/features/home/presentation/screens/home_screen.dart:241`
- Impact: User-visible inert affordances (privacy link goes nowhere; group bar shows no real data).
- Fix approach: Wire to actual routes/providers or hide until backed.

## Known Bugs

No confirmed open functional bugs found at HEAD. The most recent voice fixes are committed:
- Voice confidence band re-enabled in production (`f00b1487`, RECUX-01).
- Voice-form merchant-floor bypass fixed in Phase 51 CR-01 (per project memory; category now auto-stamped only from the floor-gated `categoryMatch`, never `?? merchantCategoryId`).

**Watch item (not a confirmed bug):** dark `list_transaction_tile` golden zh/en variants render the tile's internal date in `ja` because locale is not threaded into `ListTransactionTile`. Carried from Phase 34 WR-01; cosmetic test-fidelity only, non-blocking.

## Security Considerations

**Outbound network egress in a "local-first / zero-knowledge" app:**
- Risk: `ExchangeRateApiClient` makes plaintext-destination HTTPS calls to three third-party currency APIs (`api.frankfurter.dev`, `cdn.jsdelivr.net`, `*.currency-api.pages.dev`). This is the one component that contradicts the offline-first / no-egress posture advertised in `CLAUDE.md`.
- Files: `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` (lines 29–73)
- Current mitigation: Calls are JPY base-rate fetches only (no user financial data leaves the device); TLS is used; results cached in the `exchange_rates` table (schema v21).
- Recommendations: Document this as an explicit exception to the local-first invariant (ADR), confirm no PII/amount is ever sent, and consider a user-facing toggle / offline fallback so privacy-sensitive users can disable FX fetches.

**Crypto centralization is well enforced (positive):**
- All crypto routes through `lib/infrastructure/crypto/`; `import_guard` (custom_lint) + arch tests block layer/crypto violations. No raw `flutter_secure_storage` access found outside the security layer. No action needed; noted so it is not "fixed" away.

## Performance Bottlenecks

No measured hotspots. Potential watch areas:
- `lib/data/daos/analytics_dao.dart` (746 lines) backs reports/donut/cumulative charts; complex aggregate SQL is the most likely place for query-cost regressions as transaction volume grows. No index regression detected, but customIndices are decorative in Drift (see Fragile Areas) — verify explicit `CREATE INDEX` covers analytics query predicates.

## Fragile Areas

**iOS SQLCipher / Podfile link-order (highest fragility):**
- Files: `ios/Podfile` (`post_install`, lines 38–63)
- Why fragile: The `post_install` block strips `-l"sqlite3"` from every Pod xcconfig. If removed, any pod declaring `s.libraries = 'sqlite3'` (e.g. FirebaseMessaging) pulls in system `libsqlite3.tbd`, which wins `dlsym` over SQLCipher at runtime → `PRAGMA cipher_version` returns empty → `encrypted_database.dart` throws "SQLCipher not loaded". Also carries the `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` ML Kit fix.
- Safe modification: Never remove the strip or the EXCLUDED_ARCHS line. Verify with `PRAGMA cipher_version` on a real device/sim after any Pod change. Use only `sqlcipher_flutter_libs ^0.6.x`, never `sqlite3_flutter_libs` (enforced by import_guard + AUDIT-09).
- Test coverage: No Podfile lint; relies on reviewer + manual iOS runtime check.

**Dependency version lattice (intl / win32 / file_picker / package_info_plus / share_plus):**
- Files: `pubspec.yaml` (lines 17, 51, 53, 54)
- Why fragile: `file_picker ^11.0.2`, `package_info_plus ^9.0.1`, `share_plus ^12.0.2` are pinned together by a transitive `win32` constraint; bumping any one in isolation breaks `flutter pub get` or the iOS native build (`file_picker 12.x` ships a broken iOS Swift module). `intl` is hard-pinned to `0.20.2` by `flutter_localizations`.
- Safe modification: Upgrade the file_picker/package_info_plus/share_plus trio together and verify `flutter build ios --debug --no-codesign`. Never float `intl`.
- Test coverage: `intl` pin is structurally enforced; the win32 trio is reviewer-only.

**Drift `customIndices` is decorative:**
- Files: any table using `customIndices`, `lib/data/app_database.dart` migrations
- Why fragile: The `customIndices` getter does NOT create indices; indices must be emitted as explicit `CREATE INDEX` in `onCreate` AND every relevant `onUpgrade` step (CR-01, Phase 36). A silently-missing index degrades analytics/transaction queries with no compile error.
- Safe modification: When adding an index, add the `CREATE INDEX` statement to migrations; verify against `analytics_dao.dart` predicates.

**Riverpod 3 async-read footguns:**
- Files: `test/helpers/test_provider_scope.dart`, providers across `presentation/providers/`
- Why fragile: Bare `await container.read(provider.future)` on auto-dispose providers yields "Bad state: disposed during loading", masking real values/errors. Tests must use `waitForFirstValue` + `ProviderContainer.test()`. Side-effect listeners must live in `ref.listen`, not `ref.watch`.
- Safe modification: Follow the documented Riverpod-3 conventions in CLAUDE.md; do not reintroduce `watch`-driven navigation/snackbars.

**Voice recognition pipeline (v1.9 new surface):**
- Files: `lib/application/voice/parse_voice_input_use_case.dart`, `recognition/merchant_recognizer.dart`, `recognition/category_recognizer.dart`, `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart`
- Why fragile: The 0.85 auto-fill floor (`kMerchantAutoFillFloor`) lives in the ORCHESTRATOR, not the recall-first engine. Category auto-fill is correct only if the floor gate and the keyword-priority merge stay in `ParseVoiceInputUseCase`; pushing floor logic into the engine, or restoring `?? merchantCategoryId` fallback, reintroduces the Phase 51 floor-bypass class of bug. iOS speech recognition has documented quirks (treat `error_no_match` by error code not the permanent flag; reset must `cancel()` to clear the recognizer buffer).
- Safe modification: Keep floor + merge in the orchestrator; auto-stamp category ONLY from floor-gated `categoryMatch`. The v1.9 milestone audit (`2a4520d9`) describes recognition UI as "dormant" — alternates/conflict chips are now consumed in `transaction_details_form.dart`, but verify any new entry path re-applies the floor.

## Scaling Limits

Not quantified for this local-first single-device app. The natural limit is per-device SQLite volume; `analytics_dao.dart` aggregate queries are the first place a large ledger would show latency. No multi-tenant/server scaling surface (P2P family sync is out of current scope per CLAUDE.md).

## Dependencies at Risk

**`sqlite3 ^2.7.5` (not migrated to 3.x):**
- Risk: `sqlcipher_flutter_libs` is pinned at `^0.6.x`; `0.7.0+eol` is a deliberate no-op because the project hasn't migrated to `sqlite3` 3.x. This couples the app to an EOL-adjacent line.
- Impact: Future SQLCipher/sqlite3 security or platform fixes may require the 3.x migration before they can be adopted.
- Migration plan: Coordinated bump of `sqlcipher_flutter_libs` + `sqlite3` to the 3.x line, re-verifying the Podfile link-strip behavior and `PRAGMA cipher_version` on device.

**`win32`-coupled trio:** see Fragile Areas — upgrade-blocked, not currently broken.

## Missing Critical Features

**OCR receipt scanning (MOD-005):** UI stubbed, no recognition backend, flag off. Blocks the "scan a receipt" entry path entirely.

**Family Sync (MOD-003):** Out of current scope per CLAUDE.md; CRDT/Bluetooth/NFC infra directories exist but are not wired into a shipping flow.

## Test Coverage Gaps

**iOS native link/runtime path (Podfile):**
- What's not tested: The `-lsqlite3` strip and EXCLUDED_ARCHS fixes have no automated lint; correctness is verified only by manual `PRAGMA cipher_version` on device.
- Files: `ios/Podfile`
- Risk: A silent Podfile edit ships an app where encryption is unavailable at runtime.
- Priority: High.

**Golden tests are macOS-baselined:**
- What's not tested: On CI (ubuntu), goldens can never pixel-match (font-AA diff); `test/flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` off-macOS, so CI verifies existence, not pixels.
- Files: `test/flutter_test_config.dart`, `test/helpers/ci_golden_comparator.dart`, `test/unit/helpers/ci_golden_comparator_test.dart`
- Risk: Visual regressions land undetected unless a developer re-baselines on macOS; never run `dart format` over the whole `test/` tree (repo is not format-clean there).
- Priority: Medium.

**OCR stub:** No producer/tests for `OcrParseDraft`; acceptable while the feature is unbuilt and flagged off.

---

*Concerns audit: 2026-06-27*
