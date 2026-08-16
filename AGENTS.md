# AGENTS.md — Happy Pocket (ハピポケ家族家計簿)

> Local-first, privacy-first family accounting for iOS and Android.
> Flutter · Riverpod · Drift · SQLCipher · ja/zh/en

This file is the operational guide for agents working in this repository. It is
intentionally based on the current source, configuration, contract tests, and
accepted ADRs rather than historical roadmap language.

---

## Project Snapshot

- The public MVP is released. The current package version is `1.0.0+3`.
- Supported platform floors are **iOS 15+** and **Android API 24+**.
- The app is local-first. Its main product surfaces are Home, transaction List,
  Analytics, and Shopping, with accounting entry, onboarding, settings,
  app-lock, backup/restore, voice entry, multi-currency, and family sync flows.
- The first public release deliberately has no Firebase Messaging, APNs/local
  notification runtime, notification permission, or notification navigation
  stack. Sponsorship UI is disabled by `ReleaseFeatures.sponsorship`.
- There is no active milestone directory. `.planning/` was retired and must not
  be recreated or referenced by active scripts or documentation.
- Audit state lives in `tool/audit/`. Durable release and compatibility evidence
  lives in `docs/testing/`; implementation plans live in `docs/plans/`.
- The accepted post-1.0 product direction is recorded in
  `docs/plans/2026-08-16-post-v1-product-roadmap.md`. Its next product release is
  the adaptive iPad experience; the roadmap remains directional until a scoped
  implementation plan is approved.

Known verification state as of 2026-08-16:

- `tool/audit/issues.json` has no open findings; eight reviewed low-severity
  duplication findings remain accepted with rationales.
- The dependency compatibility contract is not green: the tracked digests for
  `pubspec.yaml` and `ios/Runner.xcodeproj/project.pbxproj` in
  `docs/testing/STABLE_BASELINE.json` do not match the committed inputs. Treat
  this as baseline drift requiring a reviewed compatibility refresh; do not
  silently rewrite hashes or claim the release gate passes. Remove this note
  when the contract is repaired and verified.

When sources disagree, use this precedence:

1. Executable source, platform configuration, lockfiles, and contract tests.
2. Accepted ADRs under `docs/arch/03-adr/` and current requirements under
   `docs/requirement/`.
3. Current testing/release records under `docs/testing/`.
4. README files, worklogs, old plans, and historical phase references.

Do not implement a historical README/PRD claim without confirming that the
current code and accepted ADRs still support it.

---

## Branch and Change Safety

- Default development is on `main` in the current worktree. Use `codex` or
  `codex-dev` only when the user explicitly asks.
- Before editing, run `git status -sb` and confirm the branch and dirty files.
- Preserve all unrelated user changes. Never reset, revert, overwrite, or fold
  them into the task commit.
- Keep commits scoped and reviewable. Use
  `<type>(<scope>): <description>` with `feat`, `fix`, `refactor`, `docs`,
  `test`, or `chore`.
- Do not push `main` or tags unless the user asks.

---

## Repository Map

```text
lib/
├── application/       # cross-feature use cases, orchestration, composition roots
├── core/              # initialization, config, constants, licenses, state, theme
├── data/              # Drift database, tables, DAOs, repository implementations
├── features/          # feature domain contracts and presentation code
├── infrastructure/    # crypto, storage, sync, speech, ML, platform/network adapters
├── l10n/              # source ARB files: en, ja, zh
├── generated/         # tracked generated localizations
└── shared/            # shared widgets, constants, and utilities

test/                  # unit, widget, infrastructure, architecture, golden tests
integration_test/      # device and SQLCipher lifecycle journeys
scripts/               # validation, release, audit, and maintenance tooling
tool/audit/            # audit manifests, findings, coverage scope, scanner artifacts
docs/arch/             # architecture guides, module specs, ADRs, UI specifications
docs/testing/          # compatibility baselines, release decisions, device evidence
publish/               # store metadata and release assets
third_party/           # reviewed local dependency forks/assets
```

---

## Architecture and Dependency Direction

The repository uses Clean Architecture with centralized data and application
layers. Follow the patterns already present; do not infer the older
per-feature `data/application` layout from historical documents.

- `features/*/domain/` contains pure business models and repository contracts.
- `data/` owns Drift tables/DAOs and concrete repository implementations.
- `infrastructure/` owns technical adapters and may depend on domain contracts.
- `application/` owns use cases and orchestration. Only composition-root files
  named `*_providers.dart` may construct or import concrete data-layer types.
- `features/*/presentation/` owns UI, navigation, and presentation providers.
- `core/` owns app bootstrap and global policy; `shared/` is for genuinely
  cross-feature, non-owning code.

