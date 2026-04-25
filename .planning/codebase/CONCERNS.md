# CONCERNS

**Analysis Date:** 2026-04-25

This audit captures technical debt, security risks, fragile areas, and incomplete modules in the Home Pocket Flutter app (Phase 1, v0.1.0). Findings sourced from inline `TODO`/`FIXME` markers, `docs/issues/`, worklog entries, and direct code review.

---

## Tech Debt

### Inline TODO markers (small set, but several touch core flows)

**Wa-Modern theme migration — legacy aliases retained:**
- `lib/core/theme/app_colors.dart:60`, `lib/core/theme/app_text_styles.dart:171`
- `// TODO: Remove after all screens are migrated to Wa-Modern` — old token names kept as aliases
- Impact: Two parallel design-token systems coexist; inconsistent styling and dead-code accumulation
- Fix: Audit screens for legacy token usage, replace with Wa-Modern tokens, delete deprecated constants

**Home screen — group integration not wired:**
- `lib/features/home/presentation/screens/home_screen.dart:147,176`
- `// TODO: Wire GroupBar with actual group data when available` — `isGroupMode` branch renders `SizedBox.shrink()`
- `// TODO: Navigate to full transaction list` — "すべて見る" button is a no-op `GestureDetector`
- Fix: Build `GroupBar` widget bound to `currentGroupProvider`; add a route to a full transaction-list screen

**Settings privacy policy stub:**
- `lib/features/settings/presentation/widgets/about_section.dart:29`
- `// TODO: Navigate to privacy policy` — tap handler empty
- Fix: Create localized privacy policy screen or open external URL

### Deprecated services still wired into provider graph

**`ResolveLedgerTypeService` retained alongside `CategoryService`:**
- `lib/application/dual_ledger/resolve_ledger_type_service.dart:10`, `lib/features/accounting/presentation/providers/use_case_providers.dart:13,66-69`
- `@Deprecated('Use CategoryService instead')` — old service kept with three `// ignore: deprecated_member_use_from_same_package`
- Fix: Migrate every call site to `CategoryService.resolveLedgerType` and `resolveL1`, delete `resolve_ledger_type_service.dart`

**Sync repository deprecated fields kept for backward compatibility:**
- `lib/features/family_sync/domain/repositories/sync_repository.dart:48,51`
- `@Deprecated('Use groupId instead.')` and `@Deprecated('targetDeviceId is removed for group fan-out.')`
- Fix: Remove after confirming all queued/in-flight sync messages are migrated

### Hardcoded UI strings violate i18n rule

- ~169 occurrences of CJK text in non-generated source files (excluding intentional dictionaries)
- Notable hotspots:
  - `lib/features/home/presentation/screens/home_screen.dart:83` (`'今月の支出'`), `:108` (`'帳 本'`), `:169` (`'最近の取引'`), `:179` (`'すべて見る'`), `:197` (`'取引がまだありません'`), `:266-302` (ledger labels `'生'`/`'灵'`/`'共'`, `'生存帳本'`, `'灵魂帳本'`)
  - `lib/features/home/presentation/widgets/soul_fullness_card.dart:56` (`'灵魂の充実度'`)
  - `lib/features/accounting/presentation/screens/voice_input_screen.dart:131` (`'マイクへのアクセスを許可してください'`)
  - `lib/features/settings/presentation/widgets/appearance_section.dart:12` — language-name map hardcoded
- Impact: Chinese and English locales display untranslated Japanese; violates `CLAUDE.md` "All UI text via `S.of(context)`"
- Fix: Extract every literal to `lib/l10n/app_*.arb` (all three files), regenerate via `flutter gen-l10n`

### Static localization fallback duplicates ARB content

- `lib/infrastructure/category/category_service.dart` (735 lines)
- Maintains parallel `_ja`, `_zh`, `_en` maps because Flutter's generated `S` class does not support dynamic-key lookup
- Risk: Translation drift — devs may update ARB but forget the static map (or vice versa)
- Fix: Replace with a generated lookup that ingests ARB, or add a build-time consistency test

### Generated code carries broad lint suppressions

- All `*.freezed.dart` and `*.g.dart` carry `// ignore_for_file: ... deprecated_member_use ...`
- Acceptable for generated files; periodically regenerate and watch hand-written code analyzer output

---

## Known Bugs / Open Issues

