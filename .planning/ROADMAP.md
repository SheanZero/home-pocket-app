# Roadmap: Happy Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 迭代帐本输入** — Phases 18-23 (shipped 2026-05-26) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 列表功能** — Phases 24-30 (shipped 2026-05-31) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 文案与配色统一** — Phases 31-35 (shipped 2026-06-02) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 购物清单** — Phases 36-39 (shipped 2026-06-12) — [archive](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 多币种支持** — Phases 40-42 (shipped 2026-06-14) — [archive](milestones/v1.7-ROADMAP.md)
- ✅ **v1.8 统计页面重设计（实用化 × 悦己情感化）** — Phases 43-48 (shipped 2026-06-22) — [archive](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 语音类目与商家识别系统重构** — Phases 49-52 (shipped 2026-06-25) — [archive](milestones/v1.9-ROADMAP.md)
- ✅ **v2.0 完成第一版上线前最后的功能开发** — Phases 53-56 (shipped and archived 2026-08-05) — [roadmap](milestones/v2.0-ROADMAP.md) · [requirements](milestones/v2.0-REQUIREMENTS.md) · [audit](milestones/v2.0-MILESTONE-AUDIT.md)
- 🚧 **v2.1 依赖与原生工具链现代化** — Phases 57-63 (roadmapped 2026-08-05) — production-stable compatibility window, automated release gates, and isolated wired-iPhone acceptance

<details>
<summary>✅ v2.0 archived phase index (Phases 53-56)</summary>

- [x] **Phase 53: HTML Design Gate** — 4/4 plans complete; three design directions approved; zero-production-code gate passed.
- [x] **Phase 54: Onboarding Flow** — 7/7 plans complete; canonical close verification reconciled to the live V16 intro → settings flow with inline optional security.
- [x] **Phase 55: App Lock (Face ID + PIN)** — 12/12 plans complete; 6/6 device UAT complete; G1-G4 fixed and verified.
- [x] **Phase 56: Legal, Sponsor, and Release Settings** — 7/7 plans complete; offline trilingual legal surfaces and release documentation verified.

Full plan and verification history: `.planning/milestones/v2.0-phases/`.

</details>

## Current Planning State

v2.1 is active and roadmapped. It upgrades the SDK, generator, native-toolchain, and dependency lanes only as a mutually compatible production-stable window. No phase may weaken SQLCipher, local-first privacy, architecture enforcement, minimum platform support, or existing user behavior merely to claim a newer version.

## Backlog

- App-lock progressive PIN retry delay (`LOCK-V2-04`) remains deliberately descoped from v2.0.
- Preserve historical deferred items in `.planning/STATE.md`; promote only work that belongs to the next milestone goal.

## v2.1 依赖与原生工具链现代化

**Milestone Goal:** Upgrade to an officially verified production-stable compatibility window while proving that encrypted local data, migration, backup recovery, and core accounting behavior remain safe through automated gates and one isolated wired-iPhone acceptance.

## Phases

**Phase Numbering:** Continues from v2.0 Phase 56. Integer phases are planned milestone work; decimal phases, if urgently inserted, execute between their surrounding integers.

- [x] **Phase 57: Stable Baseline & Compatibility Contract** - Establish the official-source stable decision and reproducible, machine-checked dependency policy. (completed 2026-08-06)
- [x] **Phase 58: Flutter, Analyzer & Code Generation Lane** - Select a coherent SDK, analyzer, lint, and generator graph without weakening architecture enforcement. (completed 2026-08-08)
- [ ] **Phase 59: Controlled Platform Plugin Cohorts** - Upgrade or evidence-hold native plugin groups through narrow behavioral compatibility lanes.
- [ ] **Phase 60: SQLCipher & iOS Native Safety Lane** - Preserve and prove the encrypted iOS database, migration, and backup path from clean native artifacts.
- [ ] **Phase 61: Android Toolchain & Emulator Lane** - Complete an all-or-hold AGP/Gradle/Kotlin migration with signed release and emulator evidence.
- [ ] **Phase 62: Automated Release-Gate Lock** - Reproduce the final candidate through all generation, analysis, test, release, and simulator/emulator gates.
- [ ] **Phase 63: Isolated Wired-iPhone Acceptance** - Validate the final candidate only in a separate test identity on the current wired iPhone.

## Phase Details

### Phase 57: Stable Baseline & Compatibility Contract

**Goal**: Maintainers have one auditable, official-source production-stable baseline that prevents unsafe or partial dependency upgrades before any compatibility lane changes.
**Depends on**: Nothing (first v2.1 phase)
**Requirements**: BASE-01, BASE-02, BASE-03, BASE-04
**Success Criteria** (what must be TRUE):

  1. A reviewer can see the query date, official source, current value, and production-stable candidate for every required SDK, native tool, and direct dependency.
  2. A clean checkout resolves the reviewed Dart, Flutter, native-project, and lockfile combination reproducibly.
  3. The executable compatibility contract rejects beta/RC/dev, EOL SQLCipher packaging, unapproved overrides, and a partially upgraded dependency lane.
  4. Every intentional hold has recorded official evidence, a compatibility reason, and an exit condition while iOS 15 and Android API 24 remain supported.

**Plans**: 3/3 plans executed

- [x] 57-01-PLAN.md
- [x] 57-02-PLAN.md
- [x] 57-03-PLAN.md

### Phase 58: Flutter, Analyzer & Code Generation Lane

**Goal**: The project uses a single production-stable Flutter/Dart and code-generation compatibility graph without losing Clean Architecture or lint protection for current production entrypoints and project-supported syntax.
**Depends on**: Phase 57
**Requirements**: GEN-01, GEN-02, GEN-03, GEN-04
**Success Criteria** (what must be TRUE):

  1. Developers and CI use the same officially verified Flutter/Dart stable toolchain and declared Dart SDK range.
  2. Invalid imports and Riverpod roots in current production entrypoints and project-supported syntax fail the active import_lint/Riverpod lint and repository-owned architecture guards after the analyzer decision; the exact analyzer 12 hold is explicit and enforced. The token scanner is defense-in-depth, with complete Dart grammar parsing outside its contract.
  3. Riverpod, Freezed, JSON, Drift, build_runner, analyzer, and lints resolve as one exact compatible graph with no forced override, removed guard, or split runtime/generator lane.
  4. From a clean generation state, dependency resolution, localization generation, and code generation finish with no unexpected tracked generated-file diff or hand-edited output.

**Plans**: 10/10 plans executed

Plans:

**Wave 0**

- [x] 58-01-PLAN.md — Create fail-first import_guard, source-scanning architecture, and Riverpod lint test infrastructure.
- [x] 58-03-PLAN.md — Create the source-tested authoritative locked-resolution, two-pass generation, then lint/architecture wrapper.

**Wave 1** *(blocked on Wave 0 completion)*

- [x] 58-02-PLAN.md — Enforce Flutter 3.44.8/Dart 3.12.2 and the exact analyzer 12.1.0 coherent generator graph; Flutter 3.44.9 is a documented hold pending a full identity transaction.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 58-04-PLAN.md — Make Stable CI call the authoritative wrapper once and remove pre-generation/inline duplicate gates.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 58-05-PLAN.md — Execute and record the full targeted, full-suite, coverage, and clean-generation evidence matrix.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 58-06-PLAN.md — Close the qualified `runApp` guard bypass and default-concurrency fixture collision, then re-prove the lock-enforced coverage lane.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 58-07-PLAN.md — Close the `runApp.call` parser bypass and lexical-shadow boundary false positives with parser and live-tooling regressions.

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 58-08-PLAN.md — Make the tooling fixture lock recover from setup/resource failures and re-prove the final automated regression lane.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 58-09-PLAN.md — Close exact one-layer parenthesized `runApp` parsing and bound C-style/for-in Riverpod alias shadows to their loop statements.

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 58-10-PLAN.md — Require the complete conflict-deleting build_runner command on both authoritative passes and re-run the final owned regression lane.

Cross-cutting constraints:

- Flutter 3.44.8 Stable / Dart 3.12.2 and the exact analyzer 12.1.0 / import_lint 2.0.0 / active riverpod_lint 3.1.4 cohort remain one no-override graph.
- One authoritative local/Stable-CI wrapper enforces locked resolution → two clean l10n/build_runner passes → analyzer → active import_lint/Riverpod lint → layer/domain/presentation architecture tests → Riverpod/import-boundary negative proof; no Stable pre-generation analysis duplicate remains.

### Phase 59: Controlled Platform Plugin Cohorts

**Goal**: Users retain working file, share, speech, notification, biometric, and secure-storage behavior while each plugin cohort is either safely modernized or evidence-held.
**Depends on**: Phase 58
**Requirements**: PLUG-01, PLUG-02, PLUG-03, PLUG-04
**Success Criteria** (what must be TRUE):

  1. Each direct or significant native/transitive plugin is independently recorded as the latest safe production-stable version or as an evidence-backed hold.
  2. Users can still select and import a `.hpb` backup and invoke the supported system share flow with the file/share/package-info/win32 cohort treated atomically.
  3. Japanese, Chinese, and English voice entry retain parsing, permission, cancellation, and error behavior after a stable speech upgrade; otherwise version 7.3.0 remains with the failed acceptance evidence recorded.
  4. Firebase/notification, biometric, and secure-storage initialization still works without resurfacing the intentionally hidden notification setting or changing the disclosed cloud-fallback behavior.

**Plans**: 2/7 plans executed

Plans:

- [x] 59-01-PLAN.md
- [x] 59-02-PLAN.md
- [ ] 59-03-PLAN.md
- [ ] 59-04-PLAN.md
- [ ] 59-05-PLAN.md
- [ ] 59-06-PLAN.md
- [ ] 59-07-PLAN.md
- [ ] `59-01-PLAN.md` — Wave 0 evidence ledger, atomic cohort contracts, six edge-probe resolutions, and complete API capability coverage.
- [ ] `59-02-PLAN.md` — Atomic file/share/package-info/win32 candidate-or-hold lane with picker, import, share-sheet, and package-identity proof.
- [ ] `59-03-PLAN.md` — Speech stable-candidate lane with ja/zh/en unit, corpus, and physical-iPhone evidence or exact hold.
- [ ] `59-04-PLAN.md` — Firebase/notification cohort lane preserving Android FCM, iOS APNs, and hidden first-release notification policy.
- [ ] `59-05-PLAN.md` — Biometric cohort lane preserving biometric-only options and app-PIN fallback.
- [ ] `59-06-PLAN.md` — Secure-storage cohort lane preserving Keychain accessibility and fail-closed encrypted startup.
- [ ] `59-07-PLAN.md` — Cross-cohort convergence, full regression, coverage, generated-output, and source-audit closure.

### Phase 60: SQLCipher & iOS Native Safety Lane

**Goal**: Users' local financial data remains encrypted, readable, migratable, and recoverable through the clean iOS native dependency path.
**Depends on**: Phase 58
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06
**Success Criteria** (what must be TRUE):

  1. The selected native graph keeps the proven `sqlcipher_flutter_libs 0.6.8` / `sqlite3 2.9.4` / SQLCipher Pod 4.10.0 lane unless a separately approved, equivalently evidenced replacement exists; EOL, `sqlite3_flutter_libs`, and plaintext/system-SQLite paths are rejected.
  2. Clean SwiftPM plus SQLCipher-only CocoaPods resolution builds the supported simulator/device and debug/profile/release configurations while retaining the Podfile system-`sqlite3` linker protection.
  3. An encrypted database returns a non-empty `PRAGMA cipher_version` on initial open and after close/reopen, and its sentinel data remains readable.
  4. A previous released encrypted schema migrates through the real upgrade path with its version, tables, indices, defaults, and representative data intact.
  5. Test-only `.hpb` export, clear, and password restore preserve current and supported legacy backups atomically; wrong passwords, truncation, and resource-limit failures leave existing data intact, and missing master keys continue to fail closed without an upgrade-only schema bump.

**Plans**: TBD

### Phase 61: Android Toolchain & Emulator Lane

**Goal**: The supported Android build is either fully migrated as one production-stable AGP lane or safely held at the last green AGP 8 lane, with no partial toolchain state.
**Depends on**: Phase 58
**Requirements**: AND-01, AND-02, AND-03, AND-04
**Success Criteria** (what must be TRUE):

  1. The AGP 9.0.1 / Gradle 9.1 / JDK 17 / API 36 candidate is evaluated as a single lane while preserving minSdk 24.
  2. If AGP 9 is compatible, built-in Kotlin/new DSL adoption, legacy KGP removal, and temporary Flutter opt-out cleanup are complete across the app and plugin graph; if it is not, the entire lane is held at the last green AGP 8 combination with its blocker recorded.
  3. The final Android combination produces a non-debug-signed release AAB/APK that the signing contract accepts and that contains no test-only registrar or plugin.
  4. Key integration journeys pass on a supported Android Emulator, and the final evidence explicitly says Android physical-device acceptance was not performed or claimed.

**Plans**: TBD

### Phase 62: Automated Release-Gate Lock

**Goal**: The exact final compatibility graph can be reproduced from clean state and passes all automated release prerequisites before it reaches a physical phone.
**Depends on**: Phase 59, Phase 60, Phase 61
**Requirements**: QA-01, QA-02, QA-03, QA-04
**Success Criteria** (what must be TRUE):

  1. The final lockfile passes analyze, custom lint/import guard, architecture, privacy, dependency, and whitespace contracts with zero issues and no new unjustified ignore.
  2. Target regressions, the full test suite, coverage gate, and any necessary single-concurrency confirmation pass for the selected graph.
  3. A clean release preflight regenerates native registrants and proves the production Runner excludes development-only plugins while CI pins the same Flutter stable, lockfile, and generation steps.
  4. iPhone Simulator and Android Emulator prerequisites pass, and a compatibility report records exact commands, environment, commit, version deltas, intentional holds, fixes, residual debt, and the absence of Android physical-device validation.

**Plans**: TBD

### Phase 63: Isolated Wired-iPhone Acceptance

**Goal**: The final signed candidate is accepted on the currently wired iPhone without touching the production app, its financial data, or its credentials.
**Depends on**: Phase 62
**Requirements**: DEVICE-01, DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05, DEVICE-06, DEVICE-07
**Success Criteria** (what must be TRUE):

  1. The UAT app uses an additive, test-only Bundle ID/App ID, container, Keychain group, entitlements, notification/Firebase configuration, and test keys; automated checks prove it is not the production identity.
  2. Install, uninstall, clear-data, and destructive backup/restore exercises use only synthetic UAT data, while the production app, database, Keychain, and backups on the phone remain untouched and records redact device/sensitive financial material.
  3. The current wired `“Xin Zhang”的 iPhone` installs the exact signed profile- or release-compatible artifact for the final commit/lockfile, with model, iOS, Xcode, Flutter, build mode, install, and cold-start evidence recorded.
  4. On that phone, SQLCipher open/reopen, released-schema migration, and encrypted backup clear/restore preserve the sentinel and schema invariants; first-run initialization, daily and joy manual entries, cold-restart persistence, and App Lock PIN/Face ID/fallback/relock all work.
  5. The encrypted sync queue/E2EE smoke is redacted and passes only when the required test environment exists; otherwise it is explicitly limited or blocked, and profile/release performance evidence uses a same-device baseline rather than marking `baseline_required` as passed.

**Plans**: TBD

## Progress

**Execution Order:** 57 → 58 → 59 → 60 → 61 → 62 → 63. Phases 59–61 share the Phase 58 resolved SDK graph; they may only converge at Phase 62 with the identical final lockfile and all joint gates green.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 57. Stable Baseline & Compatibility Contract | 3/3 | Complete    | 2026-08-06 |
| 58. Flutter, Analyzer & Code Generation Lane | 10/10 | Complete    | 2026-08-08 |
| 59. Controlled Platform Plugin Cohorts | 2/7 | In Progress|  |
| 60. SQLCipher & iOS Native Safety Lane | 0/TBD | Not started | - |
| 61. Android Toolchain & Emulator Lane | 0/TBD | Not started | - |
| 62. Automated Release-Gate Lock | 0/TBD | Not started | - |
| 63. Isolated Wired-iPhone Acceptance | 0/TBD | Not started | - |
