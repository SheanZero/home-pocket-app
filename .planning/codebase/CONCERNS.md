# Codebase Concerns

**Analysis Date:** 2026-06-23

This codebase is in unusually good health for its size (~70k LOC under `lib/`): `flutter analyze` reports **0 issues**, there are **392 test files**, and `// ignore:` suppressions exist only in generated localization files. The concerns below are therefore mostly *deferred features* and *architectural fragility* rather than active rot. Concerns are ordered roughly by impact.

---

## Tech Debt

**Dual-ledger classification is single-layer (2 of 3 layers stubbed):**
- Issue: `ClassificationService` advertises a 3-layer pipeline (Rule Engine → Merchant DB → ML Classifier) but Layers 2 and 3 are no-ops. Everything that misses a category rule falls through to a hard-coded `LedgerType.daily` at `confidence: 0.5`.
- Files: `lib/application/dual_ledger/classification_service.dart` (lines 32-44)
- Impact: Classification accuracy is capped at whatever the rule engine alone can achieve. The dual-ledger feature — a headline product differentiator — silently degrades to "default to daily" for any uncovered category. The `confidence` value surfaced to callers is misleadingly precise for a fallback.
- Fix approach: Wire `lib/infrastructure/ml/merchant_database.dart` (already exists and is used by the *voice* path) into Layer 2 here, then add the TFLite Layer 3. Note the voice flow (`voice_category_resolver.dart`, `parse_voice_input_use_case.dart`) already does merchant lookup — the transaction-create path has diverged from it.

**TFLite ML classifier never built; no dependency, no model:**
- Issue: `lib/infrastructure/ml/` contains only `merchant_database.dart`. There is no TFLite classifier, no `.tflite` model asset, and **no `tflite`/`mlkit`/`google_ml_kit` dependency in `pubspec.yaml`** despite CLAUDE.md and architecture docs describing an "85%+ TFLite classifier" and "ML/OCR (mlkit, tflite)".
- Files: `lib/infrastructure/ml/` (directory), `pubspec.yaml`
- Impact: Documentation/architecture claims diverge from reality. OCR receipt scanning (MOD-005) and ML classification are aspirational, not implemented.
- Fix approach: Either implement and add deps, or downgrade the architecture docs (`ARCH-003`, CLAUDE.md "ML/OCR" claims) to match the shipped feature set so planners aren't misled.

**Per-category budget tracking removed, use case is a hollow placeholder:**
- Issue: `GetBudgetProgressUseCase.execute()` unconditionally returns `[]`. The `budgetAmount` field was removed from `Category` and no replacement Budget table exists.
- Files: `lib/application/analytics/get_budget_progress_use_case.dart`
- Impact: Any UI/analytics consuming budget progress shows empty state permanently. Tests against this use case validate nothing meaningful.
- Fix approach: Introduce a dedicated `budgets` Drift table and re-implement, or remove the use case + its callers entirely until budgeting is scheduled.

**Transaction list pagination deferred:**
- Issue: `transaction_dao.dart` returns all matching rows; pagination explicitly "deferred to v1.5".
- Files: `lib/data/daos/transaction_dao.dart` (~line 243)
- Impact: For heavy users (years of daily entries) the list query loads the full history into memory each render. Acceptable now; a scaling cliff later.
- Fix approach: Add `LIMIT/OFFSET` (or keyset) pagination to the DAO and a lazy list in presentation.