### `recoverFromSeed()` overwrites existing device keys (HIGH severity, unaddressed)

- Source: `docs/issues/recover-from-seed-overwrites-existing-keys.md`
- File: `lib/infrastructure/crypto/repositories/key_repository_impl.dart:53-79`
- Issue: `recoverFromSeed(List<int> seed)` validates only `seed.length == 32` and unconditionally writes `device_private_key`, `device_public_key`, `device_id` to secure storage — even when keys already exist
- Asymmetry: `generateKeyPair()` does check for existing keys; `recoverFromSeed` does not
- Risk: User triggers recovery while old device keys are present → old private key irreversibly lost. Encrypted/signed data may become unverifiable. Hash-chain continuity may break.
- Fix:
  1. Add `if (await getPublicKey() != null) throw StateError(...)` guard at top of `recoverFromSeed`
  2. Add unit test: existing keys → recovery throws and storage unchanged
  3. Add unit test: clean storage + valid 32-byte seed → recovery succeeds
  4. Document the contract in the `KeyRepository` interface

### AuditLogger has no retention policy (MEDIUM severity)

- Source: `docs/issues/audit-logger-retention-policy.md`
- File: `lib/infrastructure/security/audit_logger.dart`
- No `pruneOldLogs()` method; `audit_logs` table grows unbounded (~100 events/day → ~36k rows/year)
- Fix: Implement `Future<int> pruneOldLogs({int retentionDays = 90})`; schedule via `AppInitializer` or settings action

### CLAUDE.md vs reality drift around iOS Podfile

- `ios/Podfile` (lines 1-43)
- `CLAUDE.md` and `MEMORY.md` claim the Podfile contains `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` for ML Kit. Actual Podfile has only `flutter_additional_ios_build_settings(target)` inside `post_install` and no architecture override.
- The only `EXCLUDED_ARCHS` entries live in `ios/Flutter/Generated.xcconfig` (`i386`/`armv7`) — these are Flutter defaults, not the documented ML Kit fix.
- Risk: Codebase has **no ML Kit / OCR code**, so the issue is dormant — but it will resurface the moment OCR work begins. Apple Silicon simulator builds will break.
- Fix: Before adding `google_mlkit_*` dependencies, restore the `post_install` hook: `config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'`. Update `CLAUDE.md` if the workaround is no longer needed.

---

## Security Considerations

### Crypto correctness

- Implementations live in the documented locations under `lib/infrastructure/crypto/`:
  - Ed25519 keypair: `lib/infrastructure/crypto/repositories/key_repository_impl.dart`
  - ChaCha20-Poly1305 field encryption: `lib/infrastructure/crypto/repositories/encryption_repository_impl.dart`
  - SQLCipher AES-256-CBC, PBKDF2 256k iter: `lib/infrastructure/crypto/database/encrypted_database.dart:42-44`
  - Hash chain: `lib/infrastructure/crypto/services/hash_chain_service.dart`
- All match `CLAUDE.md` 4-layer encryption spec.
- Risk: `_setupEncryption` interpolates `dbKey` into `PRAGMA key = "x'$dbKey'";`. Hex key from HKDF is constrained to `[0-9a-f]`, so SQL-injection is not possible — but a regression in `_deriveDatabaseKey` emitting non-hex bytes would break encryption silently.
- Fix: Add a `RegExp(r'^[0-9a-f]{64}$').hasMatch(dbKey)` assertion before executing the PRAGMA

### Key-storage boundary

- All `flutter_secure_storage` access centralized through `lib/infrastructure/security/secure_storage_service.dart` and `lib/infrastructure/crypto/repositories/key_repository_impl.dart`. No direct `FlutterSecureStorage()` constructions in features layer (verified via grep).
- Master key derivation flows through `MasterKeyRepository.deriveKey()` (HKDF) — domain code receives derived `SecretKey`, never the raw master key.
- Confirmed-good pattern.

### Encryption boundaries (E2EE for sync)

- `lib/infrastructure/sync/e2ee_service.dart` (tests in `test/infrastructure/sync/e2ee_service_test.dart`)
- Sync payloads encrypted by `E2EEService` before hitting `RelayApiClient`; relay only sees ciphertext.
- Risk: `RequestSigner.signRequest` (`lib/infrastructure/sync/relay_api_client.dart:41`) calls `debugPrint('[RequestSigner] message=$message')` inside `if (kDebugMode)`. Signed message includes method, path, timestamp, body hash — not secrets. Acceptable.

