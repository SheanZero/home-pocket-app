# Phase 61 Android Safety Evidence

Only the JSON block between the markers is machine-authoritative. `NOT_RUN` is intentionally fail-closed and cannot satisfy strict verification.

<!-- phase61-evidence-json:start -->
```json
{
  "schema_version": 1,
  "completed_stage": "package",
  "source_commit": "b953bcc368a1783823963d4c1b4a0792fb17693e",
  "candidate_source_commit": "ab6c25a4f6a1820250656258eee775ed0e94f205",
  "compile_source_commit": "5870a04ec041c0c8dba5d6b23cffead5a30b5385",
  "started_utc": "2026-08-09T15:02:37.932294Z",
  "completed_utc": "2026-08-09T15:51:04.020537Z",
  "compile_started_utc": "2026-08-09T15:14:55Z",
  "compile_completed_utc": "2026-08-09T15:15:59Z",
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
    "compile": "PASS",
    "package": "PASS",
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
    }
  ],
  "artifacts": [
    {
      "kind": "release_aab",
      "sha256": "ec9fd01d96fc8cf60488628ba435755a82716e63fa47da714ef279f69db44c61",
      "size_bytes": 83911159,
      "certificate_class": "NON_DEBUG_EPHEMERAL_EVIDENCE",
      "certificate_subject": "CN=Happy Pocket Phase 61 Evidence",
      "certificate_sha256": "250315b3a00f8d4e6946365a44e2b875304585bb17c37bd83aea64351e0c53a7",
      "signature_tool": "jarsigner + keytool",
      "archive_and_content_hygiene": "PASS",
      "durable_artifact_retained": false
    },
    {
      "kind": "release_apk",
      "sha256": "a351fc44d27f7e5abcc2f1cfc08eeb6651c1a50281b255f911886405da688597",
      "size_bytes": 89743247,
      "certificate_class": "NON_DEBUG_EPHEMERAL_EVIDENCE",
      "certificate_subject": "CN=Happy Pocket Phase 61 Evidence",
      "certificate_sha256": "250315b3a00f8d4e6946365a44e2b875304585bb17c37bd83aea64351e0c53a7",
      "signature_tool": "apksigner",
      "archive_and_content_hygiene": "PASS",
      "durable_artifact_retained": false
    }
  ],
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
  "candidate_output_sha256": "763bd27af82051d4d022c6036741f27c1946d2664d4b8ca7b258579035fe5b99",
  "compile_runtime": {
    "gradle": "8.14",
    "launcher_jvm": "Eclipse Adoptium 17.0.20+8",
    "daemon_jvm": "verified JDK 17",
    "result": "BUILD SUCCESSFUL",
    "hosted_api36_x86_64_workflow": "NOT_RUN"
  },
  "package_source_commit": "b953bcc368a1783823963d4c1b4a0792fb17693e",
  "package_started_utc": "2026-08-09T15:48:58.779404Z",
  "package_completed_utc": "2026-08-09T15:51:04.020537Z",
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
    "result": "UNAVAILABLE",
    "source_commit": "cc048bcb62120796a3208c5096c82635e0b08888",
    "started_utc": "2026-08-10T00:20:24.365853Z",
    "completed_utc": "2026-08-10T00:20:29.220476Z",
    "api": 36,
    "abi": "x86_64",
    "profile": "pixel_6",
    "system_image": "system-images;android-36;google_apis;x86_64",
    "cold_boot": "wipe-data/no-snapshot",
    "host_architecture": "arm64",
    "runtime": "cross-architecture software translation requested (-no-accel)",
    "emulator_version": "Android emulator version 36.3.10.0 (build_id 14472402) (CL:N/A)",
    "emulator_host_binary": {
      "architecture": "arm64"
    },
    "serial_redacted": "NOT_RUN",
    "boot_started_utc": "NOT_RUN",
    "boot_ready_utc": "NOT_RUN",
    "failure": "Bad state: Android Emulator exited before readiness (exit 1): FATAL        | Avd's CPU Architecture 'x86_64' is not supported by the QEMU2 emulator on aarch64 host. System image must match the host architecture.",
    "cross_architecture_attempts": [
      {
        "emulator_version": "37.1.11",
        "build": "15917651",
        "host_binary": "x86_64",
        "archive_sha1": "7df8b0acbe915217dcbb576222bddfcc23e81230",
        "official_url": "https://dl.google.com/android/repository/emulator-darwin_x64-15917651.zip",
        "result": "UNAVAILABLE: Rosetta QEMU child did not return from -version within the bounded diagnostic window; exact process terminated."
      },
      {
        "emulator_version": "36.3.10",
        "build": "14472402",
        "host_binary": "x86_64",
        "archive_sha256": "a01025b471a9ac0ef0fbd59febd0c1cfdeb2e889cc6fedc7ea881239bd8bb9a4",
        "official_url": "https://dl.google.com/android/repository/emulator-darwin_x64-14472402.zip",
        "result": "UNAVAILABLE: matching-version Rosetta QEMU child did not return from -version within the bounded diagnostic window; exact process terminated."
      }
    ],
    "cleanup": {
      "runner_owned_avd": "ABSENT",
      "adb_devices": "NONE",
      "diagnostic_archives_and_runtimes": "ABSENT",
      "diagnostic_processes": "ABSENT",
      "api36_x86_64_system_image": "INSTALLED_OUTSIDE_REPOSITORY"
    },
    "exit_condition": "Run the checked-in API 36 google_apis x86_64 device-e2e lane on an x86_64 Linux/Intel host against this exact source graph, import redacted per-file runtime evidence, and rerun the signed post-test release rescan."
  }
}
```
<!-- phase61-evidence-json:end -->

Compile, signed package, Emulator runtime, and physical-device evidence are separate result classes. No production key, credential, user data, device identifier, or raw local path belongs in this file.
