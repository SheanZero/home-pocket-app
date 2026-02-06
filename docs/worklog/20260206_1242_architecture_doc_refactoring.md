# Architecture Documentation Refactoring Based on ARCH-008 Standards

**Date:** 2026-02-06
**Time:** 12:42
**Task Type:** Documentation / Architecture Alignment
**Status:** Completed
**Related Module:** All (ARCH-001, ARCH-005, ARCH-007, ARCH-008, ARCH-009, MOD-001~005, MOD-009, MOD-014, CLAUDE.md)

---

## Overview

Refactored all architecture documentation to align with ARCH-008 Layer Clarification standards. This was a comprehensive 8-phase effort to fix layer placement errors, deduplicate capabilities, merge i18n docs, and ensure all code path examples are consistent with the "thin Feature" pattern and global Application layer.

---

## Completed Work

### Phase 1: ARCH-001 Complete Guide
- Updated architecture layer diagram to 5-layer structure
- Updated project directory structure to show thin Feature pattern
- Updated all Drift table path comments
- Updated domain model and use case paths

### Phase 2: ARCH-008 Layer Clarification
- Added Application Layer section with directory listing and examples
- Added Domain Layer v2.0 update (ONLY models + repo interfaces)
- Added Feature constraint rules (prohibited directories)
- Added aggregated capabilities list (16 capabilities)
- Updated decision tree and quick reference table

### Phase 3: MOD-001 BasicAccounting
- Replaced architecture diagram with 5-layer version
- Updated `domain/use_cases/` → `lib/application/accounting/`
- Updated shared constants paths

### Phase 4: MOD-002 DualLedger
- RuleEngine: `data/services/` → `lib/application/dual_ledger/`
- MerchantDatabase: `data/services/` → `lib/infrastructure/ml/`
- TFLiteClassifier: `data/services/` → `lib/infrastructure/ml/`
- ClassificationService: `domain/services/` → `lib/application/dual_ledger/`

### Phase 5: MOD-004 OCR
- Deleted `features/ocr/infrastructure/` references → components to correct global locations
- 12 path corrections (Use Cases, ImagePreprocessor, OCR services, ReceiptParser, etc.)

### Phase 6: MOD-005 Security
- Corrected architecture diagram (KeyManager etc. → Infrastructure layer)
- Drift tables → `lib/data/tables/`
- DeviceKeyPair, ChainVerificationResult → `lib/infrastructure/crypto/models/` (unique)

### Phase 7: i18n Docs Merge + Small Updates
- Deprecated MOD-009 with header pointing to MOD-014
- Updated MOD-014 as canonical i18n spec (v2.0)
- ARCH-007: Removed `lib/core/i18n/` directory, noted correct locations
- ARCH-009: Updated file references and component paths
- ARCH-005: Added reference to ARCH-002, updated Use Case and Repository paths
- ARCH-000 INDEX: Added MOD-009 deprecation note

### Phase 8: Update CLAUDE.md
- Updated Architecture directory structure (added `lib/application/`, expanded `lib/infrastructure/`)
- Updated Feature structure to "thin Feature" pattern
- Added "Thin Feature Rule" explanation
- Updated Capability Classification with Application layer section
- Updated Decision Rule to include all 5 layers
- Updated Dependency Rules diagram with explicit paths
- Updated Riverpod Provider section to reference `lib/application/`

---

## Verification Results

1. No `features/{feature}/infrastructure/` paths in active docs (only changelog notes)
2. MerchantDatabase, TFLiteClassifier only defined at `lib/infrastructure/ml/`
3. All Use Cases path to `lib/application/` (except MOD-003 FamilySync - out of scope)
4. Domain layer only has models and repository interfaces
5. DeviceKeyPair, ChainVerificationResult unique at `lib/infrastructure/crypto/models/`
6. i18n canonical doc is MOD-014, MOD-009 deprecated
7. CLAUDE.md matches architecture documentation

### Known Remaining Items (Out of Scope)
- MOD-003 FamilySync still has `domain/use_cases/` paths (not in plan scope)
- ARCH-000 INDEX still references old file naming style (01_MVP_Architecture_Design.md etc.)
- ADR documents were not in plan scope

---

## Files Modified

| File | Changes |
|------|---------|
| ARCH-001_Complete_Guide.md | v2.0: 5-layer structure, all paths updated |
| ARCH-005_Integration_Patterns.md | Repository ref to ARCH-002, path fixes |
| ARCH-007_Architecture_Diagram_I18N.md | i18n component locations corrected |
| ARCH-008_Layer_Clarification.md | v2.0: Application layer, capability list |
| ARCH-009_I18N_Update_Summary.md | Updated references and component paths |
| ARCH-000_INDEX.md | MOD-009 deprecation note |
| MOD-001_BasicAccounting.md | v2.0: thin Feature, global Application |
| MOD-002_DualLedger.md | v2.0: RuleEngine, MerchantDB, TFLite paths |
| MOD-004_OCR.md | v2.0: 12 path corrections |
| MOD-005_Security.md | Architecture diagram, table/model paths |
| MOD-009_Internationalization.md | Deprecated, header pointing to MOD-014 |
| MOD-014_i18n.md | v2.0: canonical i18n spec, merge note |
| CLAUDE.md | Architecture section overhauled |

**Total files modified:** 13

---

## Testing

- [x] Grep verification: no incorrect `features/{feature}/infrastructure/` paths
- [x] Grep verification: MerchantDatabase only at `lib/infrastructure/ml/`
- [x] Grep verification: Use Cases at `lib/application/`
- [x] Grep verification: MOD-014 is canonical i18n doc
- [x] CLAUDE.md references `lib/application/` correctly
- [ ] Manual review of all documents (recommended)

---

## Follow-up Work

- [ ] Update MOD-003 FamilySync with same path corrections
- [ ] Update ARCH-000 INDEX file references to match new naming convention
- [ ] Review ADR documents for path consistency
- [ ] Consider updating MOD-006/007/008 Analytics/Settings docs

---

**Created:** 2026-02-06 12:42
**Author:** Claude Opus 4.6
