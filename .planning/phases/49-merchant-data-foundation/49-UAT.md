---
status: testing
phase: 49-merchant-data-foundation
source: [49-VERIFICATION.md]
started: 2026-06-23T06:44:58Z
updated: 2026-06-23T06:44:58Z
---

## Current Test

number: 1
name: On-device encrypted migration ladder (Success Criterion #4 / MERCH-04 closure)
expected: |
  Boot an iOS simulator (or attach an Android device/emulator), then run:
  `flutter test integration_test/merchant_migration_ladder_test.dart`

  All 7 testWidgets pass. PRAGMA cipher_version is NON-EMPTY (SQLCipher loaded,
  not plain libsqlite3); PRAGMA index_list(merchants) and index_list(merchant_match_keys)
  non-empty on BOTH fresh-v22 and v21→v22 paths; ~391 merchant rows seeded; every
  categoryId resolves to a real L2 category; re-seed leaves row counts unchanged.
awaiting: user response

## Tests

### 1. On-device encrypted migration ladder
expected: |
  Boot an iOS simulator (or attach an Android device/emulator), then run
  `flutter test integration_test/merchant_migration_ladder_test.dart`. All 7
  testWidgets pass; PRAGMA cipher_version NON-EMPTY (SQLCipher loaded, not plain
  libsqlite3); index_list(merchants) + index_list(merchant_match_keys) non-empty on
  BOTH fresh-v22 and v21→v22; ~391 merchant rows seeded; every categoryId resolves
  to a real L2; re-seed leaves row counts unchanged.
why_human: |
  sqlcipher_flutter_libs natives only load on a booted device/simulator. Host
  `flutter test` links plain libsqlite3, which would mask any cipher-path regression.
  This is the documented 49-06 checkpoint:human-verify gate (Success Criterion #4).
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
