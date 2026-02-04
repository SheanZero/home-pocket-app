# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Home Pocket (まもる家計簿)** is a local-first, privacy-focused family accounting app with a dual-ledger system. The app uses zero-knowledge architecture with 4-layer encryption, P2P family sync, and offline-first design.

**Current Phase:** Phase 1 - Infrastructure Layer (v0.1.0)
**Target:** iOS 14+ / Android 7+ (API 24+)

---

## Essential Commands

### Development Setup
```bash
# Install dependencies
flutter pub get

# Code generation (Riverpod, Freezed, Drift)
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n

# Watch mode for continuous code generation
flutter pub run build_runner watch
```

### Development
```bash
# Run app
flutter run

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

### Code Quality
```bash
# Static analysis
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

**Coverage Requirement:** ≥80%

---

## Architecture

### Clean Architecture (5 Layers)

The codebase follows strict Clean Architecture with dependency rules:

```
lib/
├── infrastructure/       # Project-wide infrastructure
│   └── crypto/          # Cryptographic primitives (MANDATORY)
│       ├── services/    # Key management, encryption, hash chain
│       ├── repositories/ # Crypto repository interfaces & implementations
│       ├── models/      # Crypto domain models
│       └── database/    # Database encryption setup
│
├── features/              # Feature modules (domain-driven)
│   └── {feature}/
│       ├── presentation/  # UI layer (screens, widgets, providers)
│       ├── application/   # Business logic (use cases, services)
│       ├── domain/        # Core entities & repository interfaces
│       └── data/          # Data access (repositories, DAOs, DTOs)
│
├── core/                  # Cross-cutting concerns
│   ├── config/           # App configuration
│   ├── constants/        # Global constants
│   ├── router/           # GoRouter navigation
│   └── theme/            # Material 3 theme
│
├── shared/               # Reusable components
│   ├── widgets/         # Common UI components
│   ├── extensions/      # Dart extensions
│   └── utils/           # Utility functions
│
└── l10n/                # Internationalization (ja, zh, en)
```

### Dependency Rules

**CRITICAL:** Outer layers depend on inner layers, never the reverse:

```
Presentation → Application → Domain ← Data
                                      ↓
                              Infrastructure
```

- **Domain layer** is completely independent (no external dependencies)
- **Data layer** implements domain repository interfaces
- **Application layer** orchestrates business logic using domain entities
- **Presentation layer** consumes application providers, no direct data access

### Key Architectural Patterns

1. **State Management:** Riverpod 2.4+ with code generation (`@riverpod`)
2. **Data Models:** Freezed for immutability (`@freezed`)
3. **Database:** Drift with SQLCipher (type-safe SQL with encryption)
4. **Routing:** GoRouter with declarative routes
5. **Localization:** flutter_localizations with ARB files

---

## Code Generation

This project heavily uses code generation. **Always run build_runner after:**
- Creating/modifying `@riverpod` providers
- Creating/modifying `@freezed` models
- Creating/modifying Drift tables
- Adding new ARB localization strings

Generated files (`.g.dart`, `.freezed.dart`) are gitignored.

---

## Security Architecture

**4-Layer Encryption:**
1. **Layer 1:** Database encryption (SQLCipher AES-256-CBC, 256k PBKDF2)
2. **Layer 2:** Field encryption (ChaCha20-Poly1305 AEAD)
3. **Layer 3:** File encryption (AES-256-GCM for photos)
4. **Layer 4:** Transport encryption (TLS 1.3 + E2EE for P2P sync)

**Key Management:**
- Ed25519 device key pairs
- BIP39 24-word recovery phrase
- HKDF key derivation with caching
- Biometric lock (Face ID/Touch ID/Fingerprint)

**Integrity Protection:**
- Blockchain-style hash chain
- Incremental verification (100-2000x performance improvement)
- Tamper detection

---

## Crypto Infrastructure Usage Rules (MANDATORY)

**CRITICAL:** All cryptographic operations MUST use the centralized infrastructure in `lib/infrastructure/crypto/`. DO NOT implement custom crypto solutions.

### Mandatory Usage Rules

1. **Key Management:**
   - ✅ MUST use `lib/infrastructure/crypto/services/key_manager.dart`
   - ❌ NEVER implement custom key generation or storage
   - ❌ NEVER access flutter_secure_storage directly for keys

2. **Field Encryption:**
   - ✅ MUST use `lib/infrastructure/crypto/services/field_encryption_service.dart`
   - ❌ NEVER use cryptography packages directly
   - ✅ MUST encrypt all sensitive fields: amounts, notes, merchant names