### Debug logging in sync layer leaks operational metadata

- ~47 `debugPrint` sites total in `lib/`. Hotspots:
  - `lib/application/family_sync/sync_engine.dart:99-117` (`'[SyncEngine] onTransactionChanged'`)
  - `lib/application/family_sync/transaction_change_tracker.dart:19-42` (logs entity IDs unguarded)
  - `lib/application/family_sync/sync_orchestrator.dart:82-186`
  - `lib/application/family_sync/full_sync_use_case.dart:31-73`
  - `lib/application/family_sync/pull_sync_use_case.dart:87-167`
- Risk: Most are `if (kDebugMode)` guarded, but a few unguarded `debugPrint` calls exist in `sync_engine.dart` and `transaction_change_tracker.dart`. Flutter no-ops `debugPrint` in release, so prod exposure is low — but dev/QA log files may capture transaction IDs, group IDs, member identifiers.
- Fix: Wrap remaining unguarded `debugPrint` in `if (kDebugMode)`; consider replacing ad-hoc logging with `dart:developer.log` for centralized filtering

### `analysis_options.yaml` permits `print()`

- `analysis_options.yaml:14` — `avoid_print: false`
- Risk: Future contributors can introduce `print()` instead of `debugPrint`/`dev.log`
- Fix: Flip to `avoid_print: true` and audit for new violations

---

## Performance Bottlenecks

### Audit-log table will grow unbounded

- `lib/data/tables/audit_logs_table.dart`
- No retention policy AND no index on `timestamp` or `event`
- Fix: Add `TableIndex(name: 'idx_audit_timestamp', columns: {#timestamp})` and `TableIndex(name: 'idx_audit_event', columns: {#event})`; combine with `pruneOldLogs`

### Three Drift tables have no custom indices

- Files (no `customIndices` getter):
  - `lib/data/tables/audit_logs_table.dart`
  - `lib/data/tables/user_profiles_table.dart`
  - `lib/data/tables/category_ledger_configs_table.dart`
- Impact: Range/filter queries (audit-log timeline, profile sync timestamp) will table-scan
- Fix: Add appropriate indices following documented `TableIndex` pattern. Bump `schemaVersion` and add migration.

### Category-selection screen renders nested reorderable list

- `lib/features/accounting/presentation/screens/category_selection_screen.dart` (691 lines, `ListView.builder` at `:340`, `ReorderableListView.builder` at `:493`)
- Cause: Reorder mode wraps L1 in `SliverReorderableList` with L2 children embedded as `ReorderableListView.builder(shrinkWrap: true)` per row
- Impact: Each L1 expansion rebuilds its own list; with many L2 children (≥30) jank likely on low-end Android
- Fix: Profile with DevTools timeline; lazy-load L2 children only when expanded, or virtualize the entire tree as a flat sliver list

### Voice input retains in-memory sound-level history

- `lib/features/accounting/presentation/screens/voice_input_screen.dart:199-200`
- `_soundLevels.add(level); _timestamps.add(now);` — lists grow for entire recording duration; never trimmed
- Impact: Long recordings accumulate hundreds of doubles
- Fix: Cap at last N seconds (e.g., 5s rolling window) by trimming when `_timestamps.first < now - 5s`

### Full localization map loaded at startup

- `lib/generated/app_localizations*.dart` (~5,400 lines combined), `lib/shared/constants/default_categories.dart` (1,268 lines)
- Cold-start parses everything; not a problem at current scale
- Revisit if cold-start budget is exceeded

---

## Fragile Areas

### iOS Podfile EXCLUDED_ARCHS workaround documented but absent

See "Known Bugs / CLAUDE.md vs reality drift" above. Restoring the workaround is a prerequisite for adding `google_mlkit_*` dependencies (currently absent from `pubspec.yaml`).

### `intl` version pin

- `pubspec.yaml:17` — `intl: 0.20.2` (pinned, no caret)
- Constraint: `flutter_localizations` (transitive) requires this exact version
- Risk: `flutter pub upgrade` may try to bump and fail; CI may break when Flutter SDK updates the upper bound
- Fix: Keep pinned. Re-check after each Flutter SDK upgrade.

### `sqlcipher_flutter_libs` vs `sqlite3_flutter_libs` conflict

