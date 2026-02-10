# Home Pocket (まもる家計簿) — Feasibility Report

**Date:** 2026-02-10
**Version:** 0.1.0 (Phase 1 — Infrastructure Layer)
**Codebase:** 78 source files, ~6,500 LOC | 45 test files, ~5,950 LOC

---

## 1. Executive Summary

Home Pocket is a local-first, privacy-focused family accounting app with a dual-ledger system, 4-layer encryption, and offline-first design. The project is in early Phase 1 with a solid architectural foundation. **The core infrastructure (crypto, database, data layer) is production-quality and well-tested.** The feature layer has working accounting, analytics, and a partial dual-ledger. Several planned capabilities (i18n, routing, sync, OCR) are not yet started.

**Overall feasibility: HIGH** — The foundations are sound, the architecture is well-designed, and the implemented code is high quality. The remaining work is execution, not design uncertainty.

---

## 2. Architecture Assessment

### 2.1 Clean Architecture Compliance: STRONG

The codebase correctly implements 5-layer Clean Architecture:

| Layer | Location | Status | Compliance |
|-------|----------|--------|------------|
| Infrastructure | `lib/infrastructure/` | Implemented | Correct — crypto, security outside features |
| Application | `lib/application/` | Implemented | Correct — use cases at root level |
| Data | `lib/data/` | Implemented | Correct — tables, DAOs, repos centralized |
| Domain | `lib/features/*/domain/` | Implemented | Correct — models + interfaces only |
| Presentation | `lib/features/*/presentation/` | Implemented | Correct — screens, widgets, providers |

The **"thin feature" pattern** is properly enforced: no feature directory contains `application/`, `infrastructure/`, or `data/` subdirectories. Dependency flow is strictly unidirectional (outer → inner).

### 2.2 Missing Architectural Components

| Component | Expected Location | Status | Impact |
|-----------|-------------------|--------|--------|
| GoRouter | `lib/core/router/` | Missing | Uses manual IndexedStack navigation |
| Theme | `lib/core/theme/` | Missing | Inline Material 3 theme in main.dart |
| App Config | `lib/core/config/` | Missing | Hardcoded values |
| i18n Infrastructure | `lib/infrastructure/i18n/` | Missing | No localization at all |
| ARB Files | `lib/l10n/` | Missing | Hardcoded English strings |
| ML/OCR | `lib/infrastructure/ml/` | Missing | Phase 4 feature |
| Sync | `lib/infrastructure/sync/` | Missing | Phase 3 feature |

The `lib/core/` directory does not exist. This is a gap relative to the architecture spec but does not block current functionality.

### 2.3 Code Generation Pipeline: CORRECT

- **Freezed** for immutable domain models (8 model classes)
- **Riverpod** code-gen for providers (`@riverpod`)
- **Drift** for type-safe database operations
- All generated files (`.g.dart`, `.freezed.dart`) are properly gitignored
- 29 generated files coexist correctly with 78 source files

---

## 3. Module Implementation Status

### Implemented Modules

**Module: MOD-006: Security & Privacy**
- **Completion:** ~80%
- **Assessment:** 4-layer encryption operational. Ed25519 keys, ChaCha20-Poly1305 field encryption, SQLCipher AES-256-CBC database, SHA-256 hash chain. Missing: photo encryption, recovery kit refactoring.

**Module: MOD-001: Basic Accounting**
- **Completion:** ~90%
- **Assessment:** Full CRUD for transactions, books, categories. Encrypted note fields. Soft-delete. Pagination.

**Module: MOD-007: Analytics & Reports**
- **Completion:** ~85%
- **Assessment:** Monthly reports, budget progress, expense trends, 8 chart widgets, analytics DAO with SQL aggregation.

**Module: MOD-003: Dual Ledger**
- **Completion:** ~70%
- **Assessment:** Rule engine (Layer 1) working. Classification service operational. Missing: merchant database (Layer 2), ML classifier (Layer 3).

