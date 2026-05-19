# AGENTS.md — Home Pocket (まもる家計簿)

> Local-first, privacy-focused family accounting app with a dual-ledger system.
> Flutter · iOS 14+ / Android 7+ · SQLCipher · Riverpod 3 · Drift

---

## Current Project State

- **v1.0 shipped:** Codebase Cleanup Initiative (2026-04-29)
- **v1.1 shipped:** Happiness Metric & Display (2026-05-05)
- **Current milestone:** v1.2 Happiness Metric Refresh
- **Completed in v1.2:** Phase 13 ADR-016 Backend Foundation; Phase 14 ADR-016 Frontend + ARB Reconciliation
- **Current focus:** Phase 15 — Custom Time Windows (`HAPPY-V2-02`), ready to discuss before planning
- **Current source of truth:** `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/REQUIREMENTS.md`

Known close debt:
- Phase 11 has one human/device UAT item accepted as deferred debt in `.planning/STATE.md`.
- Codebase map in `.planning/codebase/` predates v1.0 cleanup and v1.1 feature work; refresh before major planning.

---

## Branch & Worktree Policy

- Default development happens on the **`main` branch in a worktree**.
- Use `codex` / `codex-dev` branches only when the user explicitly asks.
- Before editing, run `git status -sb` and confirm the current branch.
- Preserve user changes. Never revert, reset, or overwrite unrelated dirty files.
- If another worktree already has `main` checked out, it is acceptable to use the current worktree on `main` when the user requested main-worktree development.

---

## Architecture

Clean Architecture with enforced import boundaries:

- `lib/infrastructure/` — platform/technical services: crypto, secure storage, sync, speech, ML, i18n formatters, platform APIs
- `lib/data/` — Drift database, tables, DAOs, repository implementations
- `lib/features/{feature}/domain/` — domain models and repository interfaces
- `lib/features/{feature}/presentation/` — screens, widgets, presentation providers/navigation
- `lib/application/` — cross-feature application use cases and orchestration services
- `lib/core/` — initialization, router/config/theme/constants
- `lib/shared/` — shared widgets, utils, constants, result helpers

Dependency rules:
- Infrastructure must not depend on `features/`, `application/`, or `data/`.
- Data may depend on domain contracts and infrastructure, but not presentation or application use cases.
- Domain models stay independent of Flutter, Drift, Riverpod, and platform SDKs.
- Features must not define Drift tables, DAOs, or infrastructure adapters.
- Prefer existing layer patterns and provider locations over new abstractions.

Capability placement:
1. Platform/technical capability → `lib/infrastructure/`
2. Cross-feature use case/orchestration → `lib/application/`
3. Database/table/DAO/repository implementation → `lib/data/`
4. Business model/repository contract → `lib/features/{feature}/domain/`
5. UI/presentation state → `lib/features/{feature}/presentation/`

---

