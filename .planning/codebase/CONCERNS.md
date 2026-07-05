# Codebase Concerns

**Analysis Date:** 2026-07-05

> Scope: full-repo scan. This document re-verifies the carried concerns from the
> prior map (2026-06-27, mid-v1.9 ~Phase 56) against current HEAD (`e811a219`,
> 185 commits later) and adds new findings. The authoritative concern inventory
> is now `docs/CODE_QUALITY_REPORT_2026-07-02.md` — a 6-dimension parallel code
> review (455 hand-written `lib/` files) that graded the codebase **B+** and
> enumerated P0/P1/P2/P3 findings. **All P0 and P1 items were fixed on
> 2026-07-05** (four commits, TDD, each verified below against source); the open
> surface is now the report's P2 (9 items) + P3 (18 items) plus new voice work.
>
> HEAD baseline (measured 2026-07-05): `flutter analyze` → **0 issues**;
> `flutter test` → **3561/3561 passed**.

## Prior-Concern Verification (2026-06-27 → 2026-07-05)

| # | Prior concern | Status | Evidence |
|---|---------------|--------|----------|
| 1 | Doc drift: CLAUDE.md says schema v21, code ahead | **RESOLVED** | `CLAUDE.md:249` now reads "**v23**" with the full v20→v21→v22→v23 migration history; `lib/data/app_database.dart:53` → `schemaVersion => 23`. |
| 2 | OCR SDK absence despite MOD-005 | **STILL-PRESENT (intentional)** | No OCR/ML Kit/TFLite dep in `pubspec.yaml`. `ocr_scanner_screen.dart` is a documented stub, gated off by `kOcrEntryEnabled = false`. |
| 3 | Legacy text-style migration marker | **STILL-PRESENT** | `lib/core/theme/app_text_styles.dart:180` still carries `// TODO: Remove after all screens are migrated to Wa-Modern`. |
| 4 | Unwired UI: privacy-policy link goes nowhere | **RESOLVED** | The privacy/OSS tiles moved to `LegalSponsorSection` (`lib/features/settings/presentation/widgets/about_section.dart:26`), wired through `lib/core/config/legal_urls.dart`. Residual: the URLs are still `example.com` placeholders (see P3-15 below). |
| 5 | Unwired UI: home GroupBar | **STILL-PRESENT** | `lib/features/home/presentation/screens/home_screen.dart:241` still `// TODO: Wire GroupBar with actual group data when available`. |
| 6 | Outbound network egress in a "local-first" app | **STILL-PRESENT** | `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` still calls three third-party FX APIs (`api.frankfurter.dev`, `cdn.jsdelivr.net`, `*.currency-api.pages.dev`). See Security below. |
| 7 | iOS SQLCipher / Podfile link-order fragility | **STILL-PRESENT (unchanged)** | `ios/Podfile` `post_install` strip + `EXCLUDED_ARCHS` fix unchanged. See Fragile Areas. |
| 8 | Dependency version lattice (win32 trio + intl pin) | **STILL-PRESENT (unchanged)** | `pubspec.yaml` pins unchanged. See Fragile Areas. |
| 9 | Drift `customIndices` is decorative | **PERSISTS, now backfilled + guarded** | The getter is still decorative, BUT v22→v23 added `_createAllDeclaredIndexes()` (`lib/data/app_database.dart:508`) run in both onCreate and a `from < 23` step, and `test/unit/data/migrations/index_v23_migration_test.dart` parses declarations and reconciles them against `sqlite_master`. The 19-missing/6-partial index gap (report P1-1) is closed. |
| 10 | Riverpod 3 async-read footguns | **STILL-PRESENT (unchanged)** | Conventions in CLAUDE.md; `test/helpers/test_provider_scope.dart` `waitForFirstValue` still required. |
| 11 | Voice recognition pipeline fragility | **PERSISTS + EXPANDED** | 0.85 floor still lives in the orchestrator (correct). New ITN-concat repair heuristic (`fc167982`, `791edd44`) added surface — see Fragile Areas. `voice_ptt_session_mixin.dart` grew 833 → **1019** lines. |
| 12 | Dual merchant source of truth | **RESOLVED (carried from 2026-06-27)** | `merchant_database.dart` gone; `MerchantRecognizer` is Drift-backed via `MerchantRepository`. |
| 13 | Watch item: dark `list_transaction_tile` golden renders date in `ja` | **STILL-PRESENT (cosmetic)** | Locale still not threaded into `ListTransactionTile`; test-fidelity only, non-blocking. |

