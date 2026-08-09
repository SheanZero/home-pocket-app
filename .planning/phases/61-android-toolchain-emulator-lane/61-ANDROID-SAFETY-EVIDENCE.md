# Phase 61 Android Safety Evidence

Only the JSON block between the markers is machine-authoritative. `NOT_RUN` is intentionally fail-closed and cannot satisfy strict verification.

<!-- phase61-evidence-json:start -->
```json
{
  "schema_version": 1,
  "source_commit": "NOT_RUN",
  "started_utc": "NOT_RUN",
  "completed_utc": "NOT_RUN",
  "host_os": "NOT_RUN",
  "graph": {
    "decision": "hold",
    "candidate_agp": "9.3.1",
    "candidate_gradle": "9.5.0",
    "selected_agp": "8.11.1",
    "selected_gradle": "8.14",
    "selected_kotlin": "2.2.20",
    "jdk": "17",
    "android_api": 36,
    "min_sdk": 24
  },
  "blocker": {
    "component": "NOT_RUN",
    "official_source": "NOT_RUN",
    "reproduction": "NOT_RUN",
    "exit_condition": "NOT_RUN"
  },
  "results": {
    "candidate": "NOT_RUN",
    "compile": "NOT_RUN",
    "package": "NOT_RUN",
    "emulator": "NOT_RUN",
    "physical_device": "NOT_PERFORMED_NOT_CLAIMED"
  },
  "commands": [],
  "artifacts": [],
  "emulator": {
    "api": 36,
    "abi": "x86_64",
    "profile": "NOT_RUN",
    "serial_redacted": "NOT_RUN"
  },
  "clean_tree": "NOT_RUN",
  "physical_device_statement": "Android physical-device validation was not performed or claimed."
}
```
<!-- phase61-evidence-json:end -->

Compile, signed package, Emulator runtime, and physical-device evidence are separate result classes. No production key, credential, user data, device identifier, or raw local path belongs in this file.
