---
phase: quick-260518-kyr
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/home/presentation/screens/main_shell_screen.dart
autonomous: true
requirements:
  - fix-soul-stats-refresh
  - fix-monthly-favorite-refresh
  - fix-sync-listener-parity

must_haves:
  truths:
    - "FAB onFabTap callback in MainShellScreen invalidates all four home providers: monthlyReportProvider, todayTransactionsProvider, happinessReportProvider, bestJoyMomentProvider"
    - "sync listener block (syncStatusStreamProvider ref.listen) invalidates all four providers on syncing→synced transition, matching FAB parity"
    - "happinessReportProvider invalidation uses currencyCode resolved from ref.read(bookByIdProvider(bookId: bookId)).value?.currency ?? 'JPY' — identical fallback to home_screen.dart:95–96"
    - "flutter analyze reports 0 issues after the change"
    - "No build_runner run needed — no @riverpod/@freezed annotations touched"
  artifacts:
    - path: "lib/features/home/presentation/screens/main_shell_screen.dart"
      provides: "Fixed FAB invalidation block (lines ~100–108) and sync listener invalidation block (lines ~44–58)"
      contains: "happinessReportProvider"
  key_links:
    - from: "main_shell_screen.dart onFabTap"
      to: "happinessReportProvider / bestJoyMomentProvider"
      via: "ref.invalidate"
      pattern: "ref\\.invalidate.*happinessReport"
    - from: "main_shell_screen.dart syncStatusStreamProvider listener"
      to: "happinessReportProvider / bestJoyMomentProvider"
      via: "ref.invalidate"
      pattern: "ref\\.invalidate.*bestJoyMoment"
---

<objective>
Fix 悦己统计 (soul stats) and 本月最爱 (monthly favorite) widgets on the home screen not
refreshing after a new soul-ledger transaction is created via the FAB, or after a sync
completes. The bug is a provider invalidation omission in MainShellScreen — two of the four
FutureProviders that HomeScreen watches are never invalidated.

Purpose: Align the FAB callback and sync listener to invalidate all four home-screen
providers consistently, matching the already-working pattern for monthlyReportProvider.

Output: A single modified Dart file. No code generation required.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/Users/xinz/Development/home-pocket-app/.planning/quick/260518-kyr-fix-soul-stats-and-monthly-favorite-not-/260518-kyr-RESEARCH.md
@/Users/xinz/Development/home-pocket-app/CLAUDE.md

<root_cause>
All three home-screen aggregate widgets use identical FutureProvider patterns (one-shot
customSelect queries — no reactive Drift streams). They only re-execute when their cached
result is explicitly invalidated via ref.invalidate().

The FAB callback (main_shell_screen.dart:93–109) calls ref.invalidate() on only 2 of 4
providers after push() resolves:
  ✓ monthlyReportProvider  — invalidated  (drives 総支出)
  ✓ todayTransactionsProvider — invalidated
  ✗ happinessReportProvider — NOT invalidated  (drives 悦己统计)
  ✗ bestJoyMomentProvider   — NOT invalidated  (drives 本月最爱)

The sync listener (main_shell_screen.dart:33–58) has the identical omission.

happinessReportProvider is a 4-arg family: (bookId, year, month, currencyCode). The
currencyCode must match what HomeScreen used when it originally built the provider family
instance. HomeScreen resolves it as:
  ref.read(bookByIdProvider(bookId: bookId)).value?.currency ?? 'JPY'
  (home_screen.dart:95–96)

The fix uses that same read pattern inside MainShellScreen at invalidation time.
</root_cause>

<interfaces>
From lib/features/analytics/presentation/providers/state_happiness.dart:
  happinessReportProvider(bookId, year, month, currencyCode)  -- 4-arg family
  bestJoyMomentProvider(bookId, year, month)                  -- 3-arg family

From lib/features/analytics/presentation/providers/state_analytics.dart (already imported
in main_shell_screen.dart via state_analytics.dart):
  monthlyReportProvider(bookId, year, month)