**Disabled-but-retained celebration feature:**
- Issue: Joy-save celebration animation gated behind `static const bool _kJoyCelebrationEnabled = false`. All scaffolding (overlay, completer machinery, `waitForCelebrationDismissed`) is kept live.
- Files: `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (lines 148-160), `joy_celebration_overlay.dart`
- Impact: Dead-but-wired code in a 1171-line file (the largest hand-written file in the repo). The completer/future plumbing still executes around a no-op overlay, adding cognitive load to an already oversized widget.
- Fix approach: Leave the flag (re-enable is intentional one-liner) but consider extracting the celebration machinery into its own widget so the form file shrinks.

---

## Fragile Areas

**iOS SQLCipher / `libsqlite3` linkage (runtime-fatal if broken):**
- Files: `ios/Podfile` (`post_install`), `lib/infrastructure/crypto/database/encrypted_database.dart`
- Why fragile: The Podfile `post_install` strips `-l"sqlite3"` from every Pod xcconfig. If removed (e.g. by a careless `pod` regeneration or merge), FirebaseMessaging pulls in the system `libsqlite3.tbd`, which wins `dlsym` over SQLCipher. `PRAGMA cipher_version` then returns empty and `encrypted_database.dart` throws `Bad state: SQLCipher not loaded`. The app fails to start with an unencrypted-or-dead database.
- Safe modification: Never touch the Podfile `post_install` without a clean iOS rebuild and verifying `PRAGMA cipher_version` is non-empty. No automated lint guards this — relies on reviewer discipline and runtime check.
- Test coverage: None at the native-linkage level; cannot be exercised in `flutter test`.

**Pinned dependency trio (`file_picker` / `package_info_plus` / `share_plus`):**
- Files: `pubspec.yaml`
- Why fragile: These three are mutually constrained through a transitive `win32` version. Bumping any one in isolation breaks `flutter pub get` or the iOS native build (`file_picker 12.x` ships a broken iOS Swift module). `intl` is similarly pinned to exactly `0.20.2` by `flutter_localizations`.
- Safe modification: Upgrade the trio together and verify `flutter build ios --debug --no-codesign`. Documented in CLAUDE.md but enforced only by build failure, not a lint.

**Drift schema at v21 with 21 hand-written migration branches:**
- Files: `lib/data/app_database.dart` (`schemaVersion => 21`, ~21 `from`/`if (from` branches)
- Why fragile: Each migration is hand-emitted. `customIndices` is decorative — indices must be emitted by hand in *both* `onCreate` and `onUpgrade` (a known footgun, see project memory). Missing a CREATE INDEX in one of the two paths produces installs whose index state depends on install-vs-upgrade history.
- Safe modification: When adding a table/index, mirror the DDL in both `onCreate` and `onUpgrade`, bump `schemaVersion`, and add a migration test. There is a `schemaVersion` mismatch risk vs CLAUDE.md which still documents "v20" — the code is already at v21.
- Test coverage: Migration tests exist but coverage of every index across both paths is not guaranteed.

---

## Security Considerations

**Swallowed exceptions on network/crypto sync paths:**
- Risk: ~20 `catch (_)` blocks. Most in sync paths are *intentional* retry-or-fail logic (e.g. `sync_queue_manager.dart` increments retry count, `pull_sync_use_case.dart` returns `false` on group-key decryption failure). But a bare `catch (_)` around `decryptGroupKeyFromOwner` (`pull_sync_use_case.dart:204`) conflates "tampered/forged payload" with "transient error" — both just return `false`.
- Files: `lib/application/family_sync/pull_sync_use_case.dart`, `lib/infrastructure/sync/sync_queue_manager.dart`, `lib/infrastructure/sync/e2ee_service.dart`, `lib/infrastructure/sync/websocket_service.dart`
- Current mitigation: Failures degrade safely (entry not consumed, retry counter advances). No secret data is logged.
- Recommendations: Distinguish authentication/integrity failures (potential attack) from transient I/O failures in the E2EE decrypt paths, and surface/audit-log the former via `audit_logger`. A silently-failing group-key decrypt could mask a man-in-the-middle relay attempting forged payloads.

**Hard-coded sync relay endpoint:**
- Risk: Relay base URL defaults to `https://sync.happypocket.app/api/v1` (derived `wss://`) in source.
- Files: `lib/infrastructure/sync/relay_api_client.dart` (lines 52, 69, 75)
- Current mitigation: TLS 1.3 + E2EE means the relay is untrusted-by-design, so a fixed URL is lower-risk than usual. The constructor appears to accept an override.
- Recommendations: Confirm the override path is actually used in production config; ensure no environment can fall through to the hard-coded default unintentionally.

---

## Performance Bottlenecks

**Unbounded transaction queries:**
- Problem: List and analytics DAOs fetch full result sets (see "pagination deferred" above).
- Files: `lib/data/daos/transaction_dao.dart`, `lib/data/daos/analytics_dao.dart` (746 lines — the largest DAO)
- Cause: No `LIMIT`; entire history materialized per query.
- Improvement path: Keyset pagination on list; pre-aggregated/cached monthly rollups for analytics rather than re-scanning all transactions on each report render.

**Oversized presentation widgets:**
- Problem: Several hand-written files exceed the project's own 800-line max from `.claude/rules/coding-style.md`:
  - `transaction_details_form.dart` — 1171 lines
  - `home_hero_card.dart` — 1155 lines
  - `manual_one_step_screen.dart` — 1025 lines
- Files: as listed, under `lib/features/`
- Cause: Accreted UI logic + animation scaffolding (some disabled) in single widgets.
- Improvement path: Extract sub-widgets and the celebration/animation machinery. These are not perf bottlenecks at runtime but are rebuild/maintenance hotspots and violate the repo's stated file-size budget.

---

## Test Coverage Gaps

**`profile` and `dual_ledger` features under-tested relative to peers:**
- What's not tested: `profile` has only 5 tests, `dual_ledger` only 6, vs. accounting (55) / analytics (65) / list (44).
- Files: `lib/features/profile/`, `lib/application/dual_ledger/`
- Risk: `dual_ledger` is the product's core differentiator and its classification fallback logic (`classification_service.dart`) is exactly the kind of branch that needs regression coverage as Layers 2/3 get wired in. `profile` includes a `catch (_)` in `save_user_profile_use_case.dart` whose failure mode is untested.
- Priority: Medium (dual_ledger), Low (profile).

**Stub use cases validated by hollow tests:**
- What's not tested meaningfully: `GetBudgetProgressUseCase` always returns `[]`, so any test of it asserts the placeholder, not behavior.
- Files: `lib/application/analytics/get_budget_progress_use_case.dart`
- Risk: Gives false coverage confidence; the real budgeting logic will be untested when introduced.
- Priority: Low (until budgeting is scheduled).

**Native iOS linkage / SQLCipher loading unverifiable in CI:**
- What's not tested: The `-lsqlite3` strip and SQLCipher runtime load (most security-critical, runtime-fatal path).
- Files: `ios/Podfile`, `lib/infrastructure/crypto/database/encrypted_database.dart`
- Risk: A regression here is invisible to `flutter test` and `flutter analyze` and only surfaces on a real device/simulator boot.
- Priority: High — consider a smoke test in iOS CI that boots the app and asserts `PRAGMA cipher_version` is non-empty.

---

## Dependencies at Risk

**`sqlcipher_flutter_libs` lacks Swift Package Manager support:**
- Risk: `flutter analyze` emits a warning that `sqlcipher_flutter_libs` does not support SPM and "this will become an error in a future version of Flutter."
- Impact: A future Flutter that hard-requires SPM could break the iOS build of the encryption layer entirely. The project is pinned to `^0.6.x` and intentionally has *not* migrated to `sqlite3` 3.x (`0.7.0+eol` is a do-nothing package).
- Migration plan: Track upstream `sqlcipher_flutter_libs` SPM adoption; this is an external blocker the project cannot resolve alone. Monitor before each Flutter SDK upgrade.

**`win32`-coupled trio and `intl 0.20.2` pin:** see "Fragile Areas". These are version-locks that constrain future upgrades.

---

## Missing Critical Features

**OCR receipt scanning (MOD-005):**
- Problem: Described in CLAUDE.md/architecture but no ML Kit dependency or OCR pipeline present in `lib/`.
- Blocks: Receipt-scan entry flow; one of the four "Enhanced" modules.

**ML transaction classifier (Layer 3 of dual ledger):** see Tech Debt — no model, no dependency.

**Per-category budgeting:** see Tech Debt — table removed, use case hollow.

---

*Concerns audit: 2026-06-23*
