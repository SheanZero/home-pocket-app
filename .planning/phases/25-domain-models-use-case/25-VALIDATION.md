---
phase: 25
slug: domain-models-use-case
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK) + mocktail ^1.0.4 |
| **Config file** | none — pubspec.yaml `flutter.test`, no separate config |
| **Quick run command** | `flutter test test/unit/application/list/ --no-pub` |
| **Full suite command** | `flutter test --no-pub` |
| **Estimated runtime** | ~3 seconds (quick) / full suite per project |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/application/list/ --no-pub`
- **After every plan wave:** Run `flutter test --no-pub && flutter analyze`
- **Before `/gsd:verify-work`:** Full suite green + `flutter analyze` reports 0 issues
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-VO   | model VOs | 1 | SC#2 | — | N/A | build | `flutter pub run build_runner build --delete-conflicting-outputs` | ❌ W0 | ⬜ pending |
| 25-VO   | model VOs | 1 | SC#2 | — | N/A | static | `flutter analyze lib/features/list/ lib/application/list/` | ❌ W0 | ⬜ pending |
| 25-VO   | model VOs | 1 | SC#4 / SORT-04 | — | N/A | unit | `flutter test test/unit/application/list/ --no-pub` | ❌ W0 | ⬜ pending |
| 25-UC   | use case | 2 | SC#3 (empty bookIds → Result.error, repo not called) | — | N/A | unit | `flutter test test/unit/application/list/get_list_transactions_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 25-UC   | use case | 2 | SC#3 (valid params forwarded to findByBookIds) | — | N/A | unit | same file | ❌ W0 | ⬜ pending |
| 25-UC   | use case | 2 | SORT-01 (timestamp forwarded) | — | N/A | unit | same file | ❌ W0 | ⬜ pending |
| 25-UC   | use case | 2 | SORT-02 (default updatedAt + desc) | — | N/A | unit | same file | ❌ W0 | ⬜ pending |
| 25-UC   | use case | 2 | SORT-03 (amount forwarded) | — | N/A | unit | same file | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/application/list/get_list_transactions_use_case_test.dart` — covers SC#3, SC#4, SORT-01..04 forwarding (Mocktail mock of `TransactionRepository`)
- [ ] `lib/features/list/domain/models/list_sort_config.dart` (+ generated `.freezed.dart`)
- [ ] `lib/features/list/domain/models/list_filter_state.dart` (+ generated `.freezed.dart`)
- [ ] `lib/application/list/get_list_transactions_use_case.dart` (new `lib/application/list/` directory)
- [ ] `lib/features/list/domain/import_guard.yaml` + `lib/features/list/domain/models/import_guard.yaml` (new `list` feature — none exist yet)

*Test stubs and source files do not exist yet — all are Wave 0 creations.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `build_runner` generates `.freezed.dart` without errors | SC#2 | Code generation is a build step, not a runtime assertion | Run `flutter pub run build_runner build --delete-conflicting-outputs`; confirm exit 0 and generated files present |
| `flutter analyze` reports zero issues on new files | SC#2 | Static analysis gate, not a unit test | Run `flutter analyze lib/features/list/ lib/application/list/`; confirm "No issues found" |

*All behavioral logic (sort forwarding, empty-bookIds Result.error, copyWith immutability) has automated unit coverage.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