3. **Transaction Integrity:**
   - ✅ MUST use `lib/infrastructure/crypto/services/hash_chain_service.dart`
   - ❌ NEVER implement custom hash chain logic
   - ✅ MUST include hash in all transaction records

4. **Database Encryption:**
   - ✅ MUST use `lib/infrastructure/crypto/database/createEncryptedExecutor`
   - ❌ NEVER create database connections without encryption

5. **Security Principles:**
   - ❌ NEVER store encryption keys in plain text
   - ❌ NEVER log sensitive data (keys, plaintext amounts)
   - ❌ NEVER bypass encryption for "convenience"
   - ✅ ALWAYS clear crypto caches on logout

### Usage Examples

**Key Management:**
```dart
@riverpod
Future<void> initializeApp(InitializeAppRef ref) async {
  final keyManager = ref.read(keyManagerProvider);

  if (!await keyManager.hasKeyPair()) {
    await keyManager.generateDeviceKeyPair();
  }
}
```

**Field Encryption:**
```dart
@riverpod
class TransactionRepository {
  Future<void> saveTransaction(Transaction tx) async {
    final encryptionService = ref.read(fieldEncryptionServiceProvider);

    final encryptedAmount = await encryptionService.encryptAmount(tx.amount);
    final encryptedNote = await encryptionService.encryptField(tx.note);

    // Save encrypted data...
  }
}
```

**Hash Chain:**
```dart
@riverpod
class TransactionService {
  Future<String> calculateHash(Transaction tx, String prevHash) async {
    final hashChain = ref.read(hashChainServiceProvider);

    return hashChain.calculateTransactionHash(
      transactionId: tx.id,
      amount: tx.amount,
      timestamp: tx.timestamp,
      previousHash: prevHash,
    );
  }
}
```

**Database Encryption:**
```dart
@riverpod
Future<AppDatabase> appDatabase(AppDatabaseRef ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  final executor = await createEncryptedExecutor(keyManager);
  return AppDatabase(executor);
}
```

---

## Module Development Priority

Follow the development plan in `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`:

**Phase 1 (Weeks 1-2): Infrastructure**
- MOD-006: Security & Privacy (10 days) - **START HERE**
- MOD-014: Internationalization (4 days)

**Phase 2 (Weeks 3-5): Core Accounting**
- MOD-001: Basic Accounting (13 days)
- MOD-003: Dual Ledger (8 days)

**Phase 3 (Weeks 6-9): Sync & Analytics**
- MOD-004: Family Sync (12 days)
- MOD-007: Analytics & Reports (8 days)
- MOD-008: Settings Management (6 days)

**Phase 4 (Weeks 10-12): Enhanced Features**
- MOD-005: OCR Scanning (7 days)
- MOD-013: Gamification (optional)

---

## Architecture Documentation

**IMPORTANT:** All architecture decisions are documented in `doc/arch/`:

### Directory Structure
```
doc/arch/
├── 01-core-architecture/    # ARCH-000 to ARCH-009 (10 docs)
├── 02-module-specs/          # MOD-001 to MOD-009 (9 module specs)
└── 03-adr/                   # Architecture Decision Records
```

### Adding New Architecture Docs

**MUST follow this workflow:**

1. **Check existing files** to find max number:
   ```bash
   ls -1 doc/arch/01-core-architecture/ARCH-*.md | sort | tail -1
   ls -1 doc/arch/02-module-specs/MOD-*.md | sort | tail -1
   ls -1 doc/arch/03-adr/ADR-*.md | sort | tail -1
   ```

2. **Use next sequential number** (e.g., if max is ARCH-009, use ARCH-010)

3. **Naming conventions:**
   - Architecture: `ARCH-{NNN}_{PascalCase_Name}.md`
   - Modules: `MOD-{NNN}_{PascalCase_Name}.md`
   - ADRs: `ADR-{NNN}_{PascalCase_Name}.md`

4. **Update corresponding INDEX.md** file

**Never:** Skip numbers, reuse numbers, or create files without checking existing numbers.

---

## Dual Ledger System

The core concept that differentiates this app:

**Survival Ledger (生存账本):**
- Daily necessities (food, housing, transport)
- Category: "Survival"
- Visual: Green theme

**Soul Ledger (灵魂账本):**
- Self-investment and enjoyment (hobbies, entertainment, education)
- Category: "Soul"
- Visual: Purple theme with celebration animation

