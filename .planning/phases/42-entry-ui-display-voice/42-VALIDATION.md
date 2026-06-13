---
phase: 42
slug: entry-ui-display-voice
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from 42-RESEARCH.md "## Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + project golden workflow (macOS-baselined; CI ubuntu uses `BaselineExistenceGoldenComparator`) |
| **Config file** | `flutter_test_config.dart` (swaps in `BaselineExistenceGoldenComparator` off-macOS) |
| **Quick run command** | `flutter test test/<targeted_path>` |
| **Full suite command** | `flutter test` (MUST run full suite per wave-merge — scoped tests miss architecture tests like `hardcoded_cjk_ui_scan`, MEMORY Phase 38) |
| **Estimated runtime** | full suite ~minutes; targeted ~seconds |
| **Scope helper** | `test/helpers/test_provider_scope.dart` (`waitForFirstValue`, `ProviderContainer.test()`) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/<area>` for the touched files
- **After every plan wave:** Run **full** `flutter test` (architecture/CJK scan tests are not scoped — MEMORY Phase 38)
- **Before `/gsd-verify-work`:** Full suite green; JPY goldens byte-identical; new goldens macOS-baselined
- **Max feedback latency:** targeted < ~30s; full suite per wave-merge

---

## Per-Task Verification Map

> Task IDs assigned by the planner. The Requirement→Test mapping below is fixed by research; executors bind each row to the concrete task that produces it.

| Requirement | Behavior | Test Type | Automated Command | File Exists |
|-------------|----------|-----------|-------------------|-------------|
| SC-5 / CURR-05 | USD 50 @ 148.30 → `amount=7415`, `original_currency='USD'` (integration smoke) | integration | `flutter test test/application/accounting/create_transaction_currency_test.dart` | ❌ W0 |
| Update plumbing | edited foreign row recomputes JPY + persists triple, no rehash (ADR-021) | unit | `flutter test test/application/accounting/update_transaction_currency_test.dart` | ❌ W0 |
| CURR-04 | JPY entry/list/detail goldens byte-identical (regression) | golden | `flutter test test/golden/` (JPY subset must stay green) | partial (existing) |
| CURR-05 / D-07 / D-08 | decimal cap + truncation on currency switch (`50.50→50`, `50.567→50.56`) | unit | `flutter test test/.../amount_input_controller_test.dart` | ❌ W0 |
| CURR-05 / D-06 | dot key hidden/replaced for JPY/KRW, 48dp preserved | golden + widget | `flutter test test/.../smart_keyboard_dot_gating_test.dart` | ❌ W0 |
| DISP-01 / D-05 | preview rate sub-row + staleness warning (fallback / actualDate≠txDate) | golden + widget | `flutter test test/.../conversion_preview_test.dart` | ❌ W0 |
| DISP-02 | foreign list row shows `USD 50.00`; JPY row unchanged | golden | `flutter test test/golden/list_transaction_tile_*` | ❌ W0 (foreign variant) |
| DISP-04 / D-10 | edit host: JPY read-only derived recalcs on original/rate change; no bidirectional loop | widget | `flutter test test/.../edit_currency_linked_test.dart` | ❌ W0 |
| D-13 / ADR-022 D-02 | manual-override + date change → two-choice dialog (no default) | widget | same edit test file | ❌ W0 |
| D-13 / ADR-022 D-03 | no-override + >1% JPY change → non-blocking toast + undo restores old rate (5s) | widget | same edit test file | ❌ W0 |
| VOICE-CUR-01/02/03 | per-currency × per-locale corpus ≥5 cases (zh: 美元/欧元/英镑/港币/澳元/加元; ja: ドル/ユーロ/ポンド/香港ドル/豪ドル); bare 元/円/ドル defaults; 元/円 ambiguity zh=CNY/ja=JPY | unit | `flutter test test/infrastructure/voice/currency_detection_test.dart` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/application/accounting/create_transaction_currency_test.dart` — SC-5 USD 50@148.30→7415 integration smoke
- [ ] `test/application/accounting/update_transaction_currency_test.dart` — edited triple recompute + no-rehash (ADR-021)
- [ ] `test/.../amount_input_controller_test.dart` — D-07 cap + D-08 truncation boundaries
- [ ] `test/infrastructure/voice/currency_detection_test.dart` — per-currency×per-locale corpus + bare-token defaults + 元/円 ambiguity
- [ ] `test/.../edit_currency_linked_test.dart` — ADR-022 D-01/D-02/D-03
- [ ] New goldens (macOS baseline): `CurrencySelectorSheet`; preview panel (loading/loaded/fallback/weekend); edit three-row; foreign list row; dot-gated keyboard (JPY vs USD)
- [ ] Flag-cell golden isolation strategy (mask flag emoji to avoid cross-platform AA divergence)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Flag emoji visual fidelity on real iOS/Android | CURR-01 / D-01 | Emoji glyphs render per-OS; goldens mask flags | Run on a physical iOS + Android device; confirm flag/region-fallback legibility in `CurrencySelectorSheet` |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] JPY-path regression goldens byte-identical
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