### Report P0/P1 fixes — verified at HEAD

| Item | Fix commit | Verified evidence |
|------|-----------|-------------------|
| P0-1 sponsor `debugPrint` not `kDebugMode`-guarded | `3bc599b5` | `production_logging_privacy_test` green; main re-greened 2026-07-02. |
| P0-2 backup restore + clear-all non-atomic | `f422c78e` | Both `_restoreData` (`import_backup_use_case.dart:105`) and `clear_all_data_use_case.dart:37` now wrap the whole delete+reinsert in `_unitOfWork.run(...)`. `UnitOfWork` domain interface at `lib/features/settings/domain/repositories/unit_of_work.dart`, Drift impl at `lib/data/repositories/unit_of_work_impl.dart`. Bonus CR-01 hardening: untrusted backup FX rows validated via `validateAppliedRate`, unknown sources skipped. |
| P1-1 declared indices never created | `2cb07b08` | schemaVersion 22→23; `_createAllDeclaredIndexes()` + parse-and-reconcile guard test (above). |
| P1-4 v≤6 databases never get `groups` table | `2cb07b08` | `lib/data/app_database.dart:124` condition widened to `if (from < 8)` (sync_queue rebuild keeps its v7-only `from >= 7 && from < 8` guard). Real v6→v23 chain migration test added. |
| P1-3 backup crypto self-rolled in application layer, weak KDF | `84eb8f7a` | Relocated to `lib/infrastructure/crypto/services/backup_crypto_service.dart`; Argon2id (OWASP profile, same as `pin_kdf.dart`) + AES-256-GCM + self-describing versioned header; legacy PBKDF2-100k `.hpb` still importable; hostile KDF params bounded (`_kMaxMemoryKib`, `_kMaxIterations`, `parallelism != 1` rejected). |
| P1-2 import_guard deny rules inert; reverse layer deps | `e811a219` | New `test/architecture/layer_import_rules_test.dart` scans REAL imports (resolves relative → lib-rooted) with an **empty allowlist**. All three flagged reverse deps removed: `infrastructure/security/providers.dart` no longer imports settings; `seed_providers.dart` deleted (wiring moved to accounting composition root `repository_providers.dart:318`); `RateResult` moved to `lib/features/currency/domain/models/rate_result.dart`. Residual scope gaps noted under Fragile Areas. |

## Tech Debt

**OCR feature is a UI-only stub (MOD-005 unfulfilled):**
- Issue: `OcrScannerScreen`/`OcrReviewScreen` render camera-style UI but do no recognition; `OcrParseDraft` model has no producer. Hidden behind `kOcrEntryEnabled = false`.
- Files: `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart`, `ocr_review_screen.dart`, `lib/features/accounting/domain/models/ocr_parse_draft.dart`, `lib/core/constants/feature_flags.dart`
- Impact: Dead UI surface + model carried in the tree; low risk while flagged off, but rots against the accounting flow.
- Fix approach: Implement with an on-device OCR SDK honoring the local-first constraint, or quarantine the stub until scheduled.

