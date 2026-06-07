---
phase: 36
slug: data-layer-domain-import-guard
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-07
---

# Phase 36 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register authored at plan time (all 7 PLANs carried `<threat_model>` blocks).
> First audit (State B — no prior SECURITY.md). Verdict: **SECURED — 15/15 resolved.**

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| client app → SQLite/SQLCipher | User data written to encrypted DB; CHECK constraints enforce allowed values | `list_type`, `ledger_type`, `note`, `tags` |
| `listType` parameter → SQL WHERE clause | Parameterized via `Variable.withString` — never string interpolation | user-supplied segment selector |
| `ShoppingItem.note` (plaintext) → `ShoppingItemRow.note` (ciphertext) | Encryption enforced at repository boundary; never stored plaintext | sensitive note text |
| `ShoppingItemRow.tags` (JSON) → `ShoppingItem.tags` (List<String>) | JSON decode with try/catch prevents malformed data crashing the stream | tag list |
| decrypt failure → `note = null` | Silent failure prevents ciphertext leakage via logs | failed-decrypt path |
| shopping_list/domain → data/infrastructure | `import_guard.yaml` deny rules prevent domain importing DAO/table/infra types | layer dependency |
| shopping_list/presentation → data/daos + data/tables | Presentation deny rules prevent direct DAO/table access from UI | layer dependency |
| cross-feature LedgerType import | Explicitly allow-listed (auditable intentional dependency), not silently permitted | type import |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-36-01 | Tampering | `list_type` column | mitigate | `CHECK(list_type IN ('public','private'))` — `shopping_items_table.dart:59` | closed |
| T-36-02 | Tampering | `ledger_type` column | mitigate | `CHECK(ledger_type IN ('daily','joy') OR ledger_type IS NULL)` — `shopping_items_table.dart:61` | closed |
| T-36-03 | Information Disclosure | `note` column plaintext at rest | mitigate | Nullable schema `shopping_items_table.dart:26`; encryption at repo boundary `shopping_item_repository_impl.dart:32,61,114,147,171` | closed |
| T-36-04 | Tampering | migration slot collision | mitigate | `schemaVersion => 20` (`app_database.dart:47`); `if (from < 20)` (`:433`); index emission onCreate+onUpgrade `_createShoppingItemIndexes()` (`:450-471`, CR-01); contract test asserts `equals(20)` | closed |
| T-36-05 | Tampering | layer boundary enforcement | mitigate | Deny rules `domain/import_guard.yaml:3-8`, `presentation/import_guard.yaml:8-12`; gate active via `custom_lint` (`analysis_options.yaml:10`) + `import_guard_custom_lint` (`pubspec.yaml:95`) | closed |
| T-36-06 | Information Disclosure | `LedgerTypeSelector` shared/ placement | accept | Pure StatelessWidget, zero accounting state — see Accepted Risks | closed |
| T-36-07 | Information Disclosure | domain model `note` plaintext | accept | Domain holds decrypted plaintext by design; repo stores ciphertext — see Accepted Risks | closed |
| T-36-08 | Tampering | cross-feature LedgerType import | mitigate | Allow-list `domain/models/import_guard.yaml:7` matches import `shopping_item.dart:2`; enforced by `custom_lint` | closed |
| T-36-09 | Tampering | SQL injection in watchByListType | mitigate | `Variable.withString(listType)` (`shopping_item_dao.dart:82`) with `?` placeholder (`:80`) — no interpolation | closed |
| T-36-10 | Information Disclosure | reactive stream leaks private items | mitigate | `WHERE list_type = ? AND is_deleted = 0` parameterized filter at DAO (`shopping_item_dao.dart:80`) | closed |
| T-36-11 | Information Disclosure | `note` plaintext at rest | mitigate | `encryptField` on all 3 writes (insert `:32`, update `:61`, upsert `:114`); `decryptField` on read `:171`; silent catch `:172-175` | closed |
| T-36-12 | Tampering | tags JSON injection | mitigate | `jsonEncode(tags)` (`:157`); decode wrapped in try/catch returning `[]` (`:181-185`) | closed |
| T-36-13 | Information Disclosure | decrypt failure leaks `note` | mitigate | `catch (_) { decryptedNote = null; }` (`:172-175`) — no `e.toString()`/`debugPrint`/`print` | closed |
| T-36-14 | Tampering | documentation inconsistency (D7 vs D-03) | mitigate | Stale text absent in `REQUIREMENTS.md` (grep → 0 matches); D-03 override present (`:15,:63,:167`) | closed |
| T-36-SC | Tampering | dependency installs | accept | No new packages this phase — see Accepted Risks | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-36-01 | T-36-06 | `LedgerTypeSelector` is a pure `StatelessWidget` taking only `selected` (LedgerType), `onChanged`, and label strings — no provider reads, no DB/repo access, no accounting-specific state. Placement in `lib/shared/` is correct and leaks no accounting state. | gsd-security-auditor (verified) | 2026-06-07 |
| AR-36-02 | T-36-07 | By layered-encryption design the domain layer holds decrypted plaintext (`note: String?`); ciphertext exists only at the repository impl boundary, which encrypts before persist and decrypts on read. Layered model intact. | gsd-security-auditor (verified) | 2026-06-07 |
| AR-36-03 | T-36-SC | No new packages added in Phase 36; `custom_lint` / `import_guard_custom_lint` were pre-existing. No supply-chain surface introduced. | gsd-security-auditor (verified) | 2026-06-07 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-07 | 15 | 15 | 0 | gsd-security-auditor (State B, first audit) |

### Audit Notes
- All 12 `mitigate` threats verified by locating the actual mitigation call/constraint at the cited line — not by code-structure inference. T-36-11 confirmed `encryptField` present on **all three** write entry points (insert, update, upsert).
- 3 `accept` threats: rationale verified against the implementation rather than taken on faith.
- **Unregistered flags:** none. All SUMMARY 01–07 `## Threat Flags` entries either report "None" or map to registered IDs (36-06 table → T-36-11/12/13; 36-07 docs-only).
- **Implementation gaps:** none. No implementation files modified during the audit.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-07