- `pubspec.yaml:65` declares only `sqlcipher_flutter_libs: ^0.6.7`; no `sqlite3_flutter_libs` in `pubspec.yaml` or `pubspec.lock`
- Risk: A transitive dep introducing `sqlite3_flutter_libs` would cause native-library symbol conflict at link time
- Mitigation in place: `lib/infrastructure/crypto/database/encrypted_database.dart:78-83` — `ensureNativeLibrary()` calls `open.overrideFor(OperatingSystem.android, openCipherOnAndroid)` to force SQLCipher binary on Android
- Fix: Add `dependency_overrides` if a transitive dep ever pulls in `sqlite3_flutter_libs`; add CI check `! grep -q sqlite3_flutter_libs pubspec.lock`

### Drift `TableIndex` syntax is easy to get wrong

- 8 of 11 tables under `lib/data/tables/` correctly use `TableIndex(name: 'idx_...', columns: {#columnName})` — see `transactions_table.dart:45-51`, `categories_table.dart:22-25`, `books_table.dart:26-30`
- Risk per `CLAUDE.md` Common Pitfalls #11: easy mistakes are using `Index()` constructor, adding `@override`, omitting `#` Symbol prefix, misspelling `customIndices` as `customIndexes`
- Fix: Add a unit test that asserts every table either declares `customIndices` or is documented as not requiring indices. Three tables currently violate this.

### Database migrations chain is long and fragile

- `lib/data/app_database.dart:50-244`
- `schemaVersion = 14`; migrations from v3 → v14 (11 step-functions)
- Risks:
  - `from < 14` migration (lines 159-242) uses raw `customStatement` with **string interpolation** of category fields — a single quote in `cat.name` would inject SQL. Current `DefaultCategories` has no quotes, but a future translation containing one (e.g., `D'arc`) breaks migration.
  - Several conditional branches (`from >= 8 && from < 13`) couple migration logic to historical schema states.
  - Migration v14 issues 30+ `INSERT OR REPLACE` statements (in a transaction block, but slow on cold start of upgrading users).
- Fix: Replace string interpolation in v14 with parameterized statements: `customStatement('INSERT OR REPLACE INTO categories ... VALUES (?, ?, ?, ...)', [cat.id, cat.name, ...])`

### `appDatabaseProvider` throws by default

- `lib/infrastructure/security/providers.dart:96-102`
- `@riverpod AppDatabase appDatabase(Ref ref) { throw UnimplementedError(...); }`
- Reason: Provider is intentionally a placeholder — `lib/main.dart:73-75` overrides via `ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(database)])`
- Risk: Any code path using `appDatabaseProvider` without going through the override (e.g., a widget test that constructs its own `ProviderScope`, a future feature with a child container) throws at runtime. No static check that the override is in place.
- Fix: Add an integration test verifying the override is wired

---

## Incomplete Modules

### MOD-004 OCR — completely absent

- Status: Not started. Backlog: `docs/plans/2026-02-26-mod004-ocr-phase2-backend-pipeline.md`, `docs/issues/ocr-phase2-llm-labeling-tiny-model.md`
- Evidence:
  - No `lib/application/ocr/` directory
  - No `lib/infrastructure/ml/ocr/` directory (only `merchant_database.dart` under `lib/infrastructure/ml/`)
  - L10n keys `ocrScan`, `ocrScanTitle`, `ocrHint` exist in `lib/generated/app_localizations_en.dart:517,559,562` but no screen implements them
  - No `google_mlkit_*` or `tflite_flutter` packages in `pubspec.yaml`
- Risk: Restoring iOS `EXCLUDED_ARCHS` workaround is mandatory before this work begins

### MOD-003 ML Classifier — stubbed

- `lib/application/dual_ledger/classification_service.dart:32-44`
- Layer 1 (rule engine) implemented; Layers 2 (`MerchantDatabase`) and 3 (`TFLiteClassifier`) skipped. `MerchantDatabase` exists but `ClassificationService` does not consult it. `TFLiteClassifier` does not exist.
- Code:
  ```dart
  // Layer 2: Merchant Database (stub for MVP)
  // TODO: Implement MerchantDatabase lookup when lib/infrastructure/ml/ is built
  // Layer 3: ML Classifier (stub for MVP)
  // TODO: Implement TFLiteClassifier when model is available
  return ClassificationResult(ledgerType: LedgerType.survival, confidence: 0.5, ...);
  ```
