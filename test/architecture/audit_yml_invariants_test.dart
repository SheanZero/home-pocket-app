// test/architecture/audit_yml_invariants_test.dart
// Architecture meta-test: enforces the load-bearing structural invariants of
// .github/workflows/audit.yml established by Phase 8 Plans 08-02 / 08-03 / 08-06.
//
// These invariants are the post-cleanup CI-permanence contract (EXIT-04 / EXIT-05).
// Failing this test means a future PR weakened a permanent guardrail. The fix is
// either to revert the audit.yml change OR to amend ADR-011 first — never to
// loosen this assertion.
//
// The 6 invariants under test (per the gap brief):
//   1. Top-of-file warning comment block contains `Permanent gate`, `ADR-011`,
//      and `Phase 8 D-05` substrings.
//   2. Zero `continue-on-error: true` lines anywhere in the file.
//   3. Zero `if: ${{ github.event_name == 'pull_request' }}` lines (the Phase 8
//      D-05 #3 lift; restoring it would let direct-to-main bypass the coverage
//      gate).
//   4. The authoritative reproducibility wrapper is present as a blocking
//      architecture gate; it owns import_lint after two clean generation passes.
//   5. `coverage_gate.dart --list
//      .planning/audit/coverage-gate-required-files.txt` (the current
//      risk-boundary manifest; not either retired historical manifest).
//   6. `coverage_gate.dart` invocation includes
//      `--deferred .planning/audit/coverage-gate-deferred.txt` (per 08-06
//      amendment #2).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('audit.yml permanent-gate invariants', () {
    const path = '.github/workflows/audit.yml';
    late String content;

    setUpAll(() {
      final f = File(path);
      expect(f.existsSync(), isTrue, reason: 'audit.yml must exist at $path');
      content = f.readAsStringSync();
    });

    test(
      'Invariant 1: top-of-file warning comment block has all three '
      'load-bearing substrings (Permanent gate / ADR-011 / Phase 8 D-05)',
      () {
        // The warning block must appear before `name: audit` so that the first
        // thing any future editor sees is the load-bearing-ness notice.
        final nameIdx = content.indexOf('name: audit');
        expect(
          nameIdx,
          greaterThan(0),
          reason: 'audit.yml must contain a top-level `name: audit` line',
        );
        final preamble = content.substring(0, nameIdx);

        expect(
          preamble,
          contains('Permanent gate'),
          reason:
              'Top-of-file warning comment must say "Permanent gate" — '
              'this is the explicit signal Phase 8 D-05 #1 mandated.',
        );
        expect(
          preamble,
          contains('ADR-011'),
          reason: 'Top-of-file warning comment must cross-reference ADR-011.',
        );
        expect(
          preamble,
          contains('Phase 8 D-05'),
          reason:
              'Top-of-file warning comment must cite Phase 8 D-05 by name '
              'so future readers can locate the decision context.',
        );
      },
    );

    test('Invariant 2: zero `continue-on-error: true` lines (no soft-fail '
        'flag on any guardrail)', () {
      // Any matching line is a regression of the Phase 8 D-05 #2 sweep.
      // Allow whitespace tolerance via regex.
      final regex = RegExp(r'continue-on-error:\s*true', multiLine: true);
      final matches = regex.allMatches(content).toList();
      expect(
        matches,
        isEmpty,
        reason:
            'audit.yml must contain ZERO `continue-on-error: true` lines. '
            'Found ${matches.length} occurrence(s) — restoring soft-fail on a '
            'guardrail violates Phase 8 D-05 #2 (permanence).',
      );
    });

    test('Invariant 3: zero `if: pull_request`-only guards (the Phase 8 D-05 '
        '#3 lift means push-to-main also runs every job)', () {
      // The exact form Phase 8 D-05 #3 removed.
      // Match conservatively — any literal `pull_request` inside an `if:`
      // expression that gates a job exclusively to PR events.
      // We guard against three textual forms:
      //   if: ${{ github.event_name == 'pull_request' }}
      //   if: github.event_name == 'pull_request'
      //   if: ${{ github.event_name == "pull_request" }}
      final regexes = [
        RegExp(
          r'''if:\s*\$\{\{\s*github\.event_name\s*==\s*['"]pull_request['"]\s*\}\}''',
        ),
        RegExp(r'''if:\s*github\.event_name\s*==\s*['"]pull_request['"]'''),
      ];
      for (final re in regexes) {
        final matches = re.allMatches(content).toList();
        expect(
          matches,
          isEmpty,
          reason:
              'audit.yml must contain ZERO `if: pull_request`-only guards '
              '(Phase 8 D-05 #3). Found ${matches.length} match(es) for '
              'pattern `${re.pattern}`. Restoring this guard would let '
              'direct-to-main commits bypass the coverage gate.',
        );
      }
    });

    test('Invariant 4: the authoritative wrapper is a blocking architecture '
        'gate', () {
      final regex = RegExp(
        r'^\s*run:\s+bash\s+scripts/verify_codegen_reproducibility\.sh\s*$',
        multiLine: true,
      );
      expect(
        regex.hasMatch(content),
        isTrue,
        reason:
            'audit.yml must invoke the authoritative wrapper that runs '
            'import_lint after locked resolution and two clean generation '
            'passes.',
      );
      expect(content, isNot(contains('dart run custom_lint')));
      expect(
        content,
        isNot(contains('dart run import_lint')),
        reason:
            'audit.yml must not restore a parallel inline import_lint path; '
            'the sole wrapper owns the ordered architecture gate.',
      );
    });

    test('Invariant 5: coverage_gate.dart `--list` argument points at '
        '.planning/audit/coverage-gate-required-files.txt', () {
      // The gate must read the curated risk-boundary manifest, rather than a
      // historical phase-union list whose stale paths weaken the invariant.
      final regex = RegExp(
        r'coverage_gate\.dart\s+--list\s+\.planning/audit/coverage-gate-required-files\.txt',
      );
      expect(
        regex.hasMatch(content),
        isTrue,
        reason:
            'audit.yml must invoke `coverage_gate.dart --list '
            '.planning/audit/coverage-gate-required-files.txt`. Reverting to '
            'a retired historical manifest would weaken the active coverage '
            'obligation.',
      );

      for (final retiredManifest in [
        'cleanup-touched-files.txt',
        'phase6-touched-files.txt',
      ]) {
        final retired = RegExp(
          'coverage_gate\\.dart\\s+--list\\s+\\.planning/audit/'
          '${RegExp.escape(retiredManifest)}',
        );
        expect(
          retired.hasMatch(content),
          isFalse,
          reason:
              'Retired `--list .planning/audit/$retiredManifest` must NOT '
              'appear in audit.yml. The risk-boundary manifest is the active '
              'coverage gate input.',
        );
      }
    });

    test('Invariant 6: coverage_gate.dart invocation includes '
        '`--deferred .planning/audit/coverage-gate-deferred.txt` (08-06 '
        'amendment #2)', () {
      // The deferral file is the load-bearing mechanism that lets the gate
      // pass while the 10 known-low-coverage files carry written rationale.
      // Removing --deferred would either re-fail the gate (if those files
      // remain low) or hide them behind WARNINGs — both regressions.
      final regex = RegExp(
        r'--deferred\s+\.planning/audit/coverage-gate-deferred\.txt',
      );
      expect(
        regex.hasMatch(content),
        isTrue,
        reason:
            'audit.yml must pass `--deferred '
            '.planning/audit/coverage-gate-deferred.txt` to coverage_gate.dart '
            '(Phase 8 08-06 amendment #2). The deferral file carries '
            'rationale for each scope-reduced entry; removing this flag '
            'breaks the EXIT-04 close contract.',
      );

      // Cross-check: the deferred file itself must exist at the referenced path.
      // (If the path drifts, the gate fails at runtime — but the test catches
      // the drift earlier by verifying the file is present.)
      expect(
        File('.planning/audit/coverage-gate-deferred.txt').existsSync(),
        isTrue,
        reason:
            '.planning/audit/coverage-gate-deferred.txt must exist (referenced '
            'by audit.yml --deferred argument).',
      );
    });

    test(
      'Invariant 7: every Stable Flutter job retrieves the committed lock',
      () {
        final coverage = RegExp(
          r'^  coverage:\n([\s\S]*?)(?=^  [a-z][a-z0-9-]*:\n|\z)',
          multiLine: true,
        ).firstMatch(content)?.group(1);
        expect(coverage, isNotNull, reason: 'audit.yml must retain coverage');
        expect(
          coverage,
          contains('flutter pub get --enforce-lockfile'),
          reason:
              'coverage is an independent Stable Flutter job and must retrieve '
              'the committed dependency graph with lock enforcement.',
        );
        expect(
          RegExp(
            r'^\s*-\s*run:\s*flutter pub get\s*$',
            multiLine: true,
          ).hasMatch(coverage!),
          isFalse,
          reason: 'coverage must not retain ordinary unlocked Pub retrieval.',
        );
      },
    );
  });
}
