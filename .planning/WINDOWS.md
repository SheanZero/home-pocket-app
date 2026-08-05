---
schema_version: 1
open_count: 0
waived_count: 0
fixed_count: 1
total_count: 1
last_updated: 2026-08-05T14:18:19.498Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 57 | deviation | scripts/dependency_compatibility.dart |  | Repaired interrupted manifest validator and portable test fixture before baseline verification. | fixed |  | 2026-08-05T14:17:34.534Z | 2026-08-05T14:18:19.498Z |

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
  }
]
````
