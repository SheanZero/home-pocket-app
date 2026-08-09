# Phase 60: SQLCipher & iOS Native Safety Lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-09
**Phase:** 60-sqlcipher-ios-native-safety-lane
**Areas discussed:** Native graph authority, iOS build acceptance boundary, migration fixture support window, backup destructive-test isolation

---

## Native Graph Authority

### Authoritative baseline

| Option | Description | Selected |
|--------|-------------|----------|
| Current Native Assets | Keep Drift 2.34.0, sqlite3 3.5.1, SQLCipher 4.17.x and correct stale planning text. | ✓ |
| Restore legacy Flutter libs | Return to sqlcipher_flutter_libs 0.6.8/sqlite3 2.9.4/Pod 4.10.0. | |
| Add another ADR first | Defer the baseline despite ADR-002's existing 2026-08-06 update. | |

### Version movement

| Option | Description | Selected |
|--------|-------------|----------|
| Keep exact graph | Avoid analyzer/generator/native evidence churn. | ✓ |
| Upgrade when gates pass | Permit a newer Drift/sqlite graph inside Phase 60. | |
| sqlite3 patch only | Permit Native Asset patch movement while Drift stays fixed. | |

### Stale planning reconciliation

| Option | Description | Selected |
|--------|-------------|----------|
| Atomic canonical correction | Align ROADMAP, REQUIREMENTS, and compatibility contract in the first plan. | ✓ |
| CONTEXT note only | Leave the canonical conflict unresolved. | |
| Dual-track policy | Treat legacy and Native Assets as simultaneously valid. | |

### Enforcement depth

| Option | Description | Selected |
|--------|-------------|----------|
| Source + graph + runtime | Reject forbidden packages/config and prove real SQLCipher identity/header. | ✓ |
| Graph only | Check configuration and resolution without runtime proof. | |
| Runtime fixture only | Omit static and resolved-graph prohibitions. | |

**User's choice:** Option 1 for all four questions.
**Notes:** The Native Assets graph is the only authority; the old ROADMAP text must not trigger a security downgrade.

---

## iOS Build Acceptance Boundary

### Device boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Generic-device compile only | Simulator runtime plus unsigned generic-device compilation; Phase 63 owns signing/install. | ✓ |
| Signed build, no install | Use development signing in Phase 60. | |
| Physical install | Move device acceptance into Phase 60. | |

### Configuration matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Full matrix | Simulator and generic device Debug/Profile/Release clean-builds with honest runtime labels. | ✓ |
| Risk-weighted | Test only selected high-risk configurations. | |
| Debug only | Defer Profile/Release proof. | |

### Clean-state proof

| Option | Description | Selected |
|--------|-------------|----------|
| Locked rebuild + isolated resolution | Preserve main-tree locks and compare a disposable from-zero resolution. | ✓ |
| Locked rebuild only | Clean generated artifacts but never re-resolve from zero. | |
| Delete locks in main tree | Resolve directly in the working tree and accept changes. | |

### iOS deployment mismatch

| Option | Description | Selected |
|--------|-------------|----------|
| Normalize to iOS 15 | Use supported/reproducible generation and fail closed if alignment is impossible. | ✓ |
| Keep generated iOS 13 | Accept the mismatch when builds happen to pass. | |
| Downgrade dependencies | Reduce Firebase/plugin requirements to fit the generated declaration. | |

**User's choice:** Option 1 for all four questions.
**Notes:** Compile-only evidence cannot be reported as SQLCipher runtime acceptance, and generated ephemeral files cannot be hand-edited.

---

## Migration Fixture Support Window

### Historical starting points

| Option | Description | Selected |
|--------|-------------|----------|
| v35 and v23 | Prove both native-library continuity and v2.0 product-data continuity. | ✓ |
| v35 only | Cover only the latest pre-v36 encrypted fixture. | |
| v23 only | Cover only the latest shipped milestone schema. | |

### v23 fixture authenticity

| Option | Description | Selected |
|--------|-------------|----------|
| Genuine historical artifact | Generate with historical code/config and commit immutable bytes/hash/provenance. | ✓ |
| Dynamic current-code fixture | Construct old tables and user_version during the test. | |
| Migration mocks only | Add no encrypted historical artifact. | |

### Sentinel breadth

| Option | Description | Selected |
|--------|-------------|----------|
| Cross-domain synthetic pack | Exercise accounting, encrypted fields, reference data, shopping, settings, and sync/device state. | ✓ |
| Core accounting only | Limit representative data to book/transaction/category. | |
| Schema only | Check structures without data continuity. | |

### Terminal migration proof

| Option | Description | Selected |
|--------|-------------|----------|
| Migrate/write/cold-reopen | Verify old and new data plus SQLCipher identity/integrity/header after cold reopen. | ✓ |
| Initial migration only | Stop after first successful open. | |
| Regenerate failed fixtures | Rewrite historical fixtures to match current code. | |

**User's choice:** Option 1 for all four questions.
**Notes:** Historical fixtures are immutable witnesses and contain only synthetic data.

---

## Backup Destructive-Test Isolation

### Test environment

| Option | Description | Selected |
|--------|-------------|----------|
| Temporary simulator sandbox | Unique directories, keys, synthetic data, and injected storage dependencies per test. | ✓ |
| Default simulator container | Reuse the normal Runner container after checking it is empty. | |
| Physical-device container | Run destructive backup testing on the iPhone. | |

### Supported formats

| Option | Description | Selected |
|--------|-------------|----------|
| v2 + existing pre-v2 | Keep current Argon2id/AES-GCM and legacy headerless PBKDF2 recovery. | ✓ |
| v2 only | Retire pre-v2 backup recovery. | |
| Heuristic compatibility | Attempt unknown formats loosely. | |

### Failure atomicity

| Option | Description | Selected |
|--------|-------------|----------|
| All persisted state unchanged | Stage all validation before one commit point and compare all sandbox state. | ✓ |
| Database rows only | Allow auxiliary files/settings to change on failure. | |
| Clear on failure | Verify only that an error is returned. | |

### Success-path realism

| Option | Description | Selected |
|--------|-------------|----------|
| Production use cases with isolation | Invoke export, clear-all, import/restore with injected sandbox dependencies. | ✓ |
| Crypto service only | Test bytes without production restore orchestration. | |
| Direct DAO/file manipulation | Simulate the journey outside production use cases. | |

**User's choice:** Option 1 for all four questions.
**Notes:** Successful restore must survive cold reopen and a second export; failure paths preserve keys, settings, attachments, data, and the source backup.

---

## the agent's Discretion

- Exact command sequence, temporary-copy mechanism, test decomposition, fixture names, and additional synthetic rows.
- The supported reproducible source mechanism that aligns generated SwiftPM deployment targets to iOS 15.

## Deferred Ideas

- Android toolchain/emulator evidence remains Phase 61.
- Final automated release convergence remains Phase 62.
- Signed installation and all physical-iPhone runtime acceptance remain Phase 63.
- Drift/analyzer or future SQLCipher packaging upgrades require separate equivalent evidence.
