---
schema_version: 1
open_count: 6
waived_count: 0
fixed_count: 2
total_count: 8
last_updated: 2026-08-09T12:15:46.161Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 57 | deviation | scripts/dependency_compatibility.dart |  | Repaired interrupted manifest validator and portable test fixture before baseline verification. | fixed |  | 2026-08-05T14:17:34.534Z | 2026-08-05T14:18:19.498Z |
| 2 | 58 | deviation | scripts/verify_codegen_reproducibility.sh |  | Added explicit second-pass nondeterminism diagnostic required by the D-09 fail-closed wrapper. | open |  | 2026-08-05T16:52:20.549Z |  |
| 3 | 59 | deviation | test/architecture/dependency_compatibility_contract_test.dart |  | Corrected Task 2 lock-version mutation expectations so lock fixtures use selected versions rather than caret constraints. | open |  | 2026-08-09T00:09:13.461Z |  |
| 4 | 59 | lint-warning | lib/** |  | flutter analyze reports 289 pre-existing prefer_initializing_formals information diagnostics outside the Phase 59 cohort; recorded in 59 deferred-items.md. | fixed |  | 2026-08-09T00:21:31.870Z | 2026-08-09T02:24:35.100Z |
| 5 | 60 | unrun-verify | test/ |  | Serialized full Flutter suite was stopped after two scoped regressions were fixed; its remaining long script-fixture tail was not rerun. | open |  | 2026-08-09T08:58:42.785Z |  |
| 6 | 60 | unrun-verify | integration_test/sqlcipher_native_assets_lifecycle_test.dart |  | Current-schema Simulator lifecycle blocked before test launch by existing iOS linker/CoreSimulator failure. | open |  | 2026-08-09T10:44:44.080Z |  |
| 7 | 60 | unrun-verify | integration_test/sqlcipher_backup_recovery_test.dart |  | Booted-Simulator recovery verifier stopped during Flutter Xcode build before emitting a runtime test result. | open |  | 2026-08-09T11:00:58.351Z |  |
| 8 | 60 | unrun-verify | scripts/verify_ios_native_safety_lane.dart |  | Current-schema lifecycle Simulator runtime is blocked by Flutter-symbol linkage before launch; do not substitute compile-only evidence. | open |  | 2026-08-09T12:15:46.161Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "57",
    "file": "scripts/dependency_compatibility.dart",
    "line": null,
    "description": "Repaired interrupted manifest validator and portable test fixture before baseline verification.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-05T14:17:34.534Z",
    "resolved_at": "2026-08-05T14:18:19.498Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "58",
    "file": "scripts/verify_codegen_reproducibility.sh",
    "line": null,
    "description": "Added explicit second-pass nondeterminism diagnostic required by the D-09 fail-closed wrapper.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-05T16:52:20.549Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "59",
    "file": "test/architecture/dependency_compatibility_contract_test.dart",
    "line": null,
    "description": "Corrected Task 2 lock-version mutation expectations so lock fixtures use selected versions rather than caret constraints.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-09T00:09:13.461Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "lint-warning",
    "phase": "59",
    "file": "lib/**",
    "line": null,
    "description": "flutter analyze reports 289 pre-existing prefer_initializing_formals information diagnostics outside the Phase 59 cohort; recorded in 59 deferred-items.md.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-09T00:21:31.870Z",
    "resolved_at": "2026-08-09T02:24:35.100Z"
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "60",
    "file": "test/",
    "line": null,
    "description": "Serialized full Flutter suite was stopped after two scoped regressions were fixed; its remaining long script-fixture tail was not rerun.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-09T08:58:42.785Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "unrun-verify",
    "phase": "60",
    "file": "integration_test/sqlcipher_native_assets_lifecycle_test.dart",
    "line": null,
    "description": "Current-schema Simulator lifecycle blocked before test launch by existing iOS linker/CoreSimulator failure.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-09T10:44:44.080Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "60",
    "file": "integration_test/sqlcipher_backup_recovery_test.dart",
    "line": null,
    "description": "Booted-Simulator recovery verifier stopped during Flutter Xcode build before emitting a runtime test result.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-09T11:00:58.351Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "unrun-verify",
    "phase": "60",
    "file": "scripts/verify_ios_native_safety_lane.dart",
    "line": null,
    "description": "Current-schema lifecycle Simulator runtime is blocked by Flutter-symbol linkage before launch; do not substitute compile-only evidence.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-09T12:15:46.161Z",
    "resolved_at": null
  }
]
````