## Build & Dev Commands

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
dart format .
flutter test
flutter test --coverage
flutter test integration_test/
flutter devices
flutter run -d <device_id>
```

Code generation triggers:
- Run build_runner after changing `@riverpod`, `@freezed`, Drift tables/DAOs, or files with `part '*.g.dart'`.
- Run `flutter gen-l10n` after changing any ARB file.
- After merge/rebase/branch switch, regenerate if generated inputs changed.
- Do not hand-edit generated files; edit sources and regenerate tracked outputs.

---

## State Management & Coding Patterns

- Riverpod 3.1+ with `@riverpod` code generation (`riverpod_generator` 4.x).
- Freezed for immutable data models; avoid mutation-style updates.
- Drift + SQLCipher for local encrypted persistence.
- GoRouter for declarative routing.
- One `repository_providers.dart` per feature/module where the repo pattern already exists.
- Do not duplicate repository providers.
- UI providers may reference feature/application use case providers; lower layers must not reference UI providers.
- Widget parameters should use nullable explicit overrides with provider fallback.
- Fallback priority: explicit param > current selection > user default > null.

Riverpod 3 conventions:
- Main entry point: `package:flutter_riverpod/flutter_riverpod.dart`.
- Legacy `StateNotifier`, `StateProvider`, `StateController`, and `ChangeNotifierProvider` live in `package:flutter_riverpod/legacy.dart`.
- Misc symbols such as `Override`, `ProviderListenable`, `ProviderException`, `Family`, `Refreshable`, and `ProviderBase` live in `package:flutter_riverpod/misc.dart`.
- Generated provider names strip `Notifier`: `class LocaleNotifier` generates `localeProvider`, not `localeNotifierProvider`.
- `AsyncValue.valueOrNull` is gone; use nullable `.value`.
- Provider errors are wrapped in `ProviderException`; inspect `.exception` in tests.
- Use `ref.listen` for navigation, snackbars, dialogs, and other side effects.
- In tests, prefer `ProviderContainer.test()` and `waitForFirstValue<T>(container, provider)` from `test/helpers/test_provider_scope.dart` for auto-dispose async providers.

---

## Security & Privacy

The app uses 4-layer protection:

1. **Database:** SQLCipher AES-256-CBC with PBKDF2
2. **Field:** ChaCha20-Poly1305 AEAD
3. **File:** AES-256-GCM for photos/files
4. **Transport:** TLS + E2EE for sync

Mandatory rules:
- Use `lib/infrastructure/crypto/` and existing security services for crypto operations.
- Never access `flutter_secure_storage` directly for keys outside the established secure-storage/key-manager layer.
- Sensitive fields such as amounts, notes, merchant names, keys, tokens, recovery material, and sync payload details must not be logged.
- Use `sqlcipher_flutter_libs`; never add or reintroduce `sqlite3_flutter_libs`.
- Preserve local-first and zero-knowledge assumptions in new features.

Initialization:
- `AppInitializer.initialize()` must complete before `runApp()`.
- Initialization order must preserve key/security readiness before encrypted database access.
- Use `UncontrolledProviderScope` for the initialized provider container.

---

## i18n

Supported locales: `ja`, `zh`, `en`.

- All user-facing text must come from `S.of(context)` or generated localizations.
- Update all 3 ARB files together.
- Run `flutter gen-l10n` after ARB changes.
- Keep ARB keys stable unless a task explicitly scopes a key rename.
- Use project formatters for dates/currency; pass locale and currency code.
- Currency decimals: JPY 0; USD/CNY/EUR/GBP 2.
- Product lexical hierarchy from ADR-015:
  - In-product: 悦己 / ときめき / Joy
  - Documentation/research framing: 幸福 / happiness
  - CN family mode avoids 「家族悦己」; use the accepted family wording from ADR-015.
- ADR-016 retired density/Joy-per-yen as a user-facing Joy metric. Do not reintroduce `Joy/¥`, density, ROI, `homeHappinessROI`, or `homeJoyPerYen*` UI surfaces.

---

## ADR-016 Joy Metric Rules

- `Σ joy_contribution` is the single Joy expression after v1.2 Phase 14.
- HomeHero is month-anchored: ring progress uses the current calendar month's cumulative Joy contribution toward the active monthly target.
- Active monthly target priority: configured `monthly_joy_target` > recommended target > fallback baseline.
- Ring color transitions smoothly from `#47B88A` to gold and clamps at gold at/above 100%.
- Crossing 100% must produce **no discrete event**: no toast, notification, haptic, celebration copy, badge, pulse, glow, confetti, streak, or achievement.
- Analytics Variant epsilon uses cumulative Joy Index first; density/Joy-per-yen surfaces remain retired.

---

## Drift Database Rules

- Use `TableIndex`, not `Index`.
- Use symbol syntax: `columns: {#columnName}`.
- Do not add `@override` to Drift table index getters unless Drift requires it.
- Index naming: `idx_{table}_{columns}`.
- Schema changes require migration tests and all Dart-side defaults to be updated in lockstep.
- Current schema is post-v1.1 v16 with unipolar positive satisfaction semantics.

---

## Testing & Quality Gates

