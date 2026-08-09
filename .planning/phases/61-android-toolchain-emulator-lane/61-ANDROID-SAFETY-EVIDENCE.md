# Phase 61 Android Safety Evidence

Only the JSON block between the markers is machine-authoritative. `NOT_RUN` is intentionally fail-closed and cannot satisfy strict verification.

<!-- phase61-evidence-json:start -->
```json
{
  "schema_version": 1,
  "completed_stage": "candidate",
  "source_commit": "ab6c25a4f6a1820250656258eee775ed0e94f205",
  "started_utc": "2026-08-09T15:02:37.932294Z",
  "completed_utc": "2026-08-09T15:02:41.018026Z",
  "host_os": "macOS 26.5.1 arm64",
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
    "component": "Flutter 3.44.8 and resolved legacy-KGP plugin graph",
    "official_source": "https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers",
    "reproduction": "flutter build apk --debug --config-only (exit 0); Flutter configuration restored the legacy built-in-Kotlin/new-DSL opt-outs.",
    "exit_condition": "Upgrade Flutter through a reviewed identity transaction to 3.47 or later and select Phase 59-approved plugin releases whose Android modules no longer apply legacy KGP, then rerun the complete candidate transaction."
  },
  "results": {
    "candidate": "INCOMPATIBLE",
    "compile": "NOT_RUN",
    "package": "NOT_RUN",
    "emulator": "NOT_RUN",
    "physical_device": "NOT_PERFORMED_NOT_CLAIMED"
  },
  "commands": [
    {
      "command": "java -version",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "flutter pub get --enforce-lockfile",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "flutter build apk --debug --config-only",
      "exit_code": 0,
      "timed_out": false
    }
  ],
  "artifacts": [],
  "emulator": {
    "api": 36,
    "abi": "x86_64",
    "profile": "NOT_RUN",
    "serial_redacted": "NOT_RUN"
  },
  "clean_tree": "PASS: source and resolved-plugin input digests unchanged",
  "physical_device_statement": "Android physical-device validation was not performed or claimed.",
  "plugin_legacy_kgp_inventory": [
    "file_picker",
    "package_info_plus",
    "share_plus",
    "speech_to_text"
  ],
  "candidate_observation": "Flutter configuration restored the legacy built-in-Kotlin/new-DSL opt-outs.",
  "candidate_output_sha256": "763bd27af82051d4d022c6036741f27c1946d2664d4b8ca7b258579035fe5b99"
}
```
<!-- phase61-evidence-json:end -->

Compile, signed package, Emulator runtime, and physical-device evidence are separate result classes. No production key, credential, user data, device identifier, or raw local path belongs in this file.