### Not Started

| Module | Priority | Dependency |
|--------|----------|------------|
| **MOD-014: i18n** | Phase 1 | Blocks production release |
| **MOD-004: Family Sync** | Phase 3 | Requires CRDT, P2P networking |
| **MOD-005: OCR Scanning** | Phase 4 | Requires ML Kit, TFLite |
| **MOD-008: Settings** | Phase 3 | UI placeholder exists |

---

## 4. Security Analysis

### 4.1 Encryption Architecture: STRONG

| Layer | Algorithm | Config | Status |
|-------|-----------|--------|--------|
| L1: Database | AES-256-CBC (SQLCipher) | 256K PBKDF2 iterations | Implemented |
| L2: Fields | ChaCha20-Poly1305 AEAD | 96-bit random nonce | Implemented |
| L3: Files | AES-256-GCM | — | Planned (Phase 2) |
| L4: Transport | TLS 1.3 + E2EE | — | Planned (Phase 3) |

### 4.2 Key Management: CORRECT

- **Master key**: 256-bit random, stored in platform Keychain/KeyStore
- **Key derivation**: HKDF-SHA256 with purpose-binding (`field_encryption`, `database_encryption`)
- **Device keys**: Ed25519 key pairs with sign/verify
- **Key caching**: In-memory with explicit cache-clearing on logout
- **No hardcoded secrets** found anywhere in the codebase

### 4.3 Identified Issues

| Issue | Severity | Details |
|-------|----------|---------|
| Simplified hash formula | LOW | Current: 4 fields. Planned: 9 fields. Intentional MVP simplification. |
| Static HKDF salt | NONE | `homepocket-v1-2026` is appropriate for KDF context binding. |
| No sensitive data logging | NONE | Verified: no keys or plaintext logged. |

**Security posture: No vulnerabilities identified.**

---

## 5. Data Layer Analysis

### 5.1 Database Schema: COMPLETE

4 tables (Books, Categories, Transactions, AuditLogs) with proper:
- Foreign key relationships (bookId → Books, categoryId → Categories)
- 11 database indexes including 2 compound indexes for query optimization
- Hash chain fields (prevHash, currentHash) for integrity verification
- Soft-delete pattern for audit trail preservation
- Denormalized stats in Books table for performance

Schema version 3 with working migration strategy.

### 5.2 Repository Pattern: CORRECT

- 3 repository interfaces in domain layer (abstract only)
- 3 repository implementations in data layer
- 4 DAOs with comprehensive query methods
- TransactionRepositoryImpl handles automatic field encryption/decryption
- Proper `Future.wait()` for parallel decryption in batch reads

### 5.3 Performance Design

- Database-level SQL aggregation in AnalyticsDao (not in-memory)
- Compound indexes for multi-column queries
- Pagination support (limit/offset) in TransactionDao
- Incremental hash chain verification (100-2000x improvement)
- Denormalized balance counters avoid full-table scans

---

## 6. Code Quality Assessment

### 6.1 Metrics

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Source files | 78 | — | Reasonable |
| Source LOC | ~6,500 | — | Lean codebase |
| Test files | 45 | — | Good coverage breadth |
| Test LOC | ~5,950 | — | Nearly 1:1 test-to-source ratio |
| Max file length | ~130 lines | <800 | Well within limits |
| Max method length | ~30 lines | <50 | Within limits |

### 6.2 Strengths

- **Immutability**: All domain models use Freezed with `copyWith`
- **Single Responsibility**: Each file has one clear purpose
- **Naming**: Clear, descriptive names throughout
- **Error handling**: Custom exceptions (e.g., `MacValidationException`)
- **Provider organization**: repository_providers.dart as single source of truth
- **Test structure**: Mirrors source directory layout (unit/, widget/, infrastructure/)

### 6.3 Concerns