Enforced dependency rules:

- Domain must not import Flutter, data, infrastructure, application, or
  presentation.
- Infrastructure must not import application or feature presentation code.
  Importing feature domain contracts is allowed.
- Application code must not import presentation. Non-composition-root
  application files must not import data.
- Presentation UI must not import infrastructure, Drift DAOs, or Drift tables.
- Keep shared constants free of feature ownership; do not use `shared/` to hide
  a dependency inversion.

`analysis_options.yaml`, `import_lint`, and the architecture tests enforce these
directions for both package and relative imports. Do not weaken a rule or add an
allowlist entry to make a feature compile without an explicit architectural
decision.

Capability placement:

1. Business model or repository contract → `features/<feature>/domain/`
2. Database/table/DAO/repository implementation → `data/`
3. Platform, crypto, storage, network, speech, or sync adapter → `infrastructure/`
4. Cross-feature use case or orchestration → `application/`
5. Screen, widget, navigation, or presentation state →
   `features/<feature>/presentation/`

---

## Bootstrap and Navigation

- `AppInitializer.initialize()` must finish before `runApp()`.
- Preserve startup ordering: native SQLCipher readiness → secure key readiness →
  encrypted database open → final provider container → pending privacy-wipe
  recovery → app UI.
- Never mint a new master key when an existing encrypted database is present.
- The initialized container is attached with `UncontrolledProviderScope`.
- The app currently uses `MaterialApp`, `Navigator`, `MaterialPageRoute`, and
  nested navigators. It does **not** use GoRouter.
- App-lock is a root security barrier above the live navigation stack. Preserve
  its back-navigation interception and privacy-mask ordering.
- The main shell uses a lazy four-tab stack. Keep tab state/provider invalidation
  behavior intact when changing navigation or transaction flows.

---

## Product Contracts

### Local-first and privacy

- User financial data must remain usable without a cloud account or continuous
  network connection.
- Family relay/sync work must preserve zero-knowledge and offline-queue
  assumptions. Do not send plaintext financial fields, family keys, recovery
  material, or sync payload contents to logs or analytics.
- Notification infrastructure is a future, separately approved feature. Do not
  add a notification package, permission, token registration, native delegate,
  or notification route as incidental sync work.

### Dual ledger and Joy

- The user-facing ledger concepts are needs/survival and Joy/self-directed
  spending. Reuse the established enum/model and localized wording.
- `Σ joy_contribution` is the sole Joy metric. Do not reintroduce Joy-per-yen,
  density, ROI, or `homeHappinessROI`-style surfaces.
- Home Hero is month-anchored. Active target priority is configured monthly
  target → recommended target → fallback baseline.
- Reaching or crossing 100% changes the ring color smoothly and produces no
  discrete event: no toast, notification, haptic, badge, achievement, streak,
  pulse, glow, confetti, celebration copy, or sound.
- A legacy Joy celebration overlay remains disabled. Do not enable or reuse it
  without an accepted ADR change.
- Joy-side cross-period comparisons, trends, rankings, public sharing, streaks,
  badges, achievements, and daily satisfaction targets are prohibited.
- Neutral cross-period comparison is allowed only for expense-side analytics
  such as total or daily spend.

### Product language

- In-product lexical hierarchy: `悦己` / `ときめき` / `Joy`.
- Documentation and research may use `幸福` / `happiness` as framing.
- Chinese family-mode copy must use the accepted ADR-015 wording; do not invent
  `家族悦己` copy.

---

## Database and Drift

- The current database schema version is **36**.
- Schema changes require a new migration rung plus fresh-install, ladder, and
  affected DAO/repository tests. Update Dart defaults, SQL defaults, constraints,
  sync serialization, backup compatibility, and wipe classification together.
- Use `TableIndex`, symbol columns such as `{#bookId, #timestamp}`, and names of
  the form `idx_<table>_<columns>`.
- This repository's `customIndices` getters are declarations only; Drift does
  not create them. Keep every declaration synchronized with explicit
  `CREATE INDEX IF NOT EXISTS` statements for both fresh installs and the
  correct upgrade rung.
- `membership_rotation_intents` is deliberately created with explicit SQL and
  is not in the `@DriftDatabase` table list. Treat it as part of the schema,
  migration, backup, and privacy-wipe contracts.
- `wipeLocalUserData()` fails closed if any table is unclassified. Classify a
  new table as local user data or preserved reference data before it ships.
- Never hand-edit `*.g.dart`, `*.freezed.dart`, mocks, or files in
  `lib/generated/`. Change inputs and regenerate tracked outputs.