- Impact: Every transaction not matching a hardcoded rule defaults to `survival` ledger with 0.5 confidence — soul ledger under-populated
- Fix: Inject `MerchantDatabase` into `ClassificationService` constructor; consult it after Layer 1 miss

### `MerchantDatabase` carries seed data, not the spec'd 500+ entries

- `lib/infrastructure/ml/merchant_database.dart:46-119` — 12 hardcoded entries (Japanese conbini, fast food, electronics)
- Per `CLAUDE.md`: should be 500+ entries
- Fix: Move to a Drift table populated from a JSON asset; seed via migration; expand to 500+ entries

### P2P sync infrastructure (Bluetooth/NFC/WiFi) — not implemented

- Per `CLAUDE.md`: `lib/infrastructure/sync/` should contain `crdt`, `bluetooth`, `nfc`, `wifi` subdirectories
- Reality: `lib/infrastructure/sync/` has only server-relay implementations (`relay_api_client.dart`, `websocket_service.dart`, `apns_push_messaging_client.dart`, `e2ee_service.dart`, `push_notification_service.dart`, `sync_lifecycle_observer.dart`, `sync_queue_manager.dart`, `sync_scheduler.dart`)
- Impact: "Local-first, P2P sync" promise is currently server-mediated only. CRDT logic absent.
- Fix: Out of scope for Phase 1 per worklog evidence; document the architectural divergence or update `CLAUDE.md`/`MEMORY.md` to reflect relay-server reality

---

## Test Coverage Gaps

### Counts
- Source files (excluding generated): **268**
- Test files: **183**
- Naive ratio: ~68% — gaps concentrated in critical infrastructure

### Untested infrastructure modules (high risk)

- **`lib/infrastructure/ml/merchant_database.dart`** — no test file (fuzzy match logic uncovered)
- **`lib/infrastructure/category/category_service.dart`** — no test file (735 lines; ARB-vs-static-map drift invisible)
- **`lib/application/family_sync/sync_engine.dart`** — only one test (`test/application/family_sync/sync_engine_dedup_test.dart`); lifecycle observer wiring, WebSocket event subscription, status stream behavior uncovered
- **`lib/application/family_sync/sync_orchestrator.dart`** — no dedicated test
- **`lib/infrastructure/sync/sync_queue_manager.dart`, `sync_scheduler.dart`, `sync_lifecycle_observer.dart`** — no test files (backoff, retry, lifecycle uncovered)
- **`lib/application/family_sync/transaction_change_tracker.dart`** — no test file (per worklog `20260405_1854_add_transaction_change_tracker.md`)
- Priority: Mostly High — sync engine is critical-path orchestrator

### Negative-path test gaps in crypto

- `recoverFromSeed()` lacks a test for "existing keys present → must reject" (see Known Bugs). Single existing call site in `test/infrastructure/crypto/services/key_manager_test.dart:116-131` only tests the happy path.
- `KeyRepositoryImpl.signData` has no test for "private key missing → throws `KeyNotFoundException`"
- Priority: High — security regressions silent

### Widget-test gaps for high-traffic screens

- `lib/features/accounting/presentation/screens/transaction_form_screen.dart` — no widget test
- `lib/features/accounting/presentation/screens/transaction_list_screen.dart` — no widget test
- `lib/features/family_sync/presentation/screens/create_group_screen.dart`, `join_group_screen.dart` — no widget tests
- Priority: Medium

### Test-mock artifacts in repo

- 8 `*.mocks.dart` files committed under `test/` (e.g., `test/integration/sync/bill_sync_round_trip_test.mocks.dart`)
- Generated by `mockito`; must be regenerated on every interface change
- Priority: Low

---

## Scaling Limits

### Single-database write contention

- Drift uses a single SQLite connection on Flutter (no pool)
- Heavy operations (full migration, bulk import) block all reads
- Limit: Bulk backup/restore of 10k+ transactions will freeze UI without isolate offload
- Path: Move heavy operations to background isolates using Drift's isolate APIs

### Sync queue unbounded retention

- `lib/data/tables/sync_queue_table.dart`
- Has `customIndices` on `createdAt` but no automatic eviction of successfully-acked entries
- Risk: Long-offline devices may accumulate large queues that never get pruned
- Fix: Add "delete after successful ack" path in `SyncQueueManager`