**3-Layer Classification Engine:**
1. Rule Engine (keyword matching)
2. Merchant Database (500+ Japanese merchants)
3. ML Classifier (TensorFlow Lite, 85%+ accuracy)

---

## Testing Strategy

**TDD Methodology (MANDATORY):**
1. Write test first (RED)
2. Run test - should fail
3. Write minimal implementation (GREEN)
4. Run test - should pass
5. Refactor (IMPROVE)
6. Verify 80%+ coverage

**Test Types:**
- Unit tests: Business logic, utilities, repositories
- Widget tests: UI components
- Integration tests: E2E user flows, database operations, encryption

**Test Location:**
```
test/
├── unit/           # Business logic tests
├── widget/         # UI component tests
└── integration/    # Integration tests

integration_test/   # E2E tests
```

---

## Localization

**Supported Languages:** Japanese (default), Chinese, English

**ARB Files:** `lib/l10n/app_{ja,zh,en}.arb`

**Generated Class:** `S` (from `lib/generated/app_localizations.dart`)

**Usage:**
```dart
import 'package:home_pocket/generated/app_localizations.dart';

Text(S.of(context).appName)
```

**After modifying ARB files:** Run `flutter gen-l10n`

---

## Performance Optimizations

Critical performance targets from architecture decisions:

1. **Incremental Balance Updates:** 40-400x improvement vs full recalculation (ADR-008)
2. **Incremental Hash Chain Verification:** 100-2000x improvement vs full chain (ADR-009)
3. **Pagination:** 50-100 items per page
4. **Fast Entry:** <3 seconds to complete transaction entry
5. **UI Smoothness:** 60 FPS scrolling

---

## Immutability Requirement

**CRITICAL:** All data operations must use immutable patterns.

**WRONG:**
```dart
void updateUser(User user, String name) {
  user.name = name;  // MUTATION!
}
```

**CORRECT:**
```dart
User updateUser(User user, String name) {
  return user.copyWith(name: name);  // Freezed copyWith
}
```

Use Freezed's `copyWith` for all state updates.

---

## Git Workflow

**Commit Format:**
```
<type>: <description>

<optional body>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Types:** feat, fix, refactor, docs, test, chore

**Branches:**
- `main`: Stable branch
- `feature/MOD-XXX-description`: Feature branches

---

## Key References

- **Architecture Guide:** `doc/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- **Data Architecture:** `doc/arch/01-core-architecture/ARCH-002_Data_Architecture.md`
- **Security Architecture:** `doc/arch/01-core-architecture/ARCH-003_Security_Architecture.md`
- **State Management:** `doc/arch/01-core-architecture/ARCH-004_State_Management.md`
- **Development Plan:** `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`
- **Project Structure:** `FLUTTER_PROJECT_STRUCTURE.md`
- **Quick Start:** `QUICKSTART.md`

---

## iOS Build Configuration

**IMPORTANT:** The project uses SQLCipher for encryption, not regular SQLite3.

**Dependencies:**
- ✅ `sqlcipher_flutter_libs` (for encrypted database)
- ❌ `sqlite3_flutter_libs` (DO NOT use - conflicts with SQLCipher)

**Podfile Configuration:**
The `ios/Podfile` includes a fix for ML Kit simulator builds:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Fix for ML Kit simulator build issue
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

**Troubleshooting iOS Build:**

If you encounter "different definitions in different modules" error:
```bash
flutter clean
cd ios && rm -rf Pods Podfile.lock .symlinks
cd .. && flutter pub get
cd ios && pod install
```

If you encounter "linking in object file built for iOS" (simulator issue):
- Verify `ios/Podfile` has EXCLUDED_ARCHS fix (see above)
- Run `cd ios && pod install && cd ..`

---

## Common Pitfalls

1. **Don't modify generated files** (`.g.dart`, `.freezed.dart`)
2. **Don't violate layer dependencies** (e.g., Domain importing Data)
3. **Don't skip code generation** after modifying annotated classes
4. **Don't mutate objects** - always use `copyWith`
5. **Don't add architecture docs without checking max number first**
6. **Don't forget to update INDEX.md** when adding new architecture docs
7. **Don't use `intl` version other than 0.20.2** (pinned by flutter_localizations)
8. **Don't add `sqlite3_flutter_libs`** - use only `sqlcipher_flutter_libs` (conflicts!)
9. **Don't modify `ios/Podfile` post_install** without preserving EXCLUDED_ARCHS fix

---

**Project Status:** 🟢 Ready for Development (Phase 1: MOD-006 Security Module)
