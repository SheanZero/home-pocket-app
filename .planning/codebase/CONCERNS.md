# Codebase Concerns

**Analysis Date:** 2026-08-05
**Last mapped commit:** `7b4f1bac44644ea821835e85d09d9571a601e82a`

This audit covers the committed tree and the current P1/P2 working tree. Core local-first storage and cryptographic boundaries are healthy; the largest remaining risks are release configuration, legal accuracy, CI drift, and concentrated complexity.

## Tech Debt

**Release signing is still a debug configuration (HIGH):**
- Issue: Release builds explicitly use the debug signing key.
- Files: `android/app/build.gradle.kts:35-39`
- Impact: A debug-signed APK cannot establish a production Play upgrade chain and creates supply-chain risk.
- Fix approach: Inject a protected upload/app-signing configuration from CI secrets or an untracked `key.properties`; fail release builds when the certificate is debug.

**Legal content still contains launch placeholders (HIGH):**
- Issue: Bundled Japanese, English, and Chinese legal documents retain `support@example.com`, draft wording, and Tokusho operator placeholders.
- Files: `assets/legal/privacy_ja.md`, `assets/legal/privacy_en.md`, `assets/legal/privacy_zh.md`, `assets/legal/terms_ja.md`, `assets/legal/terms_en.md`, `assets/legal/terms_zh.md`, `assets/legal/tokusho_ja.md`, `assets/legal/tokusho_en.md`, `assets/legal/tokusho_zh.md`
- Impact: Store review and Japanese compliance risk; users receive non-actionable support information.
- Fix approach: Complete legal review, replace operator/contact values and effective dates, and add a build-time placeholder scan.

**Privacy policy wording must match relay behavior (HIGH):**
- Issue: Policies describe direct device-to-device sync and no server retention, while the relay temporarily stores opaque encrypted messages until ACK/expiry.
- Files: `assets/legal/privacy_ja.md`, `assets/legal/privacy_en.md`, `assets/legal/privacy_zh.md`, `lib/infrastructure/sync/relay_api_client.dart`, `docs/arch/server/SERVER-001_SyncRelay.md`
- Impact: The zero-knowledge property remains, but absolute retention claims are inaccurate and may conflict with privacy disclosures.
- Fix approach: Describe encrypted relay storage, deletion trigger/retention, and metadata handling consistently in all locales.

**Dependency/toolchain migration debt (MEDIUM):**
- Issue: `sqlcipher_flutter_libs ^0.6.x` remains tied to sqlite3 2.x; Flutter warns about future Swift Package Manager and built-in Kotlin migrations. `file_picker`, `package_info_plus`, and `share_plus` are constrained as a trio.
- Files: `pubspec.yaml`, `ios/Podfile`, `android/settings.gradle.kts`
- Impact: Future Flutter upgrades can turn warnings into build failures; isolated dependency bumps are not resolvable.
- Fix approach: Plan a coordinated dependency/toolchain upgrade with SQLCipher device verification and both-platform release builds.

## Known Bugs

**Golden and architecture gates are not green (MEDIUM):**
- Issue: Current working-tree test runs have known light-theme golden diffs and a mockup quantity-decrease contract failure; these are easy to mistake for intentional P1/P2 design changes.
- Files: `test/golden/`, `test/widget/`, `docs/mockup/v16/index.html`, `test/architecture/`
- Impact: CI remains red and visual regressions can be masked by bulk baseline updates.
- Fix approach: Review each changed baseline, regenerate only approved goldens on macOS, and restore/synchronize the mockup contract.

## Security Considerations

**SQLCipher linkage is build-sensitive (HIGH):**
- Risk: A Podfile change can let system sqlite3 win symbol resolution and prevent encrypted database startup.
- Files: `ios/Podfile`, `lib/infrastructure/crypto/database/encrypted_database.dart`
- Current mitigation: Podfile strips `-l"sqlite3"`; runtime checks `PRAGMA cipher_version` and fails closed.
- Recommendations: Preserve the post-install strip and run an iOS device smoke test asserting SQLCipher activation after native dependency changes.

