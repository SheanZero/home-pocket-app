# Deferred Items

## 2026-08-09 — current-schema SQLCipher Simulator lifecycle

`integration_test/sqlcipher_native_assets_lifecycle_test.dart` could not execute because the existing iOS build failed before test launch with unresolved Flutter linker symbols, after which CoreSimulator was unavailable. This is outside the Phase 60 scope-correction change set: no native project, dependency graph, or production SQLCipher code was modified. Re-run the checked-in native safety runner after the iOS linking environment is repaired; do not record a runtime pass until it emits `RUNTIME_PASS`.