| Concern | Severity | Details |
|---------|----------|---------|
| `avoid_print: false` in analysis_options | LOW | Allows `print()` statements; should use `dev.log()` in production |
| No GoRouter | MEDIUM | Manual navigation limits deep linking, testing |
| Hardcoded strings in UI | MEDIUM | All user-facing text is English-only, no l10n |
| No `lib/core/` directory | LOW | Architectural spec not fully realized |
| Widget tests are shallow | LOW | Some tests verify rendering without provider integration |

---

## 7. Test Coverage Analysis

### 7.1 Test Distribution

| Category | Test Files | Coverage Area |
|----------|------------|---------------|
| Infrastructure (crypto) | 8 | Key management, encryption, hash chain, models |
| Infrastructure (security) | 5 | Audit logging, biometrics, secure storage |
| Application (use cases) | 11 | All accounting, analytics, dual-ledger use cases |
| Data (DAOs + repos) | 9 | All DAOs, all repositories, all tables |
| Domain (models) | 6 | All Freezed models |
| Shared (utils) | 2 | Result type, default categories |
| Widget tests | 4 | Transaction tile, dual ledger screen, celebration overlay |
| **Total** | **45** | |

### 7.2 Test Quality

The crypto infrastructure tests are the strongest — comprehensive round-trip testing, tamper detection, edge cases (empty strings, Unicode, negative amounts). Application use case tests use Mockito/Mocktail mocks correctly. Widget tests are relatively shallow (basic rendering checks).

**Estimated coverage**: The breadth is good (45 files covering all implemented modules), but actual line coverage would need `flutter test --coverage` to measure against the 80% target.

---

## 8. Feasibility Verdict

### 8.1 Technical Feasibility: HIGH

| Aspect | Rating | Rationale |
|--------|--------|-----------|
| Architecture | HIGH | Clean Architecture properly enforced, clear layer boundaries |
| Security | HIGH | Industry-standard algorithms, no vulnerabilities found |
| Data layer | HIGH | Complete schema, proper encryption, good performance design |
| Scalability | HIGH | Pagination, incremental verification, database aggregation |
| Maintainability | HIGH | Small files, single responsibility, comprehensive tests |
| Code generation | HIGH | Freezed + Riverpod + Drift pipeline working correctly |

### 8.2 Risks

**Risk:** P2P sync complexity (CRDT)
**Likelihood:** HIGH
**Impact:** HIGH
**Mitigation:** Well-documented spec exists; start with simple conflict resolution

**Risk:** ML classifier accuracy (<85%)
**Likelihood:** MEDIUM
**Impact:** MEDIUM
**Mitigation:** Rule engine provides reliable fallback

**Risk:** iOS build compatibility
**Likelihood:** LOW
**Impact:** MEDIUM
**Mitigation:** SQLCipher + ML Kit Podfile fixes documented

**Risk:** Performance at scale (100K+ txns)
**Likelihood:** LOW
**Impact:** MEDIUM
**Mitigation:** Incremental verification + pagination already designed

### 8.3 Gaps Before Production

**Must-Have (Phase 1 completion):**
1. **i18n infrastructure** (MOD-014) — All UI strings are hardcoded English
2. **GoRouter setup** — Current IndexedStack navigation won't scale
3. **AppInitializer in lib/core/** — Currently inline in main.dart
4. **Test coverage measurement** — Need to verify against 80% target

**Should-Have (Phase 2):**
1. Photo encryption service (Layer 3)
2. Recovery kit service refactoring to infrastructure
3. Full hash formula (9 fields)
4. Settings module UI

### 8.4 Recommendation

**Proceed with development.** The foundation is solid. Priority for next work:

1. Complete MOD-014 (i18n) — blocks all user-facing features
2. Add `lib/core/` infrastructure (router, theme, config, initialization)
3. Run `flutter test --coverage` and close gaps to 80%
4. Then advance to Phase 2 (MOD-001 completion, MOD-003 layers 2-3)