**Placeholder legal URLs shipped (report P3-15):**
- Issue: Privacy/Terms/Support links resolve to `https://example.com/homepocket/...`.
- Files: `lib/core/config/legal_urls.dart:19-23` (all three carry `// TODO 上线前填真实值`)
- Impact: Now that the About tiles are wired (prior concern #4 resolved), these links are user-reachable and go to a dead placeholder. Release blocker.
- Fix approach: Fill real URLs; attach to a release checklist.

**Coverage threshold contradicts project rule (report P2-4):**
- Issue: CI enforces per-file `--threshold 70` and `min_coverage: 70` (`.github/workflows/audit.yml:128,133`), but `.claude/rules/testing.md` mandates 80%. Phase 8 (2026-04-28) dropped it "revisited after v1 feature work completes"; v1 reached Phase 56. Backlog ID `coverage-baseline-review` unresolved.
- Impact: Standing double standard; the documented bar is not the enforced bar.
- Fix approach: Raise the gate back to 80% or amend `testing.md` — pick one and close the backlog item.

**`kMerchantAutoFillFloor` double-defined with no drift guard (report P3-7):**
- Issue: `0.85` floor declared twice — `lib/features/voice/domain/services/recognition_reconciler.dart:9` and `lib/application/voice/parse_voice_input_use_case.dart:19`. The mirror is intentional (domain service cannot import application) but has no parity test.
- Impact: Silent divergence if one is edited; reintroduces the Phase 51 floor-bypass bug class.
- Fix approach: Add a one-line parity test asserting the two constants are equal.

**Legacy text-style migration marker + GroupBar stub:** see Prior-Concern rows #3 and #5.

**Base-currency `'JPY'` literals scattered (report P3-6):** 59 sites, 7 sharing one predicate variant. Extract `kBaseCurrency` + `isForeignCurrency()` into `lib/shared/utils/currency_conversion.dart`.

**Large files (report P2-7) — one regressed since last map:**

| File | Lines | Note |
|------|-------|------|
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | 1370 | Highest priority; `TransactionDetailsFormState` exposes ~20 public members driven imperatively via GlobalKey (`submit()`, `build()` both oversized). |
| `lib/features/home/presentation/widgets/home_hero_card.dart` | 1155 | 5 visual blocks + ~25 `_xxx` builders; split under `widgets/home_hero/`. |
| `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` | 1027 | Extract FX-triple push + rate-signal helpers. |
| `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` | **1019** (was 833) | Grew via the ITN-concat repair work; recording state machine should stay whole (260622-nhs timing fix), but the "recognition→form fill" segment can extract. |

(`lib/shared/constants/default_categories.dart`, 1273 lines, is pure seed data — not a split target.)

## Known Bugs

No confirmed open functional bugs at HEAD: `flutter analyze` reports 0 issues and `flutter test` is 3561/3561 green (measured 2026-07-05).

**Watch items (not confirmed bugs):**
- **ITN-concat repair heuristic false-positive surface.** `VoiceTextParser.detectConcatRepairCandidate` (`voice_text_parser.dart:152`) can mis-flag a legitimate round-then-small amount (e.g. a genuine `50006` → 5000+6 → 5006). Mitigated by design — it never auto-rewrites; it only surfaces a one-tap suggestion, or auto-adopts when an alternate transcript independently agrees (`parse_voice_input_use_case.dart:97-112`). Precision-over-recall guardrails (length 5–9, zero-led/all-zero tails rejected) keep the common cases safe, but a user tapping "apply" on a false suggestion could corrupt a correct amount.
- **Dark `list_transaction_tile` golden** renders its internal date in `ja` for zh/en variants (locale not threaded into `ListTransactionTile`). Cosmetic, carried from Phase 34 WR-01.

## Security Considerations

**Outbound egress in a "local-first / zero-knowledge" app (unchanged):**
- Risk: `ExchangeRateApiClient` makes plaintext-destination HTTPS calls to three third-party FX APIs. This is the one component contradicting the offline-first / no-egress posture in CLAUDE.md.
- Files: `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart` (lines 10-12, 29-31)
- Current mitigation: JPY base-rate fetches only (no user financial data leaves the device); TLS; results cached in `exchange_rates`. Backup-import path now re-validates any imported rate against the canonical floor (CR-01), so a hostile cache seed cannot ride in.
- Recommendations: Document as an explicit ADR exception to the local-first invariant; add a user-facing FX-fetch toggle / offline fallback.

**Family-sync group key stored plaintext in Drift (report P3-1):**
- Risk: `groupKey` (symmetric key) is a plain `TextColumn` (`lib/data/tables/groups_table.dart:11`), protected only by database-level SQLCipher — weaker handling than every other key material (which uses secure storage / `FieldEncryptionService`).
- Recommendation: Route through `FieldEncryptionService` or move to secure storage.

**Third crypto implementation site outside `crypto/` (report P3-4):**
- Risk: `lib/infrastructure/sync/e2ee_service.dart` implements pinenacl NaCl Box in `sync/`, not `crypto/`, violating the "all crypto in `infrastructure/crypto/`" rule. (Note: the backup-crypto violation, formerly the second offsite site, was relocated into `crypto/` by P1-3.)
- Recommendation: Move into `crypto/` or record an explicit CLAUDE.md exemption.

**PIN has no failure lockout / backoff (report P3-2, D-06 accepted risk):**
- Risk: `pin_kdf.dart` verification has no attempt counter or exponential backoff; offline brute force is bounded only by Argon2id cost.
- Recommendation: Add a persisted (keychain) failure counter + exponential backoff in a later version.

**Backup file retained after share (report P3-3):** `export_backup_use_case.dart` writes the `.hpb` to the Documents directory and never deletes it post-share; it accumulates and is swept into iCloud backup. Write to a temp dir and delete in the share callback.

**Migration SQL built via string interpolation (report P3-5):** the `from < 14` step (`app_database.dart:294-302`) interpolates values into SQL. Current data contains no `'`, so it does not break today, but it is a latent injection/DoS-on-corruption seam — switch to bound parameters.

**Positive (do not "fix" away):** PIN storage (Argon2id → PHC in keychain, constant-time compare), `flutter_secure_storage` confined to 4 infra/crypto+security files, SQL fully parameterized with enum-gated ORDER BY, zero hardcoded secrets, encrypted (`note`) columns never in WHERE/ORDER BY — all re-verified in the 2026-07-02 review. Backup crypto is now correctly centralized in `infrastructure/crypto` with hostile-parameter bounds.

## Performance Bottlenecks

**Search box re-runs the full month query + row-decrypt on every keystroke (report P2-1):**
- Files: `lib/features/list/presentation/widgets/list_sort_filter_bar.dart:336` (`onChanged` writes `listFilterProvider` directly — no debounce/Timer), consumed by `state_list_transactions.dart`
- Cause: Each keystroke re-runs an unbounded month SQL and re-decrypts every row's `note` (ChaCha20).
- Improvement: 300 ms debounce; split `searchQuery` out of the SQL-refetch dependency so text filtering happens in memory.

**`findByBookIds` has no pagination (report P2-2):**
- Files: `lib/data/daos/transaction_dao.dart:243` — comment still reads "Pagination is deferred to v1.5" (now v2.x)
- Cause: Consumed directly by the transaction list and several analytics providers; family mode pulls a full month across multiple books.
- Improvement: keyset pagination (timestamp + id).

**Member-filtered category breakdown aggregates in Dart (report P2-3):**
- Files: `lib/features/analytics/presentation/providers/state_analytics.dart:102-129` — pulls both ledgers' full rows (each `note` decrypted) and loops `tx.deviceId == deviceId` in Dart
- Cause: `analytics_dao` already has a SQL GROUP BY path; it only lacks a `deviceId` filter parameter.
- Improvement: add optional `deviceId` to `getCategoryTotals` and push the aggregation into SQL.

**Watch area:** `lib/data/daos/analytics_dao.dart` (~746 lines) backs reports/donut/cumulative charts; the most likely place for query-cost regression as ledger volume grows. Note the P1-1 index backfill now creates the transaction/analytics indices that were previously never built — verify hot queries with `EXPLAIN QUERY PLAN` after the v23 upgrade (the backfill also carries a one-time index-build cost on the first launch after upgrade for existing large ledgers).

**Also open (P3):** dead reactive `watch()` path in `get_list_transactions_use_case.dart:70-88` (zero production consumers, includes a full-row re-decrypt path — P3-8); shopping-list Drift stream rebuilds on any filter field change (P3-9).

## Fragile Areas

**iOS SQLCipher / Podfile link-order (highest fragility, unchanged):**
- Files: `ios/Podfile` (`post_install`)
- Why fragile: strips `-l"sqlite3"` from every Pod xcconfig; if removed, any pod declaring `s.libraries = 'sqlite3'` (e.g. FirebaseMessaging) pulls system `libsqlite3.tbd`, which wins `dlsym` over SQLCipher → `PRAGMA cipher_version` empty → `encrypted_database.dart` throws "SQLCipher not loaded". Also carries the `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` ML Kit fix.
- Safe modification: never remove the strip or EXCLUDED_ARCHS; verify with `PRAGMA cipher_version` on device after any Pod change; use only `sqlcipher_flutter_libs ^0.6.x`.
- Test coverage: no Podfile lint; manual runtime check only.

**Dependency version lattice (unchanged):**
- Files: `pubspec.yaml`
- Why fragile: `file_picker ^11.0.2`, `package_info_plus ^9.0.1`, `share_plus ^12.0.2` are pinned together by a transitive `win32` constraint; bumping one in isolation breaks `flutter pub get` or the iOS native build. `intl` is hard-pinned to `0.20.2` by `flutter_localizations`.
- Safe modification: upgrade the file_picker/package_info_plus/share_plus trio together and verify `flutter build ios --debug --no-codesign`; never float `intl`.

**Voice recognition pipeline (expanded surface):**
- Files: `lib/application/voice/parse_voice_input_use_case.dart`, `voice_text_parser.dart`, `voice_chunk_merger.dart`, `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart`
- Why fragile: (a) the 0.85 auto-fill floor lives in the ORCHESTRATOR, not the recall-first engine — pushing floor logic into the engine or restoring a `?? merchantCategoryId` fallback reintroduces the Phase 51 floor-bypass bug class; (b) amount extraction is now a multi-stage heuristic gauntlet (Arabic regex vs. CJK state machine vs. comma-grouped authority vs. spaced/unspaced ITN-concat repair) whose routing correctness rests on several hand-tuned regexes (`_spacedRoundGroupPattern`, `detectConcatRepairCandidate` guardrails); (c) iOS speech quirks (treat `error_no_match` by error code, `cancel()` on reset to clear the buffer). The mixin is now 1019 lines.
- Safe modification: keep floor + keyword merge in the orchestrator; keep `detectConcatRepairCandidate` confirmation-gated (never auto-rewrite without alternate-transcript agreement); extend the voice unit-test corpus (`voice_amount_repair_test.dart`, `voice_text_parser_test.dart`) whenever a regex is touched.
- UX watch: the repair/undo affordances surface as a floating `SnackBar` with an action button (`voice_ptt_session_mixin.dart:538-558`, 4 s) that can overlap a modal form's bottom actions — minor overlay collision, not functional.

**Drift `customIndices` getter is decorative (persists, now mitigated):**
- Files: `lib/data/app_database.dart` migrations, any table using `customIndices`
- Why fragile: the getter still does NOT create indices; a new declared index only exists if it is also added to `_createAllDeclaredIndexes()` (which the guard test reconciles). The trap remains for anyone who adds a `customIndices` entry expecting it to take effect.
- Safe modification: add the index to the reconciled helper, not just the getter; `index_v23_migration_test.dart` will fail if a declaration is unbacked.

**Riverpod 3 async-read footguns (unchanged):**
- Files: `test/helpers/test_provider_scope.dart`, providers across `presentation/providers/`
- Why fragile: bare `await container.read(provider.future)` on auto-dispose providers yields "Bad state: disposed during loading"; use `waitForFirstValue` + `ProviderContainer.test()`; keep side-effect listeners in `ref.listen`, not `ref.watch`.

**Layer enforcement now has a real test but a narrow scope (P1-2 residual):**
- Files: `test/architecture/layer_import_rules_test.dart`, `lib/**/import_guard.yaml` (39 files)
- Why fragile: the new test is the real enforcement point, but it only forbids infrastructure→application/presentation, application→presentation, and domain→everything. It deliberately does NOT enforce presentation→data, infrastructure→data, or application→data. Meanwhile the 39 `import_guard.yaml` deny rules still match `package:` prefixes and remain inert against this repo's relative imports (the yaml side was left as deferred cleanup). Concretely, `lib/infrastructure/security/providers.dart:5` imports `data/app_database.dart` — a violation of that file's own yaml `deny: package:home_pocket/data/**` that neither the inert yaml nor the new test catches (it is a deliberate composition-root reach, but the declared rule and reality still disagree).
- Safe modification: when adding a layer rule, add it to `layer_import_rules_test.dart` (the yaml is not enforcing); if you want the yaml to mean something, add relative-path patterns or normalize imports first, and add `allow` exceptions for the composition-root `providers/` DAO/DB imports.

**Transactional writes that cross into SharedPreferences (P0-2 residual):**
- Files: `import_backup_use_case.dart:184-193`, `clear_all_data_use_case.dart:59-63`
- Why fragile: settings persist via SharedPreferences (not Drift), so the `_settingsRepo.updateSettings(...)` call inside `_unitOfWork.run(...)` is NOT rolled back if the surrounding Drift transaction aborts. The code mitigates this by running the settings write LAST (documented in-line), shrinking the window, but a settings write that itself throws would leave DB rolled back yet the pref possibly applied. Acceptable residual, but do not add more non-Drift side effects inside a `UnitOfWork` block.

## Scaling Limits

Not quantified for this local-first single-device app. The natural limit is per-device SQLite volume; `analytics_dao.dart` aggregate queries plus the unpaginated `findByBookIds` (P2-2) are the first places a large or multi-book ledger would show latency. No multi-tenant/server scaling surface (P2P family sync is out of current scope).

## Dependencies at Risk

**`sqlite3 ^2.7.5` / `sqlcipher_flutter_libs ^0.6.x` (not migrated to 3.x):**
- Risk: `0.7.0+eol` is a deliberate no-op because the project has not migrated to `sqlite3` 3.x; this couples the app to an EOL-adjacent line.
- Impact: future SQLCipher/sqlite3 security or platform fixes may require the 3.x migration first.
- Migration plan: coordinated bump of both, re-verifying the Podfile link-strip and `PRAGMA cipher_version` on device.

**`win32`-coupled trio:** see Fragile Areas — upgrade-blocked, not currently broken.

## Missing Critical Features

**OCR receipt scanning (MOD-005):** UI stubbed, no recognition backend, flag off. Blocks the "scan a receipt" entry path entirely.

**Family Sync (MOD-003):** out of current scope per CLAUDE.md; CRDT/Bluetooth/NFC infra directories exist but are not wired into a shipping flow. Its group-lifecycle use cases are also a test gap (below).

## Test Coverage Gaps

**iOS native link/runtime path (Podfile):** the `-lsqlite3` strip and EXCLUDED_ARCHS fixes have no automated lint; correctness is verified only by manual `PRAGMA cipher_version` on device. A silent Podfile edit could ship an app where encryption is unavailable at runtime. Priority: High.

**Real-device E2E is a single test (report P2-9):** `integration_test/` holds only one encrypted-migration test. Record-save and app-lock unlock each need at least one on-device smoke path — the three known app-lock failure modes (Info.plist `NSFaceIDUsageDescription`, `biometricOnly` default, `startOnPinPage` wiring) reproduce ONLY on real hardware. Priority: High.

**Family-sync group lifecycle untested (report P2-9):** `check_group_validity` / `handle_group_dissolved` / `handle_member_left` in `lib/application/family_sync/` have no dedicated unit tests — multi-device consistency boundary paths. Note also the silent `catch (_) { return false; }` at `pull_sync_use_case.dart:204` (E2EE group-key decrypt failure → member "silently never syncs"), one of three diagnostic-log gaps (report P2-8; also `exchange_rate_api_client.dart` two-tier fallback, `voice_ptt_session_mixin.dart` fill exception).

**Other gaps (report P2-9):** `lib/application/analytics/demo_data_service.dart` at 0% coverage (and its per-row insert is unbatched); app-lock widget tests cover only 4 cases (missing PIN-mismatch, `startOnPinPage` branch); `get_user_profile_use_case` read path untested (write path covered).

**Golden tests are macOS-baselined:** on CI (ubuntu) goldens can never pixel-match; `test/flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` off-macOS, so CI verifies existence, not pixels. Visual regressions land undetected unless re-baselined on macOS. Never run `dart format` over the whole `test/` tree (not format-clean). Priority: Medium.

**OCR stub:** no producer/tests for `OcrParseDraft`; acceptable while the feature is unbuilt and flagged off.

---

*Concerns audit: 2026-07-05*