From lib/features/home/presentation/providers/state_today_transactions.dart (already imported):
  todayTransactionsProvider(bookId)

bookByIdProvider lives in:
  lib/features/accounting/presentation/providers/repository_providers.dart

Confirmed import paths (same base dir as main_shell_screen.dart = lib/features/home/presentation/screens/):
  import '../../../../features/accounting/presentation/providers/repository_providers.dart';
  import '../../../../features/analytics/presentation/providers/state_happiness.dart';

Both paths confirmed from home_screen.dart (same directory), lines 12 and 15.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add missing provider invalidations to FAB callback and sync listener</name>
  <files>lib/features/home/presentation/screens/main_shell_screen.dart</files>
  <action>
Edit main_shell_screen.dart to fix both omission sites.

**Step 1 — Add two imports** (the file does not currently have these; add them after the
existing imports, sorted alphabetically with the other package imports):

  import '../../../../features/accounting/presentation/providers/repository_providers.dart';
  import '../../../../features/analytics/presentation/providers/state_happiness.dart';

These paths are confirmed from home_screen.dart (same directory: lib/features/home/presentation/screens/).

**Step 2 — Site 1: FAB onFabTap callback** (currently lines 100–108).

The existing block ends at `ref.invalidate(todayTransactionsProvider(bookId: bookId));`
on line 108, before the closing `}` of onFabTap. Insert AFTER that line:

  final book = ref.read(bookByIdProvider(bookId: bookId)).value;
  final currencyCode = book?.currency ?? 'JPY';
  ref.invalidate(
    happinessReportProvider(
      bookId: bookId,
      year: now.year,
      month: now.month,
      currencyCode: currencyCode,
    ),
  );
  ref.invalidate(
    bestJoyMomentProvider(bookId: bookId, year: now.year, month: now.month),
  );

The `now` variable is already declared above at line 100 — do not redeclare it.

**Step 3 — Site 2: sync listener block** (currently lines 44–57, inside the
`if (wasSyncing && nowDone)` guard). The existing block ends at:

  ref.invalidate(
    shadowAggregateProvider(year: now.year, month: now.month),
  );

Insert AFTER that block, before the closing `}` of the if-guard:

  final book = ref.read(bookByIdProvider(bookId: bookId)).value;
  final currencyCode = book?.currency ?? 'JPY';
  ref.invalidate(
    happinessReportProvider(
      bookId: bookId,
      year: now.year,
      month: now.month,
      currencyCode: currencyCode,
    ),
  );
  ref.invalidate(
    bestJoyMomentProvider(bookId: bookId, year: now.year, month: now.month),
  );

The `now` variable is already declared above at line 45 in the sync block — do not redeclare it.

**Rules:**
- Use ref.invalidate — NOT ref.refresh (RESEARCH.md Section 7 pitfall)
- Use .value (nullable) NOT .valueOrNull (removed in Riverpod 3 per CLAUDE.md)
- Do NOT mutate shared state
- Preserve all existing code; only insert the new lines and imports
- Do NOT add @riverpod annotations or any build_runner-triggering changes
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze lib/features/home/presentation/screens/main_shell_screen.dart 2>&1 | grep -E "error|warning|info|No issues"</automated>
  </verify>
  <done>
Both ref.invalidate blocks contain all four home-screen providers. happinessReportProvider
invalidation uses currencyCode resolved from bookByIdProvider with ?? 'JPY' fallback.
flutter analyze on the modified file reports 0 issues.
  </done>
</task>

<task type="auto">
  <name>Task 2: Full-project analyze and document manual test steps</name>
  <files></files>
  <action>
Run flutter analyze on the full project to confirm 0 issues project-wide (CLAUDE.md hard rule).

If analyze reports issues in main_shell_screen.dart, fix them:
- Unused import → remove that import
- Wrong symbol name → grep for the exact exported identifier in state_happiness.dart and
  repository_providers.dart, correct the name in the invalidation calls
- Type mismatch → confirm family function signature from the generated .g.dart file

