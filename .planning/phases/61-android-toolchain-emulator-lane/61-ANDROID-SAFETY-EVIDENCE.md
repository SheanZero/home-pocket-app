# Phase 61 Android Safety Evidence

Only the JSON block between the markers is machine-authoritative. `NOT_RUN` is intentionally fail-closed and cannot satisfy strict verification.

<!-- phase61-evidence-json:start -->
```json
{
  "schema_version": 1,
  "completed_stage": "emulator",
  "source_commit": "e6b5cbf672e885dcbb4446621cc20e7ca05aa058",
  "candidate_source_commit": "ab6c25a4f6a1820250656258eee775ed0e94f205",
  "compile_source_commit": "5870a04ec041c0c8dba5d6b23cffead5a30b5385",
  "started_utc": "2026-08-09T15:02:37.932294Z",
  "completed_utc": "2026-08-10T00:43:09.500889Z",
  "compile_started_utc": "2026-08-09T15:14:55Z",
  "compile_completed_utc": "2026-08-09T15:15:59Z",
  "host_os": "macOS 26.5.1 arm64",
  "graph": {
    "decision": "hold",
    "candidate_agp": "9.3.1",
    "candidate_gradle": "9.5.0",
    "candidate_queried_on": "2026-08-09",
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
    "compile": "PASS",
    "package": "PASS",
    "emulator": "PASS",
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
    },
    {
      "command": "./gradlew --no-daemon -Dorg.gradle.java.home=<verified-jdk17> --version",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "./gradlew --no-daemon -Dorg.gradle.java.home=<verified-jdk17> clean :app:assembleDebug",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "./gradlew <verified-jdk17> -Pphase61SigningEvidence=true :app:verifyReleaseSigning (credentials absent)",
      "exit_code": 1,
      "timed_out": false
    },
    {
      "command": "./gradlew <verified-jdk17> -Pphase61SigningEvidence=true :app:verifyReleaseSigning (Android Debug certificate)",
      "exit_code": 1,
      "timed_out": false
    },
    {
      "command": "bash scripts/release_preflight.sh --platform android --package (ephemeral non-debug evidence certificate)",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "apksigner verify --verbose --print-certs app-release.apk",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "jarsigner -verify app-release.aab",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "keytool -printcert -jarfile app-release.aab",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "aapt dump badging app-release.apk",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "./gradlew <verified-jdk17> -Pphase61SigningEvidence=true :app:verifyReleaseSigning (credentials absent)",
      "exit_code": 1,
      "timed_out": false
    },
    {
      "command": "./gradlew <verified-jdk17> -Pphase61SigningEvidence=true :app:verifyReleaseSigning (Android Debug certificate)",
      "exit_code": 1,
      "timed_out": false
    },
    {
      "command": "bash scripts/release_preflight.sh --platform android --package (ephemeral non-debug evidence certificate)",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "apksigner verify --verbose --print-certs app-release.apk",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "jarsigner -verify app-release.aab",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "keytool -printcert -jarfile app-release.aab",
      "exit_code": 0,
      "timed_out": false
    },
    {
      "command": "aapt dump badging app-release.apk",
      "exit_code": 0,
      "timed_out": false
    }
  ],
  "artifacts": [
    {
      "kind": "release_aab",
      "sha256": "2c8cebace1d09a69d60f334aacc158ed83ea676a7bc89299cc78a5049d97905e",
      "size_bytes": 83911152,
      "certificate_class": "NON_DEBUG_EPHEMERAL_EVIDENCE",
      "certificate_subject": "CN=Happy Pocket Phase 61 Evidence",
      "certificate_sha256": "c929afb8b0287d2d13d4c7ac89b63ed5b19a90e067e00e55aeff9a628f16ae38",
      "signature_tool": "jarsigner + keytool",
      "archive_and_content_hygiene": "PASS",
      "durable_artifact_retained": false
    },
    {
      "kind": "release_apk",
      "sha256": "be48e7ee43f5ed4cdace8e9b33faba63d40abc4e123445e4628063adc948aefc",
      "size_bytes": 89743247,
      "certificate_class": "NON_DEBUG_EPHEMERAL_EVIDENCE",
      "certificate_subject": "CN=Happy Pocket Phase 61 Evidence",
      "certificate_sha256": "c929afb8b0287d2d13d4c7ac89b63ed5b19a90e067e00e55aeff9a628f16ae38",
      "signature_tool": "apksigner",
      "archive_and_content_hygiene": "PASS",
      "durable_artifact_retained": false
    }
  ],
  "emulator": {
    "lane": "primary_local_arm64",
    "api": 36,
    "abi": "arm64-v8a",
    "profile": "pixel_6",
    "serial_redacted": "<emulator-redacted>"
  },
  "x86_64_supplemental": {
    "result": "UNAVAILABLE_LIMITATION",
    "api": 36,
    "abi": "x86_64",
    "system_image": "system-images;android-36;google_apis;x86_64",
    "execution_surface": "GitHub/Intel x86_64 host",
    "claim": "Supplemental only; no local primary acceptance claim.",
    "historical_failure": "Apple Silicon QEMU rejected x86_64; bounded Rosetta diagnostics were unavailable."
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
  "candidate_output_sha256": "763bd27af82051d4d022c6036741f27c1946d2664d4b8ca7b258579035fe5b99",
  "compile_runtime": {
    "gradle": "8.14",
    "launcher_jvm": "Eclipse Adoptium 17.0.20+8",
    "daemon_jvm": "verified JDK 17",
    "result": "BUILD SUCCESSFUL",
    "hosted_api36_x86_64_workflow": "NOT_RUN"
  },
  "package_source_commit": "e6b5cbf672e885dcbb4446621cc20e7ca05aa058",
  "package_started_utc": "2026-08-10T00:40:50.988047Z",
  "package_completed_utc": "2026-08-10T00:43:09.500889Z",
  "release_signing_negatives": {
    "missing_credentials": {
      "result": "REJECTED_AS_REQUIRED",
      "exit_code": 1
    },
    "android_debug_certificate": {
      "result": "REJECTED_AS_REQUIRED",
      "exit_code": 1
    }
  },
  "release_package_metadata": {
    "application_id": "com.sheanzero.happypocket.app",
    "version_code": "1",
    "version_name": "0.1.0",
    "min_sdk": "24",
    "target_sdk": "36"
  },
  "release_cleanup": {
    "private_key_material": "ABSENT",
    "release_aab": "DELETED_AFTER_EVIDENCE",
    "release_apk": "DELETED_AFTER_EVIDENCE",
    "repository_secret_or_artifact": "ABSENT"
  },
  "emulator_preparation": {
    "result": "PASS",
    "lane": "primary_local_arm64",
    "source_commit": "e6b5cbf672e885dcbb4446621cc20e7ca05aa058",
    "started_utc": "2026-08-10T00:38:02.465875Z",
    "completed_utc": "2026-08-10T00:43:09.529135Z",
    "api": 36,
    "abi": "arm64-v8a",
    "profile": "pixel_6",
    "system_image": "system-images;android-36;google_apis;arm64-v8a",
    "cold_boot": "wipe-data/no-snapshot",
    "host_architecture": "arm64",
    "runtime": "native Apple Silicon host execution",
    "emulator_version": "Android emulator version 36.3.10.0 (build_id 14472402) (CL:N/A)",
    "emulator_host_binary": {
      "architecture": "arm64"
    },
    "serial_redacted": "<emulator-redacted>",
    "boot_started_utc": "2026-08-10T00:38:03.065910Z",
    "boot_ready_utc": "2026-08-10T00:38:24.611832Z",
    "cleanup": {
      "runner_owned_avd": "DELETED",
      "unrelated_devices": "ABSENT_BEFORE_BOOT"
    }
  },
  "integration_matrix": [
    {
      "file": "device_critical_journey_test.dart",
      "exit_code": 0,
      "timed_out": false,
      "duration_ms": 55232
    },
    {
      "file": "device_sync_delivery_test.dart",
      "exit_code": 0,
      "timed_out": false,
      "duration_ms": 17546
    },
    {
      "file": "merchant_migration_ladder_test.dart",
      "exit_code": 0,
      "timed_out": false,
      "duration_ms": 15938
    },
    {
      "file": "performance/performance_baseline_test.dart",
      "exit_code": 0,
      "timed_out": false,
      "duration_ms": 16778
    },
    {
      "file": "sqlcipher_backup_recovery_test.dart",
      "exit_code": 0,
      "timed_out": false,
      "duration_ms": 23293
    },
    {
      "file": "sqlcipher_native_assets_lifecycle_test.dart",
      "exit_code": 0,
      "timed_out": false,
      "duration_ms": 14849
    }
  ]
}
```
<!-- phase61-evidence-json:end -->

Compile, signed package, Emulator runtime, and physical-device evidence are separate result classes. No production key, credential, user data, device identifier, or raw local path belongs in this file.