Use TDD for behavior changes:
1. RED: write or expose the failing test.
2. GREEN: minimal implementation.
3. IMPROVE: refactor with tests green.

Test locations:
- `test/unit/`
- `test/widget/`
- `test/infrastructure/`
- `test/architecture/`
- `test/golden/`
- `integration_test/`

Quality gates:
- `flutter analyze` must report 0 issues.
- `flutter test` should pass before shipping behavior changes.
- Coverage gate is currently **70%** global/per configured cleanup-touched files, with deferred exceptions tracked from v1.0.
- ARB parity and hardcoded-CJK architecture tests protect i18n.
- For frontend/UI changes, run targeted widget/golden tests and inspect visual diffs when goldens change.
- If default-concurrency `flutter test` hits script subprocess timeouts, rerun affected files in isolation and use `flutter test --concurrency=1` for a full-suite confirmation before declaring the suite green.

Note: `dart format .` may touch unrelated legacy files depending on formatter version. If that happens, do not mix unrelated formatting churn into scoped commits.

---

## iOS Build Notes

- Keep `sqlcipher_flutter_libs` at the current `^0.6.x` line; `0.7.0+eol` is intentionally a no-op package and this project has not migrated to `sqlite3` 3.x.
- Never add `sqlite3_flutter_libs`.
- Preserve the Podfile ML Kit simulator `EXCLUDED_ARCHS` fix if present.
- Preserve the `ios/Podfile` `post_install` strip that removes `-l"sqlite3"` from Pod xcconfig files. FirebaseMessaging and other pods can otherwise pull in system `libsqlite3.tbd`, causing `PRAGMA cipher_version` to return empty and SQLCipher initialization to fail.
- Switching between simulator/device or `--no-codesign` and signed builds can leave native-asset framework artifacts behind; run `flutter clean` before iOS device verification when signatures look stale.

Clean rebuild:

```bash
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
flutter pub get
cd ios
pod install
```

Dependency pins to leave alone unless upgraded together with iOS build verification:
- `file_picker: ^11.0.2`
- `package_info_plus: ^9.0.1`
- `share_plus: ^12.0.2`

---

## GSD Workflow

- Planning state lives in `.planning/`.
- Completed milestones are archived under `.planning/milestones/`.
- v1.2 active requirements live in `.planning/REQUIREMENTS.md`.
- Use `$gsd-progress` to inspect current status.
- Current recommended next command: `$gsd-discuss-phase 15`.
- Use `$gsd-cleanup` later if phase directories should be archived out of `.planning/phases/`.

When editing planning files:
- Keep `PROJECT.md`, `ROADMAP.md`, `STATE.md`, `REQUIREMENTS.md`, and `MILESTONES.md` consistent.
- Archive before deleting active milestone files.
- Record accepted gaps/deferred work explicitly in `STATE.md`.

---

## Git Workflow

Commit format:

```text
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.

Rules:
- Keep commits scoped and reviewable.
- Do not commit generated or formatter-only churn unless it is required by the task.
- Do not commit directly to a non-main branch unless the user requested that branch.
- Push `main` and tags only when the user asks.

---

## Pre-Commit Checklist

- [ ] `git status -sb` reviewed
- [ ] Relevant generated files regenerated
- [ ] `flutter analyze` for code changes
- [ ] Relevant targeted tests run
- [ ] Full `flutter test` or justified equivalent for broad behavior changes
- [ ] ARB changes update ja/zh/en and run `flutter gen-l10n`
- [ ] No unrelated user changes reverted
- [ ] No `// ignore:` suppressions added without a specific, documented reason

---

## Architecture Docs

Architecture docs live under `docs/arch/`:

- `01-core-architecture`
- `02-module-specs`
- `03-adr`
- `04-basic`
- `05-UI`

Before adding a new architecture doc:
- Check the highest existing number in the target folder.
- Use the next sequential number.
- Update the relevant index, especially `docs/arch/01-core-architecture/ARCH-000_INDEX.md` or ADR index files.
- Accepted ADRs are append-only; add dated update sections instead of rewriting history.