Do NOT suppress analyzer warnings with // ignore: comments — fix the root cause.

Also run the grep verification:
  grep -n "happinessReport\|bestJoyMoment" lib/features/home/presentation/screens/main_shell_screen.dart

Expected: ≥4 matches (2 from FAB block, 2 from sync listener block).

Document manual test steps in the task completion output:

Manual verification steps:
1. Launch app on simulator or device
2. Navigate to home screen — note current 悦己统计 ring values and 本月最爱 merchant name
3. Tap FAB → create a new soul-ledger (Soul / 灵魂账本) transaction with a category
4. Confirm the transaction — app returns to home screen automatically
5. WITHOUT pull-to-refresh: verify 悦己统计 ring percentages or amounts update
6. WITHOUT pull-to-refresh: verify 本月最爱 merchant name or amount updates
7. If no visible change: create a second soul transaction with a higher amount for a
   different merchant — best joy changes when a higher-ranked entry exists

Sync path (if family sync configured):
1. On a second family device, create a soul-ledger transaction
2. After sync status goes idle on the first device, confirm home 悦己统计 + 本月最爱 update
   without swipe-to-refresh

Service-layer risk note for SUMMARY.md (no code fix needed here):
Analytics screen also watches happinessReportProvider and bestJoyMomentProvider. If a
transaction is entered from the analytics tab FAB, analytics screen will not auto-refresh
those providers on return — user must swipe-to-refresh. Record under "Related Risk" in
SUMMARY.md per CONTEXT.md instructions.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze 2>&1 | tail -3</automated>
  </verify>
  <done>
flutter analyze reports "No issues found!" (0 issues). Grep confirms ≥4 occurrences of
happinessReport/bestJoyMoment in main_shell_screen.dart. Manual test steps documented.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Riverpod container cache → UI | Stale cached FutureProvider values served to widgets without re-query |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-kyr-01 | Information Disclosure | happinessReportProvider family key | accept | currencyCode is non-sensitive (currency symbol string like "JPY"); reading from already-watched bookByIdProvider poses no new exposure |
| T-kyr-02 | Tampering | ref.invalidate on wrong family instance | mitigate | Use ?? 'JPY' fallback matching home_screen.dart:95–96 exactly — ensures invalidation targets the live cached instance, not a new family key |
</threat_model>

<verification>
1. `flutter analyze` — must report "No issues found!" (0 issues)
2. `grep -n "happinessReport\|bestJoyMoment" lib/features/home/presentation/screens/main_shell_screen.dart` — must return ≥4 lines (2 in FAB block, 2 in sync listener block)
3. `grep -c "ref\.invalidate" lib/features/home/presentation/screens/main_shell_screen.dart` — must be ≥8 (was 4 before fix)
</verification>

<success_criteria>
- main_shell_screen.dart FAB onFabTap block invalidates monthlyReportProvider, todayTransactionsProvider, happinessReportProvider, and bestJoyMomentProvider
- main_shell_screen.dart sync listener block invalidates the same four providers on syncing→synced transition
- happinessReportProvider invalidation in both sites uses currencyCode from bookByIdProvider ?? 'JPY'
- Two new imports added: repository_providers.dart and state_happiness.dart
- flutter analyze 0 issues
- No build_runner run required
- Analytics screen "Related Risk" documented in SUMMARY.md (no code change to analytics screen)
</success_criteria>

<output>
Create `.planning/quick/260518-kyr-fix-soul-stats-and-monthly-favorite-not-/260518-kyr-SUMMARY.md` when done.

Include in SUMMARY.md under "Related Risk":
> Analytics screen (analytics_screen.dart) also watches happinessReportProvider and
> bestJoyMomentProvider. It has pull-to-refresh that manually invalidates them, but if a
> transaction is entered from the analytics tab FAB, those providers are NOT auto-invalidated
> on return. The user must swipe-to-refresh to see updated soul stats on the analytics screen.
> This is a latent UX inconsistency — out of scope for this fix per CONTEXT.md.
</output>