Run code generation after changing Riverpod annotations, Freezed/JSON models,
Drift declarations, `part` inputs, or ARB files:

```bash
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
```

For a release-relevant generation change, use
`bash scripts/verify_codegen_reproducibility.sh`; it verifies two clean passes.

---

## Security and Cryptography

Use only the established services under `lib/infrastructure/crypto/`,
`lib/infrastructure/security/`, and `lib/infrastructure/storage/`.

- Database: SQLCipher Native Assets, AES-256-CBC, PBKDF2-HMAC-SHA512 with
  256,000 iterations, and a database key derived from the installation master
  key with HKDF.
- Database startup must verify SQLCipher `4.17.x`, `cipher_status == 1`, a
  readable `sqlite_master`, and a non-plaintext file header.
- Sensitive fields: ChaCha20-Poly1305 AEAD.
- `.hpb` backup v2: Argon2id password KDF plus AES-256-GCM, versioned header,
  bounded hostile KDF parameters, and authenticated wrong-password/tamper
  failure.
- App PIN: four digits, stored only as an Argon2id PHC hash. Never persist or log
  the plaintext PIN. Biometric unlock must not silently accept device-passcode
  fallback in place of the app PIN.
- Device identity and relay authentication use Ed25519. Family E2EE uses the
  established X25519/XSalsa20-Poly1305 envelope flow and key epochs.

Mandatory safety rules:

- Never access `flutter_secure_storage` directly outside the existing secure
  storage/key-manager boundary.
- Never log amounts, notes, merchant names, keys, tokens, recovery material,
  database paths that expose identity, or decrypted sync payload details.
- Keep `hooks.user_defines.sqlite3.source: sqlcipher` in `pubspec.yaml`.
- Never add `sqlite3_flutter_libs`, `sqlcipher_flutter_libs`, a separate
  SQLCipher CocoaPod, or the obsolete iOS `-l"sqlite3"` workaround.
- Missing keys, cipher mismatch, wipe mismatch, and authentication failures must
  fail closed; do not add plaintext or data-loss fallbacks.

---

## Riverpod and Coding Conventions

- Runtime baseline is Riverpod `3.3.2`, annotations `4.0.3`, generator `4.0.4`,
  and `riverpod_lint 3.1.4`.
- Main APIs come from `package:flutter_riverpod/flutter_riverpod.dart`; legacy
  notifier APIs come from `/legacy.dart`; `Override`, `ProviderListenable`,
  `ProviderException`, and related types come from `/misc.dart`.
- Generated provider names strip `Notifier`: `LocaleNotifier` generates
  `localeProvider`.
- `AsyncValue.valueOrNull` is unavailable; use nullable `.value`.
- Use immutable state and Freezed where the surrounding module does. Do not
  mutate state objects in place.
- Use `ref.listen` for navigation, dialogs, snackbars, lifecycle actions, and
  other side effects.
- Keep one repository-provider composition root per established module. Reuse
  providers; do not create parallel providers for the same repository.
- Widget override fallback order is explicit parameter → current selection →
  user default → `null`.
- In tests, prefer `ProviderContainer.test()`. For auto-dispose async providers,
  use `waitForFirstValue` from `test/helpers/test_provider_scope.dart` so a live
  subscription is retained.
- Follow repository lint style: relative internal imports, single quotes, no
  `print`, and no new blanket `ignore` suppressions.
- Format only the touched Dart scope. `dart format .` can create unrelated
  legacy churn and must not be included in a scoped change.

---

## Localization, UI, and Accessibility

- Supported locales are `ja`, `zh`, and `en`.
- All user-facing text must come from `S.of(context)` or generated localization
  accessors. Update all three ARB files together and run `flutter gen-l10n`.
- Keep ARB keys stable unless the task explicitly includes a coordinated rename.
- Use project currency/date formatters and pass locale plus currency code. JPY
  has zero fraction digits; USD/CNY/EUR/GBP have two.
- Reuse `AppTheme`, palette, spacing, typography, icon, sheet, feedback, and
  accessibility patterns. Do not introduce arbitrary color literals or duplicate
  design tokens.
- Add semantic labels and adequate tap targets for interactive controls. Run
  targeted widget/golden tests and inspect visual diffs for UI changes.
- Never solve layout issues by adding unlocalized text, disabling accessibility,
  or globally suppressing overflow.

---

## Dependencies and Platform Baseline

- Production SDK baseline: Flutter `3.44.8`, Dart `3.12.2`.
- Canonical dependency/toolchain state is
  `docs/testing/STABLE_BASELINE.json`; rationale and upgrade exit conditions are
  in `docs/testing/DEPENDENCY_COMPATIBILITY.md`.