---

## Dependencies at Risk

### `intl: 0.20.2` (pinned)
- Pinned by transitive constraint from `flutter_localizations`
- Migration: Track Flutter changelogs; bump in lockstep with SDK upgrade

### `flutter_secure_storage: ^9.2.4`
- Critical for crypto layer; any breakage destroys keys
- Risk: Major version bumps have historically changed Android Keystore behavior, occasionally requiring re-enrollment
- Migration: Pin major version, test recovery flow before upgrading

### `cryptography: ^2.7.0`
- Pure-Dart crypto for Ed25519, ChaCha20-Poly1305
- Risk: Verify package remains active. Switching primitives mid-flight is expensive because hash chain depends on stable signatures.
- Migration: Track package activity; `pinenacl` already in deps as fallback

### `firebase_core: ^4.1.1`, `firebase_messaging: ^16.0.1`
- Used solely for FCM push wake-ups (`lib/infrastructure/sync/push_notification_service.dart`)
- Risk: Firebase initialization adds cold-start cost; introduces Google dependency to an otherwise privacy-focused app
- Mitigation: APNS also wired (`apns_push_messaging_client.dart`)

---

## Missing Critical Features

### Centralized `AppInitializer`

- Per `CLAUDE.md`: "Core services MUST be initialized before `runApp()` via `AppInitializer` (`lib/core/initialization/app_initializer.dart`)"
- Reality: `lib/core/initialization/` directory does not exist; initialization logic inlined in `lib/main.dart:28-83` (master key → keypair → DB → seed → ensure book)
- Impact: Init steps not unit-testable; ordering implicit; error recovery partial — inlined `try/catch` in `_HomePocketAppState._initialize` covers post-DB steps only — a master-key failure crashes before the catch
- Fix: Extract `lib/core/initialization/app_initializer.dart` with `Future<InitResult> initialize(ProviderContainer container)`; main.dart calls it; result drives fallback screen

### Privacy policy / Terms of Service screens

- `lib/features/settings/presentation/widgets/about_section.dart:29` — TODO noted
- Required for App Store / Play Store submission

### Full transaction-list screen routing

- `lib/features/home/presentation/screens/home_screen.dart:176` — TODO noted
- `transaction_list_screen.dart` exists but is not routed from home

### Recovery-kit / BIP39 export UI

- Per `CLAUDE.md`: "BIP39 recovery phrase, HKDF derivation"
- Reality: No BIP39 dependency in `pubspec.yaml`; no recovery-kit screen
- Impact: Users have no documented way to back up keys; `recoverFromSeed()` callable but no UI entry point
- Fix: Add `bip39` package + `recovery_kit_screen.dart` once key-overwrite bug (Known Bugs) is fixed

---

## Files Referenced

- `docs/issues/recover-from-seed-overwrites-existing-keys.md`
- `docs/issues/audit-logger-retention-policy.md`
- `docs/issues/ocr-phase2-llm-labeling-tiny-model.md`
- `docs/plans/2026-02-26-mod004-ocr-phase2-backend-pipeline.md`
- `lib/infrastructure/crypto/repositories/key_repository_impl.dart`
- `lib/infrastructure/crypto/database/encrypted_database.dart`
- `lib/infrastructure/security/audit_logger.dart`
- `lib/application/dual_ledger/classification_service.dart`
- `lib/application/family_sync/sync_engine.dart`, `sync_orchestrator.dart`, `transaction_change_tracker.dart`
- `lib/infrastructure/sync/sync_queue_manager.dart`, `sync_scheduler.dart`, `sync_lifecycle_observer.dart`
- `lib/infrastructure/security/providers.dart`
- `lib/infrastructure/ml/merchant_database.dart`
- `lib/infrastructure/category/category_service.dart`
- `lib/data/app_database.dart`
- `lib/data/tables/audit_logs_table.dart`, `user_profiles_table.dart`, `category_ledger_configs_table.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/accounting/presentation/screens/category_selection_screen.dart`, `voice_input_screen.dart`
- `lib/features/settings/presentation/widgets/about_section.dart`
- `lib/core/theme/app_colors.dart`, `app_text_styles.dart`
- `lib/main.dart`
- `ios/Podfile`
- `pubspec.yaml`, `analysis_options.yaml`