**Plaintext preferences must stay non-sensitive (MEDIUM):**
- Risk: SharedPreferences is not SQLCipher-protected and is suitable only for non-secret flags.
- Files: `lib/features/settings/`, `lib/core/`
- Current mitigation: Keys and backup secrets use established secure-storage/crypto services.
- Recommendations: Keep PINs, tokens, recovery material, and financial data out of SharedPreferences; retain the logging privacy architecture tests.

## Performance Bottlenecks

**Migration and sync orchestration complexity (MEDIUM):**
- Problem: Schema migration and family-sync execution concentrate many branches, retries, and entity cases.
- Files: `lib/data/app_database.dart`, `lib/application/family_sync/check_group_validity_use_case.dart`, `lib/application/family_sync/pull_sync_use_case.dart`, `lib/application/family_sync/apply_sync_operations_use_case.dart`
- Cause: Large methods and nested state/error handling increase review and regression cost.
- Improvement path: Extract versioned migration steps and per-entity sync handlers behind characterization tests.

## Fragile Areas

**Voice parsing across platform STT/ITN (HIGH):**
- Files: `lib/application/voice/voice_text_parser.dart`, `lib/application/voice/voice_chunk_merger.dart`, `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart`, `lib/features/accounting/presentation/screens/voice_input_screen.dart`
- Why fragile: iOS Japanese/Chinese inverse text normalization can corrupt numeric speech before Dart receives it; several compensating parser paths must remain coordinated.
- Safe modification: Run the full ja/zh/en unit matrix plus real-device voice UAT after any parser or PTT change.
- Test coverage: Host tests cannot reproduce recognizer-side ITN corruption.

**Oversized UI/data modules (MEDIUM):**
- Files: `lib/features/accounting/presentation/widgets/transaction_details_form.dart`, `lib/features/home/presentation/widgets/home_hero_card.dart`, `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart`, `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart`
- Why fragile: Large build methods and mixed responsibilities make localized UI changes affect unrelated states and goldens.
- Safe modification: Extract sections/sub-widgets incrementally with targeted widget and golden tests.

## Scaling Limits

**Device-level E2E coverage is narrow (MEDIUM):**
- Current capacity: `integration_test/merchant_migration_ladder_test.dart` is the only device integration test.
- Limit: Onboarding, cold-start app lock, backup restore, relay ACK, push, and real SQLCipher initialization are not exercised end-to-end in CI.
- Scaling path: Add a minimal iOS and Android smoke journey covering install, create transaction, lock/cold start, backup restore, and sync.

## Dependencies at Risk

**Coordinated package upgrades required (MEDIUM):**
- Risk: Direct upgrades of `file_picker`, `package_info_plus`, or `share_plus` currently conflict through transitive `win32` constraints; `intl` is pinned by Flutter localization.
- Impact: Ad hoc upgrades can break dependency resolution or native builds.
- Migration plan: Upgrade the constrained trio together, retain SQLCipher 0.6.x until a tested sqlite3 3.x migration exists, and verify iOS/Android builds.

## Missing Critical Features

**Production release-owner configuration:**
- Problem: Real legal/support destinations, production signing, and final store metadata are not represented as enforced release configuration.
- Blocks: Public store submission despite a functioning application foundation.

## Test Coverage Gaps

**Provider and device-path coverage (MEDIUM):**
- What's not tested: Error/fallback branches in analytics/settings providers and full device lifecycle flows.
- Files: `lib/features/analytics/presentation/providers/state_analytics.dart`, `lib/features/settings/presentation/providers/repository_providers.dart`, `integration_test/`
- Risk: Global coverage can remain high while these operational paths regress unnoticed.
- Priority: Medium; add provider characterization tests and the cross-platform smoke journey.

---

*Concerns audit: 2026-08-05*