- Do not use `dependency_overrides` or `pubspec_overrides.yaml` to force an
  upgrade through the production graph.
- Upgrade coupled lanes as one reviewed transaction: analyzer/codegen/lints;
  Drift/sqlite3/SQLCipher; file/share/package-info/win32; speech/native adapters;
  and the Android Gradle/Kotlin/Flutter toolchain.
- Notable current pins/holds include `file_picker ^11.0.3`,
  `package_info_plus ^9.0.1`, `share_plus ^12.0.2`, and
  `speech_to_text 7.3.0`.
- Android baseline: AGP `8.11.1`, Gradle `8.14`, Kotlin `2.2.20`, JDK 17,
  compile/target API 36, minimum API 24.
- iOS deployment target is 15.0 in Runner, CocoaPods, SwiftPM, and generated
  plugin metadata. SQLCipher is embedded by sqlite3 Native Assets, not CocoaPods.
- Release signing must fail closed. Never substitute the Android debug keystore
  for a release build.

When native artifacts look stale after switching simulator/device or signing
modes, clean and regenerate instead of committing generated native debris.

---

## Testing and Quality Gates

Use TDD for behavior changes:

1. Expose the failure with a focused test.
2. Implement the smallest correct behavior.
3. Refactor with the focused test still green.

Minimum validation by change type:

- Docs-only: relevant contract test if a test reads the document, plus
  `git diff --check`.
- Dart logic: targeted tests, `flutter analyze`, then broader affected suites.
- Schema/crypto/backup/sync: targeted unit and migration/lifecycle tests plus the
  relevant integration journey.
- UI: targeted widget tests; golden tests and visual inspection when appearance
  changes.
- Dependency/platform/release: the repository-owned compatibility and native
  safety lanes; do not infer runtime SQLCipher success from compile-only output.

Common commands:

```bash
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
dart run import_lint
flutter test
flutter test --coverage
flutter test integration_test/ -d <device_id>
git diff --check
```

Release authority:

```bash
dart run scripts/release_gate.dart --scope=host
dart run scripts/release_gate.dart --scope=full
```

- `--scope=host` is the PR/host gate. `--scope=full` is the Apple-Silicon
  platform/device release gate and must run on the authorized environment.
- The release gate owns codegen reproducibility, analysis, architecture
  contracts, full tests, filtered LCOV, and the per-file **70%** coverage gate.
- Required and explicitly deferred coverage files are maintained in
  `tool/audit/coverage-gate-required-files.txt` and
  `tool/audit/coverage-gate-deferred.txt`. Every deferral needs a rationale.
- If the default-concurrency Flutter suite hits subprocess timeouts, run the
  named tests in isolation, then confirm the full suite with
  `--concurrency=1`. Do not relabel a functional assertion failure as a timeout.
- Golden pixel comparison is authoritative on macOS; other hosts still verify
  that baselines exist and widgets render.

---

## Documentation, Audit, and Release Assets

- Do not recreate `.planning/`. New implementation plans belong in `docs/plans/`.
- Architecture documents belong under `docs/arch/`; accepted ADRs are
  append-only. Add a dated update or a superseding ADR instead of rewriting
  accepted history.
- Before adding an architecture document, use the next sequence number and
  update the relevant index, especially
  `docs/arch/01-core-architecture/ARCH-000_INDEX.md` or the ADR index.
- Audit manifests and generated scanner output belong under `tool/audit/`.
  Keep accepted findings and rationales intact unless the underlying issue is
  actually resolved.
- Public legal routes are canonicalized by `LegalUrls` at
  `https://happypocket.app/privacy`, `/terms`, `/tokusho`, and `/support`.
- Store metadata and screenshots live under `publish/`. Keep source, store copy,
  offline legal assets, and the three localized variants consistent.
- Historical worklogs and phase labels are provenance only. Do not use them as
  current status or create new phase-number coupling in production code.

---

## Pre-Commit Checklist

- [ ] `git status -sb` reviewed; branch and unrelated changes preserved.
- [ ] Change matches current source/ADR contracts, not a stale historical doc.
- [ ] Generated outputs regenerated when their inputs changed.
- [ ] All three locales updated for user-facing copy.
- [ ] Schema/security/privacy contracts covered for sensitive changes.
- [ ] Targeted tests pass; broader gates run in proportion to risk.
- [ ] `flutter analyze` reports zero issues for code changes.
- [ ] `git diff --check` passes.
- [ ] No secrets, sensitive logs, plaintext storage fallback, debug signing, or
  unrelated formatter churn entered the diff.
