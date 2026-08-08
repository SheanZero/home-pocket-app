---
phase: 59
plan: "01"
status: in_progress
redaction: required
---

# Phase 59 Plugin Acceptance Ledger

This ledger records decision evidence only. Do not add transcripts, recognized
speech, tokens, keys, database paths, device identifiers, financial values, or
production credentials.

## Official evidence

| queried_on | package | selected | candidate | decision | official source | result |
|---|---|---|---|---|---|---|
| 2026-08-09 | speech_to_text | 7.3.0 declared/resolved | 7.4.0 Stable; 7.5.0-beta.1 ineligible | hold | https://pub.dev/packages/speech_to_text | Stable candidate rechecked; no resolver change made. |

## Speech acceptance evidence

| commit | package | platform | destination | os | build_mode | command_result | scenario | automated result | physical-iPhone result | hold_reason | exit_condition |
|---|---|---|---|---|---|---|---|---|---|---|---|
| pending task commit | speech_to_text 7.3.0 | Dart | repository contract | n/a | test | `dependency_compatibility_contract_test.dart` | Manifest evidence and declaration/lock drift | pending targeted run | not applicable | None after automated result is recorded | Targeted contract must pass. |
| pending device evidence | speech_to_text 7.3.0 | iOS | physical iPhone | not recorded | supported build | unavailable | ja/zh/en permission, recognition, cancellation, error, and caller-controlled fallback | Adapter/corpus evidence is separate | unavailable — hold | A simulator, corpus, or resolver result is not physical-iPhone proof. | Run the named scenarios on a supported physical iPhone and record only redacted outcome metadata. |

## Decision rule

`speech_to_text` is accepted only when the centralized adapter, ja/zh/en corpus,
permission, recognition, cancellation, error, caller-controlled network
fallback, and physical-iPhone evidence are all complete. Until then, the exact
selected 7.3.0 graph remains a hold.
